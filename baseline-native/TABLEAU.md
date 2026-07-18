# Baseline native — tableau par grammaire

**v5** — figée le 2026-07-18 · binaire bp3 v3.4.4 (graphics-for-BP3) · graine 1

`action` = ce que fait le moteur nativement. Les deux voies doivent répliquer **la même action**.

- **single** = la grammaire *joue* un morceau : une réalisation, un item, graine fixe.
- **produce-all** = production purement symbolique, le moteur énumère l'ensemble.

## Les 89 qui produisent

| grammaire | action | mode natif | jetons | mots | items | énumérable |
|---|---|---|---|---|---|---|
| `all-items` | produce-all | TEXTE | 0 | 36 | 12 | 12 |
| `all-items1` | produce-all | TEXTE | 0 | 36 | 12 | 12 |
| `checkBT` | produce-all | TEXTE | 0 | 4 | 1 | 1 |
| `destru` | produce-all | TEXTE | 0 | 48 | 2 | 2 |
| `dhadhatite` | produce-all | TEXTE | 0 | 2 | 1 | 1 |
| `dhadhatite1` | produce-all | TEXTE | 0 | 2 | 1 | 1 |
| `dhadhatite_v2` | produce-all | TEXTE | 0 | 2 | 1 | 1 |
| `dhati2` | produce-all | TEXTE | 0 | 65 | 1 | 1 |
| `dhati3` | produce-all | TEXTE | 0 | 65 | 1 | 1 |
| `dhin1` | produce-all | TEXTE | 0 | 1940 | 20 | 20 |
| `ek-do-tin` | produce-all | TEXTE | 0 | 99 | 1 | 1 |
| `flags` | produce-all | TEXTE | 0 | 400 | 20 | 20 |
| `gramgene1` | produce-all | TEXTE | 0 | 142 | 25 | 25 |
| `koto1` | produce-all | TEXTE | 0 | 8 | 1 | 1 |
| `koto2` | produce-all | TEXTE | 0 | 8 | 1 | 1 |
| `look-and-say` ⚠ | produce-all | TEXTE | 0 | 1 | 1 | 1 |
| `polyphony1` | produce-all | TEXTE | 0 | 76 | 25 | 25 |
| `repeat` | produce-all | TEXTE | 0 | 40 | 5 | 5 |
| `templates` | produce-all | TEXTE | 0 | 25 | 5 | 5 |
| `testHO2` | produce-all | TEXTE | 0 | 4 | 1 | 1 |
| `tryAllItems0` | produce-all | TEXTE | 0 | 20 | 8 | 8 |
| `tryAllItems1` | produce-all | TEXTE | 0 | 36 | 12 | 12 |
| `tryCsoundObjects` | produce-all | TEXTE | 0 | 2 | 1 | 1 |
| `tryLIN` | produce-all | TEXTE | 0 | 25 | 25 | 25 |
| `tryObjects` | produce-all | TEXTE | 0 | 18 | 1 | 1 |
| `tryPatternGrammar` | produce-all | TEXTE | 0 | 52 | 4 | 4 |
| `tryflags2` | produce-all | TEXTE | 0 | 25 | 25 | 25 |
| `tryflags3` | produce-all | TEXTE | 0 | 25 | 25 | 25 |
| `trytemplates` | produce-all | TEXTE | 0 | 98 | 25 | 25 |
| `trytemplates2` | produce-all | TEXTE | 0 | 20 | 4 | 4 |
| `765432` | single | MIDI | 823 | 1405 | 1 | refusé par le moteur |
| `Alarm` | single | TEXTE | 0 | 26 | 1 | refusé par le moteur |
| `Djinns` | single | MIDI | 895 | 851 | 1 | refusé par le moteur |
| `Mozartexpression` | single | MIDI | 251 | 27 | 1 | refusé par le moteur |
| `MyMelody` | single | MIDI | 31 | 31 | 1 | 20 |
| `Nadaka-1er-essai` | single | MIDI | 4 | 4 | 1 | 1 |
| `PP` | single | MIDI | 2 | 9 | 1 | — |
| `acceleration` | single | MIDI | 78 | 100 | 1 | 1 |
| `acceleration_v2` | single | MIDI | 78 | 100 | 1 | 1 |
| `alan-dice` | single | MIDI | 270 | 181 | 1 | refusé par le moteur |
| `ames` | single | MIDI | 11 | 7 | 1 | 1 |
| `asymmetric` | single | TEXTE | 0 | 15 | 1 | — |
| `beatrix-dice` | single | MIDI | 270 | 179 | 1 | refusé par le moteur |
| `bells` | single | MIDI | 16 | 17 | 1 | 1 |
| `check&` | single | MIDI | 4 | 6 | 1 | 7 |
| `checkSUB` | single | MIDI | 10 | 13 | 1 | — |
| `checkSUB.new` | single | MIDI | 10 | 13 | 1 | — |
| `checkSUB1` | single | TEXTE | 0 | 2 | 1 | refusé par le moteur |
| `checkVolMasterSlave` | single | MIDI | 6 | 12 | 1 | 1 |
| `dhati` | single | MIDI | 23 | 144 | 1 | 20 |
| `doeslittle` | single | MIDI | 7 | 11 | 1 | 1 |
| `drum` | single | MIDI | 12 | 23 | 1 | 1 |
| `gramgene2` | single | TEXTE | 0 | 78 | 1 | — |
| `graphics` | single | MIDI | 6 | 7 | 1 | 1 |
| `harmony` | single | MIDI | 20 | 20 | 1 | 1 |
| `koto3` | single | MIDI | 2 | 15 | 1 | — |
| `kss2` | single | MIDI | 97 | 138 | 1 | — |
| `livecode1` | single | MIDI | 27 | 23 | 1 | 1 |
| `livecode2` | single | MIDI | 29 | 1048558 | 1 | 1 |
| `major-minor` | single | MIDI | 24 | 2 | 1 | 1 |
| `mohanam` | single | MIDI | 27 | 41 | 1 | 16 |
| `mozart-dice` | single | MIDI | 269 | 172 | 1 | refusé par le moteur |
| `nadaka` | single | MIDI | 714 | 1007 | 1 | — |
| `negative-context` | single | MIDI | 6 | 6 | 1 | — |
| `not-reich` | single | MIDI | 580 | 565 | 1 | 1 |
| `one-scale` | single | MIDI | 6 | 6 | 1 | 1 |
| `ruwet` | single | MIDI | 126 | 157 | 1 | 8 |
| `shapes-rhythm` | single | MIDI | 1952 | 4685 | 1 | refusé par le moteur |
| `simpletemplates` | single | MIDI | 7 | 11 | 1 | 3 |
| `testNC1` | single | MIDI | 6 | 7 | 1 | 1 |
| `time-patterns` | single | MIDI | 8 | 13 | 1 | 1 |
| `transposition1` | single | MIDI | 75 | 107 | 1 | 1 |
| `transposition3` | single | MIDI | 66 | 30 | 1 | — |
| `tryGOTO` | single | TEXTE | 0 | 1 | 1 | refusé par le moteur |
| `tryKeyMap` | single | MIDI | 392 | 450 | 1 | 1 |
| `tryKeyXpand` | single | MIDI | 91 | 120 | 1 | 1 |
| `tryMIDIfile` | single | MIDI | 8 | 9 | 1 | 2 |
| `tryRagas` | single | MIDI | 42 | 1048572 | 1 | 1 |
| `tryRotate` | single | MIDI | 65 | 67 | 1 | 1 |
| `trySerial` | single | MIDI | 8 | 7 | 1 | 1 |
| `trySrand` | single | MIDI | 25 | 37 | 1 | 1 |
| `tryTicks` | single | MIDI | 16 | 16 | 1 | 1 |
| `tryhomomorphism` | single | MIDI | 6 | 12 | 1 | 1 |
| `tunings` | single | MIDI | 16 | 16 | 1 | 1 |
| `visser-shapes` | single | MIDI | 2086 | 2553 | 1 | — |
| `visser-waves` | single | MIDI | 365 | 433 | 1 | — |
| `visser3` | single | MIDI | 401 | 770 | 1 | 33 |
| `visser5` | single | MIDI | 1152 | 1822 | 1 | 19 |
| `watch` | single | MIDI | 2105 | 5122 | 1 | 7 |

