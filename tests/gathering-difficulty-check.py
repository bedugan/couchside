"""Classic reference-band boundaries and live display refresh; no exact chance claim."""
from pathlib import Path
import runpy

ROOT = Path(__file__).resolve().parents[1]
legend = runpy.run_path(str(ROOT / 'tests/gathering-legend-check.py'))
make, check = legend['make'], legend['check']

check('native 138 skill sample produces distinct Classic reference bands', r'''
local profile={herb={status='ok',rank=138,maximum=225}}
for name,key in pairs({Peacebloom='gray',Mageroyal='green',Briarthorn='green',Bruiseweed='yellow',Kingsblood='orange',['Purple Lotus']='red'}) do
 assert(ns.ResourceDifficulty.Evaluate(name,profile).key==key,name)
end
assert(ns.ResourceDifficulty.Evaluate('NPC',profile).key=='unknown')
''')
check('explicit exceptional bands and every exact threshold are respected', r'''
local names={'Peacebloom','Mageroyal','Dreamfoil','Copper Vein','Tin Vein','Rich Thorium Vein','Small Obsidian Chunk'}
for _,name in ipairs(names) do
 local entry=ns.ResourceCatalog.Lookup(name);local b=entry.difficulty
 local function key(rank) return ns.ResourceDifficulty.Evaluate(name,{[entry.category]={status='ok',rank=rank,maximum=500}}).key end
 if b.minimum>1 then assert(key(b.minimum-1)=='red') end
 assert(key(b.minimum)=='orange' and key(b.yellow-1)=='orange')
 assert(key(b.yellow)=='yellow' and key(b.green-1)=='yellow')
 assert(key(b.green)=='green' and key(b.gray-1)=='green' and key(b.gray)=='gray')
end
local d=ns.ResourceCatalog.Lookup('Dreamfoil').difficulty
assert(d.minimum==270 and d.yellow==290 and d.green==315 and d.gray==370)
''')
check('cap and missing skill preserve supported reasons without inventing red', r'''
assert(ns.ResourceDifficulty.Evaluate('Kingsblood',{herb={status='ok',rank=150,maximum=150}}).key=='cap')
assert(ns.ResourceDifficulty.Evaluate('Purple Lotus',{herb={status='ok',rank=150,maximum=150}}).key=='red')
assert(ns.ResourceDifficulty.Evaluate('Copper Vein',{ore={status='nil'}}).key=='unknown')
assert(ns.ResourceDifficulty.Evaluate('Incendicite Mineral Vein',{ore={status='ok',rank=150,maximum=150}}).key=='unknown')
''')
check('live skill capture gates client invalid data bonuses and restricted fields', r'''
function GetBuildInfo() return '12.1.0' end
local reads=0;C_SkillInfo={GetSkillLineInfoByID=function() reads=reads+1 end}
assert(ns.ResourceDifficulty.Capture().herb.status=='unsupported-client' and reads==0)
function GetBuildInfo() return '1.60.1' end
C_SkillInfo.GetSkillLineInfoByID=function(id) return {skillID=id,rank=138,maxRank=225,modifier=5,tempPoints=0} end
assert(ns.ResourceDifficulty.Capture().herb.status=='unverified-bonus')
function issecretvalue(v) return type(v)=='table' and v.secret end
C_SkillInfo.GetSkillLineInfoByID=function(id) return {skillID=id,rank={secret=true},maxRank=225,modifier=0,tempPoints=0} end
assert(ns.ResourceDifficulty.Capture().herb.status=='invalid')
C_SkillInfo.GetSkillLineInfoByID=function() error('unavailable') end
assert(ns.ResourceDifficulty.Capture().herb.status=='error')
''')
check('display uses live skill not saved reports and reused tints reset to neutral', r'''
function GetBuildInfo() return '1.60.1' end
local rank=138
C_SkillInfo={GetSkillLineInfoByID=function(id) if rank then return {skillID=id,rank=rank,maxRank=225,modifier=0,tempPoints=0} end end}
CouchsideMinimapDB.skillReports={{skills={Herbalism={result={value={rank=300}}}}}}
local d=ns.NearbyList.Show(scan({{text='Mageroyal',x=.8,y=.5}}))
local badge=markers()[1];assert(badge.symbol.tint[1]<1 and d.difficultyModel=='classic-reference-v1')
local low=false;for _,f in ipairs(frames) do if f.text=='Low' and f.shown then low=true end end;assert(low)
rank=nil;ns.NearbyList.Show(scan({{text='Mageroyal',x=.8,y=.5}}))
assert(markers()[1]==badge and badge.symbol.tint[1]==1 and badge.symbol.tint[2]==1 and badge.symbol.tint[3]==1)
''')
check('skill refresh updates existing snapshot without scan work or extending expiry', r'''
function GetBuildInfo() return '1.60.1' end
local rank,reads=149,0
C_SkillInfo={GetSkillLineInfoByID=function(id) reads=reads+1;return {skillID=id,rank=rank,maxRank=225,modifier=0,tempPoints=0} end}
local s=scan({{text='Mageroyal',x=.8,y=.5}});ns.NearbyList.Show(s)
local badge=markers()[1];assert(ns.NearbyList.Remaining()==60 and reads==2)
rank=150;tick(1.1)
assert(markers()[1]==badge and math.abs(ns.NearbyList.Remaining()-58.9)<.001 and reads==4 and nativeCalls==0)
local gray=false;for _,f in ipairs(frames) do if f.text=='No gain' and f.shown then gray=true end end;assert(gray)
ns.NearbyList.Clear('test');tick(2);assert(reads==4)
''')
check('difficulty labels do not leak to unknown rows or legacy display', r'''
function GetBuildInfo() return '1.60.1' end
C_SkillInfo={GetSkillLineInfoByID=function(id) return {skillID=id,rank=138,maxRank=225,modifier=0,tempPoints=0} end}
ns.NearbyList.Show(scan({{text='Mageroyal',x=.8,y=.5}}))
local function labels() local n=0;for _,f in ipairs(frames) do if f.text=='Low' and f.shown then n=n+1 end end;return n end
assert(labels()==1);ns.NearbyList.Show(scan({{text='NPC',x=.8,y=.5}}));assert(labels()==0)
legend=false;ns.NearbyList.Show(scan({{text='Mageroyal',x=.8,y=.5}}));assert(labels()==0)
''')
check('catalog band copies and ooze aliases preserve stable shared metadata', r'''
local first=ns.ResourceCatalog.Lookup('Mageroyal');first.difficulty.gray=0
assert(ns.ResourceCatalog.Lookup('Mageroyal').difficulty.gray==150)
local normal=ns.ResourceCatalog.Lookup('Silver Vein');local ooze=ns.ResourceCatalog.Lookup('Ooze Covered Silver Vein')
assert(normal.stamp==ooze.stamp and normal.difficulty.gray==ooze.difficulty.gray)
''')

vm = make()
catalog = vm.globals().ns.ResourceCatalog
import re
names = re.findall(r'names = \{ "([^"]+)"', (ROOT / 'Couchside_Gathering/ResourceCatalog.lua').read_text())
bands = [catalog.Lookup(name).difficulty for name in names]
assert sum(band is not None for band in bands) == 41
for band in bands:
    if band is not None:
        assert band.minimum < band.yellow < band.green < band.gray
print('PASS 41 explicit reference-band tuples are ordered and three special minerals remain unknown')
print('8 difficulty checks plus catalog data coverage passed; native appearance remains pending')
