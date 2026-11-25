"""Check the second-press command and class defaults in Lua 5.1 with stubbed game APIs.

Covers command parsing, known-spell filtering, fallback to the class default and the saved report.
Spell IDs, casting and secure bindings still require an in-game check.
"""
from pathlib import Path

from lupa.lua51 import LuaRuntime

ROOT = Path(__file__).resolve().parents[1]
STUB = r'''
printed={};cmds={}
charData={}
ns={RegisterCommand=function(name,_,run) cmds[name]=run end, CharacterData=function() return charData end,
 Print=function(fmt,...) printed[#printed+1]=fmt:format(...) end, Debug=function() end}
known={[331]=true}
function UnitClass() return class,class end
function UnitLevel() return 20 end
function UnitName() return 'Burn' end
function date() return 'now' end
function InCombatLockdown() return false end
C_SpellBook={IsSpellKnownOrInSpellBook=function(id) return known[id]==true end}
local spells={[331]='Healing Wave',[8004]='Lesser Healing Wave',[526]='Cure Poison',[136]='Mend Pet',[755]='Health Funnel'}
class='SHAMAN'
C_Spell={GetSpellInfo=function(x)
 for id,name in pairs(spells) do
  if x==id or (type(x)=='string' and x:lower()==name:lower()) then return {name=name,spellID=id} end
 end
end}
function GetMacroInfo(i) if i==130 then return 'Heal Me' end end
function last() return printed[#printed-2] end
Couchside={RegisterPanelPage=function(spec) panelPage=spec end}
-- The window page's list entries, as the settings window would build them.
function entries()
 local list
 panelPage.build({Header=function() end,List=function(_,_,fn) list=fn end})
 return list()
end
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
assert(printed[#printed-1]=='Class actions you can choose: Healing Wave (331).')
assert(printed[#printed]=='Dispels you can choose: none known yet.')
known[8004]=true;cmds.secondpress('')
assert(last()=='Second press: spell Lesser Healing Wave (class default).')
''')
check('a chosen spell must be known and is kept by ID', '''
cmds.secondpress('spell lesser healing wave')
assert(printed[1]:find('No known spell',1,true))
cmds.secondpress('spell healing wave')
assert(last()=='Second press: spell Healing Wave (chosen spell).')
assert(charData.secondPress.spellID==331)
''')
check('a chosen spell unknown to this character falls back to the class default', '''
known[8004]=true
charData.secondPress={mode='spell',spell='Cure Poison',spellID=526}
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
check('pet care is a class default for the pet only', '''
class='HUNTER';known[136]=true
cmds.secondpress('')
assert(last()=='Second press: spell Mend Pet, pet only (class default).')
assert(select(4,ns.SecondPressAction())==true)
class='WARLOCK';known[755]=true;cmds.secondpress('')
assert(last()=='Second press: spell Health Funnel, pet only (class default).')
''')
check('a chosen pet spell is pet only, a heal is not', '''
known[136]=true
cmds.secondpress('spell mend pet');assert(select(4,ns.SecondPressAction())==true)
cmds.secondpress('spell healing wave');assert(select(4,ns.SecondPressAction())==false)
''')
check('the window lists the default, known spells, a macro and nothing, and choosing saves', '''
known[8004]=true;known[526]=true
local list=entries()
assert(list[1].text=='Class default: Lesser Healing Wave' and list[1].selected)
assert(list[2].text=='Healing Wave' and not list[2].selected)
assert(list[3].text=='Cure Poison')
assert(list[4].text=='Macro: Heal Me' and list[5].text=='Nothing')
list[2].onClick();assert(charData.secondPress.mode=='spell' and charData.secondPress.spellID==331)
list=entries();assert(list[2].selected and not list[1].selected)
list[4].onClick();assert(charData.secondPress.macro=='Heal Me');assert(entries()[4].selected)
list[5].onClick();assert(charData.secondPress.mode=='off' and entries()[5].selected)
assert(panelPage.sections[1]=='Second press' and panelPage.module=='controller')
''')
check('pet care says it is for the pet only', '''
class='HUNTER';known[136]=true
assert(entries()[1].description:find("pet's button",1,true))
''')
