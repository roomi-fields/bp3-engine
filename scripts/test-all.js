#!/usr/bin/env node
// Test all grammars from bp3-ctests against WASM engine
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
    add("Quantization", "Quantization", 5);
    add("Time_res", "Time resolution", 6);
    add("Nature_of_time", "Nature of time", 9);
    add("Improvize", "Improvize", 33);
    if (lines.length >= 47) add("MaxConsoleTime", "Max console time", 47);
    if (lines.length >= 65) add("C4key", "C4 key number", 65);
    if (lines.length >= 66) add("A4freq", "A4 frequency", 66);
    if (!obj.NoteConvention) return null;
    return JSON.stringify(obj);
}

const BP3Module = require(path.join(__dirname, '..', 'build', 'bp3.js'));

BP3Module().then(bp3 => {
    const init = bp3.cwrap('bp3_init', 'number', []);
    const loadGr = bp3.cwrap('bp3_load_grammar', 'number', ['string']);
    const loadAl = bp3.cwrap('bp3_load_alphabet', 'number', ['string']);
    const loadSe = bp3.cwrap('bp3_load_settings', 'number', ['string']);
    const loadTo = bp3.cwrap('bp3_load_tonality', 'number', ['string']);
    const produce = bp3.cwrap('bp3_produce', 'number', []);
    const getResult = bp3.cwrap('bp3_get_result', 'string', []);
    const getMsg = bp3.cwrap('bp3_get_messages', 'string', []);
    const getMidiCount = bp3.cwrap('bp3_get_midi_event_count', 'number', []);

    const grFiles = fs.readdirSync(BP3_CTESTS)
        .filter(f => f.startsWith('-gr.'))
        .sort();

    let ok = 0, miss = 0, abort = 0, err = 0, crash = 0;

    for (const grFile of grFiles) {
        const name = grFile.replace('-gr.', '');
        try {
            init();
            const gr = fs.readFileSync(path.join(BP3_CTESTS, grFile), 'utf-8');

            // Load settings
            const seMatch = gr.match(/-se\.(\S+)/);
            if (seMatch) {
                const seFile = path.join(BP3_CTESTS, '-se.' + seMatch[1]);
                if (fs.existsSync(seFile)) {
                    let se = fs.readFileSync(seFile, 'utf-8');
                    if (!se.trim().startsWith('{')) se = convertOldSettings(se);
                    if (se) loadSe(se);
                }
            }

            // Load alphabet
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

            // Load tonality
            const toMatch = gr.match(/-to\.(\S+)/);
            if (toMatch) {
                const toFile = path.join(BP3_CTESTS, '-to.' + toMatch[1]);
                if (fs.existsSync(toFile)) loadTo(fs.readFileSync(toFile, 'utf-8'));
            }
            const csMatch = gr.match(/-cs\.(\S+)/);
            if (csMatch && !toMatch) {
                const toFile2 = path.join(BP3_CTESTS, '-to.' + csMatch[1]);
                if (fs.existsSync(toFile2)) loadTo(fs.readFileSync(toFile2, 'utf-8'));
            }

            loadGr(gr);
            const r = produce();
            const out = getResult().trim();
            const msg = getMsg();
            const errMatch = msg.match(/Errors:\s*(\d+)/);
            const errs = errMatch ? parseInt(errMatch[1]) : -1;
            const midi = getMidiCount();
            const tokens = out.split(/\s+/).filter(t => t.length > 0).length;

            let status;
            if (r === 1 && errs === 0) { status = 'OK'; ok++; }
            else if (r === 0) { status = 'MISS'; miss++; }
            else if (r < 0) { status = 'ABORT'; abort++; }
            else { status = 'ERR'; err++; }

            const preview = out.substring(0, 50).replace(/\n/g, ' ');
            console.log(`${status.padEnd(5)} | ${name.padEnd(25)} | r=${r} e=${errs} t=${tokens} m=${midi} | ${preview}`);
        } catch(e) {
            console.log(`CRASH | ${name.padEnd(25)} | ${e.message.substring(0, 60)}`);
            crash++;
        }
    }

    console.log(`\n=== SUMMARY ===`);
    console.log(`Total: ${grFiles.length}`);
    console.log(`OK:    ${ok}`);
    console.log(`MISS:  ${miss}`);
    console.log(`ABORT: ${abort}`);
    console.log(`ERR:   ${err}`);
    console.log(`CRASH: ${crash}`);

    process.exit(0);
}).catch(e => {
    console.error("FATAL:", e.message);
    process.exit(1);
});
