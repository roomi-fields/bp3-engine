#!/usr/bin/env node
// Test: run multiple complex grammars in sequence with re-init between each
const fs = require('fs');
const path = require('path');
process.chdir(path.join(__dirname, '..', 'build'));

const BP3_CTESTS = path.join(__dirname, '..', 'test-data');

function convertOldSettings(content) {
    const lines = content.split('\n');
    if (lines.length < 12) return null;
    const val = (n) => (lines[n-1] || '').trim();
    const num = (n) => { const v = parseFloat(val(n)); return isNaN(v) ? null : v; };
    const obj = {};
    const add = (key, name, line) => {
        const v = num(line);
        if (v !== null) obj[key] = {name, value: String(v), boolean: "0"};
    };
    add("NoteConvention", "Note convention", 10);
    add("Nature_of_time", "Nature of time", 9);
    if (lines.length >= 47) add("MaxConsoleTime", "Max console time", 47);
    if (!obj.NoteConvention) return null;
    return JSON.stringify(obj);
}

const BP3Module = require(path.join(__dirname, '..', 'build', 'bp3.js'));

BP3Module().then(bp3 => {
    const init = bp3.cwrap('bp3_init', 'number', []);
    const loadGr = bp3.cwrap('bp3_load_grammar', 'number', ['string']);
    const loadAl = bp3.cwrap('bp3_load_alphabet', 'number', ['string']);
    const loadSe = bp3.cwrap('bp3_load_settings', 'number', ['string']);
    const produce = bp3.cwrap('bp3_produce', 'number', []);
    const getResult = bp3.cwrap('bp3_get_result', 'string', []);
    const getMsg = bp3.cwrap('bp3_get_messages', 'string', []);
    const getMidiCount = bp3.cwrap('bp3_get_midi_event_count', 'number', []);

    function runGrammar(name) {
        init();

        const grFile = path.join(BP3_CTESTS, '-gr.' + name);
        if (!fs.existsSync(grFile)) { console.log(`  SKIP: ${grFile} not found`); return null; }
        const gr = fs.readFileSync(grFile, 'utf-8');

        // Load settings
        const seMatch = gr.match(/-se\.(\S+)/);
        if (seMatch) {
            const seFile = path.join(BP3_CTESTS, '-se.' + seMatch[1]);
            if (fs.existsSync(seFile)) {
                let seContent = fs.readFileSync(seFile, 'utf-8');
                if (!seContent.trim().startsWith('{')) seContent = convertOldSettings(seContent);
                if (seContent) loadSe(seContent);
            }
        }

        // Load alphabet
        const alMatch = gr.match(/-al\.(\S+)/);
        if (alMatch) {
            const alFile = path.join(BP3_CTESTS, '-al.' + alMatch[1]);
            if (fs.existsSync(alFile)) loadAl(fs.readFileSync(alFile, 'utf-8'));
        }

        loadGr(gr);
        const r = produce();
        const out = getResult().trim();
        const midi = getMidiCount();
        const msg = getMsg();
        const errMatch = msg.match(/Errors:\s*(\d+)/);
        const errs = errMatch ? parseInt(errMatch[1]) : -1;
        const tokens = out.split(/\s+/).filter(t => t.length > 0).length;

        return { name, result: r, errors: errs, tokens, midi, preview: out.substring(0, 60) };
    }

    const grammars = ['Ames', 'look-and-say', 'Ruwet', 'Mozart', 'Visser3', '12345678', 'Alan'];
    console.log("=== Sequential grammar test (with re-init) ===\n");

    for (const name of grammars) {
        const r = runGrammar(name);
        if (r) {
            const status = (r.result === 1 && r.errors === 0) ? 'OK' : 'ISSUE';
            console.log(`${status} | ${r.name.padEnd(20)} | result=${r.result} errors=${r.errors} tokens=${r.tokens} midi=${r.midi} | ${r.preview}`);
        }
    }

    process.exit(0);
}).catch(e => {
    console.error("ERROR:", e.message);
    process.exit(1);
});
