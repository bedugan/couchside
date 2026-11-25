"""Read-only quest-role report lifecycle and evidence preservation, using Lua 5.1."""
from pathlib import Path
from lupa.lua51 import LuaRuntime

ROOT = Path(__file__).resolve().parents[1]
STUB = r'''
logs={};commands={};timers={};frames={};mapCalls={};requests={};reads=0
ns={RegisterCommand=function(name,_,fn) commands[name]=fn end,
 OnReady=function(fn) fn() end,Print=function(fmt,...) logs[#logs+1]=string.format(fmt,...) end,Debug=function() end}
function GetBuildInfo() return '1.60.1','70374','',16001 end
function GetServerTime() return 100 end
playerMap=1413
C_Map={GetBestMapForUnit=function(unit) assert(unit=='player');reads=reads+1;return playerMap end}
WorldMapFrame={GetMapID=function() error('must not read viewed map as player context') end}
C_Minimap={GetUiMapID=function() return 1413 end,GetNumTrackingTypes=function() return 1 end,
 GetTrackingInfo=function(index) return {name='Quest Givers',active=true,type='other',index=index} end}
points={{questID=1,mapID=1413,x=.4,y=.6,isQuestStart=false,inProgress=true}}
offers={{questID=2,questName='Available',isQuestStart=true,inProgress=false,isDaily=false}}
force={2}
C_QuestLog={GetQuestsOnMap=function(mapID) mapCalls[#mapCalls+1]=mapID;return points end,
 GetTitleForQuestID=function(id) return 'Quest '..id end,GetLogIndexForQuestID=function(id) if id==1 then return 3 end end,
 IsComplete=function(id) return id==1 end,ReadyForTurnIn=function(id) return id==1 end,
 IsRepeatableQuest=function() return false end}
C_QuestLine={GetAvailableQuestLines=function(mapID) mapCalls[#mapCalls+1]=mapID;return offers end,
 GetForceVisibleQuests=function(mapID) mapCalls[#mapCalls+1]=mapID;return force end,
 GetQuestLineInfo=function(id,mapID,displayableOnly) assert(displayableOnly==false);return {questID=id,startMapID=mapID,isHidden=true} end,
 RequestQuestLinesForMap=function(mapID) requests[#requests+1]=mapID end}
C_TooltipInfo={GetMinimapMouseover=function() return {type=21,lines={{leftText='NPC / Resource',rightText='raw'}},questID=2} end}
C_GossipInfo={GetAvailableQuests=function() return {{questID=2,title='Available',isRepeatable=false}} end,
 GetActiveQuests=function() return {{questID=1,title='Quest 1',isComplete=true}} end}
GossipFrame={IsShown=function() return false end}
C_Timer={After=function(delay,fn) timers[#timers+1]={delay=delay,fn=fn} end}
function CreateFrame()
 local frame={}
 function frame:RegisterEvent(event) if eventError then error('unsupported event') end;self.event=event end
 function frame:UnregisterAllEvents() self.event=nil end
 function frame:SetScript(key,fn) self[key]=fn end
 frames[#frames+1]=frame;return frame
end
function event(value) local f=frames[1];if f and f.OnEvent then f.OnEvent(f,'QUESTLINE_UPDATE',value) end end
function last() return CouchsideQuestsRoleDB.reports[#CouchsideQuestsRoleDB.reports] end
function timeout(index) timers[index or #timers].fn() end
function forbidden() error('native mutation must not occur') end
Minimap={SetUsingSoftCursor=forbidden,UpdateMouseoverAtPoint=forbidden}
C_QuestLog.AddQuestWatch=forbidden;C_QuestLog.RemoveQuestWatch=forbidden
C_Minimap.SetTracking=forbidden
function issecretvalue(value) return type(value)=='table' and value.secret==true end
'''


def check(name, code):
    vm = LuaRuntime(register_eval=False, register_builtins=False)
    vm.execute(STUB)
    vm.execute('assert(loadstring(...))("Couchside_Quests",ns)', (ROOT / 'Couchside_Quests/QuestRoleProbe.lua').read_text())
    vm.execute(code)
    print('PASS', name)


