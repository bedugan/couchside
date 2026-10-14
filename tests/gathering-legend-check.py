"""Lua 5.1 checks for prototype classification and display lifecycle.

These fixtures cannot establish WoW taint safety or native texture appearance.
"""
from pathlib import Path
from lupa.lua51 import LuaRuntime

ROOT = Path(__file__).resolve().parents[1]
FILES = ("ScanLog.lua", "QuestTextFilter.lua", "ResourceLegend.lua", "ResourceClassifier.lua", "MotionGuard.lua", "NearbyList.lua")
STUB = r'''
logs={};commands={};frames={};nativeCalls=0;clock=0;combat=false;enabled=true;legend=true;motion=false
pose={mapID=1413,x=.5,y=.5,facing=0,rotating=false}
ns={Print=function(fmt,...) table.insert(logs,string.format(fmt,...)) end,Debug=function() end,
 RegisterCommand=function(k,_,fn) commands[k]=fn end,OnReady=function(fn) fn() end,
 IsEnabled=function(k) return k=='resourceLegend' and legend or k=='nearbyList' and enabled end,
 OnOptionChanged=function(fn) optionHandlers[#optionHandlers+1]=fn end}
optionHandlers={}
changed=function(key) for _,fn in ipairs(optionHandlers) do fn(key) end end
function GetTime() return clock end
function InCombatLockdown() return combat end
function CreateFrame(_,_,parent)
 local f={shown=true,parent=parent,scripts={},events={}}
 function f:Show() self.shown=true end
 function f:Hide() self.shown=false end
 function f:SetScript(k,v) self.scripts[k]=v end
 function f:SetPoint(...) self.point={...} end
 function f:ClearAllPoints() self.point=nil end
 function f:SetText(v) self.text=v end
 function f:SetTexture(v) self.texture=v end
 function f:SetRotation(v) self.rotation=v end
 function f:SetSize(w,h) self.width=w;self.height=h end
 function f:RegisterEvent(e) self.events[e]=true end
 function f:UnregisterAllEvents() self.events={} end
 function f:CreateTexture() return CreateFrame(nil,nil,self) end
 function f:CreateFontString() return CreateFrame(nil,nil,self) end
 for _,k in ipairs({'EnableMouse','SetWidth','SetHeight','SetColorTexture','SetAllPoints','SetVertexColor','SetTextColor','SetWordWrap','SetAtlas','SetFrameLevel'}) do f[k]=function() end end
 frames[#frames+1]=f;return f
end
Minimap={GetRect=function() return 100,100,198,198 end,GetEffectiveScale=function() return .711 end,
 GetZoom=function() return 0 end,IsVisible=function() return true end,GetFrameLevel=function() return 1 end,
 UpdateMouseoverAtPoint=function() nativeCalls=nativeCalls+1 end,SetUsingSoftCursor=function() nativeCalls=nativeCalls+1 end}
function IsInInstance() return false,'none' end
function GetUnitSpeed() return 0 end
function IsPlayerMoving() return false end
function UnitPosition() return nil end
function GetPlayerFacing() if pose.facingError then error(pose.facingError) end;return pose.facing end
function GetCVarBool() return pose.rotating end
C_Map={GetBestMapForUnit=function() return pose.mapID end,
 GetPlayerMapPosition=function()
  if pose.positionError then error(pose.positionError) end
  return {GetXY=function() return motion and .6 or pose.x,pose.y end}
 end}
snapshot={available=true,titles={['Centaur Bracers']=855},objectives={},warnings={}}
function scan(regions,filters)
 return {regions=regions,filtersByText=filters or {},questText=snapshot,
 geometry={left=100,bottom=100,width=198,height=198,scale=.711,zoom=0},
 motion={status='still',unknownSamples=0,trace={pose}},cleanupRequestSucceeded=true}
end
function visiblePanel()
 for _,f in ipairs(frames) do if f.parent==Minimap and f.shown and f.point and f.point[1]=='TOPRIGHT' then return true end end
 return false
end
function markers()
 local result={};for _,f in ipairs(frames) do if f.parent==Minimap and f.shown and f.symbol then result[#result+1]=f end end;return result
end
function tick(delta)
 clock=clock+delta
 for _,f in ipairs(frames) do if f.shown and f.scripts.OnUpdate then f.scripts.OnUpdate(f,delta) end end
end
'''


