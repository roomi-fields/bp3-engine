# Changelog — Portage WASM (csrc/wasm/)

Évolution des fichiers WASM : `bp3_api.c`, `bp3_wasm_stubs.c`, `bp3_wasm_platform.h`.
Ces fichiers n'existent QUE dans le portage WASM — pas dans le code de Bernard.

Pour l'architecture générale, voir `WASM_PORT.md`.

---

## bp3_api.c — API JavaScript

### Nouvelles fonctions API

#### `bp3_set_seed(unsigned int seed)`
Set le seed aléatoire sans toucher aux autres settings. Utilise `srand(Seed)` directement.
Permet un seed override après `bp3_load_settings()` pour la reproductibilité des tests.

#### `bp3_set_write_midi(int enable)`
Active/désactive la sortie MIDI indépendamment. Nécessaire car `WriteMIDIfile=TRUE` est forcé par défaut en WASM pour activer le pipeline PlayBuffer→TimeSet. Doit être désactivé pour les grammaires purement textuelles (look-and-say, gramgene) où le MIDI causerait des erreurs.

#### `bp3_provision_file(const char* filename, const char* content)`
Remplace l'ancien `bp3_load_csound_resources()`. Écrit n'importe quel contenu dans le filesystem virtuel Emscripten. Utilisé pour tous les fichiers auxiliaires : `-mi.` (prototypes MIDI), `-or.` (orchestres), `-tb.` (time bases), `-gl.` (glossaries), `-in.` (interactive MIDI). Doit être appelé avant `bp3_load_grammar()`.

#### `bp3_set_trace(int compute, int weights)` / `bp3_get_flag_state()`
Fonctions debug pour l'investigation des boucles SUB et des flags K-param. `bp3_get_flag_state()` retourne un dump JSON de l'état des flags (Jflag, Flagthere, Varweight, valeurs, noms).

### Modifications API existantes

#### `bp3_init()` — Init conditionnelle
`LoadSettings()` interne n'est appelé qu'au premier init (`!bp3_initialized`). Évite la ré-initialisation redondante quand l'état interne existe déjà.

#### `bp3_load_settings_params()` — Fix seed
Remplacé `ReseedOrShuffle(seed)` par `srand(Seed)` direct. L'ancien calculait `(Seed+seed)%32768`, donnant un seed effectif différent (seed=1 → srand(2) au lieu de srand(1)).

#### `bp3_load_object_prototypes()` — Simplifié
Suppression du stripping de tags HTML (plus nécessaire). Écriture directe du contenu `-mi.`, appel à `LoadObjectPrototypes()`.

#### `bp3_produce()` — Improvize
Le flag `Improvize` n'est plus forcé à FALSE. En mode non-rtMIDI (WASM), `ProduceItems` boucle jusqu'à `MaxItemsProduce` et retourne ABORT — c'est le comportement normal, pas une erreur. L'accumulateur timed tokens est reset au début (`wasm_accum_count = 0`).

#### `bp3_get_timed_tokens()` — ExpandKey + accumulateur
Lit depuis l'accumulateur multi-items (`wasm_accum`) quand disponible (mode Improvize), sinon depuis `p_Instance` directement. Applique `TransposeKey()` et `ExpandKey()` avec le flag `lastistranspose` pour l'ordre des opérations.

### Constantes modifiées

| Constante | Avant | Après | Raison |
|-----------|-------|-------|--------|
| MaxMIDIMessages | 1000 | 50000 | Insuffisant pour grammaires complexes (Visser3: 1646 events) |
| MIDI_JSON_BUF_SIZE | 512 KB | 4 MB | Support jusqu'à 50K événements MIDI |

### Supprimé

- `bp3_set_object_duration()` et système de durées différées (`deferred_durations[]`, `apply_deferred_durations()`) — scaffold plus utilisé.

---

## bp3_wasm_stubs.c — Stubs et implémentations

### RNG glibc-compatible

Remplacement du LCG simple de musl par le générateur TYPE_3 non-linéaire à rétroaction additive de glibc (degré 31). Musl et glibc produisent des séquences complètement différentes pour le même seed — causant des divergences sur toutes les grammaires avec sélection pondérée (SUB, RND).

