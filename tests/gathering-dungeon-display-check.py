"""Replay the native missing-coordinate case through the actual display path.

These checks establish guard logic, not native placement or controller safety.
"""
import json
import runpy
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
legend = runpy.run_path(str(ROOT / "tests/gathering-legend-check.py"))
fixture = json.loads((ROOT / "tests/fixtures/gathering-wailing-caverns-motion.json").read_text())
STUB = r'''
speed=0;moving=false;instanceID=43;instanceType='party';inInstance=true;rotating=false
local oldCreateFrame=CreateFrame
function CreateFrame(...)
 local f=oldCreateFrame(...);f.events={}
 function f:RegisterEvent(e) if rejectEvent==e then error('event unavailable') end;self.events[e]=true end
 function f:UnregisterAllEvents() self.events={} end
 return f
end
function fire(event)
 for _,f in ipairs(frames) do if f.events and f.events[event] then f.scripts.OnEvent(f,event) end end
end
function GetUnitSpeed() return speed end
function IsPlayerMoving() return moving end
function IsInInstance() return inInstance,instanceType end
function UnitPosition() return nil,nil,nil,instanceID end
function GetPlayerFacing() return nil end
function GetCVarBool() return rotating end
C_Map={GetBestMapForUnit=function() return 11 end,GetPlayerMapPosition=function() return nil end}
function dungeonScan()
 local s=scan({{text='Earthroot',x=.4583333333333334,y=.7083333333333334}})
 s.motion=ns.MotionGuard.Finish(ns.MotionGuard.Start());return s
end
'''


SCANNER_STUB = r'''
queue={};soft=false
function GetBuildInfo() return '1.60.1','70374','date',16001 end
function GetServerTime() return 1791940000 end
function GetCursorPosition() return 0,0 end
Minimap.SetUsingSoftCursor=function(_,value) soft=value end
Minimap.UpdateMouseoverAtPoint=function() end
C_TooltipInfo={GetMinimapMouseover=function() return {lines={{leftText='Earthroot'}}} end}
C_QuestLog={GetInfo=function() return nil end,GetQuestObjectives=function() return {} end}
C_Timer={After=function(delay,fn) queue[#queue+1]={at=clock+delay,fn=fn} end}
function drainTimers()
 local count=0
 while #queue>0 do
  table.sort(queue,function(a,b) return a.at<b.at end)
  local next=table.remove(queue,1);clock=next.at;next.fn();count=count+1;assert(count<10000)
 end
end
'''


def to_lua(vm, value):
    if isinstance(value, dict):
        return vm.table_from({key: to_lua(vm, child) for key, child in value.items()})
    if isinstance(value, list):
        return vm.table_from([to_lua(vm, child) for child in value])
    return value


def make(setup=""):
    vm = legend["make"](STUB + setup)
    vm.globals().captured = to_lua(vm, fixture)
    if vm.globals().loadScanner:
        vm.execute('assert(loadstring(...))("Couchside_Gathering",ns)', (ROOT / "Couchside_Gathering/MinimapProbe.lua").read_text())
    return vm


def check(name, code, setup=""):
    make(setup).execute(code)
    print("PASS", name)


