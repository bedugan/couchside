"""Catalog coverage, stable assignments and packaged stamp assets."""
import hashlib
from pathlib import Path
import runpy
import struct

ROOT = Path(__file__).resolve().parents[1]
legend = runpy.run_path(str(ROOT / 'tests/gathering-legend-check.py'))
check = legend['check']

check('Purple Lotus receives the PL resource stamp in the real display model', r'''
local model=ns.ResourceLegend.Build(scan({{text='Purple Lotus',x=.75,y=.5}}))
assert(#model.marks==1 and model.rows[1].kind=='resource-candidate')
assert(model.marks[1].symbol=='stamp-pl' and model.marks[1].minimapSize==16)
ns.NearbyList.Show(scan({{text='Purple Lotus',x=.75,y=.5}}))
assert(#markers()==1 and markers()[1].symbol.texture:find('stamp%-pl'))
''')
check('all original seven herbs use explicit stable letter stamps', r'''
local expected={Peacebloom='PB',Silverleaf='SL',Earthroot='ER',Mageroyal='MR',Briarthorn='BT',Bruiseweed='BW',Kingsblood='KB'}
for name,code in pairs(expected) do
 local entry=ns.ResourceCatalog.Lookup(name)
 assert(entry.stamp==code and entry.minimapSize==16)
end
''')
check('resource stamps survive changed scan order and repeat locations', r'''
local a=ns.ResourceLegend.Build(scan({{text='Purple Lotus',x=.1,y=.2},{text='Copper Vein',x=.8,y=.2}}))
local b=ns.ResourceLegend.Build(scan({{text='Copper Vein',x=.6,y=.4},{text='Purple Lotus',x=.7,y=.2},{text='Purple Lotus',x=.8,y=.2}}))
assert(a.rows[1].symbol==b.rows[1].symbol and a.rows[2].symbol==b.rows[2].symbol)
assert(b.marks[2].symbol=='stamp-pl' and b.marks[3].symbol=='stamp-pl')
''')
check('ooze variants share a mineral type but retain their full node labels', r'''
local normal=ns.ResourceCatalog.Lookup('Silver Vein')
local ooze=ns.ResourceCatalog.Lookup('Ooze Covered Silver Vein')
assert(normal.key==ooze.key and normal.stamp=='SV' and ooze.stamp=='SV')
local model=ns.ResourceLegend.Build(scan({{text='Silver Vein',x=.2,y=.5},{text='Ooze Covered Silver Vein',x=.8,y=.5}}))
assert(#model.rows==2 and #model.marks==2 and model.rows[1].text~=model.rows[2].text)
''')
check('herbs ore and unknowns group separately without assigning NPC roles', r'''
local d=ns.NearbyList.Show(scan({{text='Copper Vein',x=.2,y=.5},{text='Purple Lotus',x=.8,y=.5},{text='Jorn Skyseer',x=.5,y=.5}}))
assert(d.status=='shown' and #markers()==2)
local text={};for _,frame in ipairs(frames) do if frame.text and frame.shown then text[frame.text]=true end end
assert(text.Herbs and text.Ore and text['Other tracking'])
assert(not ns.ResourceCatalog.Lookup('Jorn Skyseer') and not ns.ResourceCatalog.Lookup('Swiftthistle'))
''')
check('new mixed resource and unknown entries preserve names and withhold marks', r'''
local filter={text='Purple Lotus / NPC',entries={'Purple Lotus','NPC'},removed={}}
local model=ns.ResourceLegend.Build(scan({{text=filter.text,x=.5,y=.5}},{raw=filter}))
assert(#model.rows==2 and #model.marks==0 and model.withheldRegions==1)
''')
check('catalog lookups cannot mutate later assignments', r'''
local entry=ns.ResourceCatalog.Lookup('Purple Lotus');entry.stamp='XX';entry.symbol='bad'
assert(ns.ResourceCatalog.Lookup('Purple Lotus').stamp=='PL' and ns.ResourceCatalog.Lookup('Purple Lotus').symbol=='stamp-pl')
assert(ns.ResourceCatalog.Lookup('Purple Lotus').observed and not ns.ResourceCatalog.Lookup('Dreamfoil').observed)
''')

# This is the required name-coverage contract, independently listed from the Lua table.
HERBS = "Peacebloom|Silverleaf|Earthroot|Mageroyal|Briarthorn|Stranglekelp|Bruiseweed|Wild Steelbloom|Grave Moss|Kingsblood|Liferoot|Fadeleaf|Goldthorn|Khadgar's Whisker|Wintersbite|Firebloom|Purple Lotus|Arthas' Tears|Sungrass|Blindweed|Ghost Mushroom|Gromsblood|Golden Sansam|Dreamfoil|Mountain Silversage|Plaguebloom|Icecap|Black Lotus".split('|')
ORES = "Copper Vein|Tin Vein|Silver Vein|Ooze Covered Silver Vein|Iron Deposit|Gold Vein|Ooze Covered Gold Vein|Mithril Deposit|Ooze Covered Mithril Deposit|Truesilver Deposit|Ooze Covered Truesilver Deposit|Dark Iron Deposit|Small Thorium Vein|Ooze Covered Thorium Vein|Rich Thorium Vein|Ooze Covered Rich Thorium Vein|Hakkari Thorium Vein|Incendicite Mineral Vein|Indurium Mineral Vein|Lesser Bloodstone Deposit|Small Obsidian Chunk|Large Obsidian Chunk".split('|')
vm = legend['make']()
lookup = vm.globals().ns.ResourceCatalog.Lookup
symbols, keys = {}, set()
for category, names in (('herb', HERBS), ('ore', ORES)):
    for name in names:
        entry = lookup(name)
        assert entry and entry.category == category, name
        assert entry.key.startswith(category + ':')
        if entry.key in symbols:
            assert symbols[entry.key] == entry.symbol, name
        symbols[entry.key] = entry.symbol
        keys.add(entry.key)
assert len(keys) == 44 and len(set(symbols.values())) == 44
assert vm.globals().ns.ResourceCatalog.nameCount == len(HERBS) + len(ORES) == 50
print('PASS all 28 herb and 22 mineral labels resolve into 44 distinct stamped types')

assets = {path.stem: path for path in (ROOT / 'Couchside_Gathering/Media').glob('*.tga')}
assert set(assets) == set(symbols.values()), 'Missing or retired symbol assets'
hashes = set()
for path in assets.values():
    data = path.read_bytes()
    header = struct.unpack('<BBBHHBHHHHBB', data[:18])
    assert header[2] == 2 and header[8:12] == (64, 64, 32, 0x28), path.name
    assert len(data) == 18 + 64 * 64 * 4
    assert max(data[21::4]) == 255 and min(data[21::4]) == 0
    hashes.add(hashlib.sha256(data).digest())
assert len(hashes) == 44, 'Blank or duplicate resource stamps'
print('PASS every distinct stamp has its own complete alpha TGA asset and retired shapes are absent')
