"""Real addon namespaces and load order for Minimap ownership/compatibility.

These checks exercise persistence contracts and dispatch, not native taint safety.
"""
from pathlib import Path
import runpy
from lupa.lua51 import LuaRuntime

ROOT = Path(__file__).resolve().parents[1]
legend = runpy.run_path(str(ROOT / 'tests/gathering-legend-check.py'))
launch = runpy.run_path(str(ROOT / 'tests/gathering-launch-check.py'))
STARTUP = r'''
loadCallbacks={};loadedAddons={};settingsPages={};settingsValues={}
EventUtil={ContinueOnAddOnLoaded=function(name,fn)
 if loadedAddons[name] then fn() else
  loadCallbacks[name]=loadCallbacks[name] or {};table.insert(loadCallbacks[name],fn)
 end
end}
function loaded(name)
 loadedAddons[name]=true
 for _,fn in ipairs(loadCallbacks[name] or {}) do fn() end
 loadCallbacks[name]=nil
end
print=function(text) logs[#logs+1]=text end
SlashCmdList={}
C_AddOns.GetAddOnMetadata=function(addon,key) return key=='Version' and 'test' or addon end
local function layout() return {AddInitializer=function() end} end
function CreateSettingsListSectionHeaderInitializer(title) return title end
Settings={VarType={Boolean='Boolean'},
 RegisterVerticalLayoutCategory=function(title) return {GetID=function() return 1 end},layout() end,
 RegisterVerticalLayoutSubcategory=function(_,title) settingsPages[#settingsPages+1]=title;return {},layout() end,
 RegisterAddOnCategory=function() end,CreateCheckbox=function() end,OpenToCategory=function() end,
 RegisterAddOnSetting=function(_,variable,key,db,_,name,default)
  local setting={db=db,key=key,default=default,name=name}
  function setting:SetValueChangedCallback(fn) self.callback=fn end
  settingsValues[variable]=setting;return setting
 end,
 SetValue=function(variable,value)
  local setting=assert(settingsValues[variable],variable)
  setting.db[setting.key]=value;setting.callback(setting,value)
 end,
}
function slash(text) SlashCmdList.COUCHSIDE(text) end
'''


def load_addon(vm, name, namespace):
    for line in (ROOT / name / (name + '.toc')).read_text().splitlines():
        if line.endswith('.lua'):
            vm.execute('local text,addon,namespace=...;assert(loadstring(text))(addon,namespace)',
                       (ROOT / name / line).read_text(), name, namespace)
    vm.globals().loaded(name)


def make(setup='', gathering=True):
    vm = LuaRuntime(register_eval=False, register_builtins=False)
    vm.execute(legend['STUB'])
    vm.execute(launch['STUB'])
    vm.execute(STARTUP)
    vm.execute(setup)
    vm.execute('baseNS={};minimapNS={};gatheringNS={}')
    load_addon(vm, 'Couchside', vm.globals().baseNS)
    load_addon(vm, 'Couchside_Minimap', vm.globals().minimapNS)
    if gathering:
        load_addon(vm, 'Couchside_Gathering', vm.globals().gatheringNS)
    vm.execute("fire('PLAYER_LOGIN')")
    return vm


def check(name, code, setup='', gathering=True):
    make(setup, gathering).execute(code)
    print('PASS', name)


