#!/usr/bin/env node
// Test that bp3_init() properly resets state between grammars
const path = require('path');
process.chdir(path.join(__dirname, '..', 'build'));

const BP3Module = require(path.join(__dirname, '..', 'build', 'bp3.js'));

BP3Module().then(bp3 => {
    const init = bp3.cwrap('bp3_init', 'number', []);
    const loadGr = bp3.cwrap('bp3_load_grammar', 'number', ['string']);
    const produce = bp3.cwrap('bp3_produce', 'number', []);
    const getResult = bp3.cwrap('bp3_get_result', 'string', []);

    // Grammar A: simple ORD
    const gramA = "ORD\ngram#1[1] S --> A B C\n";
    // Grammar B: simple RND (different)
    const gramB = "RND\ngram#1[1] S --> X Y Z\n";

    // First run
    init();
    loadGr(gramA);
    const r1 = produce();
    const out1 = getResult().trim();
    console.log(`Run 1: result=${r1}, output="${out1}"`);

    // Second run — should be completely independent
    init();
    loadGr(gramB);
    const r2 = produce();
    const out2 = getResult().trim();
    console.log(`Run 2: result=${r2}, output="${out2}"`);

    // Verify no contamination
    const ok1 = out1 === "A B C";
    const ok2 = (out2 === "X Y Z" || out2 === "Y Z X" || out2 === "Z X Y" ||
                 out2 === "X Z Y" || out2 === "Y X Z" || out2 === "Z Y X");

    console.log(`\nRun 1 correct (A B C): ${ok1 ? 'PASS' : 'FAIL — got "' + out1 + '"'}`);
    console.log(`Run 2 correct (permutation of X Y Z): ${ok2 ? 'PASS' : 'FAIL — got "' + out2 + '"'}`);

    if(!ok1 || !ok2) {
        console.log("\nSTATE CONTAMINATION DETECTED");
        process.exit(1);
    } else {
        console.log("\nNo contamination — bp3_init() reset is clean");
        process.exit(0);
    }
}).catch(e => {
    console.error("ERROR:", e.message);
    process.exit(1);
});
