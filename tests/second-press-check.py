"""Check the second-press command and class defaults in Lua 5.1 with stubbed game APIs.

Covers command parsing, known-spell filtering, fallback to the class default and the saved report.
Spell IDs, casting and secure bindings still require an in-game check.
"""
from pathlib import Path

from lupa.lua51 import LuaRuntime

ROOT = Path(__file__).resolve().parents[1]
STUB = r'''
printed={};cmds={}
ns={RegisterCommand=function(name,_,run) cmds[name]=run end,
 Print=function(fmt,...) printed[#printed+1]=fmt:format(...) end, Debug=function() end}
known={[331]=true}
function UnitClass() return 'Shaman','SHAMAN' end
function UnitLevel() return 20 end
function UnitName() return 'Burn' end
function date() return 'now' end
C_SpellBook={IsSpellKnownOrInSpellBook=function(id) return known[id]==true end}
local spells={[331]='Healing Wave',[8004]='Lesser Healing Wave',[526]='Cure Poison'}
C_Spell={GetSpellInfo=function(x)
 for id,name in pairs(spells) do
  if x==id or (type(x)=='string' and x:lower()==name:lower()) then return {name=name,spellID=id} end
 end
end}
function GetMacroInfo(i) if i==130 then return 'Heal Me' end end
function last() return printed[#printed-2] end
'''


def check(name, code):
    vm = LuaRuntime(register_eval=False, register_builtins=False)
    vm.execute(STUB)
    vm.execute('local text=...;assert(loadstring(text))("Couchside_Controller",ns)',
               (ROOT / 'Couchside_Controller/SecondPress.lua').read_text())
    vm.execute(code)
    print('PASS', name)


check('the class default is the first known heal and only known spells are offered', '''
cmds.secondpress('')
assert(last()=='Second press: spell Healing Wave (class default).')
assert(printed[#printed-1]=='Heals you can choose: Healing Wave (331).')
assert(printed[#printed]=='Dispels you can choose: none known yet.')
known[8004]=true;cmds.secondpress('')
assert(last()=='Second press: spell Lesser Healing Wave (class default).')
''')
check('a chosen spell must be known and is kept by ID', '''
cmds.secondpress('spell lesser healing wave')
assert(printed[1]:find('No known spell',1,true))
cmds.secondpress('spell healing wave')
assert(last()=='Second press: spell Healing Wave (chosen spell).')
assert(CouchsideControllerDB.secondPress.spellID==331)
''')
check('a chosen spell unknown to this character falls back to the class default', '''
known[8004]=true
CouchsideControllerDB={secondPress={mode='spell',spell='Cure Poison',spellID=526}}
cmds.secondpress('')
assert(last()=='Second press: spell Lesser Healing Wave (Cure Poison unknown here, class default).')
''')
check('macros match in any case, off and bad input behave', '''
cmds.secondpress('macro heal me')
assert(last()=='Second press: macro Heal Me (chosen macro).')
cmds.secondpress('macro nope');assert(printed[#printed]=='No macro named "nope".')
cmds.secondpress('off');assert(last()=='Second press: nothing (off).')
cmds.secondpress('bogus');assert(printed[#printed]:find('Usage',1,true))
''')
check('each character keeps its own saved report with the ID checks', '''
cmds.secondpress('')
local saved=CouchsideControllerReportDB.secondPress.Burn
assert(#saved.lines==4 and saved.lines[4]:find('331 Healing Wave known',1,true))
''')
