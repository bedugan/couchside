"""Check Couchside's settings window in Lua 5.1 with stubbed frames.

Loads the real base (Core, Panel, WindowTest) and the Controller module's options and second
press page, then drives the window as the controller would: pages, each control kind, the action
list, close, NPC closes and combat. Navigation, layout and taint still require an in-game check.
"""
from pathlib import Path

from lupa.lua51 import LuaRuntime

ROOT = Path(__file__).resolve().parents[1]
STUB = r'''
printed={};frames={};events={}
function print(t) printed[#printed+1]=t end
function date() return 'now' end
combat=false
function InCombatLockdown() return combat end
function GetCVar() return '0' end
function SetCVar() end
function GetTime() return 1 end
function UnitClass() return 'Shaman','SHAMAN' end
function UnitLevel() return 20 end
function UnitName() return 'Burn' end
function GetMacroInfo(i) if i==121 then return 'Bandage' end end
C_SpellBook={IsSpellKnownOrInSpellBook=function(id) return id==331 or id==526 end}
local spells={[331]='Healing Wave',[8004]='Lesser Healing Wave',[526]='Cure Poison'}
C_Spell={GetSpellInfo=function(x) local name=spells[x] if name then return {name=name,spellID=x} end end}
C_AddOns={GetAddOnMetadata=function() return 'x' end}
C_Timer={After=function(_,fn) fn() end}
EventUtil={ContinueOnAddOnLoaded=function(_,fn) fn() end}
SlashCmdList={}
local function newframe(kind,template)
 local f={kind=kind,template=template,shown=true,scripts={},checked=false}
 local mt={__index=function(t,k) if type(k)=='string' and k:match('^%u') then return function() end end end}
 function f:SetParent(p) self.parent=p end
 function f:SetScript(k,fn) self.scripts[k]=fn end
 function f:GetScript(k) return self.scripts[k] end
 function f:HookScript(k,fn) local old=self.scripts[k]; self.scripts[k]=function(...) if old then old(...) end fn(...) end end
 function f:Show() if not self.shown then self.shown=true; if self.scripts.OnShow then self.scripts.OnShow(self) end end end
 function f:Hide() if self.shown then self.shown=false; if self.scripts.OnHide then self.scripts.OnHide(self) end end end
 function f:SetShown(v) if v then self:Show() else self:Hide() end end
 function f:IsShown() return self.shown end
 function f:IsMouseOver() return false end
 function f:SetChecked(v) self.checked=v and true or false end
 function f:GetChecked() return self.checked end
 function f:SetText(x) self.text=x end
 function f:GetText() return self.text end
 function f:SetTitle(x) self.title=x end
 function f:GetStringHeight() return 14 end
 function f:GetPoint() return 'TOPLEFT',nil,'TOPLEFT',40,-80 end
 function f:SetPoint(...) self.point={...} end
 function f:RegisterEvent(e) events[e]=events[e] or {}; table.insert(events[e],self) end
 function f:CreateFontString() return newframe('FontString') end
 function f:CreateTexture() return newframe('Texture') end
 function f:RegisterCallback(_,fn,owner) self.onValue=function(v) fn(owner,v) end end
 return setmetatable(f,mt)
end
function CreateFrame(kind,name,parent,template)
 local f=newframe(kind,template)
 f.parent=parent
 if template=='ButtonFrameTemplate' then f.CloseButton=newframe('Button') end
 if template=='RightSideTabTemplate' then f.Icon=newframe('Texture') end
 if template=='MinimalSliderWithSteppersTemplate' then f.Slider=newframe('Slider');f.Back=newframe('Button');f.Forward=newframe('Button') end
 if name then _G[name]=f end
 table.insert(frames,f)
 return f
end
function Fire(event,...) for _,f in ipairs(events[event] or {}) do f.scripts.OnEvent(f,event,...) end end
function Click(f) if f.template=='UICheckButtonTemplate' then f.checked=not f.checked end f.scripts.OnClick(f) end
-- Frames on a page with a template, in creation order.
function On(page,template) local list={} for _,f in ipairs(frames) do if f.parent==page.frame and f.template==template then list[#list+1]=f end end return list end
function Logged(text) for _,line in ipairs(CouchsideDB.windowTest) do if line:find(text,1,true) then return true end end return false end
UIParent={}
ButtonFrameTemplate_HidePortrait=function() end
PanelTemplates_SelectTab=function(tab) tab.selected=true end
PanelTemplates_DeselectTab=function(tab) tab.selected=false end
PanelTemplates_TabResize=function() end
PlaySound=function() end
SOUNDKIT={}
navigationFrame=nil
local mgr={}
function mgr:FrameShown(f) navigationFrame=f end
function mgr:FrameHidden(f) navigationFrame=nil end
GamepadMode={FrameControlsManager=mgr}
SmartNavigation={HandlePanelOpen=function() rescans=(rescans or 0)+1 end,SelectFirstButton=function() end}
setmetatable(SmartNavigation,{__index=function(t,k) if k=='activeInfo' then return navigationFrame and {frame=navigationFrame} end end})
MinimalSliderWithSteppersMixin={Event={OnValueChanged=1},Label={Right=2}}
base={};ctl={}
'''


def run(code):
    vm = LuaRuntime(register_eval=False, register_builtins=False)
    vm.execute(STUB)
    for path, ns in (('Couchside/Core.lua', 'base'), ('Couchside/Panel.lua', 'base'), ('Couchside/WindowTest.lua', 'base'),
                     ('Couchside_Controller/Controller.lua', 'ctl'), ('Couchside_Controller/SecondPress.lua', 'ctl')):
        addon = path.split('/')[0]
        vm.execute(f'local text,addon=...;assert(loadstring(text))(addon,{ns})', (ROOT / path).read_text(), addon)
    vm.execute(code)