check("native dungeon nil coordinates with verified still signals show Earthroot", r'''
local first=captured.samples[1];speed=first.speed;moving=first.moving;instanceID=first.instanceID
local s=dungeonScan();local d=ns.NearbyList.Show(s)
assert(visiblePanel() and #markers()==1,'native nil-coordinate case still hides the list')
assert(s.motion.status=='unknown' and s.motion.unknownSamples>0 and d.guardMode=='dungeon-motion')
assert(markers()[1].symbol.texture:find('circle%-orange'))
''')
check("native event trace invalidates the accepted snapshot", r'''
local s=dungeonScan();local d=ns.NearbyList.Show(s);assert(visiblePanel())
for _,event in ipairs(captured.events) do fire(event.event);tick(.1) end
assert(not visiblePanel() and #markers()==0 and d.status=='cleared' and d.reason:find('event'))
''')
check("native travel samples never become stationary dungeon displays", r'''
local movingSamples=0
for _,sample in ipairs(captured.samples) do
 speed=sample.speed;moving=sample.moving
 if speed>0 or moving then
  movingSamples=movingSamples+1;ns.NearbyList.Show(dungeonScan());assert(not visiblePanel())
 end
end
assert(movingSamples>0)
''')
check("moving and returning between samples stays rejected", r'''
local state=ns.MotionGuard.Start()
fire('PLAYER_STARTED_MOVING');fire('PLAYER_STOPPED_MOVING')
local s=scan({{text='Earthroot',x=.4,y=.7}});s.motion=ns.MotionGuard.Finish(state)
ns.NearbyList.Show(s);assert(not visiblePanel() and s.motion.dungeonGuard.status~='still')
''')
check("each start, stop and transition event clears stale marks", r'''
for _,event in ipairs({'PLAYER_STARTED_MOVING','PLAYER_STOPPED_MOVING','PLAYER_STARTED_TURNING',
 'PLAYER_STOPPED_TURNING','PLAYER_STARTED_LOOKING','PLAYER_STOPPED_LOOKING',
 'PLAYER_ENTERING_WORLD','PLAYER_LEAVING_WORLD','ZONE_CHANGED_NEW_AREA'}) do
 ns.NearbyList.Show(dungeonScan());assert(visiblePanel())
 fire(event);tick(.1);assert(not visiblePanel() and #markers()==0,event)
end
''')
check("rotating maps, non-party instances and outdoors retain strict guard", r'''
rotating=true;ns.NearbyList.Show(dungeonScan());assert(not visiblePanel())
rotating=false;instanceType='raid';ns.NearbyList.Show(dungeonScan());assert(not visiblePanel())
instanceType='party';inInstance=false;ns.NearbyList.Show(dungeonScan());assert(not visiblePanel())
''')
check("secret speed and missing movement or instance state stay unknown", r'''
local secret={};issecretvalue=function(v) return v==secret end
GetUnitSpeed=function() return secret end;ns.NearbyList.Show(dungeonScan());assert(not visiblePanel())
GetUnitSpeed=function() return 0 end;IsPlayerMoving=function() return nil end
ns.NearbyList.Show(dungeonScan());assert(not visiblePanel())
IsPlayerMoving=function() return false end;instanceID=nil
ns.NearbyList.Show(dungeonScan());assert(not visiblePanel())
for _,id in ipairs({0,-1,1.5,math.huge}) do instanceID=id;ns.NearbyList.Show(dungeonScan());assert(not visiblePanel()) end
''')
check("both speed and movement flag must agree on stillness", r'''
speed=0;moving=true;ns.NearbyList.Show(dungeonScan());assert(not visiblePanel())
speed=7;moving=false;ns.NearbyList.Show(dungeonScan());assert(not visiblePanel())
''')
check("instance changes and new unreadable state clear the live display", r'''
local d=ns.NearbyList.Show(dungeonScan());assert(visiblePanel())
instanceID=44;tick(.1);assert(not visiblePanel() and d.reason:find('instance'))
instanceID=43;ns.NearbyList.Show(dungeonScan());assert(visiblePanel())
GetUnitSpeed=function() error('restricted') end;tick(.1);assert(not visiblePanel())
''')
check("disabled feature releases all event listeners and refuses fallback", r'''
ns.NearbyList.Show(dungeonScan());enabled=false;changed('nearbyList')
assert(not visiblePanel())
for _,f in ipairs(frames) do if f.events then assert(next(f.events)==nil) end end
local token=ns.MotionGuard.Prepare(dungeonScan().motion);assert(not token)
''')
check("event registration failure cannot authorize a dungeon snapshot", r'''
ns.NearbyList.Show(dungeonScan());assert(not visiblePanel())
local token=ns.MotionGuard.Prepare(dungeonScan().motion);assert(not token)
''', "rejectEvent='PLAYER_STARTED_TURNING'")
check("ordinary readable outdoor poses keep their existing behavior", r'''
inInstance=false
C_Map.GetPlayerMapPosition=function() return {GetXY=function() return .5,.5 end} end
GetPlayerFacing=function() return 0 end
local s=dungeonScan();local d=ns.NearbyList.Show(s)
assert(visiblePanel() and d.guardMode=='map-pose' and s.motion.status=='still')
C_Map.GetPlayerMapPosition=function() return {GetXY=function() return .6,.5 end} end
tick(.1);assert(not visiblePanel())
''')
check("dungeon snapshot expiry, combat and option changes retain lifecycle", r'''
for _,why in ipairs({'expiry','combat','option'}) do
 clock=0;combat=false;legend=true
 local d=ns.NearbyList.Show(dungeonScan());assert(visiblePanel())
 if why=='expiry' then clock=10;tick(.1)
 elseif why=='combat' then combat=true;tick(.1)
 else legend=false;changed('resourceLegend') end
 assert(not visiblePanel() and #markers()==0 and d.status=='cleared')
end
''')
check("complete scanner persists the accepted dungeon guard and later clearing", SCANNER_STUB + r'''
commands.scan('');drainTimers()
local records=CouchsideGatheringScanDB.scans;local s=records[#records]
assert(s and s.display.status=='shown' and s.display.guardMode=='dungeon-motion' and s.motion.status=='unknown')
assert(not soft and visiblePanel() and #markers()==1)
fire('PLAYER_STARTED_MOVING');tick(.1)
assert(s.display.status=='cleared' and not visiblePanel())
''', "loadScanner=true")
check("actual scanner cancellation cleans up and adds no finished evidence", SCANNER_STUB + r'''
commands.scan('');assert(soft);commands.scan('off');drainTimers()
assert(not soft and #CouchsideGatheringScanDB.scans==0 and not visiblePanel())
''', "loadScanner=true")
check("movement within a query batch rejects the completed display", SCANNER_STUB + r'''
local queried=0
Minimap.UpdateMouseoverAtPoint=function()
 queried=queried+1
 if queried==100 then fire('PLAYER_STARTED_MOVING');fire('PLAYER_STOPPED_MOVING') end
end
commands.scan('');drainTimers()
local s=CouchsideGatheringScanDB.scans[1]
assert(s and s.display.status=='withheld' and s.motion.dungeonGuard.status=='changed')
assert(not soft and not visiblePanel())
''', "loadScanner=true")
print("16 dungeon display checks passed")

