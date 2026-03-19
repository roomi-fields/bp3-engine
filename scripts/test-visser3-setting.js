#!/usr/bin/env node
// Test a single setting key with Visser3
// Usage: node test-visser3-setting.js key1,key2,...
const fs = require('fs');
const path = require('path');
process.chdir(path.join(__dirname, '..', 'build'));

const keys = (process.argv[2] || '').split(',').filter(k => k);
const fullSe = JSON.parse(fs.readFileSync(path.join(__dirname, '..', 'test-data', '-se.Visser3'), 'utf-8'));
const gr = fs.readFileSync(path.join(__dirname, '..', 'test-data', '-gr.Visser3'), 'utf-8');

const obj = {};
for (const k of keys) if (fullSe[k]) obj[k] = fullSe[k];

const BP3Module = require(path.join(__dirname, '..', 'build', 'bp3.js'));
BP3Module().then(bp3 => {
    const init = bp3.cwrap('bp3_init', 'number', []);
    const loadGr = bp3.cwrap('bp3_load_grammar', 'number', ['string']);
    const loadSe = bp3.cwrap('bp3_load_settings', 'number', ['string']);
    const produce = bp3.cwrap('bp3_produce', 'number', []);
    const getMidi = bp3.cwrap('bp3_get_midi_event_count', 'number', []);

    init();
    if (keys.length > 0) loadSe(JSON.stringify(obj));
    loadGr(gr);
    const r = produce();
    console.log('OK midi=' + getMidi());
    process.exit(0);
}).catch(e => {
    console.log('CRASH');
    process.exit(1);
});

setTimeout(() => { console.log('TIMEOUT'); process.exit(2); }, 30000);
