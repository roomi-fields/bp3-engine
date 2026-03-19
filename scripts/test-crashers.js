#!/usr/bin/env node
const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const grammars = ['Visser3', 'Visser5', 'NotReich', 'Visser.Shapes', 'Visser.Waves',
                  'Watch_What_Happens', 'Ames', 'Mozart', 'Alan', 'Alarm', '765432'];

for (const g of grammars) {
    const grFile = path.join(__dirname, '..', 'test-data', '-gr.' + g);
    if (!fs.existsSync(grFile)) { console.log(`${g}: SKIP (not found)`); continue; }
    try {
        const out = execSync(`node ${path.join(__dirname, 'test-visser3-setting.js')} ""`, {
            timeout: 30000,
            env: { ...process.env, TEST_GRAMMAR: g }
        }).toString().trim();
        console.log(`${g}: ${out}`);
    } catch(e) {
        console.log(`${g}: CRASH (exit ${e.status})`);
    }
}
