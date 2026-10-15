"""Exercise automatic/manual scan ownership and native macro setup through commands.

Lua fixtures establish lifecycle and bounds, not native input or taint safety.
"""
from pathlib import Path
from gathering_sources import source_path
import runpy
from lupa.lua51 import LuaRuntime

ROOT = Path(__file__).resolve().parents[1]
legend = runpy.run_path(str(ROOT / "tests/gathering-legend-check.py"))
STUB = r'''
autoEnabled=false;speed=0;moving=false;mapVisible=true;cursorX=0;cursorY=0
function GetUIPanel() return nil end
local priorEnabled=ns.IsEnabled
ns.IsEnabled=function(k) if k=='autoScan' then return autoEnabled end;return priorEnabled(k) end
function GetUnitSpeed() return speed end
function IsPlayerMoving() return moving end
function GetBuildInfo() return '1.60.1','70374','date',16001 end
function GetServerTime() return 1791940000+math.floor(clock) end
function GetCursorPosition() return cursorX,cursorY end
Minimap.IsVisible=function() return mapVisible end
queue={};soft=false;softRequests={};queries=0
Minimap.SetUsingSoftCursor=function(_,value)
 assert(not combat,'native cursor setter in combat')
 softRequests[#softRequests+1]=value;soft=value
 if failEnable and value then error('native cursor enable failed') end
 if failCleanup and not value then error('native cleanup failed') end
end
Minimap.UpdateMouseoverAtPoint=function()
 queries=queries+1
 if queryAction then queryAction(queries) end
 if failQuery then error('native point query failed') end
end
C_TooltipInfo={GetMinimapMouseover=function() return {lines={{leftText='Earthroot'}}} end}
C_QuestLog={GetInfo=function() return nil end,GetQuestObjectives=function() return {} end}
C_Timer={After=function(delay,fn) queue[#queue+1]={at=clock+delay,fn=fn} end}
function fire(e,...)
 for _,f in ipairs(frames) do if f.events[e] and f.scripts.OnEvent then f.scripts.OnEvent(f,e,...) end end
end
function advance(seconds)
 local target=clock+seconds;local callbacks=0
 while clock<target-.0000001 do
  local nextTick=math.min(clock+.05,target)
  while true do
   table.sort(queue,function(a,b) return a.at<b.at end)
   if not queue[1] or queue[1].at>nextTick then break end
   local item=table.remove(queue,1);clock=item.at;item.fn()
   callbacks=callbacks+1;assert(callbacks<100000,'timer runaway')
  end
  clock=nextTick
  for _,f in ipairs(frames) do if f.shown and f.scripts.OnUpdate then f.scripts.OnUpdate(f,.05) end end
 end
end
function enableAuto() autoEnabled=true;changed('autoScan') end
Constants={MacroConsts={MAX_ACCOUNT_MACROS=3,MAX_CHARACTER_MACROS=2}}
macros={};accountCount=0;characterCount=0;created=0
function GetNumMacros() return accountCount,characterCount end
function GetMacroInfo(i)
 local m=macros[i];if m then return m.name,m.icon,m.body end
end
function CreateMacro(name,icon,body,character)
 assert(not combat and not character)
 created=created+1;accountCount=accountCount+1
 macros[accountCount]={name=name,icon=icon,body=body};return accountCount
end
'''


def make(setup=""):
    vm = legend["make"](STUB + setup)
    for name in ("PanelGuard.lua", "MinimapProbe.lua", "AutomaticScan.lua", "ScanMacro.lua"):
        vm.execute('assert(loadstring(...))("Couchside_Gathering",ns)', source_path(name).read_text())
    return vm


def check(name, code, setup=""):
    make(setup).execute(code)
    print("PASS", name)


# Real multi-addon TOC/startup coverage now lives in minimap-migration-check.py.