```c
static int32_t glibc_state[DEG_3 + 1];  // 31+1 entries
static int glibc_fptr = SEP_3;           // 3
static int glibc_rptr = 0;
```

`srand()` : seed → warm-up de 310 itérations (identique à glibc).
`rand()` : `state[fptr] += state[rptr]` → shift right → mask.

### PlayBuffer1 — Pipeline complet

Séquence : `PolyMake()` → `MakeEventSpace()` → scan buffer → `TimeSet()` → extraction MIDI → accumulation.

#### T4 guard (scan buffer avant TimeSet)

Après `PolyMake`, scan le buffer pour les types de tokens. Si AUCUN token T3+ ou T4 n'est trouvé (que des T0/T1/T2 structurels), skip TimeSet → `FillPhaseDiagram` crasherait sur ces buffers en WASM.

```c
int t4_count = 0, known_count = 0;
for(scan = 0; scan < expanded_len; scan += 2) {
    tokenbyte m = (**pp_buff)[scan];
    if(m == T4) t4_count++;
    else if(m >= T3) known_count++;
}
if(known_count == 0 && t4_count == 0 && expanded_len > 0) {
    result = OK;
    goto SORTIR;
}
```

**Itérations :**
1. Guard strict `has_vars → skip` — bloquait kss2 (7 variables parmi ~100 tokens)
2. Guard supprimé — crashait negative-context (OOB)
3. Guard ratio `t4 >= known` — negative-context crashait encore
4. Guard `known==0 && t4==0` — **solution finale**

#### Extraction MIDI de p_Instance

Pour chaque instance `k` dans `p_Instance[2..kmax]` :
- Skip si `object < 2` (silence/marqueur)
- Notes simples : `object >= 16384` → `midiKey = object - 16384`
- Sound objects complexes : skip (pas encore supporté)
- **TransposeKey + ExpandKey** : appliqués selon `lastistranspose` flag (match natif MakeSound.c:421-423)
- **Skip vel=0** : en natif, vel=0 = NoteOff (note silencieuse, ex: `_vel(0) do#4`)
- **Déduplication** : scan `eventStack[eventCountAtItemStart..eventCount]` pour même note+time+channel déjà émis. Les séquences polymétriques (nmax) dupliquent chaque note — le natif émet une seule fois.

#### Accumulation Improvize multi-items

En mode Improvize (`Improvize && p_Instance != NULL && kmax > 1`), les instances sont copiées dans `wasm_accum[]` avec :
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
| T4 guard smart | kss2, negative-context | TimeSet skip sélectif |
| ExpandKey | visser5, visser-waves | Inversion/expansion des clés MIDI |
| Accumulateur Improvize | bells, kss2 | Multi-items avec offset temporel |
| NoTracePath guard | vina, vina2, watch | Désactive graphiques quand pas de trace path |

**Score parité : 24/35 EXACT** (18 MIDI + 6 TEXT), seed=1, build 2026-04-02.

---

## Fix moteur appliqué à csrc/bp3/ (affecte WASM)

### ConsoleMain.c + SaveLoads1.c — Guard NoTracePath graphiques (2026-04-02)

**Bug :** Les settings JSON de Bernard (ex: `-se.Vina`) activent `ShowObjectGraph=1` → `SaveLoads1.c:758` force `ShowGraphic=TRUE`. En console/WASM sans trace path, `imagePtr` reste NULL → segfault dans `Graphic.c:1388` ou boucle infinie dans le pipeline graphique.

**Cause :** `LoadSettings()` est appelé AVANT `PrepareTraceDestination()` dans `ConsoleMain.c`. Le guard `NoTracePath` dans `SaveLoads1.c:704` était commenté ET inopérant (NoTracePath pas encore positionné).

**Fix :**
1. `ConsoleMain.c` : guard `if(NoTracePath) { ShowObjectGraph = ShowPianoRoll = ShowGraphic = FALSE; }` ajouté après `PrepareTraceDestination()`, avant le switch d'action
2. `SaveLoads1.c` : décommentage du guard ligne 704 (double protection)

**Grammaires débloquées :** vina (segfault→6 MIDI), vina2 (segfault→texte OK), Watch_What_Happens (timeout→2106 MIDI en 81s)
