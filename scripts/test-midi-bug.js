#!/usr/bin/env node
// Reproduce: grammar with -se.xxx header kills MIDI on subsequent runs
const path = require('path');
process.chdir(path.join(__dirname, '..', 'build'));

const BP3Module = require(path.join(__dirname, '..', 'build', 'bp3.js'));

BP3Module().then(bp3 => {
    const init = bp3.cwrap('bp3_init', 'number', []);
    const loadGr = bp3.cwrap('bp3_load_grammar', 'number', ['string']);
    const produce = bp3.cwrap('bp3_produce', 'number', []);
    const getResult = bp3.cwrap('bp3_get_result', 'string', []);
    const getMsg = bp3.cwrap('bp3_get_messages', 'string', []);
    const getMidiCount = bp3.cwrap('bp3_get_midi_event_count', 'number', []);

    // Run 1: simple grammar — should produce MIDI
    init();
    loadGr("RND\ngram#1[1] S --> C4 D4 E4\n");
    produce();
    const midi1 = getMidiCount();
    const out1 = getResult().trim();
    console.log(`Run 1 (simple): output="${out1}", MIDI=${midi1}`);

    // Run 2: grammar with -se.xxx header (file doesn't exist in WASM FS)
    init();
    loadGr("-se.drum\n-ho.drum\nRND\ngram#1[1] S --> C4 D4 E4 F4 G4 A4 B4 C5\n");
    produce();
    const midi2 = getMidiCount();
    const out2 = getResult().trim();
    const msg2 = getMsg();
    console.log(`Run 2 (with -se.drum): output="${out2}", MIDI=${midi2}`);
    if (msg2.includes('Error') || msg2.includes('error')) {
        const errLines = msg2.split('\n').filter(l => /error/i.test(l));
        errLines.forEach(l => console.log(`  MSG: ${l.trim()}`));
    }

    // Run 3: simple grammar again — should still produce MIDI
    init();
    loadGr("ORD\ngram#1[1] S --> F4 G4\n");
    produce();
    const midi3 = getMidiCount();
    const out3 = getResult().trim();
    console.log(`Run 3 (simple after -se): output="${out3}", MIDI=${midi3}`);

    console.log(`\nRun 1: ${midi1 > 0 ? 'PASS' : 'FAIL'} (${midi1} events)`);
    console.log(`Run 2: ${midi2 > 0 ? 'PASS' : 'FAIL'} (${midi2} events)`);
    console.log(`Run 3: ${midi3 > 0 ? 'PASS' : 'FAIL'} (${midi3} events)`);

    process.exit((midi1 > 0 && midi3 > 0) ? 0 : 1);
}).catch(e => {
    console.error("ERROR:", e.message);
    process.exit(1);
});
