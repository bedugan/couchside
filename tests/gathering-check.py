"""Lua 5.1 checks for the Gathering catalog, difficulty bands and tooltip line.

Fixtures cannot establish taint safety or how the native tooltip renders.
"""
from pathlib import Path

from lupa.lua51 import LuaRuntime

ROOT = Path(__file__).resolve().parents[1]
FILES = ("Gathering.lua", "ResourceCatalog.lua", "ResourceDifficulty.lua", "Tooltip.lua", "SkillProbe.lua")
STUB = r'''
logs={};commands={};clock=0;enabled=true;build='1.60.1'
skill={herb={rank=138,maxRank=225,modifier=0,tempPoints=0}}
C_AddOns={GetAddOnMetadata=function() return 'test' end}
Enum={TooltipDataType={Object=4}}
Couchside={RegisterModule=function(ns,spec)
 ns.spec=spec;ns.Debug=function() end
 ns.Print=function(fmt,...) logs[#logs+1]=string.format(fmt,...) end
 ns.RegisterCommand=function(k,_,fn) commands[k]=fn end
 ns.IsEnabled=function(k) assert(k=='tooltipDifficulty');return enabled end
end}
function GetTime() return clock end
function GetBuildInfo() return build,'70374' end
C_SkillInfo={GetSkillLineInfoByID=function(id)
 local s=skill[id==182 and 'herb' or 'ore'];if not s then return nil end
 return {skillID=id,rank=s.rank,maxRank=s.maxRank,modifier=s.modifier,tempPoints=s.tempPoints}
end}
postCalls={}
TooltipDataProcessor={AllTypes='ALL',AddTooltipPostCall=function(kind,fn) assert(kind=='ALL');postCalls[#postCalls+1]=fn end}
native={};hooks={};shows=0
GameTooltip={owner={GetName=function() return 'UIParent' end}}
function GameTooltip:GetOwner() return self.owner end
function GameTooltip:HookScript(k,fn) hooks[k]=fn end
function GameTooltip:NumLines() return #native end
function GameTooltip:AddLine(text,r,g,b) native[#native+1]={text=text,r=r,g=g,b=b,ours=true} end
function GameTooltip:Show() shows=shows+1;hooks.OnShow(self) end
for i=1,20 do _G['GameTooltipTextLeft'..i]={GetText=function() return native[i] and native[i].text end} end
-- Data-driven build, as TooltipDataHandler:ProcessInfo does it.
function dataTooltip(kind,lines)
 native={};hooks.OnTooltipCleared()
 local data={type=kind,lines={}}
 for i,t in ipairs(lines) do data.lines[i]={leftText=t};native[i]={text=t} end
 for _,fn in ipairs(postCalls) do fn(GameTooltip,data) end
 GameTooltip:Show()
end
-- Natively filled tooltip with no data post-call.
function nativeTooltip(lines)
 native={};hooks.OnTooltipCleared()
 for i,t in ipairs(lines) do native[i]={text=t} end
 GameTooltip:Show()
end
function added() local r={};for _,l in ipairs(native) do if l.ours then r[#r+1]=l end end;return r end
'''


def make():
    vm = LuaRuntime(register_eval=False)
    vm.execute(STUB)
    vm.execute("ns={}")
    for name in FILES:
        vm.execute('local text=...;assert(loadstring(text))("Couchside_Gathering",ns)',
                   (ROOT / 'Couchside_Gathering' / name).read_text())
    return vm


def check(name, code):
    make().execute(code)
    print('PASS', name)


