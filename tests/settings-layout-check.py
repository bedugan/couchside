"""Check Couchside's settings-row geometry and pooled-row cleanup in Lua 5.1.

The fixture follows Blizzard's InitFrame/Resetter lifecycle. Native font fitting,
settings navigation and controller behavior still require an in-game check.
"""
from pathlib import Path

from lupa.lua51 import LuaRuntime

ROOT = Path(__file__).resolve().parents[1]
STUB = r'''
initializers={};settings={};pages={};notifications={};debugMessages={}
ns={base={sections={{title='General',options={
 {key='debug',name='Enable debug output',default=false,tooltip='Debug tooltip'},
}}},variablePrefix='BASE_',db={}},modules={
 {title='Minimap',sections={{title='Nearby tracking',options={
  {key='resourceLegend',name='Resource letter stamps and other tracking',default=false,tooltip='Resource tooltip'},
 }}},variablePrefix='MINIMAP_',db={}},
}}
ns.NotifyOptionChanged=function(page,key,value)
 notifications[#notifications+1]={page=page,key=key,value=value}
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
Settings={VarType={Boolean='Boolean'},RegisterVerticalLayoutCategory=category,
 RegisterVerticalLayoutSubcategory=function(_,title) return category(title) end,
 RegisterAddOnCategory=function() end,
 RegisterAddOnSetting=function(_,variable,key,db,_,name,default)
  local s={key=key,db=db,name=name,default=default}
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
assert(#initializers==2 and #pages==2 and pages[2]=='Minimap')
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
local setting=settings.MINIMAP_RESOURCELEGEND
assert(setting.name=='Resource letter stamps and other tracking' and setting.default==false)
assert(initializers[2].tooltip=='Resource tooltip')
setting.callback(setting,true)
assert(#notifications==1 and notifications[1].page==ns.modules[1])
assert(notifications[1].key=='resourceLegend' and notifications[1].value==true)
''')
