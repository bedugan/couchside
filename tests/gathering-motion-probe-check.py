"""Read-only probe lifecycle and restricted-value handling, not native coverage."""
from pathlib import Path
from lupa.lua51 import LuaRuntime

ROOT = Path(__file__).resolve().parents[1]
STUB = r'''
clock=0;combat=false;logs={};commands={};frames={};speed=0;moving=false
ns={Print=function(fmt,...) logs[#logs+1]=string.format(fmt,...) end,
 Debug=function() end,IsEnabled=function() return false end,OnOptionChanged=function() end,
 OnReady=function(fn) fn() end,RegisterCommand=function(k,_,fn) commands[k]=fn end}
function GetTime() return clock end
function GetBuildInfo() return '1.60.1','70374','date',16001 end
function InCombatLockdown() return combat end
function GetUnitSpeed() return speed,7,7,4 end
function IsPlayerMoving() return moving end
function UnitPosition() return nil end
function IsInInstance() return true,'party' end
function GetInstanceInfo() return 'Wailing Caverns','party',1,'Normal',5,0,false,43 end
C_Map={GetBestMapForUnit=function() return 11 end,GetPlayerMapPosition=function() return nil end}
function GetPlayerFacing() return nil end
function GetCVarBool() return false end
function CreateFrame()
 local f={shown=true,events={},scripts={}}
 function f:Hide() self.shown=false end
 function f:Show() self.shown=true end
 function f:RegisterEvent(e) self.events[e]=true end
 function f:UnregisterAllEvents() self.events={} end
 function f:SetScript(k,fn) self.scripts[k]=fn end
 frames[#frames+1]=f;return f
end
function tick(dt)
 clock=clock+dt
 for _,f in ipairs(frames) do if f.shown and f.scripts.OnUpdate then f.scripts.OnUpdate(f,dt) end end
end
function event(e)
 for _,f in ipairs(frames) do if f.events[e] then f.scripts.OnEvent(f,e) end end
end
'''


def check(name, code):
    vm = LuaRuntime()
    vm.execute(STUB)
    for file in ("ScanLog.lua", "MotionGuard.lua", "MotionProbe.lua"):
        vm.execute('assert(loadstring(...))("Couchside_Gathering",ns)', (ROOT / "Couchside_Gathering" / file).read_text())
    vm.execute("probeFrame=frames[#frames]")
    vm.execute(code)
    print("PASS", name)


check("nil dungeon coordinates remain explicit beside readable alternatives", r'''
commands.motion('');local r=CouchsideGatheringScanDB.motionReport
assert(r.reason=='single sample' and r.build=='70374' and #r.samples==1)
local s=r.samples[1];assert(s.speed.values[1]==0 and s.moving.values[1]==false)
assert(s.worldPosition.values[1]==nil and s.mapPose.positionError and s.mapPose.facingError)
assert(not probeFrame.shown and next(probeFrame.events)==nil)
''')
check("timed watch records movement and turning and releases listeners", r'''
commands.motion('watch');tick(3);speed=7;moving=true;event('PLAYER_STARTED_MOVING');tick(.2)
tick(2.8);speed=0;moving=false;event('PLAYER_STOPPED_MOVING');event('PLAYER_STARTED_TURNING');tick(.2)
tick(2.8);event('PLAYER_STOPPED_TURNING');tick(3.2)
local r=CouchsideGatheringScanDB.motionReport;assert(r.reason=='completed' and #r.events==4)
assert(r.samples[3].speed.values[1]==7 and r.samples[5].moving.values[1]==false)
assert(not probeFrame.shown and next(probeFrame.events)==nil)
''')
check("secret speed is sanitized before printing or saving", r'''
local secret={};issecretvalue=function(v) return v==secret end
GetUnitSpeed=function() return secret end;commands.motion('')
assert(CouchsideGatheringScanDB.motionReport.samples[1].speed.values[1]=='<secret omitted>')
''')
check("missing and erroring alternative APIs are recorded independently", r'''
GetUnitSpeed=nil;IsPlayerMoving=function() error('restricted') end
commands.motion('');local s=CouchsideGatheringScanDB.motionReport.samples[1]
assert(s.speed.error and s.moving.error:find('restricted') and s.worldPosition.values.n==1)
''')
check("combat refuses a start and interrupts a running watch", r'''
combat=true;commands.motion('watch');assert(not CouchsideGatheringScanDB.motionReport and not probeFrame.shown)
combat=false;commands.motion('watch');combat=true;tick(.1)
assert(CouchsideGatheringScanDB.motionReport.reason=='combat interrupted' and not probeFrame.shown)
''')
check("cancellation and event registration errors preserve bounded evidence", r'''
probeFrame.RegisterEvent=function(self,e) if e=='PLAYER_STARTED_TURNING' then error('unknown event') end;self.events[e]=true end
commands.motion('watch');for i=1,200 do event('PLAYER_STARTED_MOVING') end
commands.motion('off');local r=CouchsideGatheringScanDB.motionReport
assert(r.reason=='cancelled' and #r.events==128 and r.eventsTruncated and r.eventRegistrationErrors.PLAYER_STARTED_TURNING)
assert(not probeFrame.shown and next(probeFrame.events)==nil)
''')
check("history clearing also clears the latest probe", r'''
commands.motion('');commands.log('clear');assert(not CouchsideGatheringScanDB.motionReport)
''')
check("pose sampler errors do not lose other native reads", r'''
ns.MotionGuard.Start=function() error('pose restricted') end
commands.motion('');local s=CouchsideGatheringScanDB.motionReport.samples[1]
assert(s.mapPose.readError:find('pose restricted') and s.speed.values[1]==0)
''')
check("frequent frame updates keep the sample count bounded", r'''
commands.motion('watch');for i=1,370 do tick(.033) end
local r=CouchsideGatheringScanDB.motionReport
assert(r.reason=='completed' and #r.samples>50 and #r.samples<=121 and not probeFrame.shown)
''')
print("9 motion probe checks passed")
