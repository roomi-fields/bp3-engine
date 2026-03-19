#!/usr/bin/env node
const fs = require('fs');
const path = require('path');
process.chdir(path.join(__dirname, '..', 'build'));

const BP3_CTESTS = path.join(__dirname, '..', 'test-data');

function convertOldSettings(content) {
    const lines = content.split('\n');
    if (lines.length < 12) return null;
    const num = (n) => { const v = parseFloat((lines[n-1] || '').trim()); return isNaN(v) ? null : v; };
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
    const getMidi = bp3.cwrap('bp3_get_midi_event_count', 'number', []);

    function runGrammar(name) {
        init();
        const grFile = path.join(BP3_CTESTS, '-gr.' + name);
        if (!fs.existsSync(grFile)) return null;
        const gr = fs.readFileSync(grFile, 'utf-8');

        const seMatch = gr.match(/-se\.(\S+)/);
        if (seMatch) {
            const seFile = path.join(BP3_CTESTS, '-se.' + seMatch[1]);
            if (fs.existsSync(seFile)) {
                let se = fs.readFileSync(seFile, 'utf-8');
                if (!se.trim().startsWith('{')) se = convertOldSettings(se);
                if (se) loadSe(se);
            }
        }
        const alMatch = gr.match(/-al\.(\S+)/);
        if (alMatch) {
            const alFile = path.join(BP3_CTESTS, '-al.' + alMatch[1]);
            if (fs.existsSync(alFile)) loadAl(fs.readFileSync(alFile, 'utf-8'));
        }
        const hoMatch = gr.match(/-ho\.(\S+)/);
        if (hoMatch && !alMatch) {
            const alFile = path.join(BP3_CTESTS, '-al.' + hoMatch[1]);
            if (fs.existsSync(alFile)) loadAl(fs.readFileSync(alFile, 'utf-8'));
        }

        loadGr(gr);
        try {
            const r = produce();
            const midi = getMidi();
            console.log(`${name}: result=${r} midi=${midi}`);
            return true;
        } catch(e) {
            console.log(`${name}: CRASH - ${e.message.substring(0,80)}`);
            return false;
        }
    }

    // Exact same order as test-sequence
    const grammars = ['Ames', 'look-and-say', 'Ruwet', 'Mozart', 'Visser3'];
    for (const g of grammars) runGrammar(g);

    process.exit(0);
}).catch(e => { console.log('FATAL:', e.message); process.exit(1); });
