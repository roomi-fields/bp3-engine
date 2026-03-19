#!/usr/bin/env node
const fs = require('fs');
const path = require('path');
process.chdir(path.join(__dirname, '..', 'build'));

const BP3_CTESTS = path.join(__dirname, '..', 'test-data');
const BP3Module = require(path.join(__dirname, '..', 'build', 'bp3.js'));

BP3Module().then(bp3 => {
    const init = bp3.cwrap('bp3_init', 'number', []);
    const loadGr = bp3.cwrap('bp3_load_grammar', 'number', ['string']);
    const produce = bp3.cwrap('bp3_produce', 'number', []);
    const getMidi = bp3.cwrap('bp3_get_midi_event_count', 'number', []);
    const getResult = bp3.cwrap('bp3_get_result', 'string', []);

    init();
    const gr = fs.readFileSync(path.join(BP3_CTESTS, '-gr.Visser3'), 'utf-8');
    loadGr(gr);
    const r = produce();
    const midi = getMidi();
    console.log(`Visser3: result=${r} midi=${midi}`);
    process.exit(0);
}).catch(e => {
    console.log('ERROR:', e.message.substring(0, 200));
    process.exit(1);
});
