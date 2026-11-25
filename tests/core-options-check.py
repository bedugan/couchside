"""Check Couchside's option kinds, saved-value validation and /cs option parsing in Lua 5.1.

Loads the real Couchside/Core.lua with minimal stubs. The settings window is covered by
settings-window-check.py; native behavior still requires an in-game check.
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
 {key='mine',default=false,scope='character',name='Mine',tooltip='Mine tooltip'},
}}}})
mod=moduleNS
'''


def runtime(saved, char='{}'):
    vm = LuaRuntime(register_eval=False, register_builtins=False)
    vm.execute(STUB)
    vm.execute('ns={}')
    vm.execute('local text=...;assert(loadstring(text))("Couchside",ns)',
               (ROOT / 'Couchside/Core.lua').read_text())
    vm.execute(MODULE)
    vm.execute('CouchsideDB={modules={test=' + saved + '}}')
    vm.execute('CouchsideCharDB=' + char)
    vm.execute('loaded.Couchside();loaded.Couchside_Test()')
    return vm


def check(name, saved, code, char='{}'):
    runtime(saved, char).execute(code)
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
check('a character option is saved per character, not account-wide', '{}', '''
assert(mod.IsEnabled('mine')==false)
SlashCmdList.COUCHSIDE('option test.mine on')
assert(mod.IsEnabled('mine')==true and CouchsideCharDB.modules.test.mine==true)
assert(CouchsideDB.modules.test.mine==nil)
assert(printed[#printed]:find('(this character)',1,true))
''')
check('an account value left from before an option became per character is dropped', "{mine=true}", '''
assert(mod.IsEnabled('mine')==false and CouchsideCharDB.modules.test.mine==nil)
assert(CouchsideDB.modules.test.mine==nil)
''')
check('a per-character value left from before an option became account-wide is dropped', '{}', '''
assert(CouchsideCharDB.modules.test.flag==nil)
''', char="{modules={test={flag=false}}}")
check('a character that already chose keeps its choice', "{mine=true}", '''
assert(mod.IsEnabled('mine')==false)
''', char="{modules={test={mine=false}}}")
check('modules get their own per-character data table', '{}', '''
local data=mod.CharacterData();data.x=1
assert(mod.CharacterData().x==1 and CouchsideCharDB.data.test.x==1)
''')