def check(name, code):
    run(code)
    print('PASS', name)


check('/cs opens a page per module plus Second press and General, and the controller takes it', '''
SlashCmdList.COUCHSIDE('')
local window=CouchsideWindow
assert(window:IsShown() and navigationFrame==window)
assert(window.title=='Couchside: Controller')
assert(CouchsideWindowTab1.text=='Controller' and CouchsideWindowTab2.text=='Second press' and CouchsideWindowTab3.text=='General')
assert(CouchsideWindowTab1.selected and not CouchsideWindowTab2.selected and CouchsideWindowTab1.parent==window)
assert(Logged('controller navigation on the window: PASS'))
SlashCmdList.COUCHSIDE('');assert(not window:IsShown() and navigationFrame==nil and Logged('hidden'))
''')
check('each control kind saves to the right table and logs PASS', '''
SlashCmdList.COUCHSIDE('')
local checks,buttons,sliders={},{},{}
for _,f in ipairs(frames) do
 if f.template=='UICheckButtonTemplate' then checks[#checks+1]=f end
 if f.template=='UIPanelButtonTemplate' then buttons[#buttons+1]=f end
 if f.template=='MinimalSliderWithSteppersTemplate' then sliders[#sliders+1]=f end
end
Click(checks[1]);assert(CouchsideDB.modules.controller.pageNumbers==true)
assert(Logged('set controller.pageNumbers to true: PASS, saved'))
assert(buttons[1].text=='Automatic');Click(buttons[1]);assert(CouchsideCharDB.modules.controller.partyHintPosition=='left')
assert(buttons[1].text=='Left')
assert(buttons[2].text=='Automatic');Click(buttons[2]);assert(CouchsideDB.modules.controller.partyHintLabels=='xbox')
sliders[1].onValue(123);assert(CouchsideCharDB.modules.controller.partyHintSize==120)
assert(Logged('set controller.partyHintSize to 120: PASS, saved'))
''')
check('the Second press tab holds its checkbox and the action list, and picking saves', '''
SlashCmdList.COUCHSIDE('')
local before=rescans or 0
Click(CouchsideWindowTab2)
assert(CouchsideWindow.title=='Couchside: Second press' and rescans==before+1)
assert(Logged('page Second press (tab)'))
local rows={}
for _,f in ipairs(frames) do if f.template=='UIPanelButtonTemplate' and rawget(f,'Tick') then rows[#rows+1]=f end end
assert(rows[1].text=='Class default: Healing Wave' and rows[2].text=='Cure Poison')
assert(rows[3].text=='Macro: Bandage' and rows[4].text=='Nothing' and not rows[5]:IsShown())
Click(rows[3]);assert(CouchsideCharDB.data.controller.secondPress.macro=='Bandage')
assert(Logged('picked Macro: Bandage'))
local secondPressChecks=0
for _,f in ipairs(frames) do if f.template=='UICheckButtonTemplate' and f.parent and f.parent.shown and f.parent~=CouchsideWindow and f.parent.parent==CouchsideWindow then secondPressChecks=secondPressChecks+1 end end
assert(secondPressChecks==1, secondPressChecks)
''')
check('NPC closes after the window are checked three times', '''
SlashCmdList.COUCHSIDE('');SlashCmdList.COUCHSIDE('')
Fire('GOSSIP_CLOSED');Fire('MERCHANT_CLOSED')
Fire('ADDON_ACTION_FORBIDDEN','Couchside','SetPreferredGamepadInteractTarget()')
Fire('GOSSIP_CLOSED');Fire('GOSSIP_CLOSED')
assert(Logged('NPC window close 1 of 3 (GOSSIP_CLOSED): PASS'))
assert(Logged('NPC window close 3 of 3 (GOSSIP_CLOSED): FAIL'))
assert(Logged('NPC checks: 2 of 3 passed'))
''')
check('combat closes the window and stops it opening', '''
SlashCmdList.COUCHSIDE('')
Fire('PLAYER_REGEN_DISABLED')
assert(not CouchsideWindow:IsShown() and navigationFrame==nil and Logged('closed itself for combat'))
combat=true;SlashCmdList.COUCHSIDE('')
assert(not CouchsideWindow:IsShown() and printed[#printed]:find('out of combat',1,true))
''')
check('/cs help still lists the commands', '''
SlashCmdList.COUCHSIDE('help')
local found=false for _,line in ipairs(printed) do if line:find('/cs - open or close the settings window',1,true) then found=true end end
assert(found)
''')
check('dragging saves the position and the next window opens there', '''
SlashCmdList.COUCHSIDE('')
CouchsideWindow.scripts.OnDragStop(CouchsideWindow)
assert(CouchsideDB.windowPosition.point=='TOPLEFT' and CouchsideDB.windowPosition.x==40)
assert(Logged('moved to TOPLEFT 40, -80; saved'))
''')
check('a saved position places the window when it is built', '''
CouchsideDB={windowPosition={point='TOPLEFT',x=40,y=-80}}
SlashCmdList.COUCHSIDE('')
assert(CouchsideWindow.point[1]=='TOPLEFT' and CouchsideWindow.point[4]==40)
assert(Logged('opened at the saved position TOPLEFT 40, -80'))
''')
