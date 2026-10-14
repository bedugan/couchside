"""Saved-text classification and report lifecycle; no native identity claim."""
from pathlib import Path
from lupa.lua51 import LuaRuntime

ROOT = Path(__file__).resolve().parents[1]
FILES = ('ScanLog.lua', 'QuestTextFilter.lua', 'ResourceCatalog.lua', 'ResourceClassifier.lua')


def make(setup=''):
    vm = LuaRuntime()
    vm.execute('''
logs={};commands={};nativeCalls=0
ns={version='test',Print=function(fmt,...) table.insert(logs,string.format(fmt,...)) end,
 Debug=function() end,RegisterCommand=function(name,_,fn) commands[name]=fn end,OnReady=function(fn) fn() end}
snapshot={available=true,titles={['Centaur Bracers']=855},objectives={['Centaur Bracers']=855},warnings={}}
''')
    vm.execute(setup)
    for name in FILES:
        vm.execute('assert(loadstring(...))("Couchside_Gathering",ns)', (ROOT / 'Couchside_Gathering' / name).read_text())
    return vm


def check(name, code, setup=''):
    make(setup).execute(code)
    print('PASS', name)


check('Purple Lotus and ore use the same static catalog as the display', r'''
for _,name in ipairs({'Peacebloom','Silverleaf','Earthroot','Mageroyal','Briarthorn','Kingsblood','Purple Lotus'}) do
 local r=ns.ResourceClassifier.Classify({entries={name},removed={}},snapshot,ns.ResourceCatalog.Lookup)
 assert(r[1].kind=='resource-candidate' and r[1].category=='herb' and r[1].symbol)
end
local r=ns.ResourceClassifier.Classify({entries={'Copper Vein','NPC'},removed={}},snapshot,ns.ResourceCatalog.Lookup)
assert(r[1].category=='ore' and r[2].kind=='unknown')
''')
check('mixed tooltip preserves resource unknown and excluded quest evidence', r'''
local f=ns.QuestTextFilter.Filter({lines={{leftText='Peacebloom\nSpirit Fingies\nCentaur Bracers|cffffffff\n- 0/15 Centaur Bracers|r'}}},snapshot)
assert(f.text=='Peacebloom / Spirit Fingies')
local r=ns.ResourceClassifier.Classify(f,snapshot,ns.ResourceCatalog.Lookup)
assert(#r==4 and r[1].kind=='resource-candidate' and r[2].kind=='unknown' and r[3].kind=='quest-text' and not r[3].retained and r[4].kind=='quest-text')
''')
check('resource quest-title collision is explicit despite exclusion', r'''
snapshot.titles['Purple Lotus']=1
local f=ns.QuestTextFilter.Filter({lines={{leftText='Purple Lotus'}}},snapshot)
local r=ns.ResourceClassifier.Classify(f,snapshot,ns.ResourceCatalog.Lookup)
assert(f.text=='' and #r==1 and r[1].kind=='ambiguous' and r[1].questID==1 and not r[1].retained)
''')
check('older joined text remains whole and unknown', r'''
local r=ns.ResourceClassifier.Classify({text='Peacebloom / NPC',removed={}},snapshot,ns.ResourceCatalog.Lookup)
assert(#r==1 and r[1].kind=='unknown')
''')
check('lookup errors and ambiguous matches never become resource icons', r'''
local filter={entries={'Same name'},removed={}}
local r=ns.ResourceClassifier.Classify(filter,snapshot,function() return nil,'unavailable' end)
assert(r[1].kind=='unknown' and r[1].catalogError=='unavailable')
r=ns.ResourceClassifier.Classify(filter,snapshot,function() return {ambiguous=true} end)
assert(r[1].kind=='ambiguous' and not r[1].resourceKey)
''')
SEED = r'''
CouchsideGatheringScanDB.scans={{id=23,build='70338',pointCount=1,hitCount=1,questText=snapshot,
regions={{text='Purple Lotus'}},tipsByText={['Purple Lotus\nCentaur Bracers']={lines={{leftText='Purple Lotus\nCentaur Bracers'}}}}}}
'''
check('report saves a separate verdict without changing raw scan or native state', SEED + r'''
local old=CouchsideGatheringScanDB.scans[1]
Minimap={UpdateMouseoverAtPoint=function() nativeCalls=nativeCalls+1 end}
commands.classify('')
assert(CouchsideGatheringScanDB.scans[1]==old and old.tipsByText['Purple Lotus\nCentaur Bracers'].lines[1].leftText=='Purple Lotus\nCentaur Bracers')
local report=CouchsideGatheringScanDB.classificationReport
assert(report.scanID==23 and report.counts['resource-candidate']==1 and report.counts['quest-text']==1 and nativeCalls==0)
''')
check('missing saved quest evidence remains explicit', r'''
CouchsideGatheringScanDB.scans={{id=2,build='70338',regions={{text='Mageroyal'}}}}
commands.classify('');assert(table.concat(logs,'\n'):find('Saved quest snapshot: false'))
''')
check('report caches each cleaned name once', SEED + r'''
CouchsideGatheringScanDB.scans[1].tipsByText['Purple Lotus\nOther']={lines={{leftText='Purple Lotus\nOther'}}}
local original=ns.ResourceCatalog.Lookup;local calls={}
ns.ResourceCatalog.Lookup=function(name) calls[name]=(calls[name] or 0)+1;return original(name) end
commands.classify('');assert(calls['Purple Lotus']==1)
''')
check('selection compatibility alias and invalid input stay bounded', SEED + r'''
commands.classify('23');assert(table.concat(logs,'\n'):find('saved scan 23'))
local old=CouchsideGatheringScanDB.classificationReport
logs={};commands.classify('99');assert(#logs==1 and logs[1]:find('No matching'))
logs={};commands.classify('library');assert(#logs==1 and logs[1]:find('Usage:'))
assert(CouchsideGatheringScanDB.classificationReport==old)
commands.classify('prototype 23');assert(CouchsideGatheringScanDB.classificationReport.scanID==23)
''')
check('withdrawn provider cannot be called and loaded history is retired', SEED + r'''
GatherMate2={GetIDForNode=function() error('withdrawn provider called') end}
assert(not ns.ResourceClassifier.LibraryLookup and not ns.ResourceClassifier.ObservedLookup and not ns.SaveProviderReport)
commands.classify('');assert(CouchsideGatheringScanDB.classificationReport)
assert(not CouchsideGatheringScanDB.providerReports and not CouchsideGatheringScanDB.nextProviderReportID)
''', "CouchsideGatheringScanDB={version=1,nextID=1,scans={},providerReports={{id=1}},nextProviderReportID=2}")
check('latest report caps detail preserves counts and is cleared with the log', r'''
local tips={};for i=1,55 do tips['NPC '..i]={lines={{leftText='NPC '..i}}} end
CouchsideGatheringScanDB.scans={{id=1,build='70338',pointCount=55,hitCount=55,questText=snapshot,regions={},tipsByText=tips}}
commands.classify('');local r=CouchsideGatheringScanDB.classificationReport
assert(r.entriesTruncated and #r.entries==40 and r.totalEntries==55 and r.counts.unknown==55)
commands.classify('');assert(CouchsideGatheringScanDB.classificationReport~=r)
commands.log('');assert(table.concat(logs,'\n'):find('Latest classification report: scan 1'))
commands.log('clear');assert(#CouchsideGatheringScanDB.scans==0 and not CouchsideGatheringScanDB.classificationReport)
''')
check('texture atlas and named-color cleanup leave original evidence intact', r'''
local raw='|cnGREEN_FONT_COLOR:|A:atlas:16:16|a|Tarrow:16|tPurple Lotus|r\n|A:quest:16:16|aCentaur Bracers'
local data={lines={{leftText=raw}}}
local f=ns.QuestTextFilter.Filter(data,snapshot)
assert(f.text=='Purple Lotus' and #f.removed==1 and data.lines[1].leftText==raw)
local r=ns.ResourceClassifier.Classify(f,snapshot,ns.ResourceCatalog.Lookup)
assert(r[1].symbol=='stamp-pl' and r[2].kind=='quest-text')
assert(ns.QuestTextFilter.Filter({lines={{leftText='|AunfinishedEarthroot'}}},snapshot).text=='|AunfinishedEarthroot')
''')
print('12 static classifier checks passed')
