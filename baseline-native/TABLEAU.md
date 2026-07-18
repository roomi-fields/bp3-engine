# Baseline native — tableau par grammaire

**v6** — figée le 2026-07-19 · binaire bp3 v3.4.4 (graphics-for-BP3) · graine 1

`action` = ce que fait le moteur nativement. Les deux voies doivent répliquer **la même action**.

- **single** = la grammaire *joue* un morceau : une réalisation, un item, graine fixe.
- **produce-all** = production purement symbolique, le moteur énumère l'ensemble.

## Les 90 qui produisent

| grammaire | action | mode natif | jetons | mots | items | énumération |
|---|---|---|---|---|---|---|
| `all-items` | produce-all | TEXTE | 0 | 36 | 12 | acceptée (12 items) |
| `all-items1` | produce-all | TEXTE | 0 | 36 | 12 | acceptée (12 items) |
| `checkBT` | produce-all | TEXTE | 0 | 4 | 1 | acceptée (1 items) |
| `destru` | produce-all | TEXTE | 0 | 48 | 2 | acceptée (2 items) |
| `dhadhatite` | produce-all | TEXTE | 0 | 2 | 1 | acceptée (1 items) |
| `dhadhatite1` | produce-all | TEXTE | 0 | 2 | 1 | acceptée (1 items) |
| `dhadhatite_v2` | produce-all | TEXTE | 0 | 2 | 1 | acceptée (1 items) |
| `dhati2` | produce-all | TEXTE | 0 | 65 | 1 | acceptée (1 items) |
| `dhati3` | produce-all | TEXTE | 0 | 65 | 1 | acceptée (1 items) |
| `dhin1` | produce-all | TEXTE | 0 | 1940 | 20 | acceptée (20 items) |
| `ek-do-tin` | produce-all | TEXTE | 0 | 99 | 1 | acceptée (1 items) |
| `flags` | produce-all | TEXTE | 0 | 400 | 20 | acceptée (20 items) |
| `gramgene1` | produce-all | TEXTE | 0 | 142 | 25 | acceptée (25 items) |
| `koto1` | produce-all | TEXTE | 0 | 8 | 1 | acceptée (1 items) |
| `koto2` | produce-all | TEXTE | 0 | 8 | 1 | acceptée (1 items) |
| `look-and-say` ⚠ | produce-all | TEXTE | 0 | 1 | 1 | acceptée (1 items) |
| `polyphony1` | produce-all | TEXTE | 0 | 76 | 25 | acceptée (25 items) |
| `repeat` | produce-all | TEXTE | 0 | 40 | 5 | acceptée (5 items) |
| `templates` | produce-all | TEXTE | 0 | 25 | 5 | acceptée (5 items) |
| `testHO2` | produce-all | TEXTE | 0 | 4 | 1 | acceptée (1 items) |
| `tryAllItems0` | produce-all | TEXTE | 0 | 20 | 8 | acceptée (8 items) |
| `tryAllItems1` | produce-all | TEXTE | 0 | 36 | 12 | acceptée (12 items) |
| `tryCsoundObjects` | produce-all | TEXTE | 0 | 2 | 1 | acceptée (1 items) |
| `tryLIN` | produce-all | TEXTE | 0 | 25 | 25 | acceptée (25 items) |
| `tryObjects` | produce-all | TEXTE | 0 | 18 | 1 | acceptée (1 items) |
| `tryPatternGrammar` | produce-all | TEXTE | 0 | 52 | 4 | acceptée (4 items) |
| `tryflags2` | produce-all | TEXTE | 0 | 25 | 25 | acceptée (25 items) |
| `tryflags3` | produce-all | TEXTE | 0 | 25 | 25 | acceptée (25 items) |
| `trytemplates` | produce-all | TEXTE | 0 | 98 | 25 | acceptée (25 items) |
| `trytemplates2` | produce-all | TEXTE | 0 | 20 | 4 | acceptée (4 items) |
| `765432` | single | MIDI | 823 | 1405 | 1 | — (elle joue) |
| `Alarm` | single | TEXTE | 0 | 26 | 1 | **refusée** (SUB) |
| `Djinns` | single | MIDI | 895 | 851 | 1 | — (elle joue) |
| `Mozartexpression` | single | MIDI | 251 | 27 | 1 | — (elle joue) |
| `MyMelody` | single | MIDI | 31 | 31 | 1 | — (elle joue) |
| `Nadaka-1er-essai` | single | MIDI | 4 | 4 | 1 | — (elle joue) |
| `PP` | single | MIDI | 2 | 9 | 1 | — (elle joue) |
| `acceleration` | single | MIDI | 78 | 100 | 1 | — (elle joue) |
| `acceleration_v2` | single | MIDI | 78 | 100 | 1 | — (elle joue) |
| `alan-dice` | single | MIDI | 270 | 181 | 1 | — (elle joue) |
| `ames` | single | MIDI | 11 | 7 | 1 | — (elle joue) |
| `asymmetric` | single | TEXTE | 0 | 15 | 1 | **vide** |
| `beatrix-dice` | single | MIDI | 270 | 179 | 1 | — (elle joue) |
| `bells` | single | MIDI | 16 | 17 | 1 | — (elle joue) |
| `check&` | single | MIDI | 4 | 6 | 1 | — (elle joue) |
| `checkSUB` | single | MIDI | 10 | 13 | 1 | — (elle joue) |
| `checkSUB.new` | single | MIDI | 10 | 13 | 1 | — (elle joue) |
| `checkSUB1` | single | TEXTE | 0 | 2 | 1 | **refusée** (SUB) |
| `checkVolMasterSlave` | single | MIDI | 6 | 12 | 1 | — (elle joue) |
| `dhati` | single | MIDI | 23 | 144 | 1 | — (elle joue) |
| `doeslittle` | single | MIDI | 7 | 11 | 1 | — (elle joue) |
| `drum` | single | MIDI | 12 | 23 | 1 | — (elle joue) |
| `gramgene2` | single | TEXTE | 0 | 78 | 1 | **bloquée** > 90 s |
| `graphics` | single | MIDI | 6 | 7 | 1 | — (elle joue) |
| `harmony` | single | MIDI | 20 | 20 | 1 | — (elle joue) |
| `koto3` | single | MIDI | 2 | 15 | 1 | — (elle joue) |
| `kss2` | single | MIDI | 97 | 138 | 1 | — (elle joue) |
| `livecode1` | single | MIDI | 27 | 23 | 1 | — (elle joue) |
| `livecode2` | single | MIDI | 29 | 1048558 | 1 | — (elle joue) |
| `major-minor` | single | MIDI | 24 | 2 | 1 | — (elle joue) |
| `mohanam` | single | MIDI | 27 | 41 | 1 | — (elle joue) |
| `mozart-dice` | single | MIDI | 269 | 172 | 1 | — (elle joue) |
| `nadaka` | single | MIDI | 714 | 1007 | 1 | — (elle joue) |
| `negative-context` | single | MIDI | 6 | 6 | 1 | — (elle joue) |
| `not-reich` | single | MIDI | 580 | 565 | 1 | — (elle joue) |
| `one-scale` | single | MIDI | 6 | 6 | 1 | — (elle joue) |
| `ruwet` | single | MIDI | 126 | 157 | 1 | — (elle joue) |
| `shapes-rhythm` | single | MIDI | 1952 | 4685 | 1 | — (elle joue) |
| `simpletemplates` | single | MIDI | 7 | 11 | 1 | — (elle joue) |
| `testNC1` | single | MIDI | 6 | 7 | 1 | — (elle joue) |
| `testTie7` | single | MIDI | 2 | 40 | 1 | — (elle joue) |
| `time-patterns` | single | MIDI | 8 | 13 | 1 | — (elle joue) |
| `transposition1` | single | MIDI | 75 | 107 | 1 | — (elle joue) |
| `transposition3` | single | MIDI | 66 | 30 | 1 | — (elle joue) |
| `tryGOTO` | single | TEXTE | 0 | 1 | 1 | **refusée** (SUB) |
| `tryKeyMap` | single | MIDI | 392 | 450 | 1 | — (elle joue) |
| `tryKeyXpand` | single | MIDI | 91 | 120 | 1 | — (elle joue) |
| `tryMIDIfile` | single | MIDI | 8 | 9 | 1 | — (elle joue) |
| `tryRagas` | single | MIDI | 42 | 1048572 | 1 | — (elle joue) |
| `tryRotate` | single | MIDI | 65 | 67 | 1 | — (elle joue) |
| `trySerial` | single | MIDI | 8 | 7 | 1 | — (elle joue) |
| `trySrand` | single | MIDI | 25 | 37 | 1 | — (elle joue) |
| `tryTicks` | single | MIDI | 16 | 16 | 1 | — (elle joue) |
| `tryhomomorphism` | single | MIDI | 6 | 12 | 1 | — (elle joue) |
| `tunings` | single | MIDI | 16 | 16 | 1 | — (elle joue) |
| `visser-shapes` | single | MIDI | 2086 | 2553 | 1 | — (elle joue) |
| `visser-waves` | single | MIDI | 365 | 433 | 1 | — (elle joue) |
| `visser3` | single | MIDI | 401 | 770 | 1 | — (elle joue) |
| `visser5` | single | MIDI | 1152 | 1822 | 1 | — (elle joue) |
| `watch` | single | MIDI | 2105 | 5122 | 1 | — (elle joue) |