check('role probe does no reads or polling until explicitly called', r'''
assert(reads==0 and #timers==0 and #frames==0 and #CouchsideQuestsRoleDB.reports==0)
''')
check('explicit player map and raw states stay separate from role inference', r'''
commands.roles('offer');local r=last()
assert(r.label=='offer' and r.mapData.points.rows[1].isQuestStart==false)
assert(r.mapData.offers.rows[1].isQuestStart==true)
assert(r.mapData.quests[1].complete.value and r.mapData.quests[1].logIndex.value==3)
assert(r.mapData.quests[2].logIndex.status=='nil' and r.mapData.quests[2].repeatable.value==false)
assert(r.mapData.quests[2].lineInfo.value.isHidden and r.gossipVisible.value==false)
for _,id in ipairs(mapCalls) do assert(id==1413) end
assert(r.hover.value.lines[1].leftText=='NPC / Resource' and r.hover.value.questID==2)
assert(#logs==1 and #timers==0 and #requests==0)
''')
check('missing nil empty false and errors remain distinguishable', r'''
C_QuestLine=nil;C_QuestLog.GetQuestsOnMap=function() return nil end
C_GossipInfo.GetAvailableQuests=function() return {} end
C_GossipInfo.GetActiveQuests=function() error('read failed') end
commands.roles('unknown');local r=last()
assert(r.mapData.offers.status=='missing' and r.mapData.points.status=='nil')
assert(r.gossipAvailable.status=='ok' and r.gossipAvailable.total==0)
assert(r.gossipActive.status=='error' and r.gossipActive.detail:find('read failed'))
assert(r.gossipVisible.value==false)
''')
check('missing player map does not fall back to viewed or minimap map', r'''
playerMap=nil;commands.roles('no-map')
assert(last().mapData.status=='no-player-map' and #mapCalls==0)
''')
check('secret and cyclic tooltip data are sanitized without native mutations', r'''
local tip={lines={{leftText={secret=true}}},secretField=function() end};tip.loop=tip
C_TooltipInfo.GetMinimapMouseover=function() return tip end
commands.roles('hover');local r=last()
assert(r.hover.value.lines[1].leftText=='<secret omitted>')
assert(r.hover.value.loop=='<repeated table>' and r.hover.value.secretField=='<function omitted>')
C_TooltipInfo.GetMinimapMouseover=function() return {secret=true} end
commands.roles('restricted');assert(last().hover.status=='restricted')
''')
check('point lists quest details strings tracking and history stay bounded', r'''
points={};offers={};force={};for i=1,65 do points[i]={questID=i} end
C_Minimap.GetNumTrackingTypes=function() return 70 end
C_TooltipInfo.GetMinimapMouseover=function() return {text=string.rep('x',900)} end
for i=1,10 do commands.roles('sample-'..i) end
local r=last();assert(r.mapData.points.total==65 and #r.mapData.points.rows==40 and r.mapData.points.truncated)
assert(#r.tracking.entries==40 and r.tracking.truncated)
assert(r.hover.value.text:find('<truncated>',1,true))
assert(#CouchsideQuestsRoleDB.reports==8 and CouchsideQuestsRoleDB.reports[1].id==3 and r.id==10)
''')
check('request captures initial hover and a separate response with event cleanup', r'''
commands.roles('request offer');assert(#requests==1 and requests[1]==1413 and #CouchsideQuestsRoleDB.reports==0)
offers={{questID=3,isQuestStart=true}};playerMap=1421;event(false)
local r=last();assert(r.requestStatus=='event-observed' and r.mapData.offers.rows[1].questID==2)
assert(r.afterRequest.offers.rows[1].questID==3 and r.afterRequest.mapID==1413 and r.playerMapAfter.value==1421)
assert(r.hover.value.questID==2 and frames[1].event==nil and frames[1].OnEvent==nil)
timeout();assert(#CouchsideQuestsRoleDB.reports==1)
''')
check('request-required event does not masquerade as a finished response', r'''
commands.roles('request repeatable');event(true);assert(#CouchsideQuestsRoleDB.reports==0)
timeout();assert(last().requestRequiredObserved and last().requestStatus=='timeout-unknown')
''')
check('replacement requests cannot be completed by old timeouts', r'''
commands.roles('request first');commands.roles('request second')
assert(last().label=='first' and last().requestStatus=='cancelled')
timeout(1);assert(#CouchsideQuestsRoleDB.reports==1)
event(false);assert(last().label=='second' and last().requestStatus=='event-observed')
''')
check('off cancels and retains the original request evidence', r'''
commands.roles('request');commands.roles('off')
assert(last().label=='unlabelled' and last().requestStatus=='cancelled')
timeout();assert(#CouchsideQuestsRoleDB.reports==1)
''')
check('request missing event or failed API remains explicit', r'''
C_QuestLine.RequestQuestLinesForMap=nil;commands.roles('request missing');assert(last().requestStatus=='missing')
C_QuestLine.RequestQuestLinesForMap=function() error('request failed') end
eventError=true;commands.roles('request event');assert(last().requestStatus=='event-unavailable')
eventError=false;commands.roles('request failed');assert(last().requestStatus=='request-error')
assert(last().requestCall.status=='error' and frames[1].event==nil)
''')
check('invalid command and show do not read native APIs or change history', r'''
commands.roles('offer');local before=reads
commands.roles('a label with spaces');commands.roles('show')
assert(reads==before and #CouchsideQuestsRoleDB.reports==1)
''')
check('unsupported saved version is preserved', r'''
CouchsideQuestsRoleDB={version=99,precious='retained'};commands.roles('offer')
assert(CouchsideQuestsRoleDB.precious=='retained' and CouchsideQuestsRoleDB.reports==nil)
''')

vm = LuaRuntime(register_eval=False, register_builtins=False)
addon = ROOT / 'Couchside_Quests'
files = sorted(addon.glob('*.lua'))
for path in files:
    vm.execute('assert(loadstring(...))', path.read_text())
toc = (addon / 'Couchside_Quests.toc').read_text()
saved_line = next(line for line in toc.splitlines() if line.startswith('## SavedVariablesPerCharacter:'))
assert {name.strip() for name in saved_line.split(':', 1)[1].split(',')} == {'CouchsideQuestsTrackingDB', 'CouchsideQuestsRoleDB'}
entries = [line.strip() for line in toc.splitlines() if line.strip() and not line.startswith('#')]
assert len(entries) == len(set(entries)) and {p.name for p in files} == set(entries)
print('PASS Quests Lua 5.1 syntax, TOC inventory and both per-character saved globals:', len(files), 'files')
print('13 quest-role checks passed; native API coverage remains unverified')
