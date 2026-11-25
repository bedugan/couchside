"""Check Couchside's settings-row geometry and pooled-row cleanup in Lua 5.1.

The fixture follows Blizzard's InitFrame/Resetter lifecycle. Native font fitting,
settings navigation and controller behavior still require an in-game check.
"""
from pathlib import Path

from lupa.lua51 import LuaRuntime

ROOT = Path(__file__).resolve().parents[1]
STUB = r'''
initializers={};settings={};pages={};notifications={};debugMessages={};dropdowns={};sliders={}
ns={base={sections={{title='General',options={
 {key='debug',name='Enable debug output',default=false,tooltip='Debug tooltip'},
}}},variablePrefix='BASE_',db={}},modules={
 {title='Gathering',sections={{title='Tooltips',options={
  {key='tooltipDifficulty',name='Show gathering difficulty in tooltips',default=true,tooltip='Difficulty tooltip'},
  {key='place',name='Place',default='auto',tooltip='Place tooltip',
   choices={{value='auto',label='Automatic'},{value='left',label='Left'}}},
  {key='size',name='Size',default=100,min=50,max=200,step=10,format='%d%%',tooltip='Size tooltip'},
  {key='mine',name='Mine',default=false,scope='character',tooltip='Mine tooltip'},
 }}},variablePrefix='GATHERING_',db={},charDB={}},
}}
ns.NotifyOptionChanged=function(page,key,value)
 notifications[#notifications+1]={page=page,key=key,value=value}
end
-- Mirrors Core.lua's ns.OptionKind.
ns.OptionKind=function(option)
 if option.choices then return 'choice' end
 return type(option.default)=='number' and 'number' or 'boolean'
end
-- Mirrors Core.lua's ns.OptionTable.
ns.OptionTable=function(page,option)
 if option.scope=='character' then return page.charDB end
 return page.db
end
ns.Debug=function(...) debugMessages[#debugMessages+1]={...} end
ns.RegisterCommand=function() end
function CreateFrame()
 return {RegisterEvent=function() end,SetScript=function(_,_,fn) login=fn end}
end
C_AddOns={GetAddOnMetadata=function() return 'Couchside' end}
function CreateSettingsListSectionHeaderInitializer(title) return title end
local function category(title)
 pages[#pages+1]=title
 return {GetID=function() return #pages end},{AddInitializer=function() end}
end
MinimalSliderWithSteppersMixin={Label={Right='Right'}}
Settings={VarType={Boolean='Boolean',String='String',Number='Number'},RegisterVerticalLayoutCategory=category,
 RegisterVerticalLayoutSubcategory=function(_,title) return category(title) end,
 RegisterAddOnCategory=function() end,
 RegisterAddOnSetting=function(_,variable,key,db,varType,name,default)
  local s={key=key,db=db,varType=varType,name=name,default=default}
  function s:SetValueChangedCallback(fn) self.callback=fn end
  settings[variable]=s;return s
 end,
 CreateCheckbox=function(_,setting,tooltip)
  local initializer={setting=setting,tooltip=tooltip}
  -- ScrollBoxFactoryInitializerMixin delegates to the pooled row's methods.
  function initializer:InitFrame(row) row:Init(self) end
  function initializer:Resetter(row) row:Release(self) end
  initializers[#initializers+1]=initializer;return initializer
 end,
 CreateControlTextContainer=function()
  local data={}
  return {Add=function(_,value,label) data[#data+1]={value=value,label=label} end,
   GetData=function() return data end}
 end,
 CreateDropdown=function(_,setting,options,tooltip)
  dropdowns[#dropdowns+1]={setting=setting,options=options,tooltip=tooltip}
 end,
 CreateSliderOptions=function(min,max,step)
  return {min=min,max=max,step=step,SetLabelFormatter=function(self,_,fn) self.formatter=fn end}
 end,
 CreateSlider=function(_,setting,options,tooltip)
  sliders[#sliders+1]={setting=setting,options=options,tooltip=tooltip}
 end,
}
function hooksecurefunc(object,key,hook)
 local original=object[key]
 object[key]=function(...) original(...);hook(...) end
end
function region()
 return {points={},ClearAllPoints=function(self) self.points={} end,
  SetPoint=function(self,point,relative,relativePoint,x,y)
   self.points[point]={relative=relative,point=relativePoint,x=x,y=y}
  end}
end
function newRow(width)
 local row={width=width,Text=region(),Checkbox=region(),Tooltip=region(),initCount=0,releaseCount=0}
 row.Checkbox:SetPoint('LEFT',row,'CENTER',-80,0)
 row.Tooltip:SetPoint('TOPLEFT',row,'TOPLEFT',0,0)
 row.Tooltip:SetPoint('BOTTOMRIGHT',row,'BOTTOM',-80,0)
 function row:Init(initializer)
  self.initCount=self.initCount+1;self.initializer=initializer
  self.Text:SetPoint('LEFT',self,'LEFT',37,0)
  self.Text:SetPoint('RIGHT',self,'CENTER',-85,0)
 end
 function row:Release() self.releaseCount=self.releaseCount+1 end
 return row
end
function assertWide(row)
 local box=row.Checkbox.points.RIGHT
 assert(box and box.relative==row and box.point=='RIGHT' and box.x==-160,
  'checkbox has not moved into the wider column')
 assert(row.Checkbox.points.LEFT==nil,'checkbox retains conflicting old anchor')
 local text=row.Text.points.RIGHT
 assert(text.relative==row.Checkbox and text.point=='LEFT' and text.x==-12,
  'label still has its narrow default width')
 local left=row.Text.points.LEFT
 assert(left.relative==row and left.point=='LEFT' and left.x==37)
 -- Default checkbox width is 30. At a 700px row the new label gets 461px,
 -- instead of 228px. This checks anchor geometry, not native glyph fitting.
 assert(row.width-160-30-12-37>=461)
 local hotspot=row.Tooltip.points.BOTTOMRIGHT
 assert(hotspot.relative==row.Checkbox and hotspot.point=='BOTTOMLEFT' and hotspot.x==0,
  'new label text lacks its native hover and click coverage')
end
function assertDefault(row)
 local box=row.Checkbox.points.LEFT
 assert(box and box.relative==row and box.point=='CENTER' and box.x==-80)
 assert(row.Checkbox.points.RIGHT==nil,'Couchside anchor leaked into shared pool')
 local text=row.Text.points.RIGHT
 assert(text.relative==row and text.point=='CENTER' and text.x==-85)
 local hotspot=row.Tooltip.points.BOTTOMRIGHT
 assert(hotspot.relative==row and hotspot.point=='BOTTOM' and hotspot.x==-80,
  'Couchside hit region leaked into shared pool')
end
'''