⚠ `look-and-say` — production degeneree : la sortie est le seul terminal de depart ("'1'"), aucune regle n'a ete appliquee. Le bug moteur #51 (all weights are nil) reste actif ; ne pas s'en servir comme reference.

## Doublons — 2 entrées qui ne sont pas des grammaires à mesurer

| entrée | doublon de | preuve |
|---|---|---|
| `a.html` | `checkSUB1` | règles identiques une fois le balisage HTML retiré |
| `tryflags3.html` | `tryflags3` | règles identiques une fois le balisage HTML retiré |

## Les 21 qui ne produisent pas

| grammaire | cause |
|---|---|
| `Nadaka1` | => Cannot produce items because all weights are nil in gram#1 |
| `Rajeev` | 27 erreur(s) de compilation : Variable must start with uppercase character or '| |
| `a` | 4 erreur(s) de compilation : Error code 52: Missing slash after /flag/ in gram#2 |
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
| `transposition` | 2 erreur(s) de compilation : Variable must start with uppercase character or '|' |
| `tryConsoleMaxTime` | => Calculation overflow (10000 derivations): task abandoned. Loop? |
| `tryShruti` | => Error reading Csound instruments file:  /home/romi/dev/bp/bp3-engine/test-dat |
| `vina` | blocage (> 90 s sans rendre la main) |
| `vina2` | blocage (> 90 s sans rendre la main) |
| `vina3` | blocage (> 90 s sans rendre la main) |