check("normal manual scan prints one completion line with unchanged scan results", r'''
commands.scan('');advance(3)
assert(#logs==1,'normal scan flooded chat: '..#logs)
assert(logs[1]:find('Scan complete') and CouchsideMinimapDB.scans[1].pointCount==1009)
assert(CouchsideMinimapDB.scans[1].cleanupRequestSucceeded and #softRequests==2)
''')
check("verbose scan keeps detailed output without changing native work", r'''
commands.scan('verbose');advance(3)
local s=CouchsideMinimapDB.scans[1]
assert(s and s.pointCount==1009 and s.cleanupRequestSucceeded and #softRequests==2)
assert(#logs>5 and table.concat(logs,'\n'):find('Quest%-text filter'))
''')
check("quiet manual scan still reports errors and interruption", r'''
failQuery=true;commands.scan('');advance(3)
assert(table.concat(logs,'\n'):find('Scan ERROR') and #CouchsideMinimapDB.scans==0 and not soft)
logs={};failQuery=false
queryAction=function(n) if n==10 then cursorX=100;cursorY=100 end end
commands.scan('');advance(3)
assert(table.concat(logs,'\n'):find('Scan stopped') and #CouchsideMinimapDB.scans==0 and not soft)
''')
check("automatic scanning defaults off and does no polling or cursor work", r'''
advance(30);assert(queries==0 and #softRequests==0)
assert(CouchsideMinimapDB.automationReport.status=='disabled')
''')
check("large grid completes at twenty frames per second before its work-sized watchdog", r'''
Minimap.GetRect=function() return 100,100,2000,2000 end
Minimap.GetEffectiveScale=function() return 1 end
C_TooltipInfo.GetMinimapMouseover=function() return nil end
local schedule=C_Timer.After
C_Timer.After=function(delay,fn) schedule(math.max(.05,delay),fn) end
commands.scan('');advance(30)
local s=CouchsideMinimapDB.scans[1]
assert(s and s.pointCount>5000 and s.pointCount<=8192,'large-grid scan discarded')
assert(s.durationSeconds>12 and s.cleanupRequestSucceeded and not soft)
''')
check("automatic history cannot evict manual diagnostic evidence", r'''
ns.SaveMinimapScan({source='manual'},true)
for i=1,11 do ns.SaveMinimapScan({source='automatic'},true) end
local scans=CouchsideMinimapDB.scans
assert(scans[1].source=='manual','automatic scans evicted manual evidence')
assert(#scans==3 and scans[2].id==11 and scans[3].id==12)
''')
check("manual and legacy histories retain ten records independently from two automatic records", r'''
for i=1,12 do ns.SaveMinimapScan({},true) end
for i=1,12 do ns.SaveMinimapScan({source='automatic'},true) end
local scans=CouchsideMinimapDB.scans
assert(#scans==12 and scans[1].id==3 and scans[10].id==12 and scans[11].id==23 and scans[12].id==24)
''')
check("loaded history is trimmed by source without changing IDs or starting scans", r'''
local scans=CouchsideMinimapDB.scans
assert(#scans==12 and scans[1].id==3 and scans[10].id==12 and scans[11].id==23 and scans[12].id==24)
assert(CouchsideMinimapDB.nextID==25 and #softRequests==0)
''', r'''
local scans={}
for i=1,24 do scans[i]={id=i,source=i>12 and 'automatic' or nil} end
CouchsideMinimapDB={version=1,nextID=25,scans=scans}
''')
check("panel report reads all manager slots and visible bags without native mutations", r'''
local queried={}
local character={GetName=function() return 'CharacterFrame' end,IsVisible=function() return true end}
CharacterFrame=character
ContainerFrame1={IsVisible=function() return true end}
GetUIPanel=function(slot) queried[slot]=true;return slot=='left' and character or nil end
commands.panels('')
local r=CouchsideMinimapDB.panelReport
assert(r.slots.left=='CharacterFrame' and r.slots.center=='none' and r.frames.ContainerFrame1=='visible')
assert(queried.left and queried.center and queried.right and queried.doublewide and queried.fullscreen)
assert(#softRequests==0 and queries==0 and r.addonVersion==ns.version)
commands.log('clear');assert(not CouchsideMinimapDB.panelReport)
''')
check("missing erroring and restricted panel reads stay explicit", r'''
GetUIPanel=nil
commands.panels('');assert(CouchsideMinimapDB.panelReport.slots.left=='API unavailable')
GetUIPanel=function() error('panel read failed') end
commands.panels('');assert(CouchsideMinimapDB.panelReport.slots.left:find('panel read failed'))
local secret={};issecretvalue=function(v) return v==secret end
GetUIPanel=function() return secret end
ContainerFrame1={IsVisible=function() return secret end}
commands.panels('');local r=CouchsideMinimapDB.panelReport
assert(r.slots.left=='restricted' and r.frames.ContainerFrame1=='restricted')
assert(#softRequests==0 and queries==0)
''')
check("panel-manager slots block launch and opening one cancels an active batch", r'''
local panel={GetName=function() return 'TestPanel' end}
local occupied='left'
GetUIPanel=function(slot) return slot==occupied and panel or nil end
enableAuto()
for _,slot in ipairs({'left','center','right','doublewide','fullscreen'}) do
 occupied=slot;advance(3);assert(#softRequests==0,'manager slot did not block: '..slot)
end
occupied=nil
queryAction=function(n) if n==10 then occupied='center' end end
advance(3);assert(not soft and queries<=16 and #CouchsideMinimapDB.scans==0)
''')
check("combined and individual bags block automatic cursor setup", r'''
local open=true
ContainerFrameCombinedBags={IsVisible=function() return open end}
enableAuto();advance(3);assert(#softRequests==0,'combined bags did not block')
open=false;ContainerFrame7={IsVisible=function() return true end}
advance(3);assert(#softRequests==0,'individual bag did not block')
''')
check("a panel opening during quest snapshot preparation prevents cursor enable", r'''
local open=false
GetUIPanel=function(slot) return open and slot=='left' and {} or nil end
C_QuestLog.GetInfo=function() open=true;return nil end
enableAuto();advance(3);assert(#softRequests==0,'cursor enabled after a panel opened in preparation')
''')
check("missing erroring or restricted panel-manager reads withhold scanning and recover when readable", r'''
GetUIPanel=nil;enableAuto();advance(3)
assert(#softRequests==0 and CouchsideMinimapDB.automationReport.reason=='native panel manager unavailable')
GetUIPanel=function() error('panel unavailable') end;advance(3)
assert(#softRequests==0 and CouchsideMinimapDB.automationReport.reason:find('native panel read failed'))
local secret={};issecretvalue=function(v) return v==secret end
GetUIPanel=function() return secret end;advance(3)
assert(#softRequests==0 and CouchsideMinimapDB.automationReport.reason:find('restricted'))
GetUIPanel=function() return nil end;advance(3);assert(#softRequests==2)
''')
check("unreadable explicit panel visibility withholds launch without faulting the scheduler", r'''
BankFrame={IsVisible=function() error('unreadable bank') end}
enableAuto();advance(3);assert(#softRequests==0)
assert(CouchsideMinimapDB.automationReport.reason:find('BankFrame'))
assert(CouchsideMinimapDB.automationReport.status=='waiting')
BankFrame.IsVisible=function() return false end;advance(3);assert(#softRequests==2)
''')
check("one second quiet interval starts the shared scanner and saves a quiet snapshot", r'''
enableAuto();advance(1);assert(#softRequests==0)
advance(.6);assert(soft and #softRequests==1)
advance(2);local s=CouchsideMinimapDB.scans[1]
assert(s and s.source=='automatic' and s.display.status=='shown' and not soft)
assert(#logs==0,'routine automatic scan spammed chat')
''')
check("stationary wait accepts whole seconds one through four and survives reload data", r'''
for _,value in ipairs({1,2,3,4}) do
 commands.auto('delay '..value);assert(CouchsideMinimapDB.automaticScanSettings.delaySeconds==value)
end
for _,value in ipairs({'0','5','-1','1.5','bad','9999999999999999999999999'}) do
 commands.auto('delay '..value);assert(CouchsideMinimapDB.automaticScanSettings.delaySeconds==4)
end
enableAuto();advance(4);assert(#softRequests==0);advance(.6);assert(soft)
''')
check("saved stationary preference is loaded without restarting a saved scan", r'''
enableAuto();advance(3);assert(#softRequests==0);advance(1);assert(soft)
assert(CouchsideMinimapDB.automationReport.delaySeconds==3)
''', "CouchsideMinimapDB={version=1,nextID=1,scans={},automaticScanSettings={delaySeconds=3},automationReport={status='scanning'}}")
check("invalid saved waits fall back to one second", r'''
commands.auto('');assert(CouchsideMinimapDB.automationReport.delaySeconds==1)
''', "CouchsideMinimapDB={version=1,nextID=1,scans={},automaticScanSettings={delaySeconds='bad'}}")
check("walking, turning and an excursion returning to pose restart the quiet interval", r'''
enableAuto();advance(.7);fire('PLAYER_STARTED_TURNING');fire('PLAYER_STOPPED_TURNING')
advance(.8);assert(#softRequests==0);advance(.7);assert(soft)
''')
check("moving or restricted speed signals never launch even with unchanged coordinates", r'''
enableAuto();moving=true;advance(3);assert(#softRequests==0)
moving=false;speed=7;advance(3);assert(#softRequests==0)
local secret={};issecretvalue=function(v) return v==secret end;speed=secret
advance(3);assert(#softRequests==0)
speed=0;advance(2);assert(soft)
''')
check("combat, hidden minimap and actual cursor hover prevent automatic launch", r'''
enableAuto();combat=true;advance(3);assert(#softRequests==0)
combat=false;mapVisible=false;advance(3);assert(#softRequests==0)
mapVisible=true;cursorX=100;cursorY=100;advance(3);assert(#softRequests==0)
cursorX=0;cursorY=0;advance(2);assert(soft)
''')
check("combat beginning during preparation prevents cursor enable", r'''
C_QuestLog.GetInfo=function() combat=true;return nil end
enableAuto();advance(4);assert(#softRequests==0 and #CouchsideMinimapDB.scans==0)
''')
check("native panels block stationary launch and opening one cancels active work", r'''
local macroOpen=true;MacroFrame={IsVisible=function() return macroOpen end}
enableAuto();advance(15);assert(#softRequests==0)
macroOpen=false;local mapOpen=false;WorldMapFrame={IsVisible=function() return mapOpen end}
queryAction=function(n) if n==10 then mapOpen=true end end
advance(4);assert(not soft and queries<=16 and #CouchsideMinimapDB.scans==0)
''')
check("restricted or unreadable panel visibility stays withheld", r'''
local secret={};issecretvalue=function(v) return v==secret end
MacroFrame={IsVisible=function() return secret end};enableAuto();advance(3);assert(#softRequests==0)
MacroFrame.IsVisible=function() return nil end;advance(3);assert(#softRequests==0)
''')
check("movement inside an automatic query batch cancels partial evidence", r'''
queryAction=function(n) if n==10 then fire('PLAYER_STARTED_MOVING');fire('PLAYER_STOPPED_MOVING') end end
enableAuto();advance(4)
assert(not soft and #CouchsideMinimapDB.scans==0 and queries<=16)
assert(CouchsideMinimapDB.automationReport.cancelled==1)
''')
check("an event at the final query still discards the automatic snapshot", r'''
queryAction=function(n) if n==1009 then fire('PLAYER_STARTED_TURNING');fire('PLAYER_STOPPED_TURNING') end end
enableAuto();advance(4);assert(queries==1009 and not soft and #CouchsideMinimapDB.scans==0)
''')
check("world and zone transitions reset the wait and cancel an automatic batch", r'''
enableAuto();advance(.7);fire('PLAYER_ENTERING_WORLD');advance(.8);assert(#softRequests==0)
queryAction=function(n) if n==10 then fire('ZONE_CHANGED_NEW_AREA') end end
advance(3);assert(not soft and queries<=16 and #CouchsideMinimapDB.scans==0)
assert(CouchsideMinimapDB.automationReport.cancelled==1)
''')
check("automatic scans use the north-up dungeon fallback and still refuse rotating instances", r'''
enableAuto();advance(4)
local s=CouchsideMinimapDB.scans[1]
assert(s and s.motion.status=='unknown' and s.display.guardMode=='dungeon-motion' and s.display.status=='shown')
pose.rotating=true;advance(20);assert(#CouchsideMinimapDB.scans==1)
''', r'''
IsInInstance=function() return true,'party' end
UnitPosition=function() return nil,nil,nil,43 end
C_Map.GetPlayerMapPosition=function() return nil end
GetPlayerFacing=function() return nil end
''')
check("a still player gets one scan per snapshot lifetime, replaced without a gap", r'''
enableAuto();advance(4);assert(#softRequests==2 and visiblePanel())
advance(40);assert(#softRequests==2,'rescanned while the snapshot was live')
for _=1,30 do advance(.5);assert(visiblePanel(),'snapshot blinked off before its refresh') end
assert(#softRequests==4 and #CouchsideMinimapDB.scans==2)
assert(CouchsideMinimapDB.automationReport.lifetimeSeconds==ns.NearbyList.LIFETIME)
''')
check("a manual scan counts as the snapshot for this stop", r'''
enableAuto();advance(20);assert(#softRequests==2)
commands.scan('');advance(3);assert(#softRequests==4 and CouchsideMinimapDB.scans[2].source=='manual')
advance(40);assert(#softRequests==4,'automatic scan replaced a live manual snapshot')
advance(15);assert(#softRequests==6 and CouchsideMinimapDB.scans[3].source=='automatic')
''')
check("a withheld automatic scan retries once per lifetime until the player moves", r'''
ns.NearbyList.Show=function() return {status='withheld',reason='fixture'} end
enableAuto();advance(4);assert(#softRequests==2)
advance(50);assert(#softRequests==2,'withheld scan retried before the lifetime')
advance(15);assert(#softRequests==4)
fire('PLAYER_STARTED_MOVING');fire('PLAYER_STOPPED_MOVING');advance(5)
assert(#softRequests==6,'a new stop did not scan')
''')
check("moving clears the snapshot and the next stop scans after the wait", r'''
enableAuto();advance(4);assert(visiblePanel() and #softRequests==2)
fire('PLAYER_STARTED_MOVING');pose.x=.6;advance(.2);assert(not visiblePanel())
fire('PLAYER_STOPPED_MOVING');advance(3);assert(#softRequests==2,'minimum gap ignored')
advance(5);assert(#softRequests==4 and visiblePanel())
''')
check("stop-and-go movement starts at most one scan per minimum gap", r'''
enableAuto()
for _=1,10 do advance(1.5);fire('PLAYER_STARTED_MOVING');fire('PLAYER_STOPPED_MOVING') end
assert(CouchsideMinimapDB.automationReport.attempts==2)
''')
check("a cancelled scan retries after the minimum gap, not the lifetime", r'''
queryAction=function(n) if n==10 then cursorX=100;cursorY=100 end end
enableAuto();advance(2);assert(CouchsideMinimapDB.automationReport.cancelled==1)
queryAction=nil;cursorX=0;cursorY=0;advance(12)
assert(#CouchsideMinimapDB.scans==1 and visiblePanel())
''')
check("a visible but unfocused chat input does not block; typing does", r'''
ChatFrame1EditBox={IsVisible=function() return true end}
focus=ChatFrame1EditBox;enableAuto();advance(3);assert(#softRequests==0)
assert(CouchsideMinimapDB.automationReport.reason=='text input focused')
focus=nil;advance(2);assert(soft)
''')
check("manual scan replaces an automatic scan without letting its old callback finish", r'''
enableAuto();advance(1.8);assert(soft)
commands.scan('');advance(3)
assert(#CouchsideMinimapDB.scans==1 and CouchsideMinimapDB.scans[1].source=='manual')
assert(not soft and CouchsideMinimapDB.automationReport.cancelled==1)
''')
check("scan off pauses automatic mode until explicit resume", r'''
enableAuto();advance(2);commands.scan('off');advance(30)
assert(not soft and #CouchsideMinimapDB.scans==0)
assert(CouchsideMinimapDB.automationReport.status=='paused')
commands.auto('resume');advance(3);assert(#CouchsideMinimapDB.scans==1)
''')
check("manual watch owns the scanner during all pauses and stops after three scans", r'''
enableAuto();commands.scan('watch');advance(30)
assert(#CouchsideMinimapDB.scans==3 and #softRequests==6)
assert(CouchsideMinimapDB.automationReport.status=='paused')
''')
check("disabling either automatic scanning or its display cancels work and polling", r'''
enableAuto();advance(2);autoEnabled=false;changed('autoScan');local before=#softRequests
advance(30);assert(not soft and #softRequests==before and #CouchsideMinimapDB.scans==0)
autoEnabled=true;enabled=false;changed('nearbyList');advance(30);assert(#softRequests==before)
''')
check("native query errors halt automatic retries for the session", r'''
failQuery=true;enableAuto();advance(30);local before=#softRequests
assert(not soft and CouchsideMinimapDB.automationReport.status=='faulted')
commands.auto('resume');advance(30);assert(#softRequests==before and #CouchsideMinimapDB.scans==0)
''')
check("a nonthrowing protected action stops queries immediately inside a batch", r'''
local inQuery=false;local normalSetter=Minimap.SetUsingSoftCursor
Minimap.SetUsingSoftCursor=function(...)
 assert(not inQuery,'setter was nested inside the native query');normalSetter(...)
end
local normalTooltip=C_TooltipInfo.GetMinimapMouseover;local afterBlock=false
C_TooltipInfo.GetMinimapMouseover=function()
 assert(not afterBlock,'tooltip read continued after protected cancellation');return normalTooltip()
end
queryAction=function(n)
 inQuery=true
 if n==10 then fire('ADDON_ACTION_BLOCKED','Couchside_Gathering');afterBlock=true end
 inQuery=false
end
enableAuto();advance(30)
assert(queries==10 and soft and #softRequests==1 and #CouchsideMinimapDB.scans==0)
assert(CouchsideMinimapDB.automationReport.status=='faulted' and CouchsideMinimapDB.automationReport.protectedAction=='ADDON_ACTION_BLOCKED')
assert(CouchsideMinimapDB.automationReport.failed==1)
commands.scan('off');assert(not soft and #softRequests==2)
''')
check("protected notification during enable never reenters the cursor setter", r'''
local normal=Minimap.SetUsingSoftCursor;local depth=0
Minimap.SetUsingSoftCursor=function(self,value)
 depth=depth+1;assert(depth==1,'cursor setter reentered')
 normal(self,value);if value then fire('ADDON_ACTION_FORBIDDEN','Couchside_Gathering') end
 depth=depth-1
end
enableAuto();advance(30)
assert(#softRequests==1 and queries==0 and #CouchsideMinimapDB.scans==0)
assert(CouchsideMinimapDB.automationReport.status=='faulted')
commands.scan('off');assert(not soft and #softRequests==2)
''')
check("protected notification during cleanup discards completion without retry", r'''
local normal=Minimap.SetUsingSoftCursor;local depth=0
Minimap.SetUsingSoftCursor=function(self,value)
 depth=depth+1;assert(depth==1,'cursor setter reentered')
 normal(self,value);if not value then fire('ADDON_ACTION_FORBIDDEN','Couchside_Gathering') end
 depth=depth-1
end
enableAuto();advance(30)
assert(#softRequests==2 and #CouchsideMinimapDB.scans==0 and not soft)
assert(CouchsideMinimapDB.automationReport.status=='faulted')
''')
check("failed protected-action listener registration prevents automatic work", r'''
for _,f in ipairs(frames) do
 local old=f.RegisterEvent
 f.RegisterEvent=function(self,event) if event=='ADDON_ACTION_BLOCKED' then error('unsupported event') end;return old(self,event) end
end
enableAuto();advance(30);assert(#softRequests==0 and CouchsideMinimapDB.automationReport.status=='faulted')
''')
check("cursor enable errors still clean up once and stop retries", r'''
failEnable=true;enableAuto();advance(30)
assert(#softRequests==2 and not soft and CouchsideMinimapDB.automationReport.failed==1)
assert(CouchsideMinimapDB.automationReport.status=='faulted')
''')
check("cursor cleanup failure never triggers another automatic request", r'''
failCleanup=true;enableAuto();advance(30);local before=#softRequests
assert(before==2 and CouchsideMinimapDB.automationReport.status=='faulted')
advance(30);assert(#softRequests==before)
''')
check("watchdog recovers dropped batch callbacks and halts automatic retries", r'''
enableAuto();advance(1.6);assert(soft)
local kept={};for _,item in ipairs(queue) do if item.at>10 then kept[#kept+1]=item end end;queue=kept
advance(30);assert(not soft and #CouchsideMinimapDB.scans==0 and #softRequests==2)
assert(CouchsideMinimapDB.automationReport.status=='faulted')
''')
check("display failure records the finished diagnostic and stops repeat scans", r'''
ns.NearbyList.Show=function() error('display failed') end
enableAuto();advance(30)
assert(#CouchsideMinimapDB.scans==1 and #softRequests==2 and not soft)
assert(CouchsideMinimapDB.scans[1].display.status=='error' and CouchsideMinimapDB.automationReport.status=='faulted')
''')
check("changing the stationary wait cancels an in-flight automatic request", r'''
enableAuto();advance(1.8);assert(soft);commands.auto('delay 4');advance(5)
assert(not soft and #CouchsideMinimapDB.scans==0 and CouchsideMinimapDB.automaticScanSettings.delaySeconds==4)
''')
check("combat interrupt never attempts a protected cleanup until manual recovery", r'''
enableAuto();advance(1.8);combat=true;advance(3)
assert(soft and #softRequests==1 and CouchsideMinimapDB.automationReport.status=='faulted')
combat=false;commands.scan('off');assert(not soft and #softRequests==2)
''')
check("a manual hover probe pauses automatic work through its capture countdown", r'''
enableAuto();commands.probe('capture');advance(20)
assert(#softRequests==0 and CouchsideMinimapDB.automationReport.status=='paused')
''')
check("native macro probe is read only and gates creation", r'''
commands.macro('create');assert(created==0)
commands.macro('probe');assert(created==0 and CouchsideMinimapDB.macroReport.status=='ready')
''')
check("macro helper creates one account entry with the map icon and exact scan body", r'''
commands.macro('probe');commands.macro('create');commands.macro('create')
assert(created==1 and macros[1].name=='Scan map' and macros[1].icon==134269 and macros[1].body=='/cs gathering scan')
assert(CouchsideMinimapDB.macroReport.status=='exists')
''')
check("existing scan macro retains its chosen icon and text", r'''
commands.macro('probe');commands.macro('create')
assert(created==0 and macros[1].icon==42 and macros[1].body==' /cs gathering scan\n')
''', "accountCount=1;macros[1]={name='Scan map',icon=42,body=' /cs gathering scan\\n'}")
check("name collisions on either scope are preserved instead of overwritten", r'''
commands.macro('probe');commands.macro('create');assert(created==0)
assert(macros[4].body=='/dance' and CouchsideMinimapDB.macroReport.status=='name conflict')
''', "characterCount=1;macros[4]={name='Scan map',icon=42,body='/dance'}")
check("full account slots and combat refuse creation", r'''
commands.macro('probe');commands.macro('create');assert(created==0)
accountCount=0;commands.macro('probe');combat=true;commands.macro('create');assert(created==0)
''', "accountCount=3;for i=1,3 do macros[i]={name='Other '..i,icon=42,body='/dance'} end")
check("unavailable or restricted macro metadata causes no mutation", r'''
GetMacroInfo=nil;commands.macro('probe');commands.macro('create');assert(created==0)
GetMacroInfo=function() return 'Other',42,'/dance' end
local secret={};issecretvalue=function(v) return v==secret end
GetNumMacros=function() return secret,0 end
commands.macro('probe');commands.macro('create');assert(created==0)
''')
check("partial macro creation error does not duplicate the entry on explicit retry", r'''
local normal=CreateMacro;CreateMacro=function(...) normal(...);error('creation returned an error') end
commands.macro('probe');commands.macro('create');assert(created==1)
commands.macro('create');assert(created==1 and CouchsideMinimapDB.macroReport.status=='exists')
''')
check("unexpected macro return index stays unverified and does not duplicate on retry", r'''
local normal=CreateMacro;CreateMacro=function(...) normal(...);return 999 end
commands.macro('probe');commands.macro('create')
assert(created==1 and CouchsideMinimapDB.macroReport.status=='creation unverified')
commands.macro('create');assert(created==1 and CouchsideMinimapDB.macroReport.existingIcon==134269)
''')
check("macro setup performs no cursor pickup, binding or native panel operation", r'''
for _,name in ipairs({'PickupMacro','SetBinding','SetOverrideBindingClick','ShowUIPanel','EditMacro','DeleteMacro'}) do
 _G[name]=function() error('unexpected native operation: '..name) end
end
commands.macro('probe');commands.macro('create');assert(created==1 and #softRequests==0)
''')
print("49 scan launch checks passed")
