// Development-only adapter. Upstream readers remain unchanged.
const fs = require('node:fs');
const fsp = fs.promises;
const path = require('node:path');
const Module = require('node:module');
const crypto = require('node:crypto');
const [workDirectory, installDirectory] = process.argv.slice(2);
if (!workDirectory || !installDirectory) throw new Error('Usage: node tools/check-client-tables.cjs <prepared-work-directory> <WoW-install-directory>');
const root = fs.realpathSync(workDirectory);
const installRoot = fs.realpathSync(installDirectory);
if (root === installRoot || root.startsWith(installRoot + path.sep)) throw new Error('Work directory must be outside the WoW installation');
const sourceManifest = JSON.parse(fs.readFileSync(path.join(root, 'source-manifest.json'), 'utf8'));
for (const [name, expected] of Object.entries(sourceManifest.files)) {
  const actual = crypto.createHash('sha256').update(fs.readFileSync(path.join(root, name))).digest('hex');
  if (actual !== expected) throw new Error('Prepared source hash changed: ' + name);
}
const output = path.join(root, 'output');
const publicKeys = new Map(fs.readFileSync(path.join(root, 'TACTKeys.txt'), 'utf8').split(/\r?\n/).map(line => line.trim().split(/\s+/)).filter(parts => parts.length === 2).map(([name, key]) => [name.toLowerCase(), key]));
const core = {view: {config: {cascLocale: 2}, $watch(_key, callback) { callback(2); return () => {}; }},
  async progressLoadingScreen(message) { console.log(message); }};