⚠ **Réserve** :
- `look-and-say` — production degeneree : la sortie est le seul terminal de depart ("'1'"), aucune regle n'a ete appliquee. Le bug moteur #51 (all weights are nil) reste actif ; ne pas s'en servir comme reference.

## Les 24 qui ne produisent pas

| grammaire | cause |
|---|---|
| `Nadaka1` | => Cannot produce items because all weights are nil in gram#1 |
| `Rajeev` | 27 erreur(s) de compilation : Variable must start with uppercase character or '| |
| `a` | 4 erreur(s) de compilation : Error code 52: Missing slash after /flag/ in gram#2 |
| `a.html` | 6 erreur(s) de compilation : Error code 8: incorrect expression or bad derivatio |
| `blurb` | blocage (> 90 s sans rendre la main) |
| `checkAllCsound` | 30 erreur(s) de compilation : => You probably forgot to create or load a '-cs' i |
| `checkHomo` | => Can't compile alphabet |
| `checkVolChan` | 6 erreur(s) de compilation : => Incorrect note. (May be wrong note convention) |
| `checkcontext` | => Calculation overflow (10000 derivations): task abandoned. Loop? |
| `checkhomo2` | => Can't compile alphabet |
| `checkrests` | 12 erreur(s) de compilation : Variable must start with uppercase character or '| |
| `cloches1` | blocage (> 90 s sans rendre la main) |
| `csound` | blocage (> 90 s sans rendre la main) |
| `dhin` | 22 erreur(s) de compilation : Variable must start with uppercase character or '| |
| `keys` | aucune sortie, aucun message |
| `scales` | => Error reading Csound instruments file:  /home/romi/dev/bp/bp3-engine/test-dat |
| `testTie7` | 1 erreur(s) de compilation : Variable must start with uppercase character or '|' |
| `transposition` | 2 erreur(s) de compilation : Variable must start with uppercase character or '|' |
| `tryConsoleMaxTime` | => Calculation overflow (10000 derivations): task abandoned. Loop? |
| `tryShruti` | => Error reading Csound instruments file:  /home/romi/dev/bp/bp3-engine/test-dat |
| `tryflags3.html` | 19 erreur(s) de compilation : Error code 8: incorrect expression or bad derivati |
| `vina` | blocage (> 90 s sans rendre la main) |
| `vina2` | blocage (> 90 s sans rendre la main) |
| `vina3` | blocage (> 90 s sans rendre la main) |
