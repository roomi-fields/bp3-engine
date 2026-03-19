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
    const loadSe = bp3.cwrap('bp3_load_settings', 'number', ['string']);
    const loadAl = bp3.cwrap('bp3_load_alphabet', 'number', ['string']);
    const produce = bp3.cwrap('bp3_produce', 'number', []);
    const getMidi = bp3.cwrap('bp3_get_midi_event_count', 'number', []);

    function loadSettingsFor(gr) {
        const seMatch = gr.match(/-se\.(\S+)/);
        if (seMatch) {
            const seFile = path.join(BP3_CTESTS, '-se.' + seMatch[1]);
            if (fs.existsSync(seFile)) {
                let se = fs.readFileSync(seFile, 'utf-8');
                if (!se.trim().startsWith('{')) se = convertOldSettings(se);
                if (se) loadSe(se);
            }
        }
    }

    function tryVisser3() {
        init();
        const gr = fs.readFileSync(path.join(BP3_CTESTS, '-gr.Visser3'), 'utf-8');
        loadSettingsFor(gr);
        loadGr(gr);
        try {
            const r = produce();
            return getMidi();
        } catch(e) {
            return 'CRASH: ' + e.message.substring(0,60);
        }
    }

    // Test A: Visser3 alone with settings
    console.log('A) Visser3 alone with settings:', tryVisser3());

    // Test B: Visser3 alone WITHOUT settings
    init();
    loadGr(fs.readFileSync(path.join(BP3_CTESTS, '-gr.Visser3'), 'utf-8'));
    try {
        produce();
        console.log('B) Visser3 alone no settings:', getMidi());
    } catch(e) {
        console.log('B) Visser3 alone no settings: CRASH');
    }

    // Test C: Just load Visser3 settings, then Visser3
    init();
    const grV = fs.readFileSync(path.join(BP3_CTESTS, '-gr.Visser3'), 'utf-8');
    loadSettingsFor(grV);
    loadGr(grV);
    try {
        produce();
        console.log('C) Settings only then Visser3:', getMidi());
    } catch(e) {
        console.log('C) Settings only then Visser3: CRASH');
    }

    // Test D: Ames then Visser3
    init();
    const grA = fs.readFileSync(path.join(BP3_CTESTS, '-gr.Ames'), 'utf-8');
    loadSettingsFor(grA);
    loadGr(grA);
    try { produce(); } catch(e) {}
    console.log('D) After Ames:', tryVisser3());

    process.exit(0);
}).catch(e => { console.log('FATAL:', e.message); process.exit(1); });