const blocked = () => { throw new Error('Unsupported UI/network operation in local-only export'); };
const stubs = {
  'src/js/log.js': {write() {}, timeLog() {}, timeEnd() {}},
  'src/js/core.js': core,
  'src/js/constants.js': {BUILD: {DATA_DIR: 'Data', MANIFEST: '.build.info'}, PRODUCTS: [{product: 'wow_classic_beta'}], CACHE: {DIR_DATA: 'data', DIR_DBD: 'dbd'}},
  'src/js/generics.js': {
    async fileExists(file) { try { await fsp.access(file); return true; } catch { return false; } },
    async readFile(file, offset, length) {
      if (!Number.isSafeInteger(length) || length < 0 || length > 512 * 1024 * 1024) throw new Error('Read bound exceeded');
      const fd = await fsp.open(file, 'r');
      try {
        const buffer = Buffer.alloc(length);
        let read = 0;
        while (read < length) {
          const result = await fd.read(buffer, read, length - read, offset + read);
          if (!result.bytesRead) throw new Error('Short archive read');
          read += result.bytesRead;
        }
        return new BufferWrapper(buffer);
      } finally { await fd.close(); }
    },
    downloadFile: blocked
  },
  'src/js/mmap.js': {create_virtual_file: blocked},
  'src/js/casc/casc-source-remote.js': class {constructor() { blocked(); }},
  'src/js/casc/build-cache.js': class {constructor() { blocked(); }},
  'src/js/casc/listfile.js': {getByID() {}, getByFilename: blocked},
  'src/js/casc/tact-keys.js': {getKey(name) { return publicKeys.get(name.toLowerCase()); }},
  'src/js/casc/dbd-manifest.js': {},
  'src/js/casc/cdn-resolver.js': {getRankedHosts: blocked}
};
const originalLoad = Module._load;
Module._load = function(request, parent, isMain) {
  if (request === 'webp-wasm') return {encode: blocked, decode: blocked};
  if (parent && request.startsWith('.')) {
    const fullPath = path.resolve(path.dirname(parent.filename), request.endsWith('.js') ? request : request + '.js');
    const relative = path.relative(root, fullPath);
    if (Object.hasOwn(stubs, relative)) return stubs[relative];
  }
  return originalLoad.apply(this, arguments);
};
const BufferWrapper = require(path.join(root, 'src/js/buffer'));
const CASCLocal = require(path.join(root, 'src/js/casc/casc-source-local'));
const WDCReader = require(path.join(root, 'src/js/db/WDCReader'));
const sha256 = data => crypto.createHash('sha256').update(data).digest('hex');
async function main() {
  await fsp.mkdir(output, {recursive: true});
  const casc = new CASCLocal(installRoot);
  await casc.init();
  casc.build = casc.builds.find(build => build.Active === '1' && build.Product === 'wow_classic_beta');
  if (!casc.build || casc.build.Version !== '1.60.1.70338') throw new Error('Expected active Forever build not found');
  // Explicitly forbid CDN fallback and all upstream cache writes.
  casc.getDataFileWithRemoteFallback = key => casc.getDataFile(key);
  casc.initializeRemoteCASC = blocked;
  casc.cache = {async getFile(name, kind) {
    if (kind !== 'dbd' || !['GameObjects.dbd', 'Creature.dbd', 'Lock.dbd', 'LockType.dbd'].includes(name)) return null;
    return BufferWrapper.readFile(path.join(root, name));
  }, storeFile: blocked};
  await casc.loadConfigs();
  await casc.loadIndexes();
  await casc.loadEncoding();
  await casc.loadRoot();
  core.view.casc = casc;
  const tables = [{name: 'GameObjects', id: 841620}, {name: 'Creature', id: 841631},
    {name: 'Lock', id: 1343608}, {name: 'LockType', id: 1284823}];
  const report = {version: 1, generatedAt: new Date().toISOString(), product: casc.build.Product,
    build: casc.build.Version, locale: 'enUS', source: 'installed local CASC, no CDN fallback',
    toolRevision: 'c2fd7bde36a712be78a5da896c995b84fbfa2545',
    schemaRevision: 'd6f50d4f351193e84226aa62a36faa0f58528afa', tables: []};
  report.adapterSha256 = sha256(fs.readFileSync(__filename));
  report.sourceManifestSha256 = sha256(fs.readFileSync(path.join(root, 'source-manifest.json')));
  report.publicKeysRevision = fs.readFileSync(path.join(root, 'TACTKeys-revision.txt'), 'utf8').trim();
  const names = ['Peacebloom', 'Silverleaf', 'Earthroot', 'Mageroyal', 'Briarthorn', 'Bruiseweed', 'Kingsblood', 'Copper Vein', 'Tin Vein'];
  for (const table of tables) {
    const entry = {name: table.name, fileDataID: table.id};
    try {
      const raw = await casc.getFile(table.id, false, true, false);
      raw.processAllBlocks();
      const data = Buffer.from(raw.raw);
      entry.bytes = data.length;
      entry.sha256 = sha256(data);
      entry.contentMD5 = crypto.createHash('md5').update(data).digest('hex');
      const localeEntry = [...casc.rootEntries.get(table.id)].find(([index]) => (casc.rootTypes[index].localeFlags & casc.locale) && !(casc.rootTypes[index].contentFlags & 128));
      entry.expectedContentMD5 = localeEntry?.[1];
      if (entry.contentMD5 !== entry.expectedContentMD5) throw new Error('Decoded content hash mismatch');
      await fsp.writeFile(path.join(output, table.name + '.db2'), data);
      entry.schemaSha256 = sha256(await fsp.readFile(path.join(root, table.name + '.dbd')));
      casc.getVirtualFileByName = async filename => {
        if (filename !== 'DBFilesClient/' + table.name + '.db2') throw new Error('Unexpected table read');
        return new BufferWrapper(data);
      };
      const reader = new WDCReader('DBFilesClient/' + table.name + '.db2');
      await reader.parse();
      const rows = [...reader.getAllRows().values()];
      entry.declaredRows = reader.recordCount;
      entry.parsedRows = rows.length;
      entry.encryptedSections = reader.sections.filter(section => section.isEncrypted).length;
      entry.fields = [...reader.schema.keys()];
      entry.typeCounts = Object.fromEntries([...new Set(rows.map(row => row.TypeID))].filter(type => type !== undefined).map(type => [type, rows.filter(row => row.TypeID === type).length]));
      entry.caseInsensitiveMatches = Object.fromEntries(names.map(name => [name, rows.filter(row => row.Name_lang?.toLowerCase() === name.toLowerCase()).length]));
      entry.byteStringMatches = Object.fromEntries(names.map(name => [name, data.includes(Buffer.from(name))]));
      entry.matches = Object.fromEntries(names.map(name => [name, rows.filter(row => row.Name_lang === name)]));
      const json = JSON.stringify(rows, (_key, value) => typeof value === 'bigint' ? value.toString() : value, 2) + '\n';
      await fsp.writeFile(path.join(output, table.name + '.json'), json);
      entry.rowsSha256 = sha256(json);
      console.log(table.name, JSON.stringify({bytes: entry.bytes, rows: rows.length, matches: Object.fromEntries(Object.entries(entry.matches).map(([name, found]) => [name, found.length]))}));
    } catch (error) { entry.error = error.message; console.log(table.name, 'failed:', error.message); }
    report.tables.push(entry);
  }
  report.experimentStatus = report.tables.some(table => table.error) ? 'partial' : 'completed';
  await fsp.writeFile(path.join(output, 'report.json'), JSON.stringify(report, null, 2) + '\n');
}
main().catch(error => { console.error(error.message); process.exitCode = 1; });