def make(extra_stub=""):
    vm = LuaRuntime()
    vm.execute(STUB)
    if extra_stub:
        vm.execute(extra_stub)
    for name in FILES:
        vm.execute('assert(loadstring(...))("Couchside_Gathering",ns)', (ROOT / "Couchside_Gathering" / name).read_text())
    return vm


def check(name, code):
    make().execute(code)
    print("PASS", name)


check("partial catalog and provisional evidence remain explicit", r'''
local m=ns.ResourceLegend.Lookup('Mageroyal');assert(m.symbol=='diamond-purple' and m.cacheLockID==9)
assert(ns.ResourceLegend.Lookup('Earthroot').cacheLockID==nil)
assert(ns.ResourceLegend.Lookup('Bruiseweed').symbol=='cross-red')
assert(ns.ResourceLegend.Lookup('Kingsblood').symbol=='hexagon-teal')
assert(not ns.ResourceLegend.Lookup('Copper Vein') and not ns.ResourceLegend.Lookup('NPC'))
local symbols={};for _,name in ipairs({'Mageroyal','Peacebloom','Silverleaf','Earthroot','Briarthorn','Bruiseweed','Kingsblood'}) do
 local entry=ns.ResourceLegend.Lookup(name);assert(entry and not symbols[entry.symbol]);symbols[entry.symbol]=true
end
''')
check("two same-name regions keep one row and identical symbols", r'''
local s=scan({{text='Mageroyal',x=.8,y=.5},{text='Mageroyal',x=.2,y=.6},{text='Peacebloom',x=.3,y=.3}})
local m=ns.ResourceLegend.Build(s);assert(#m.rows==2 and #m.marks==3)
assert(m.marks[1].symbol==m.marks[2].symbol and m.marks[1].symbol=='diamond-purple')
s.regions[1]=s.regions[2];s.regions[2]=nil;s.regions[3]=nil
m=ns.ResourceLegend.Build(s);assert(m.marks[1].symbol=='diamond-purple')
''')
check("mixed resource and unknown preserves both names", r'''
local f=ns.QuestTextFilter.Filter({lines={{leftText='Mageroyal\nLizzarik\nCentaur Bracers'}}},snapshot)
local m=ns.ResourceLegend.Build(scan({{text=f.text,x=.8,y=.5}},{raw=f}))
assert(#m.rows==2 and #m.marks==0 and m.withheldRegions==1 and m.rows[2].text=='Lizzarik' and not m.rows[2].symbol)
''')
check("two resource names in one region get no invented marks", r'''
local f={text='Mageroyal / Silverleaf',entries={'Mageroyal','Silverleaf'},removed={}}
local m=ns.ResourceLegend.Build(scan({{text=f.text,x=.5,y=.6}},{raw=f}))
assert(#m.rows==2 and #m.marks==0 and m.withheldRegions==1)
''')
check("slash names and inconsistent joined filters stay unknown", r'''
local m=ns.ResourceLegend.Build(scan({{text='Mageroyal / NPC',x=.4,y=.5}}));assert(#m.marks==0 and m.rows[1].kind=='unknown')
local m=ns.ResourceLegend.Build(scan({{text='Mageroyal / NPC',x=.4,y=.5}},
 {a={text='Mageroyal / NPC',entries={'Mageroyal','NPC'}},b={text='Mageroyal / NPC',entries={'Mageroyal / NPC'}}}))
assert(#m.marks==0 and m.rows[1].kind=='unknown')
''')
check("quest resource collision survives earlier exclusion without symbol", r'''
snapshot.titles.Mageroyal=123
local f=ns.QuestTextFilter.Filter({lines={{leftText='Mageroyal'}}},snapshot)
local m=ns.ResourceLegend.Build(scan({}, {raw=f}))
assert(#m.rows==1 and m.rows[1].kind=='ambiguous' and not m.rows[1].symbol and #m.marks==0)
''')
check("malformed positions withhold marks while keeping labels", r'''
for _,x in ipairs({-.1,1.1,math.huge,0/0,'invalid'}) do
 local m=ns.ResourceLegend.Build(scan({{text='Mageroyal',x=x,y=.5}}));assert(#m.rows==1 and #m.marks==0)
end
''')
check("prototype report persists evidence without native calls or scan mutation", r'''
CouchsideGatheringScanDB.scans={{id=39,build='70338',questText=snapshot,
 tipsByText={Mageroyal={lines={{leftText='Mageroyal'}}},NPC={lines={{leftText='NPC'}}}}}}
local old=CouchsideGatheringScanDB.scans[1];commands.classify('prototype 39')
local report=CouchsideGatheringScanDB.providerReports[1]
assert(report.provider=='Couchside prototype' and report.counts['resource-candidate']==1 and report.counts.unknown==1)
assert(report.entries[1].cacheLockID==9 and report.entries[1].symbol=='diamond-purple')
assert(old==CouchsideGatheringScanDB.scans[1] and nativeCalls==0)
''')
check("classified display hides legacy letters and shows repeated symbols", r'''
ns.NearbyList.Show(scan({{text='Mageroyal',x=.8,y=.5},{text='Mageroyal',x=.2,y=.6},{text='NPC',x=.4,y=.4}}))
assert(visiblePanel() and #markers()==2 and markers()[1].symbol.texture==markers()[2].symbol.texture)
for _,f in ipairs(frames) do if f.parent==Minimap and f.letter then assert(not f.shown) end end
assert(nativeCalls==0)
''')
check("movement, combat and expiry clear all owned marks", r'''
for _,why in ipairs({'motion','combat','expiry'}) do
 motion=false;combat=false;clock=0
 ns.NearbyList.Show(scan({{text='Mageroyal',x=.8,y=.5}}))
 if why=='motion' then motion=true elseif why=='combat' then combat=true else clock=10 end
 tick(.1);assert(not visiblePanel() and #markers()==0)
end
''')
check("option changes restore legacy layout without stale symbols", r'''
local s=scan({{text='Mageroyal',x=.8,y=.5}})
ns.NearbyList.Show(s);legend=false;changed('resourceLegend');assert(not visiblePanel() and #markers()==0)
ns.NearbyList.Show(s);assert(visiblePanel() and #markers()==0)
local letters=0;for _,f in ipairs(frames) do if f.parent==Minimap and f.shown and f.letter then letters=letters+1 end end;assert(letters==1)
enabled=false;changed('nearbyList');assert(not visiblePanel())
''')
check("row and mark limits never invent node counts", r'''
local regions={};for i=1,30 do regions[#regions+1]={text='Mageroyal',x=.5,y=.5} end
for i=1,12 do regions[#regions+1]={text='NPC '..i,x=.5,y=.5} end
ns.NearbyList.Show(scan(regions));assert(#markers()==24)
local joined='';for _,f in ipairs(frames) do if f.text then joined=joined..'\n'..f.text end end
assert(joined:find('8 of 13 names') and joined:find('some marks omitted'))
''')
check("failed cleanup and motion snapshots remain withheld", r'''
local s=scan({{text='Mageroyal',x=.8,y=.5}});s.cleanupRequestSucceeded=false
ns.NearbyList.Show(s);assert(not visiblePanel())
s.cleanupRequestSucceeded=true;s.motion.status='moving';ns.NearbyList.Show(s);assert(not visiblePanel())
''')
check("reused map badge resets star size without resizing list symbols", r'''
ns.NearbyList.Show(scan({{text='Briarthorn',x=.8,y=.5}}))
local badge=markers()[1];assert(badge.width==16 and badge.height==16)
local listStar=false;for _,f in ipairs(frames) do
 if f.texture and f.texture:find('star%-yellow') and f.width==24 then listStar=true end
end;assert(listStar)
ns.NearbyList.Show(scan({{text='Peacebloom',x=.8,y=.5}}))
assert(markers()[1]==badge and badge.width==12 and badge.height==12)
ns.NearbyList.Show(scan({{text='Briarthorn',x=.8,y=.5}}))
assert(markers()[1]==badge and badge.width==16 and badge.height==16)
''')
print("14 prototype legend checks passed")
