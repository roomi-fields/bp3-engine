# Changelog — Portage WASM (csrc/wasm/)

Évolution des fichiers WASM : `bp3_api.c`, `bp3_wasm_stubs.c`, `bp3_wasm_platform.h`.
Ces fichiers n'existent QUE dans le portage WASM — pas dans le code de Bernard.

Pour l'architecture générale, voir `WASM_PORT.md`.

---

## bp3_api.c — API JavaScript

### Nouvelles fonctions API

#### `bp3_set_timed_tokens_verbose(int v)` — verbose=2 structure tokens (wasm.9)
Nouveau niveau verbose=2 qui émet les marqueurs structurels `{`, `}`, `,` comme des pseudo-tokens
dans le flux timed tokens. Le JS peut reconstruire l'arbre polymétrique à partir de ces marqueurs.

- `{` : start = start du premier enfant, end = end du dernier enfant
- `}` : start = { start, end = { end
- `,` : start = start de la voix suivante, end = { end (parent)

Compatible : verbose=0 (sounding only) et verbose=1 (+ contrôles) sont inchangés.
Implémenté via buffer intermédiaire `emitted_buf[]` + post-pass stack-based pour résoudre les timings.

#### `bp3_set_seed(unsigned int seed)`
Set le seed aléatoire sans toucher aux autres settings. Utilise `srand(Seed)` directement.
Permet un seed override après `bp3_load_settings()` pour la reproductibilité des tests.

#### `bp3_set_write_midi(int enable)`
Active/désactive la sortie MIDI indépendamment. Nécessaire car `WriteMIDIfile=TRUE` est forcé par défaut en WASM pour activer le pipeline PlayBuffer→TimeSet. Doit être désactivé pour les grammaires purement textuelles (look-and-say, gramgene) où le MIDI causerait des erreurs.

#### `bp3_provision_file(const char* filename, const char* content)`
Remplace l'ancien `bp3_load_csound_resources()`. Écrit n'importe quel contenu dans le filesystem virtuel Emscripten. Utilisé pour tous les fichiers auxiliaires : `-mi.` (prototypes MIDI), `-or.` (orchestres), `-tb.` (time bases), `-gl.` (glossaries), `-in.` (interactive MIDI). Doit être appelé avant `bp3_load_grammar()`.

#### `bp3_set_flag(const char* name, long value)` — écriture flag JS→BP3 (wasm.10)
Permet au dispatcher JS de modifier un flag BP3 par nom. Utilisé par `@map` pour router un CC MIDI vers un flag BP3 (ex: `bp3_set_flag("intensity", 80)`). Le flag est écrit dans le même tableau `p_Flag` que BP3 utilise pour évaluer les guards — la valeur sera vue au prochain `bp3_produce()`. Retourne l'index du flag si trouvé, -1 si non trouvé, -2 si pas de flags.

#### `bp3_get_flag_names()` — liste des flags déclarés (wasm.10)
Retourne un JSON array des noms de flags déclarés dans la grammaire (`["intensity","mode",...]`). Utilisé par l'UI pour afficher les flags disponibles dans le panneau de mapping CC→flag.

#### `bp3_set_trace(int compute, int weights)` / `bp3_get_flag_state()`
Fonctions debug pour l'investigation des boucles SUB et des flags K-param. `bp3_get_flag_state()` retourne un dump JSON de l'état des flags (Jflag, Flagthere, Varweight, valeurs, noms).

#### `LoadSettingsFromString()` — Parsing JSON direct (fix corruption mémoire)
Nouvelle fonction statique dans `bp3_api.c` qui parse le JSON des settings directement depuis la string passée par JavaScript, sans passer par le filesystem virtuel Emscripten (`fopen/fputs/fclose` → `read_file(fseek/ftell/fread)` → `free`). Le round-trip fichier via MEMFS causait une corruption mémoire heap pour les gros JSON (40+ clés), ce qui corrompait `p_DefaultChannel` et d'autres structures allouées par `GiveSpace`. Symptôme : `'X' has channel 112. Should be 1..16`, puis TimeSet ABORT (-4). Le pattern non-déterministe (N dummy keys OK, N+1 FAIL, N+2 OK) confirmait une corruption heap. `bp3_load_settings()` utilise maintenant cette fonction au lieu de `LoadSettings()` de Bernard.

### Modifications API existantes

#### `bp3_init()` — Init conditionnelle
`LoadSettings()` interne n'est appelé qu'au premier init (`!bp3_initialized`). Évite la ré-initialisation redondante quand l'état interne existe déjà.

#### `bp3_load_settings_params()` — Fix seed
Remplacé `ReseedOrShuffle(seed)` par `srand(Seed)` direct. L'ancien calculait `(Seed+seed)%32768`, donnant un seed effectif différent (seed=1 → srand(2) au lieu de srand(1)).

#### `bp3_load_object_prototypes()` — Simplifié
Suppression du stripping de tags HTML (plus nécessaire). Écriture directe du contenu `-mi.`, appel à `LoadObjectPrototypes()`.

#### `bp3_produce()` — Improvize
Le flag `Improvize` n'est plus forcé à FALSE. En mode non-rtMIDI (WASM), `ProduceItems` boucle jusqu'à `MaxItemsProduce` et retourne ABORT — c'est le comportement normal, pas une erreur. L'accumulateur timed tokens est reset au début (`wasm_accum_count = 0`).

#### `bp3_set_timed_tokens_verbose(int verbose)`
Contrôle le contenu de `bp3_get_timed_tokens()` :
- `0` (défaut) : seulement les tokens sonores (notes MIDI, terminaux nommés). Exclut les tokens de contrôle (`_vel()`, `_chan()`, `_staccato()`, etc.), les silences objet (`-` avec `object==1`) et les silences gap (insertés quand `start > prev_end`).
- `1` : tout inclus — contrôles, silences, gaps. Utile pour le dispatcher BPscript qui a besoin des contrôles pour le routage runtime.

Appeler avant `bp3_produce()`. Le flag persiste entre les appels.

#### `bp3_get_timed_tokens()` — ExpandKey + accumulateur + mode verbose
Lit depuis l'accumulateur multi-items (`wasm_accum`) quand disponible (mode Improvize), sinon depuis `p_Instance` directement. Applique `TransposeKey()` et `ExpandKey()` avec le flag `lastistranspose` pour l'ordre des opérations. Respecte le flag `verbose` pour inclure ou exclure contrôles et silences.


### Constantes modifiées

| Constante | Avant | Après | Raison |
|-----------|-------|-------|--------|
| MaxMIDIMessages | 1000 | 50000 | Insuffisant pour grammaires complexes (Visser3: 1646 events) |
| MIDI_JSON_BUF_SIZE | 512 KB | 4 MB | Support jusqu'à 50K événements MIDI |

### Supprimé

- `bp3_set_object_duration()` et système de durées différées (`deferred_durations[]`, `apply_deferred_durations()`) — scaffold plus utilisé.

---

## Makefile.emscripten

### bp3_random.c ajouté à BP3_SRCS (2026-04-02)

Le RNG portable (`bp3_random.c`) n'était pas compilé dans le build WASM → erreurs linker `undefined symbol: bp3_rand/bp3_srand`. Ajouté à la liste BP3_SRCS.

### bp3_get_timed_tokens — mode verbose optionnel (2026-04-02)

`bp3_get_timed_tokens()` incluait systématiquement les tokens de contrôle (`_vel()`, `_chan()`, `_staccato()`) et les silences gap (`-`) dans la sortie. Ça gonflait le nombre de tokens par rapport au natif (S1) qui ne compte que les notes MIDI.

Ajout de `bp3_set_timed_tokens_verbose(int)` :
- `0` (défaut) : seulement les tokens sonores (notes, terminaux nommés)
- `1` : tout inclus (contrôles, silences, gaps) — utile pour le dispatcher BPscript

### bp3_load_object_prototypes exporté (2026-04-02)

`_bp3_load_object_prototypes` ajouté à EXPORTED_FUNCTIONS. L'API existait dans `bp3_api.c` mais n'était pas accessible depuis JavaScript. Nécessaire pour charger les prototypes `-so.*` (sound-object durations) dans les grammaires qui les utilisent (koto3, flags, ek-do-tin, etc.).

### MAXIMUM_MEMORY=4GB (2026-04-03)

`MAXIMUM_MEMORY` passé de 2GB (défaut Emscripten) à 4GB (`4294967296`). La grammaire `watch` (Watch_What_Happens) alloue une phase table de ~3.6GB dans `FillPhaseDiagram.c` (4046 lignes × 232,915 entrées × 4 bytes). Sans ce changement, l'allocation échouait silencieusement et la grammaire produisait 0 notes.

Note : dans `Makefile` unifié (pas Makefile.emscripten), ajouté dans `WASM_LDFLAGS`.

---

## bp3_wasm_stubs.c — Stubs et implémentations

### RNG — Évolution glibc → MSVC LCG portable

**Phase 1 (2026-03-31) :** Remplacement du LCG simple de musl par le générateur TYPE_3 glibc (degré 31) pour aligner WASM sur le natif Linux.

**Phase 2 (2026-04-02) :** Suppression du TYPE_3 glibc, remplacé par `bp3_random.c` dans `csrc/bp3/` — LCG MSVC portable (`seed * 214013 + 2531011`, `BP3_RAND_MAX = 32767`). Tous les appels `rand()`/`srand()`/`RAND_MAX` dans le moteur remplacés par `bp3_rand()`/`bp3_srand()`/`BP3_RAND_MAX`. Aligne natif+WASM sur bp.exe Windows. L'ancienne implémentation glibc dans `bp3_wasm_stubs.c` est supprimée. Les appels `srand()` dans `bp3_api.c` remplacés par `bp3_srand()`.

### PlayBuffer1 — Pipeline complet

Séquence : `PolyMake()` → `MakeEventSpace()` → scan buffer → `TimeSet()` → extraction MIDI → accumulation.

#### Guard WriteMIDIfile (remplace T4 guard)

Alignement sur le natif : TimeSet n'est appelé que si `WriteMIDIfile || OutCsound`. Les grammaires texte appellent `bp3_set_write_midi(0)` avant `bp3_produce()`, ce qui skip TimeSet entièrement — identique au comportement natif où `PlayBuffer` n'est pas appelé sans MIDI output.

**Historique T4 guard (supprimé) :** Un guard basé sur les types de tokens (T3+/T4) avait été ajouté puis retiré. Remplacé par la vérification `WriteMIDIfile` qui est le vrai mécanisme natif.

#### Extraction MIDI de p_Instance

Pour chaque instance `k` dans `p_Instance[2..kmax]` :
- Skip si `object < 2` (silence/marqueur)
- Notes simples : `object >= 16384` → `midiKey = object - 16384`
- Sound objects complexes : skip (pas encore supporté)
- **TransposeKey + ExpandKey** : appliqués selon `lastistranspose` flag (match natif MakeSound.c:421-423)
- **Skip vel=0** : en natif, vel=0 = NoteOff (note silencieuse, ex: `_vel(0) do#4`). Cast `(unsigned char)` ajouté — le champ `char velocity` de p_Instance est signé, les valeurs 128-255 devenaient négatives et étaient filtrées à tort.
- **Déduplication pré-MPE** : tableau local `(key, time)` tracké avant le remapping MPE. Nécessaire car MPE assigne des canaux uniques par note — la dédup post-MPE comparerait des canaux différents et raterait les doublons. Les séquences polymétriques (nmax) dupliquent chaque note — le natif émet une seule fois. **Allocation dynamique (wasm.10)** : les tableaux dedup sont alloués à `kmax` entrées quand `kmax > DEDUP_STATIC_MAX` (256). Corrige visser5 (+30 doublons non détectés au-delà de 256 entrées). Fallback sur tableaux statiques si malloc échoue.
- **MPE microtonal pipeline** : match natif `MIDIstuff.c:SendToDriver()`. Quand `MIDImicrotonality && scale != 0` :
  1. `FindScale(scale)` → index dans `Scale[]` (chargé par `LoadTonality()`)
  2. `correction = Scale[i_scale].deviation[midiKey] + Scale[i_scale].blockkey_shift[blockkey]` (cents)
  3. Si `|correction| >= 100` : shift de `floor(correction/100)` semitones. Si key hors range [0,127] après shift : émis sans correction (match natif qui avertit "pitchbender out of range" mais joue quand même)
  4. `wasm_MPE_assign()` : canal unique (1-15) par note+scale. Tracking via tables statiques `wasm_MPEnote/MPEscale/MPEpitch`. Reset au début de chaque PlayBuffer1.
  5. PitchBend event émis avant NoteOn avec la correction restante en cents

#### Offset MIDI inter-items (`wasm_midi_time_offset`)

En natif, `MakeSound.c` accumule `LastTime += max_endtime` entre items et offset chaque item via `t0 = LastTime / Time_res * Time_res`. PlayBuffer1 étant appelé une fois par item, l'offset était manquant en WASM — tous les items stackaient à time=0.

Fix : variable globale `wasm_midi_time_offset` (reset à 0 dans `bp3_produce()`). Après extraction MIDI de chaque item, `wasm_midi_time_offset += midi_item_max_end`. Les starttime/endtime de chaque note sont décalés de cet offset.

**Grammaires corrigées :** livecode1, ruwet (CONTENT_DIFF→EXACT), alan-dice, beatrix-dice, mozart-dice (CONTENT_DIFF→TIMING_DIFF)

#### Accumulation multi-items (Improvize + AllItems)

Condition étendue de `Improvize && p_Instance != NULL && kmax > 1` à `p_Instance != NULL && kmax > 1`. L'accumulator couvre maintenant les grammaires AllItems (non-Improvize) multi-items.

Les instances sont copiées dans `wasm_accum[]` avec :
- Offset temporel cumulé (`wasm_accum_time_offset`)
- Déduplication par item (même object+starttime+channel+transposition)
- Skip vel=0
- Buffer growable (realloc × 2)
- Tracking `item_max_end` pour calculer l'offset du prochain item

#### ItemNumber matching natif

```c
if(WriteMIDIfile || OutCsound) {
    ItemNumber++;
    if((MaxItemsProduce > 0) && ItemNumber > MaxItemsProduce) {
        return OK;
    }
}
```

Match le natif `MakeSound.c:122-128`.

### Stubs simplifiés

| Fonction | Avant | Après |
|----------|-------|-------|
| `FormatMIDIstream()` | ~80 lignes portées de MIDIstuff.c | `return OK;` (MIDI généré déjà propre) |
| `MIDItoPrototype()` | ~70 lignes portées de MIDIstuff.c | `return OK;` |
| Fonctions GUI/MIDI hw | Stubs purs | Inchangés |

### bp3_wasm_platform.h

Ajout de `#include <emscripten.h>` pour `emscripten_log()` et les macros runtime Emscripten.

---

## Résumé des corrections de parité MIDI

| Fix | Grammaires corrigées | Mécanisme |
|-----|---------------------|-----------|
| RNG glibc | Toutes les RND/SUB | Séquence aléatoire identique natif/WASM |
| Dedup polymetric | 765432, visser3, not-reich | Suppression doublons par séquence |
| MaxItemsProduce | Improvize grammaires | Nombre d'items correct |
| vel=0 skip | acceleration, ames | Notes silencieuses non émises |
| ItemNumber match | Improvize + MIDI | Comptage identique au natif |
| WriteMIDIfile guard | kss2, negative-context, texte | TimeSet skip si pas MIDI/Csound |
| ExpandKey | visser5, visser-waves | Inversion/expansion des clés MIDI |
| Accumulateur multi-items | bells, kss2, livecode1 | Multi-items avec offset temporel |
| Offset MIDI inter-items | livecode1, ruwet, alan-dice, etc. | Cumul starttime entre items |
| NoTracePath guard | vina, vina2, watch | Désactive graphiques quand pas de trace path |
| MAXIMUM_MEMORY 4GB | watch | Phase diagram 3.6GB dans adresse 32-bit |
| vel unsigned cast | visser-shapes | `(unsigned char)` pour velocity signé >127 |
| MPE microtonal pipeline | tryShruti | deviation+blockkey_shift, semitone shift, canaux MPE |
| Dedup pré-MPE | tryShruti | Dédup avant remapping pour éviter faux doublons par canal |
| Fallback MPE out-of-range | tryShruti | Notes hors range après shift → émises sans correction (match natif) |
| Tonalité avant grammaire | tryShruti | s2_wasm_orig.cjs: LoadTonality() avant LoadGrammar() |
| Dedup dynamique | visser5 | Tableaux dedup alloués dynamiquement (kmax) au lieu de DEDUP_STATIC_MAX=256 |
| NoteOff-before-re-trigger | visser-shapes | Tronque NoteOff quand la même clé+canal est retriggée avant la fin — match natif p_keyon/SendToDriver. Corrige chevauchement de notes polymétriques |
| Zerostart REMOVED (wasm.15) | ames, watch | Le zerostart soustrayait le min time local, détruisant les silences initiaux grammaticaux (ames: 666ms→0ms, watch: 1590ms→0ms). p_Instance.starttime inclut déjà les silences — pas besoin de normalisation |
| Dedup keep-longest (#33) | visser5, visser-waves | Quand deux instances polymétriques du même pitch commencent au même moment, garde la plus longue durée (met à jour le NoteOff). Match le comportement natif p_keyon (NoteOff au dernier release). visser5: 16 diffs → 1 |
| Kpress quantization offset (#35) | acceleration, visser3, visser-shapes, watch | Quand Kpress≥2, TimeSet décale T[0] d'un quantum. Le WASM soustrait `Quantization` (10ms) une fois au premier item. Corrigé : l'ancien code soustrayait min_start (strippait le silence initial grammatical de watch=1590ms). |
| T47 SSO detection (#38) | (aucune régression) | Scan pp_buff pour tags T47 après PolyMake, construit wasm_is_sso[]. bp3_api.c filtre les non-terminaux (p_Type & 1 == 0) SAUF les SSO marqués T47. Prépare l'émission correcte des silent sound objects (variables restantes traitées comme SSO par Bernard v3.3.19). |

**Score parité wasm.4 (2026-04-06) :** S1 vs S2: 26E/9T/0C/1Count. S2 vs S3: 29E/4T/3C. S3 vs S4: 33E/1T/2Count. S4: 36/36. S5: 33/36.

**Score parité wasm.15 :** 27/37 EXACT, 5 TIMING_DIFF within tolerance, 4 TIMING_DIFF vrais, 1 COUNT_DIFF, seed=1.

**Score parité wasm.20 (2026-04-05) :** S0=36/36, S1=36/36 (kss2 ASLR #39, workaround setarch), S2=37/37 (S1 vs S2: 23E/12T/2C), S3=36/36 (S2 vs S3: 30E/4T/3C), S4=36/36 (S3 vs S4: 33E/1T/2C). Non-reg wasm.20 vs wasm.18 = 0 régression. 36 grammaires actives (bells skip).

### Classification TIMING_DIFF (analyse v3.3.18-wasm.15)

| Catégorie | Grammaires | Diffs | Cause |
|-----------|-----------|------|-------|
| Within tolerance (≤3ms) | 765432, drum, alan-dice, beatrix-dice, mozart-dice | 0 (maxΔ≤3ms) | Round-trip MIDI tick dans parse_midi.py |
| FillPhaseDiagram (bug natif) | not-reich | 13 (maxΔ=34ms) | Arrondi triolets GCC diverge après 82s — FEEDBACK_BERNARD #32 |
| Durée extension (natif > WASM) | visser5, visser-waves | 32 / 3 (maxΔ=146/50ms) | Natif prolonge durées au-delà de p_Instance.endtime (mécanisme MakeSound non répliqué) — FEEDBACK_BERNARD #33 |
| Offset +10ms + durée extension | watch | 66 (maxΔ=670ms) | Combinaison offset initial +10ms (Time_res) et durée extension MakeSound |

**Note :** Les dice grammaires (mozart/alan/beatrix-dice) montrent un drift cumulé de ±1413-2838ms mais maxΔ=3ms : les timestamps WASM (TimeSet direct) sont plus précis que les timestamps S1 (reconvertis depuis ticks MIDI avec ratio 1.002673:1). Ce n'est pas un drift du moteur.

**tryShruti** (COUNT_DIFF +1) : divergence microtonale. Le pipeline MPE est implémenté en WASM (build wasm.8+) : deviation + blockkey_shift, semitone shift, canaux MPE uniques, PitchBend. 79/80 notes matchent exactement. La 80e note (raw key 70 = Bb4 dans `_retro Full_scale`) est émise par le WASM mais pas par le natif. Le natif la filtre probablement via sa logique complexe `p_keyon`/channel-tracking dans MakeSound.c (code non disponible dans le portage). Différence minimale (1 note sur 80 = 1.25%).

### Historique des builds

| Build | Date | Contenu |
|-------|------|---------|
| v3.3.18-wasm.1 | 2026-04-03 09:16 | Premier build WASM unifié (Makefile 3 targets, build.sh) |
| v3.3.18-wasm.2 | 2026-04-03 15:48 | LoadSettingsFromString (bypass MEMFS heap corruption) |
| v3.3.18-wasm.3 | 2026-04-03 20:07 | +MAXIMUM_MEMORY 4GB, offset MIDI inter-items, accum AllItems |
| v3.3.18-wasm.4 | 2026-04-03 20:47 | +vel `(unsigned char)` cast (visser-shapes fix) |
| v3.3.18-wasm.5 | 2026-04-03 21:30 | +RNG portable (bp3_random.c) dans build WASM |
| v3.3.18-wasm.6 | 2026-04-03 22:15 | +debug timing (quantification Time_res — sans effet) |
| v3.3.18-wasm.7 | 2026-04-03 22:56 | Nettoyage : suppression quantification inutile, comparateur delta-based |
| v3.3.18-wasm.8 | 2026-04-03 23:10 | +MPE pipeline (deviation, semitone shift, canaux, PitchBend) |
| v3.3.18-wasm.9 | 2026-04-04 00:15 | +Dedup pré-MPE, fallback out-of-range, tonalité avant grammaire |
| v3.3.18-wasm.10 | 2026-04-04 08:51 | +Dedup dynamique (kmax au lieu de 256 statique) — visser5 COUNT_DIFF→TIMING_DIFF |
| v3.3.18-wasm.11 | 2026-04-04 09:12 | +Normalisation time_offset MIDI — visser3→EXACT, +10ms offset éliminé |
| v3.3.18-wasm.12 | 2026-04-04 09:35 | +Zerostart normalization (BUG: cassait Improvize grammars — corrigé wasm.14) |
| v3.3.18-wasm.13c | 2026-04-04 09:50 | +NoteOff-before-re-trigger — visser-shapes→EXACT (BUG v13/13b : algo trop agressif) |
| v3.3.18-wasm.14 | 2026-04-04 09:52 | Fix zerostart pour multi-items + NoteOff-retrigger |
| v3.3.18-wasm.15 | 2026-04-04 10:38 | Zerostart REMOVED — ames EXACT, watch offset corrigé |
| v3.3.18-wasm.16 | 2026-04-04 16:07 | S5 transpiler pipeline (bp3_set_timed_tokens_verbose, prototypes) |
| v3.3.18-wasm.17 | 2026-04-04 16:57 | S5 fixes: @improvize/@allitems, flag spacing ASCII, @timepatterns |
| v3.3.18-wasm.18 | 2026-04-04 18:06 | Runtime controls: transpose, scale, rotate, keyxpand + dynamic dispatcher |
| v3.3.18-wasm.19 | 2026-04-05 | Intégration Bernard v3.3.19 (FillPhaseDiagram MakeEmptyTokensSilent refactoré, etc.) — build manuel, non fiable |
| v3.3.18-wasm.20 | 2026-04-05 14:33 | Rebuild propre via build.sh. Merge Bernard v3.3.19 + tous nos fixes WASM. Non-reg 36/36 EXACT S0→S4. |
| v3.3.19-wasm.1 | 2026-04-05 | Build propre Bernard v3.3.19 via build.sh, publish GitHub |
| v3.3.19-wasm.2 | 2026-04-06 | Fix #33 dedup keep-longest (visser5), traces BP3_DEBUG conditionnées |
| v3.3.19-wasm.3 | 2026-04-06 | Fix #35 Kpress quantization offset (acceleration, visser3, visser-shapes → EXACT) |
| v3.3.19-wasm.4 | 2026-04-06 | Bernard T47 intégré + T47 SSO detection WASM (wasm_is_sso[]). Non-reg 36/36. **build actuel** |

Note : les builds v3.3.19-wasm.* qui existaient étaient mal nommés — ils étaient basés sur la branche `wasm` (fork de v3.3.13+v3.3.15), pas sur le v3.3.19 de Bernard. Renommés en v3.3.18-wasm.3/4.

Note 2 : à partir de wasm.19, `csrc/bp3/` = `source/BP3/` (Bernard v3.3.19). Tous nos fixes moteur (#16-#31) ont été intégrés par Bernard. Le diff `csrc/bp3/` vs HEAD ne contient plus que du code Bernard.

---

## Fix moteur appliqué à csrc/bp3/ (affecte WASM)

### ConsoleMain.c + SaveLoads1.c — Guard NoTracePath graphiques (2026-04-02)

**Bug :** Les settings JSON de Bernard (ex: `-se.Vina`) activent `ShowObjectGraph=1` → `SaveLoads1.c:758` force `ShowGraphic=TRUE`. En console/WASM sans trace path, `imagePtr` reste NULL → segfault dans `Graphic.c:1388` ou boucle infinie dans le pipeline graphique.

**Cause :** `LoadSettings()` est appelé AVANT `PrepareTraceDestination()` dans `ConsoleMain.c`. Le guard `NoTracePath` dans `SaveLoads1.c:704` était commenté ET inopérant (NoTracePath pas encore positionné).

**Fix :**
1. `ConsoleMain.c` : guard `if(NoTracePath) { ShowObjectGraph = ShowPianoRoll = ShowGraphic = FALSE; }` ajouté après `PrepareTraceDestination()`, avant le switch d'action
2. `SaveLoads1.c` : décommentage du guard ligne 704 (double protection)

**Grammaires débloquées :** vina (segfault→6 MIDI), vina2 (segfault→texte OK), Watch_What_Happens (timeout→2106 MIDI en 81s)
