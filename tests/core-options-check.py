"""Check Couchside's option kinds, saved-value validation and /cs option parsing in Lua 5.1.

Loads the real Couchside/Core.lua with minimal stubs. The settings panel itself is covered by
settings-layout-check.py; native behavior still requires an in-game check.
"""
from pathlib import Path

from lupa.lua51 import LuaRuntime

ROOT = Path(__file__).resolve().parents[1]
STUB = r'''
printed={};loaded={}
function print(text) printed[#printed+1]=text end
EventUtil={ContinueOnAddOnLoaded=function(name,fn) loaded[name]=fn end}
C_AddOns={GetAddOnMetadata=function() return '1.0' end}
Settings={};SlashCmdList={}
'''
MODULE = r'''
local moduleNS={}
Couchside.RegisterModule(moduleNS,{addon='Couchside_Test',key='test',title='Test',sections={{title='Section',options={
 {key='flag',default=true,name='Flag',tooltip='Flag tooltip'},
 {key='place',default='auto',name='Place',tooltip='Place tooltip',
  choices={{value='auto',label='Automatic'},{value='left',label='Left'}}},
 {key='size',default=100,min=50,max=205,step=10,format='%d%%',name='Size',tooltip='Size tooltip'},
}}}})
mod=moduleNS
'''


def runtime(saved):
    vm = LuaRuntime(register_eval=False, register_builtins=False)
    vm.execute(STUB)
    vm.execute('ns={}')
    vm.execute('local text=...;assert(loadstring(text))("Couchside",ns)',
               (ROOT / 'Couchside/Core.lua').read_text())
    vm.execute(MODULE)
    vm.execute('CouchsideDB={modules={test=' + saved + '}}')
    vm.execute('loaded.Couchside();loaded.Couchside_Test()')
    return vm


def check(name, saved, code):
    runtime(saved).execute(code)
    print('PASS', name)


check('defaults apply with nothing saved', '{}', '''
assert(mod.IsEnabled('flag')==true and mod.GetOption('place')=='auto' and mod.GetOption('size')==100)
''')
check('saved values the option no longer accepts fall back and are cleared', "{place='middle',size=999,flag='yes'}", '''
assert(mod.GetOption('place')=='auto' and mod.GetOption('size')==100 and mod.IsEnabled('flag')==true)
assert(CouchsideDB.modules.test.place==nil and CouchsideDB.modules.test.size==nil and CouchsideDB.modules.test.flag==nil)
''')
check('valid saved values are kept', "{place='left',size=150,flag=false}", '''
assert(mod.GetOption('place')=='left' and mod.GetOption('size')==150 and mod.IsEnabled('flag')==false)
''')
check('/cs option sets each kind and rejects values it does not accept', '{}', '''
SlashCmdList.COUCHSIDE('option test.place left');assert(mod.GetOption('place')=='left')
SlashCmdList.COUCHSIDE('option test.place middle');assert(mod.GetOption('place')=='left')
assert(printed[#printed]:find('auto|left',1,true))
SlashCmdList.COUCHSIDE('option test.size 120%');assert(mod.GetOption('size')==120)
SlashCmdList.COUCHSIDE('option test.size 124');assert(mod.GetOption('size')==120)
SlashCmdList.COUCHSIDE('option test.size 999');assert(mod.GetOption('size')==120)
SlashCmdList.COUCHSIDE('option test.flag off');assert(mod.IsEnabled('flag')==false)
''')
check('number values that round past max are clamped', '{}', '''
-- 205 is 15.5 steps from 50, which rounds to 210.
SlashCmdList.COUCHSIDE('option test.size 205');assert(mod.GetOption('size')==205)
''')
check('uppercase choice values are refused at registration', '{}', '''
local ok=pcall(Couchside.RegisterModule,{},{addon='Bad',key='bad',title='Bad',sections={{title='S',options={
 {key='c',default='A',name='C',tooltip='C',choices={{value='A',label='A'}}}}}}})
assert(not ok)
''')
