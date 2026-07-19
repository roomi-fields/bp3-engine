#!/usr/bin/env node
// Test bp3_load_settings_params — direct variable setter
const path = require('path');
process.chdir(path.join(__dirname, '..', 'build'));

const BP3Module = require(path.join(__dirname, '..', 'build', 'bp3.js'));

BP3Module().then(bp3 => {
    const init = bp3.cwrap('bp3_init', 'number', []);
    const loadGr = bp3.cwrap('bp3_load_grammar', 'number', ['string']);
    const loadAl = bp3.cwrap('bp3_load_alphabet', 'number', ['string']);
    const loadSettingsParams = bp3.cwrap('bp3_load_settings_params', 'number',
        ['number', 'number', 'number', 'number', 'number', 'number']);
    const produce = bp3.cwrap('bp3_produce', 'number', []);
    const getResult = bp3.cwrap('bp3_get_result', 'string', []);
    const getMidiCount = bp3.cwrap('bp3_get_midi_event_count', 'number', []);

    // Test 1: without settings params — western notes work
    init();
    loadGr("RND\ngram#1[1] S --> C4 D4 E4\n");
    produce();
    const midi1 = getMidiCount();
    const out1 = getResult().trim();
    console.log(`Test 1 (no settings): output="${out1}", MIDI=${midi1}`);

    // Test 2: with settings params — les notes anglaises marchent toujours.
    // ⚠ La convention ANGLAISE vaut 0, pas 1 : ConventionString[] = {ENGLISH, FRENCH,
    // INDIAN, KEYS} (csrc/bp3/-BP3main.h:134). Ce test passait 1 (= FRANCAIS) avec une
    // grammaire en notes anglaises, et concluait a tort que « les reglages tuent le MIDI ».
    // Le moteur avait raison : sous convention francaise, C4 n'est pas une note.
    init();
    loadSettingsParams(0, 10, 10, 1, 42, 60);
    loadGr("RND\ngram#1[1] S --> C4 D4 E4\n");
    produce();
    const midi2 = getMidiCount();
    const out2 = getResult().trim();
    console.log(`Test 2 (English conv): output="${out2}", MIDI=${midi2}`);

    // Test 3: simple grammar AFTER settings — no corruption
    init();
    loadGr("ORD\ngram#1[1] S --> F4 G4\n");
    produce();
    const midi3 = getMidiCount();
    const out3 = getResult().trim();
    console.log(`Test 3 (after settings): output="${out3}", MIDI=${midi3}`);

    // Test 4: le scenario de reproduction — reglages, puis grammaire de batterie, puis simple
    init();
    loadSettingsParams(0, 10, 10, 1, 42, 60);
    loadGr("-se.drum\n\nS --> {_chan(1) _vel(120) _staccato(96) C8 - - -,_chan(1) _vel(120) _staccato(96) - C7 C7 C7,_chan(1) _vel(120) _staccato(92) E7 E7 E7 E7 E7 E7 E7 E7}");
    produce();
    const midi4 = getMidiCount();
    console.log(`Test 4 (settings + drum): MIDI=${midi4}`);

    init();
    loadGr("RND\ngram#1[1] S --> C4 D4 E4\n");
    produce();
    const midi5 = getMidiCount();
    const out5 = getResult().trim();
    console.log(`Test 5 (simple after drum): output="${out5}", MIDI=${midi5}`);

    // Test 6 & 7 : la convention doit etre SYMETRIQUE — chacune lit ses noms de notes
    // et refuse ceux de l'autre. Sans ces deux cas, un test vert ne prouverait pas que
    // la convention est prise en compte : il prouverait seulement qu'elle ne gene pas.
    init();
    loadSettingsParams(1, 10, 10, 1, 42, 60);
    loadGr("RND\ngram#1[1] S --> do4 re4 mi4\n");
    produce();
    const midi6 = getMidiCount();
    console.log(`Test 6 (francais + notes francaises): MIDI=${midi6}`);

    init();
    loadSettingsParams(1, 10, 10, 1, 42, 60);
    loadGr("RND\ngram#1[1] S --> C4 D4 E4\n");
    produce();
    const midi7 = getMidiCount();
    console.log(`Test 7 (francais + notes anglaises, doit etre 0): MIDI=${midi7}`);

    console.log(`\n=== RESULTS ===`);
    console.log(`Test 1: ${midi1 > 0 ? 'PASS' : 'FAIL'} (${midi1} events)`);
    console.log(`Test 2: ${midi2 > 0 ? 'PASS' : 'FAIL'} (${midi2} events) — settings must not kill MIDI`);
    console.log(`Test 3: ${midi3 > 0 ? 'PASS' : 'FAIL'} (${midi3} events)`);
    console.log(`Test 4: ${midi4 > 0 ? 'PASS' : 'FAIL'} (${midi4} events)`);
    console.log(`Test 5: ${midi5 > 0 ? 'PASS' : 'FAIL'} (${midi5} events) — no corruption after drum`);
    console.log(`Test 6: ${midi6 > 0 ? 'PASS' : 'FAIL'} (${midi6} events) — francais lit les notes francaises`);
    console.log(`Test 7: ${midi7 === 0 ? 'PASS' : 'FAIL'} (${midi7} events) — francais REFUSE les notes anglaises`);

    const allPass = midi1 > 0 && midi2 > 0 && midi3 > 0 && midi4 > 0 && midi5 > 0
                 && midi6 > 0 && midi7 === 0;
    process.exit(allPass ? 0 : 1);
}).catch(e => {
    console.error("ERROR:", e.message);
    process.exit(1);
});
