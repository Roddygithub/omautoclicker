const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const model = vm.createContext({});
vm.runInContext(fs.readFileSync('Model.js', 'utf8'), model);
assert(model.valid(10, 'left', 0, 1));
assert(model.valid(3600000, 'middle', 1000000, 10));
for (const args of [[9,'left',0,1],[100,'bad',0,1],[100,'left',-1,1],[100,'left',1,0],[NaN,'left',1,1],[10.5,'left',0,1],[100,'left',Infinity,1]]) assert(!model.valid(...args));
for (const [button, code] of Object.entries({left:'0xC0',right:'0xC1',middle:'0xC2'})) assert.deepEqual(Array.from(model.command(button)), ['ydotool','click','--next-delay','0',code]);
assert.throws(() => model.command('invalid'));
const manifest = JSON.parse(fs.readFileSync('manifest.json'));
for (const file of Object.values(manifest.entryPoints)) assert(fs.existsSync(file));
const en = JSON.parse(fs.readFileSync('i18n/en.json'));
const runtime = process.env.OMARCHY_PATH || '/usr/share/omarchy';
const locales = Object.keys(JSON.parse(fs.readFileSync(`${runtime}/default/i18n/locales.json`))).sort();
assert.deepEqual(fs.readdirSync('i18n').filter(f => f.endsWith('.json')).map(f => f.slice(0, -5)).sort(), locales,
    'Every Omarchy language needs a catalog');
for (const locale of locales) {
    const catalog = JSON.parse(fs.readFileSync(`i18n/${locale}.json`));
    assert.deepEqual(Object.keys(catalog).sort(), Object.keys(en).sort(), `${locale}: complete keys`);
    for (const [key, value] of Object.entries(catalog)) {
        assert.equal(typeof value, 'string', `${locale}/${key}`);
        assert(value.trim().length > 0, `${locale}/${key}: nonempty`);
        assert.deepEqual((value.match(/%\d+/g) || []).sort(), (en[key].match(/%\d+/g) || []).sort(), `${locale}/${key}: placeholders`);
        for (const name of ['ydotoold', 'ydotool']) {
            if (en[key].includes(name)) assert(value.includes(name), `${locale}/${key}: tool name`);
        }
        assert(!value.includes('ZXQ'), `${locale}/${key}: translation marker`);
    }
}
console.log(`Model, manifest and ${locales.length} complete translations: PASS`);
