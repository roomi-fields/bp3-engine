#!/usr/bin/env node
// Find what state differs between isolated run and after-simple-grammar run
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
    const getMsg = bp3.cwrap('bp3_get_messages', 'string', []);

    const gr = fs.readFileSync(path.join(BP3_CTESTS, '-gr.Visser3'), 'utf-8');

    // Test 1: run simple grammar first, then Visser3
    init();
    loadGr('ORD\ngram#1[1] S --> C4 D4 E4\n');
    produce();
    const msg1 = getMsg();
    console.log('After simple grammar messages (last 500):');
    console.log(msg1.substring(msg1.length - 500));

    init();
    loadGr(gr);
    console.log('\n=== Visser3 after simple grammar ===');
    try {
        const r = produce();
        console.log('Result:', r, 'MIDI:', getMidi());
    } catch(e) {
        console.log('CRASH:', e.message.substring(0, 100));
    }

    process.exit(0);
}).catch(e => {
    console.log('FATAL:', e.message.substring(0, 200));
    process.exit(1);
});
