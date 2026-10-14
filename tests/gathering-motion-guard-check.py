"""Motion-guard contracts and read counts through the shared public interface."""
from pathlib import Path
import runpy

legend = runpy.run_path(str(Path(__file__).with_name("gathering-legend-check.py")))
make = legend["make"]


def check(name, code, setup=""):
    make(setup).execute(code)
    print("PASS", name)


check("one interface owns scan evidence and live validation", r'''
assert(ns.ScanMotion==nil and ns.DungeonMotion==nil)
local motion=ns.MotionGuard.Finish(ns.MotionGuard.Start())
local guard,report=ns.MotionGuard.Prepare(motion)
assert(guard and report.guardMode=='map-pose' and report.guardStatus=='still')
assert(ns.MotionGuard.Check(guard))
pose.x=.51;local valid,reason=ns.MotionGuard.Check(guard)
assert(not valid and reason:find('position'))
''')
check("map changes and angular wrap preserve pose checks", r'''
pose.facing=2*math.pi-.01
local guard=ns.MotionGuard.Prepare(ns.MotionGuard.Finish(ns.MotionGuard.Start()))
pose.facing=.01;local valid,reason=ns.MotionGuard.Check(guard)
assert(not valid and reason:find('facing'))
pose.facing=2*math.pi-.01;pose.mapID=1421
valid,reason=ns.MotionGuard.Check(guard);assert(not valid and reason:find('map'))
''')
check("mixed readable and unreadable scan samples cannot authorize fallback", r'''
local state=ns.MotionGuard.Start()
C_Map.GetPlayerMapPosition=function() return nil end;GetPlayerFacing=function() return nil end
local motion=ns.MotionGuard.Finish(state);local guard=ns.MotionGuard.Prepare(motion)
assert(not guard and motion.status=='unknown' and motion.dungeonGuard.unknownSamples>0)
''', "IsInInstance=function() return true,'party' end;UnitPosition=function() return nil,nil,nil,43 end")
check("dungeon live checks skip unavailable map and facing calls", r'''
local motion=ns.MotionGuard.Finish(ns.MotionGuard.Start())
local guard,report=ns.MotionGuard.Prepare(motion);assert(guard and report.guardMode=='dungeon-motion')
local before=poseReads
for i=1,20 do assert(ns.MotionGuard.Check(guard)) end
assert(poseReads==before,'live dungeon checks retried unavailable pose calls')
assert(report.positionError and report.facingError and motion.status=='unknown')
''', r'''
poseReads=0
C_Map.GetPlayerMapPosition=function() poseReads=poseReads+1;return nil end
GetPlayerFacing=function() poseReads=poseReads+1;return nil end
IsInInstance=function() return true,'party' end
UnitPosition=function() return nil,nil,nil,43 end
''')
check("a lost primary pose clears rather than silently switching modes", r'''
local guard,report=ns.MotionGuard.Prepare(ns.MotionGuard.Finish(ns.MotionGuard.Start()))
C_Map.GetPlayerMapPosition=function() return nil end;GetPlayerFacing=function() return nil end
local valid,reason=ns.MotionGuard.Check(guard)
assert(not valid and report.guardMode=='map-pose' and report.positionError and reason:find('unreadable'))
''', "IsInInstance=function() return true,'party' end;UnitPosition=function() return nil,nil,nil,43 end")
check("secret or nonfinite primary reads stay unknown without leaking values", r'''
local secret={};issecretvalue=function(v) return v==secret end
for _,value in ipairs({secret,math.huge,'wrong type'}) do
 C_Map.GetPlayerMapPosition=function() return {GetXY=function() return value,.5 end} end
 local motion=ns.MotionGuard.Finish(ns.MotionGuard.Start())
 assert(motion.status=='unknown' and motion.trace[1].x==nil)
 assert(not ns.MotionGuard.Prepare(motion))
end
''')
check("empty or explicitly unreadable evidence never creates a live token", r'''
local guard,report=ns.MotionGuard.Prepare({status='still',unknownSamples=0,trace={}})
assert(not guard and report.guardReason)
guard,report=ns.MotionGuard.Prepare({status='still',unknownSamples=1,trace={pose}})
assert(not guard and report.guardReason:find('unreadable'))
''')
check("every dungeon scan sample must remain in the same instance", r'''
local state=ns.MotionGuard.Start()
instanceID=44;ns.MotionGuard.Sample(state);instanceID=43
local motion=ns.MotionGuard.Finish(state);local token,report=ns.MotionGuard.Prepare(motion)
assert(not token and motion.dungeonGuard.status=='changed' and report.guardReason:find('instance'))
''', r'''
instanceID=43;IsInInstance=function() return true,'party' end
UnitPosition=function() return nil,nil,nil,instanceID end
C_Map.GetPlayerMapPosition=function() return nil end;GetPlayerFacing=function() return nil end
''')
print("8 shared motion guard checks passed")
