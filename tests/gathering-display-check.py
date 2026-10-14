"""Display rejection/clearing diagnostics, not proof of the native failure cause."""
import runpy
from pathlib import Path

checks = runpy.run_path(str(Path(__file__).with_name("gathering-legend-check.py")))
check = checks["check"]

check("unreadable scan records the reason for an absent list", r'''
local s=scan({{text='Silverleaf',x=.8,y=.5}})
s.motion={status='unknown',unknownSamples=66,trace={{positionError='player map position unavailable',facingError='player facing unavailable'}}}
local d=ns.NearbyList.Show(s)
assert(not visiblePanel() and d.status=='withheld')
assert(d.reason:find('unknown') and d.positionError and d.facingError)
CouchsideGatheringScanDB.scans={s};s.display=d
commands.display('')
local text=table.concat(logs,'\n');assert(text:find('player map position unavailable') and text:find('player facing unavailable'))
assert(nativeCalls==0)
''')
check("acceptance guards report distinct reasons", r'''
for _,case in ipairs({
 {'cleanup',function(s) s.cleanupRequestSucceeded=false end},
 {'moving',function(s) s.motion.status='moving' end},
 {'unreadable',function(s) s.motion.unknownSamples=1 end},
 {'quest',function(s) s.questText.available=false end},
 {'combat',function() combat=true end},
 {'geometry',function(s) s.geometry.zoom=1 end},
 {'disabled',function() enabled=false end},
}) do
 combat=false;enabled=true;snapshot.available=true
 local s=scan({{text='Silverleaf',x=.8,y=.5}});case[2](s)
 local d=ns.NearbyList.Show(s)
 assert(d.status=='withheld' and d.reason:find(case[1]),d.reason)
 assert(not visiblePanel())
end
''')
check("immediate live pose failure has a saved display verdict", r'''
local s=scan({{text='Silverleaf',x=.8,y=.5}})
pose.positionError='position unavailable';pose.facingError='facing unavailable'
local d=ns.NearbyList.Show(s)
assert(d.status=='withheld' and d.positionError and d.facingError and not visiblePanel())
''')
check("clearing updates the original persisted diagnostic table", r'''
for _,why in ipairs({'position','facing','expired','combat'}) do
 motion=false;combat=false;clock=0;pose.facing=0
 local s=scan({{text='Silverleaf',x=.8,y=.5}})
 local captured={};for k,v in pairs(pose) do captured[k]=v end;s.motion.trace={captured}
 local d=ns.NearbyList.Show(s);s.display=d
 assert(d.status=='shown')
 if why=='position' then motion=true elseif why=='facing' then pose.facing=.1
 elseif why=='combat' then combat=true else clock=ns.NearbyList.LIFETIME-.1;tick(.05);assert(d.status=='shown');clock=ns.NearbyList.LIFETIME end
 tick(.1)
 assert(s.display==d and d.status=='cleared' and d.reason:find(why),d.reason)
 assert(not visiblePanel() and #markers()==0)
end
''')
check("display report after reload reads history without reviving it", r'''
CouchsideGatheringScanDB.scans={{id=91,display={status='cleared',reason='snapshot expired',addonVersion='0.11.2'}}}
commands.display('');assert(not visiblePanel() and nativeCalls==0)
assert(table.concat(logs,'\n'):find('previous session'))
''')
check("old history without a verdict remains explicit", r'''
CouchsideGatheringScanDB.scans={{id=72}}
commands.display('');assert(table.concat(logs,'\n'):find('No display verdict'))
assert(not visiblePanel() and nativeCalls==0)
''')
check("state read errors preserve the failure and stop polling", r'''
local s=scan({{text='Silverleaf',x=.8,y=.5}})
local d=ns.NearbyList.Show(s)
Minimap.GetRect=function() error('geometry unavailable') end
tick(.1);assert(d.status=='cleared' and d.reason:find('geometry unavailable'))
assert(not visiblePanel())
for _,frame in ipairs(frames) do if frame.scripts.OnUpdate then assert(not frame.shown) end end
''')
check("renderer errors replace the last diagnostic for the report", r'''
ns.NearbyList.Show(scan({{text='Silverleaf',x=.8,y=.5}}))
local d=ns.NearbyList.RecordError('texture failure')
assert(d.status=='error' and not visiblePanel() and #markers()==0)
commands.display('');assert(table.concat(logs,'\n'):find('texture failure'))
''')
print("8 display diagnostic checks passed")
