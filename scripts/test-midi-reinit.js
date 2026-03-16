#!/usr/bin/env node
// Test that MIDI events are properly generated after re-init
const path = require('path');
process.chdir(path.join(__dirname, '..', 'build'));

const BP3Module = require(path.join(__dirname, '..', 'build', 'bp3.js'));

BP3Module().then(bp3 => {
    const init = bp3.cwrap('bp3_init', 'number', []);
    const loadGr = bp3.cwrap('bp3_load_grammar', 'number', ['string']);
    const loadAl = bp3.cwrap('bp3_load_alphabet', 'number', ['string']);
    const produce = bp3.cwrap('bp3_produce', 'number', []);
    const getResult = bp3.cwrap('bp3_get_result', 'string', []);
    const getMsg = bp3.cwrap('bp3_get_messages', 'string', []);
    const getMidiCount = bp3.cwrap('bp3_get_midi_event_count', 'number', []);
    const getMidiEvents = bp3.cwrap('bp3_get_midi_events', 'string', []);

    // Grammar with notes (English convention) — should produce MIDI
    const gram1 = "ORD\ngram#1[1] S --> C4 D4 E4\n";
    const alpha1 = "C4\nD4\nE4\n";

    // Different grammar with notes
    const gram2 = "ORD\ngram#1[1] S --> F4 G4 A4 B4\n";
    const alpha2 = "F4\nG4\nA4\nB4\n";

    // Run 1
    init();
    loadAl(alpha1);
    loadGr(gram1);
    const r1 = produce();
    const out1 = getResult().trim();
    const midi1 = getMidiCount();
    console.log(`Run 1: result=${r1}, output="${out1}", MIDI events=${midi1}`);

    // Run 2 — after re-init
    init();
    loadAl(alpha2);
    loadGr(gram2);
    const r2 = produce();
    const out2 = getResult().trim();
    const midi2 = getMidiCount();
    console.log(`Run 2: result=${r2}, output="${out2}", MIDI events=${midi2}`);

    // Run 3 — one more
    init();
    loadAl(alpha1);
    loadGr(gram1);
    const r3 = produce();
    const out3 = getResult().trim();
    const midi3 = getMidiCount();
    console.log(`Run 3: result=${r3}, output="${out3}", MIDI events=${midi3}`);

    console.log(`\nRun 1 MIDI: ${midi1 > 0 ? 'PASS' : 'FAIL'} (${midi1} events)`);
    console.log(`Run 2 MIDI: ${midi2 > 0 ? 'PASS' : 'FAIL'} (${midi2} events)`);
    console.log(`Run 3 MIDI: ${midi3 > 0 ? 'PASS' : 'FAIL'} (${midi3} events)`);

    if(midi1 > 0 && midi2 > 0 && midi3 > 0) {
        console.log("\nAll runs produced MIDI events — no regression");
        process.exit(0);
    } else {
        console.log("\nMIDI EVENT REGRESSION DETECTED");
        process.exit(1);
    }
}).catch(e => {
    console.error("ERROR:", e.message);
    process.exit(1);
});