def check(name, code):
    vm = LuaRuntime(register_eval=False, register_builtins=False)
    vm.execute(STUB)
    vm.execute('local text=...;assert(loadstring(text))("Couchside",ns)',
               (ROOT / 'Couchside/Settings.lua').read_text())
    vm.execute('login()')
    vm.execute(code)
    print('PASS', name)


check('all Couchside checkbox rows widen their label and checkbox columns', '''
assert(#initializers==3 and #pages==2 and pages[2]=='Gathering')
for _,initializer in ipairs(initializers) do
 local row=newRow(700);initializer:InitFrame(row);assertWide(row)
 assert(row.initCount==1)
end
''')
check('releasing a Couchside row restores the shared template geometry', '''
local row=newRow(700);local initializer=initializers[1]
initializer:InitFrame(row);initializer:Resetter(row);assertDefault(row)
assert(row.releaseCount==1)
''')
check('reused rows stay wide after reinitialization and resizing', '''
local row=newRow(700)
initializers[1]:InitFrame(row);initializers[1]:Resetter(row)
row.width=900
initializers[2]:InitFrame(row);assertWide(row)
initializers[2]:InitFrame(row);assertWide(row)
assert(row.initCount==3)
''')
check('a recycled row returns to the default for unrelated settings', '''
local row=newRow(700)
initializers[1]:InitFrame(row);initializers[1]:Resetter(row)
row:Init({name='Unrelated setting'});assertDefault(row)
local unrelated=newRow(700);unrelated:Init({});assertDefault(unrelated)
''')
check('settings retain names defaults tooltips and value callbacks', '''
local setting=settings.GATHERING_TOOLTIPDIFFICULTY
assert(setting.name=='Show gathering difficulty in tooltips' and setting.default==true)
assert(initializers[2].tooltip=='Difficulty tooltip')
setting.callback(setting,false)
assert(#notifications==1 and notifications[1].page==ns.modules[1])
assert(notifications[1].key=='tooltipDifficulty' and notifications[1].value==false)
''')
check('choice and number options get a dropdown and a slider, not a checkbox', '''
assert(#initializers==3 and #dropdowns==1 and #sliders==1)
local place=dropdowns[1]
assert(place.setting==settings.GATHERING_PLACE and place.setting.varType=='String')
assert(place.setting.default=='auto' and place.tooltip=='Place tooltip')
local choices=place.options()
assert(#choices==2 and choices[1].value=='auto' and choices[2].label=='Left')
local size=sliders[1]
assert(size.setting==settings.GATHERING_SIZE and size.setting.varType=='Number' and size.setting.default==100)
assert(size.options.min==50 and size.options.max==200 and size.options.step==10)
assert(size.options.formatter(120)=='120%')
size.setting.callback(size.setting,150)
assert(notifications[1].key=='size' and notifications[1].value==150)
''')
check('a character option is saved per character and says so', '''
local setting=settings.GATHERING_MINE
assert(setting.db==ns.modules[1].charDB and setting.db~=ns.modules[1].db)
assert(initializers[3].tooltip=='Mine tooltip\\n\\nSaved for this character only.')
assert(settings.GATHERING_TOOLTIPDIFFICULTY.db==ns.modules[1].db)
''')
