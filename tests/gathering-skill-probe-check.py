"""Gathering skill report: raw evidence only, bounded storage, no live color use."""
from pathlib import Path
from lupa.lua51 import LuaRuntime

ROOT = Path(__file__).resolve().parents[1]
STUB = r'''
logs={};commands={};calls=0;count=2
ns={version='test',Print=function(fmt,...) logs[#logs+1]=string.format(fmt,...) end,Debug=function() end,
 RegisterCommand=function(name,_,fn) commands[name]=fn end,OnReady=function(fn) fn() end}
function GetServerTime() return 123 end
function GetBuildInfo() return '1.60.1','70374','',16001 end
character='Player-test-A'
function UnitGUID(unit) assert(unit=='player');return character end
function issecretvalue(value) return type(value)=='table' and value.secret end
C_SkillInfo={GetSkillLineInfoByID=function(id)
 calls=calls+1
 if id==182 then return {skillID=182,name='Herbalism',rank=124,maxRank=150,modifier=5,tempPoints=0} end
end,GetNumSkillLines=function() return count end,
 GetSkillLineInfo=function(index) calls=calls+1;return {skillID=index,rank=0,isCollapsed=true} end}
GameTooltip={IsShown=function() return true end,
 GetPrimaryTooltipData=function() return {lines={{leftText='Peacebloom',leftColor={r=1,g=.5,b=0}}}} end}
C_TooltipInfo={GetMinimapMouseover=function() return {type=21,lines={{leftText='Peacebloom'}}} end}
local function forbidden() error('no native mutations allowed') end
C_SkillInfo.ExpandSkillHeader=forbidden;C_SkillInfo.CollapseSkillHeader=forbidden;C_SkillInfo.AbandonSkill=forbidden
GameTooltip.SetUnit=forbidden;GameTooltip.Show=forbidden
Minimap={SetUsingSoftCursor=forbidden,UpdateMouseoverAtPoint=forbidden}
function C_TimerAfter() forbidden() end
'''


def check(name, code):
    vm = LuaRuntime(register_eval=False, register_builtins=False)
    vm.execute(STUB)
    for name_ in ('ScanLog.lua', 'SkillProbe.lua'):
        vm.execute('assert(loadstring(...))("Couchside_Gathering",ns)', (ROOT / 'Couchside_Gathering' / name_).read_text())
    vm.execute(code)
    print('PASS', name)


check('gathering skills idle until explicitly requested', "assert(calls==0 and CouchsideGatheringScanDB.skillReports==nil)")
check('gathering skill report preserves rank modifier and nil without inferring difficulty', r'''
commands.skills('baseline');local r=CouchsideGatheringScanDB.skillReports[1]
assert(r.skills.Herbalism.result.value.rank==124 and r.skills.Herbalism.result.value.modifier==5)
assert(r.skills.Mining.result.status=='nil' and r.difficulty==nil)
assert(r.tooltip.value.lines[1].leftColor.g==.5 and r.minimapHover.value.type==21)
assert(#logs==3 and r.client.build=='70374' and r.label=='baseline')
''')
check('skill API absence error and restricted values stay distinct', r'''
C_SkillInfo.GetSkillLineInfoByID=function(id) if id==182 then return {secret=true} else error('read failed') end end
commands.skills('restricted');local r=CouchsideGatheringScanDB.skillReports[1]
assert(r.skills.Herbalism.result.status=='restricted' and r.skills.Mining.result.status=='error')
C_SkillInfo=nil;commands.skills('missing');r=CouchsideGatheringScanDB.skillReports[2]
assert(r.skills.Herbalism.result.status=='missing' and r.skillCount.status=='missing')
''')
check('account-wide skill samples retain sanitized character identity', r'''
commands.skills('baseline');character='Player-test-B';commands.skills('baseline')
local reports=CouchsideGatheringScanDB.skillReports
assert(reports[1].character.value=='Player-test-A' and reports[2].character.value=='Player-test-B')
character={secret=true};commands.skills('restricted')
assert(reports[3].character.status=='restricted')
''')
check('hidden tooltip data is not mistaken for current hover', r'''
GameTooltip.IsShown=function() return false end
GameTooltip.GetPrimaryTooltipData=function() error('hidden getter must not run') end
commands.skills('hidden');local r=CouchsideGatheringScanDB.skillReports[1]
assert(r.tooltipVisible.status=='ok' and r.tooltipVisible.value==false)
assert(r.tooltip.status=='not-shown-or-unknown')
''')
check('skill enumeration and separate history stay bounded without changing raw scans', r'''
count=200;local scan={id=5,precious=true};CouchsideGatheringScanDB.scans={scan};CouchsideGatheringScanDB.nextID=6
for i=1,5 do commands.skills('sample-'..i) end
local db=CouchsideGatheringScanDB;assert(#db.skillReports==3 and db.skillReports[1].id==3)
assert(#db.skillReports[3].enumeration==64 and db.skillReports[3].enumerationTruncated)
assert(db.scans[1]==scan and db.nextID==6 and db.nextSkillReportID==6)
''')
check('invalid label and unsupported database do not run skill reads', r'''
commands.skills('bad label');assert(calls==0 and CouchsideGatheringScanDB.skillReports==nil)
CouchsideGatheringScanDB={version=99,precious=true};commands.skills('test')
assert(calls==0 and CouchsideGatheringScanDB.precious and CouchsideGatheringScanDB.skillReports==nil)
''')
check('log summarizes and clears skill reports without resetting report IDs', r'''
commands.skills('');commands.log('');assert(logs[#logs]:find('latest 1'))
commands.log('clear');assert(CouchsideGatheringScanDB.skillReports==nil)
commands.skills('new');assert(CouchsideGatheringScanDB.skillReports[1].id==2)
''')
print('8 gathering skill report checks passed; native skill APIs need validation')