check('real three-addon TOC load stays idle with all display defaults disabled', r'''
advance(30)
assert(queries==0 and created==0 and #softRequests==0)
assert(CouchsideMinimapDB.version==1 and CouchsideMinimapDB.nextID==1)
assert(minimapNS.ResourceCatalog==gatheringNS.ResourceCatalog)
assert(minimapNS.ResourceDifficulty==gatheringNS.ResourceDifficulty)
assert(settingsPages[1]=='Minimap' and #settingsPages==1)
''')
check('old and canonical scan commands share one scanner and sequential history', r'''
slash('option gathering.nearbyList on')
slash('gathering scan');advance(3)
assert(#CouchsideMinimapDB.scans==1 and queries==1009 and #softRequests==2)
slash('minimap scan');advance(3)
assert(#CouchsideMinimapDB.scans==2 and queries==2018 and #softRequests==4)
assert(CouchsideMinimapDB.scans[1].id==1 and CouchsideMinimapDB.scans[2].id==2)
assert(not soft)
''')
check('legacy history is fully copied without truncation or shared tables', r'''
local db=CouchsideMinimapDB
assert(db.nextID==500 and db.nextSkillReportID==11 and db.scans[1].id==499)
assert(db.extra.deep[3000]=='kept' and db.scans~=CouchsideGatheringScanDB.scans)
db.scans[1].nested.value='new';assert(CouchsideGatheringScanDB.scans[1].nested.value=='old')
assert(db.automaticScanSettings.delaySeconds==3)
assert(CouchsideGatheringScanDB.migration==nil)
''', r'''
CouchsideGatheringScanDB={version=1,nextID=500,scans={{id=499,nested={value='old'}}},
 nextSkillReportID=11,automaticScanSettings={delaySeconds=3},extra={deep={}}}
for i=1,3000 do CouchsideGatheringScanDB.extra.deep[i]='kept' end
''')
check('established canonical history wins without merging or modifying legacy', r'''
assert(CouchsideMinimapDB.nextID==81 and CouchsideMinimapDB.scans[1].id==80)
assert(CouchsideGatheringScanDB.nextID==501 and CouchsideGatheringScanDB.scans[1].id==500)
slash('minimap migration');assert(table.concat(logs,'\n'):find('existing Minimap history retained'))
''', "CouchsideMinimapDB={version=1,nextID=81,scans={{id=80}}};CouchsideGatheringScanDB={version=1,nextID=501,scans={{id=500}}}")
check('Minimap alone loads safely and keeps legacy scan macros working', r'''
assert(minimapNS.ResourceCatalog==nil and CouchsideMinimapDB.migration.status=='pending')
slash('option gathering.nearbyList on');slash('option gathering.resourceLegend on')
slash('gathering scan');advance(3)
assert(#CouchsideMinimapDB.scans==1 and queries==1009 and not soft)
slash('minimap classify');assert(logs[#logs]:find('requires Couchside: Gathering'))
''', gathering=False)
check('later Gathering enable imports a pristine pending canonical history', r'''
assert(CouchsideMinimapDB.scans[1].id==40 and CouchsideMinimapDB.nextID==41)
assert(CouchsideMinimapDB.migration.status=='imported')
assert(CouchsideGatheringScanDB.scans[1].id==40)
''', "CouchsideMinimapDB={version=1,nextID=1,scans={},migration={status='pending'},automationReport={attempts=0}};CouchsideGatheringScanDB={version=1,nextID=41,scans={{id=40}}}")
check('later Gathering enable preserves both histories when new evidence exists', r'''
assert(CouchsideMinimapDB.scans[1].id==1 and CouchsideMinimapDB.nextID==2)
assert(CouchsideGatheringScanDB.scans[1].id==40 and CouchsideGatheringScanDB.nextID==41)
assert(table.concat(logs,'\n'):find('conflict'))
slash('minimap migration');assert(table.concat(logs,'\n'):find('retained separately'))
''', "CouchsideMinimapDB={version=1,nextID=2,scans={{id=1}},migration={status='pending'}};CouchsideGatheringScanDB={version=1,nextID=41,scans={{id=40}}}")
check('explicit false options and both option prefixes share the existing saved table', r'''
assert(CouchsideDB.modules.gathering.nearbyList==false and CouchsideDB.modules.minimap==nil)
assert(not minimapNS.IsEnabled('nearbyList') and not minimapNS.IsEnabled('resourceLegend'))
slash('option gathering.nearbyList on');assert(minimapNS.IsEnabled('nearbyList'))
slash('option minimap.nearbyList off');assert(not minimapNS.IsEnabled('nearbyList'))
slash('option gathering.resourceLegend on');assert(minimapNS.IsEnabled('resourceLegend'))
slash('option minimap.resourceLegend off');assert(not minimapNS.IsEnabled('resourceLegend'))
assert(settingsValues.COUCHSIDE_MINIMAP_NEARBYLIST.db==CouchsideDB.modules.gathering)
''', 'CouchsideDB={modules={gathering={nearbyList=false,autoScan=false,resourceLegend=false}}}')
check('unsupported canonical schema blocks writes and leaves both copies untouched', r'''
assert(CouchsideMinimapDB.version==99 and CouchsideMinimapDB.precious=='keep')
slash('gathering skills baseline');slash('minimap log clear');advance(5)
assert(CouchsideMinimapDB.skillReports==nil and CouchsideMinimapDB.automationReport==nil)
assert(CouchsideGatheringScanDB.nextID==41 and queries==0 and #softRequests==0)
''', "CouchsideMinimapDB={version=99,precious='keep'};CouchsideGatheringScanDB={version=1,nextID=41,scans={}};CouchsideDB={modules={gathering={nearbyList=true,autoScan=true}}}")
check('unsupported legacy schema is preserved without creating a replacement history', r'''
assert(CouchsideMinimapDB==nil and CouchsideGatheringScanDB.version==99)
slash('gathering skills baseline');assert(CouchsideGatheringScanDB.skillReports==nil)
assert(table.concat(logs,'\n'):find('legacy history unavailable or unsupported'))
''', 'CouchsideGatheringScanDB={version=99,precious=true}')
check('malformed canonical history stays unavailable without diagnostic writes', r'''
assert(CouchsideMinimapDB.precious and CouchsideMinimapDB.scans==nil)
slash('gathering skills baseline');slash('minimap log clear')
assert(CouchsideMinimapDB.skillReports==nil and CouchsideMinimapDB.scans==nil)
''', 'CouchsideMinimapDB={version=1,nextID=1,precious=true}')
check('Gathering skills remain their own command and save through the Minimap owner', r'''
slash('gathering skills baseline')
assert(CouchsideMinimapDB.skillReports[1].label=='baseline')
assert(CouchsideGatheringScanDB.skillReports==nil)
assert(CouchsideMinimapDB.nextSkillReportID==2 and CouchsideMinimapDB.nextID==1)
slash('gathering classify');assert(logs[#logs]:find('No matching retained scan'))
''', 'CouchsideGatheringScanDB={version=1,nextID=1,scans={}}')
check('existing Scan map macro is recognized without rewriting its body', r'''
slash('gathering macro probe');slash('minimap macro create')
assert(created==0 and macros[1].body=='/cs gathering scan' and macros[1].icon==123)
''', "accountCount=1;macros[1]={name='Scan map',body='/cs gathering scan',icon=123}")
check('compatibility help preserves Gathering commands and explains moved commands', r'''
slash('gathering help');local text=table.concat(logs,'\n')
assert(text:find('/cs gathering skills') and text:find('/cs minimap scan'))
assert(text:find('Moved commands remain available'))
''')
check('moved diagnostics distinguish old Gathering and new Minimap provenance', r'''
slash('minimap display');assert(table.concat(logs,'\n'):find('Couchside_Gathering 0.16.2'))
logs={};slash('option minimap.nearbyList on');slash('minimap scan');advance(3)
slash('minimap display');assert(table.concat(logs,'\n'):find('Couchside_Minimap test'))
assert(CouchsideMinimapDB.scans[2].display.addon=='Couchside_Minimap')
logs={};slash('minimap panels');assert(table.concat(logs,'\n'):find('Minimap test'))
''', "CouchsideGatheringScanDB={version=1,nextID=2,scans={{id=1,display={version=1,status='cleared',reason='expired',addonVersion='0.16.2',scanID=1}}}}")
print('15 ownership migration checks passed; native load and reload acceptance remain separate')