check('native 138 skill sample produces distinct Classic reference bands', r'''
local profile={herb={status='ok',rank=138,maximum=225}}
for name,key in pairs({Peacebloom='gray',Mageroyal='green',Briarthorn='green',Bruiseweed='yellow',Kingsblood='orange',['Purple Lotus']='red'}) do
 assert(ns.ResourceDifficulty.Evaluate(name,profile).key==key,name)
end
assert(ns.ResourceDifficulty.Evaluate('NPC',profile).key=='unknown')
''')
check('every exact band threshold is respected', r'''
for _,name in ipairs({'Peacebloom','Mageroyal','Dreamfoil','Copper Vein','Tin Vein','Rich Thorium Vein','Small Obsidian Chunk'}) do
 local entry=ns.ResourceCatalog.Lookup(name);local b=entry.difficulty
 local function key(rank) return ns.ResourceDifficulty.Evaluate(name,{[entry.category]={status='ok',rank=rank,maximum=500}}).key end
 if b.minimum>1 then assert(key(b.minimum-1)=='red') end
 assert(key(b.minimum)=='orange' and key(b.yellow-1)=='orange')
 assert(key(b.yellow)=='yellow' and key(b.green-1)=='yellow')
 assert(key(b.green)=='green' and key(b.gray-1)=='green' and key(b.gray)=='gray')
end
''')
check('cap missing skill and quest-only minerals stay conservative', r'''
assert(ns.ResourceDifficulty.Evaluate('Kingsblood',{herb={status='ok',rank=150,maximum=150}}).key=='cap')
assert(ns.ResourceDifficulty.Evaluate('Purple Lotus',{herb={status='ok',rank=150,maximum=150}}).key=='red')
assert(ns.ResourceDifficulty.Evaluate('Copper Vein',{ore={status='nil'}}).key=='unknown')
assert(ns.ResourceDifficulty.Evaluate('Incendicite Mineral Vein',{ore={status='ok',rank=150,maximum=150}}).key=='unknown')
''')
check('skill capture gates client, bonuses, secrets and errors', r'''
build='12.1.0';assert(ns.ResourceDifficulty.Capture().herb.status=='unsupported-client')
build='1.60.1';skill.herb.modifier=5;assert(ns.ResourceDifficulty.Capture().herb.status=='unverified-bonus')
function issecretvalue(v) return type(v)=='table' and v.secret end
skill.herb={rank={secret=true},maxRank=225,modifier=0,tempPoints=0};assert(ns.ResourceDifficulty.Capture().herb.status=='invalid')
C_SkillInfo.GetSkillLineInfoByID=function() error('unavailable') end
assert(ns.ResourceDifficulty.Capture().herb.status=='error')
''')
check('catalog lookups are copies and ooze variants share a type', r'''
local entry=ns.ResourceCatalog.Lookup('Purple Lotus');entry.difficulty.minimum=1;entry.name='bad'
assert(ns.ResourceCatalog.Lookup('Purple Lotus').difficulty.minimum==210 and ns.ResourceCatalog.Lookup('Purple Lotus').name=='Purple Lotus')
assert(ns.ResourceCatalog.Lookup('Ooze Covered Silver Vein').key==ns.ResourceCatalog.Lookup('Silver Vein').key)
assert(not ns.ResourceCatalog.Lookup('Swiftthistle') and ns.ResourceCatalog.nameCount==50 and ns.ResourceCatalog.typeCount==44)
''')
check('a world node tooltip gets one colored line through the native OnShow path', r'''
nativeTooltip({'Kingsblood','Requires Herbalism'})
local a=added();assert(#a==1 and a[1].text=='High · Herbalism 138',a[1] and a[1].text)
assert(a[1].r==1 and a[1].g==0.682 and shows==2)
''')
check('a data tooltip is annotated once even though Show re-enters OnShow', r'''
dataTooltip(4,{'Bruiseweed'})
local a=added();assert(#a==1 and a[1].text=='Medium · Herbalism 138')
''')
check('only the first known name gets a line, after color codes are removed', r'''
dataTooltip(4,{'|cffffffffPeacebloom|r','Purple Lotus'})
local a=added();assert(#a==1 and a[1].text=='No gain · Herbalism 138')
''')
check('per-frame rebuilds do not stack lines or re-read skill', r'''
local reads=0;local read=C_SkillInfo.GetSkillLineInfoByID
C_SkillInfo.GetSkillLineInfoByID=function(...) reads=reads+1;return read(...) end
for i=1,30 do clock=clock+.016;dataTooltip(4,{'Mageroyal'}) end
assert(#added()==1 and reads<=2*1,reads)
''')
check('cap, unknown skill and Retail produce the right line or none', r'''
skill.herb={rank=150,maxRank=150,modifier=0,tempPoints=0};nativeTooltip({'Kingsblood'})
assert(added()[1].text=='At cap · Herbalism 150/150')
clock=clock+2;nativeTooltip({'Copper Vein'});assert(added()[1].text=='Mining difficulty unknown')
clock=clock+2;build='12.1.0';nativeTooltip({'Copper Vein'});assert(#added()==0)
''')
check('secret or unrelated text and the off option add nothing', r'''
function issecretvalue(v) return v=='SECRET' end
dataTooltip(4,{'SECRET'});assert(#added()==0)
nativeTooltip({'Thrall','Warchief'});assert(#added()==0)
enabled=false;nativeTooltip({'Kingsblood'});assert(#added()==0)
''')
check('unreadable data falls back to visible tooltip text', r'''
function issecretvalue(v) return v=='SECRET' end
native={};hooks.OnTooltipCleared()
for _,fn in ipairs(postCalls) do fn(GameTooltip,{type=4,lines={{leftText='SECRET'}}}) end
native={{text='Kingsblood'}};GameTooltip:Show()
assert(#added()==1)
''')
check('the tooltip report lists recent reads newest first and dedupes rebuilds', r'''
nativeTooltip({'Thrall'});for i=1,3 do dataTooltip(4,{'Mageroyal'}) end
commands.tooltip('')
local text=table.concat(logs,'\n')
assert(text:find('Object via data, owner UIParent: Mageroyal',1,true))
assert(text:find('2. native via show',1,true) and not text:find('3. ',1,true))
assert(text:find('added: Low · Herbalism 138',1,true))
''')
check('the skill report prints raw values without saving anything', r'''
skill.ore=nil;commands.skills('')
local text=table.concat(logs,'\n')
assert(text:find('Herbalism: rank 138/225',1,true) and text:find('Mining: nil',1,true))
assert(text:find('Herbalism ok, Mining nil',1,true))
''')
