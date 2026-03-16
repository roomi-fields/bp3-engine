#!/usr/bin/env node
// Exact repro: -se.drum grammar then transpiled grammar — MIDI dies
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

    // Run 1: Bernard's original grammar with -se.drum header
    init();
    loadGr("-se.drum\n\nS --> {_chan(1) _vel(120) _staccato(96) C8 - - -,_chan(1) _vel(120) _staccato(96) - C7 C7 C7,_chan(1) _vel(120) _staccato(92) E7 E7 E7 E7 E7 E7 E7 E7}");
    let r1 = produce();
    let midi1 = getMidiCount();
    let out1 = getResult().trim();
    let msg1 = getMsg();
    console.log(`Run 1 (with -se.drum): result=${r1}, MIDI=${midi1}, output="${out1.substring(0,80)}"`);
    console.log(`  messages: ${msg1.split('\n').filter(l => l.trim()).slice(0,5).join(' | ')}`);

    // Run 2: transpiled grammar (no -se header)
    init();
    loadGr("RND\ngram#1[1] S --> _chan(1) _vel(120) {_staccato(96) C8 - - -, _staccato(96) - C7 C7 C7, _staccato(92) E7 E7 E7 E7 E7 E7 E7 E7}");
    let r2 = produce();
    let midi2 = getMidiCount();
    let out2 = getResult().trim();
    let msg2 = getMsg();
    console.log(`Run 2 (transpiled, no -se): result=${r2}, MIDI=${midi2}, output="${out2.substring(0,80)}"`);
    console.log(`  messages: ${msg2.split('\n').filter(l => l.trim()).slice(0,5).join(' | ')}`);

    // Run 3: simple grammar to check if MIDI is dead
    init();
    loadGr("ORD\ngram#1[1] S --> C4 D4 E4\n");
    let r3 = produce();
    let midi3 = getMidiCount();
    let out3 = getResult().trim();
    console.log(`Run 3 (simple): result=${r3}, MIDI=${midi3}, output="${out3}"`);

    console.log(`\n=== RESULTS ===`);
    console.log(`Run 1: ${midi1 > 0 ? 'PASS' : 'FAIL'} (${midi1} MIDI events)`);
    console.log(`Run 2: ${midi2 > 0 ? 'PASS' : 'FAIL'} (${midi2} MIDI events) — should be ~24`);
    console.log(`Run 3: ${midi3 > 0 ? 'PASS' : 'FAIL'} (${midi3} MIDI events) — should be 6`);

    process.exit((midi1 > 0 && midi2 > 0 && midi3 > 0) ? 0 : 1);
}).catch(e => {
    console.error("ERROR:", e.message);
    process.exit(1);
});
