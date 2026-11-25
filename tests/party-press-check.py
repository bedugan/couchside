"""Check the party press secure snippets' logic in Lua 5.1.

Runs PartyPress.lua's restricted snippets as plain Lua against stub frames. This checks press
counting and the type each press gets, not the restricted environment, bindings or casting, which
require an in-game check.
"""
from pathlib import Path

from lupa.lua51 import LuaRuntime

ROOT = Path(__file__).resolve().parents[1]
SOURCE = (ROOT / 'Couchside_Controller/PartyPress.lua').read_text()
HARNESS = r'''
local source=...
local function snippet(name) return source:match('local '..name..' = %[%[(.-)%]%]') end
helpable={}
env=setmetatable({SecureCmdOptionParse=function(text)
 return helpable[text:match('@([^,]+)')]==false and '0' or '1'
end},{__index=_G})
local function compile(name,args)
 local fn=assert(loadstring('local '..args..' = ...\n'..snippet(name)));setfenv(fn,env);return fn
end
click=compile('CLICK_SNIPPET','self, button, down, control')
hide=compile('HIDE_SNIPPET','self')
logs={}
control={GetAttribute=function(_,key) return key=='couchside-log' end,
 CallMethod=function(_,_,text) logs[#logs+1]=text end}
function button(unit,cast)
 local attributes={unit=unit,['couchside-cast']=cast}
 return {attributes=attributes,GetAttribute=function(_,key) return attributes[key] end,
  SetAttribute=function(_,key,value) attributes[key]=value end}
end
function press(b) click(b,'LeftButton',true,control);return b.attributes.type end
function release() hide({ClearBindings=function() end,GetAttribute=function() return false end}) end
'''


def check(name, code):
    vm = LuaRuntime(register_eval=False, register_builtins=False)
    vm.execute(HARNESS, SOURCE)
    vm.execute(code)
    print('PASS', name)


check('the first press targets and later presses in the hold cast', '''
local up=button('party1','spell')
assert(press(up)=='target' and press(up)=='spell' and press(up)=='spell')
assert(logs[1]=='press party1 #1: target' and logs[3]=='press party1 #3: spell')
''')
check('another member resets the count', '''
local up,a=button('party1','macro'),button('player','macro')
press(up);press(up)
assert(press(a)=='target' and press(up)=='target' and press(up)=='macro')
''')
check('releasing the button resets the count', '''
local up=button('party1','spell')
press(up);release()
assert(press(up)=='target')
''')
check('without an action every press only targets', '''
local up=button('party1',nil)
assert(press(up)=='target' and press(up)=='target' and press(up)=='target')
''')
check('a member who cannot be helped gets no cast', '''
local up=button('party1','spell')
helpable.party1=false
assert(press(up)=='target' and press(up)=='target')
assert(logs[2]=='press party1 #2: target (can\\'t help party1)')
helpable.party1=true
assert(press(up)=='spell')
''')
