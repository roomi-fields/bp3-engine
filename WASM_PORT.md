# BP3 WASM Port — Documentation technique

Document à destination de Bernard Bel. Décrit le portage du moteur BP3 console en WebAssembly, les modifications au code C, et l'API JavaScript.

## Vue d'ensemble

Le moteur BP3 (C, console) est compilé en WebAssembly via Emscripten (v5.0.2) pour tourner dans le navigateur. Le même code C produit le résultat — seule l'interface change.

```
Code C de Bernard              Notre couche WASM
(source/BP2/ — intact)         (csrc/ — copies adaptées + API)

bolprocessor/bolprocessor      csrc/bp3/     31 fichiers C (copies nettoyées)
  ↓ fork                       csrc/wasm/    3 fichiers (API, stubs, platform shim)
roomi-fields/bp3-engine        Makefile.emscripten
  branche: wasm
```

## Pourquoi des copies de source/BP2/ ?

Les fichiers dans `source/BP2/` ne compilent pas directement en WASM à cause de :
- **Headers Mac OS** : `midi1.h`, `NavServWrapper.h`, `WASTEIntf.h` — types Mac inexistants (`ProcPtr`, `TEHandle`, `FSSpec`, `AppleEvent`...)
- **Caractères Mac Roman** : `OkBolChar()` et `OkBolChar2()` dans `CompileGrammar.c` contiennent des `case 'é':` en encodage Mac — Clang/WASM refuse les multi-byte character literals
- **Nommage** : `-BP2.h` renommé en `-BP3.h` (les `#include` dans les .c référencent `-BP3.h`)

Les fichiers dans `csrc/bp3/` sont des **copies nettoyées** de `source/BP2/` : headers Mac supprimés/commentés, caractères accentués retirés, fichiers renommés. Le code métier (grammaires, dérivation, polymétrie, TimeSet) est **identique**.

Quand Bernard met à jour ses sources dans `source/BP2/`, il faut comparer manuellement et reporter les changements dans `csrc/bp3/`. Les divergences sont minimes et isolées par des `#ifdef __BP3_WASM__`.

## Modifications au code C de Bernard

Toutes les modifications dans `csrc/bp3/` sont conditionnées par `#ifdef __BP3_WASM__` ou `#ifndef __BP3_WASM__`. Le code natif n'est pas affecté.

### 1. ConsoleMain.c — Exclusion de main()

```c
#ifndef __BP3_WASM__
int main (int argc, char* args[]) {
    // ... tout le main() de Bernard ...
}
#endif /* __BP3_WASM__ */
```

**Raison** : en WASM, le point d'entrée est `bp3_init()` dans `bp3_api.c`, pas `main()`. Le module WASM est instancié par JavaScript et piloté via l'API.

### 2. ConsoleMessages.c — Suppression des écritures stdout

```c
void ConsoleMessagesInit() {
#ifdef __BP3_WASM__
    FILE* dest = NULL;
#else
    FILE* dest = stdout;
#endif
    gOutDestinations[odiDisplay] = dest;
    // ... idem pour tous les autres canaux ...
}
```

Et dans `BPPrintMessage()` :
```c
    if(dest & odError) {
#ifndef __BP3_WASM__
        vfprintf(stdout, format, args);
#endif
    }
    if((dest & odInfo) && ...) {
#ifndef __BP3_WASM__
        result = vfprintf(stdout, format, args);
#endif
    }
```

**Raison** : chaque `vfprintf(stdout)` en WASM déclenche un appel système JavaScript (`fd_write`). Quand `Compute.c` fait de la récursion profonde (118 appels `BPPrintMessage` × profondeur), ces appels WASM→JS s'empilent sur le stack JavaScript de V8 et provoquent "Maximum call stack size exceeded". En supprimant les écritures stdout, la sortie passe uniquement par le callback C (`BPSetMessageCallback`) sans traverser la frontière WASM/JS.

**Impact** : aucun. Toute la sortie est capturée par le callback. Le natif continue d'écrire sur stdout normalement.

### 3. ProduceItems.c — Skip de PolyMake dans PrintResult

```c
int PrintResult(int expand, int w, int datamode, int ifunc, tokenbyte ***pp_a) {
    r = OK;
#ifdef __BP3_WASM__
    expand = FALSE;
#endif
    if(expand && datamode && !ifunc) {
        // ... PolyMake pour expansion avant affichage ...
    }
```

**Raison** : `PrintResult()` appelle `PolyMake()` une seconde fois pour "expandre" les expressions polymétriques avant affichage texte. Sur les grammaires complexes (Visser3 : 7593 tokens), ce second `PolyMake` cause un stack overflow. En WASM, le résultat textuel montre la forme non-expansée — c'est la représentation correcte de la structure polymétrique.

**Impact** : le texte affiché en WASM est la forme compacte (ex: `{C4 D4, E4 F4 G4}`) au lieu de la forme expansée. Les deux sont sémantiquement identiques.

### 4. CompileProcs.c — Condition _scale() pour WASM

```c
#ifdef __BP3_WASM__
    if(strcmp(line,"0") == 0 || NumberScales == 0) k = 0;
#else
    if(strcmp(line,"0") == 0 || (!OutCsound && !rtMIDI && !WriteMIDIfile)) k = 0;
#endif
```

**Raison** : en natif, `_scale()` est ignoré quand aucune sortie sonore n'est active (`!OutCsound && !rtMIDI && !WriteMIDIfile`). En WASM, `WriteMIDIfile = TRUE` (pour activer l'extraction MIDI) donc la condition native ne fonctionne pas. On conditionne sur `NumberScales == 0` : si aucune gamme n'a été chargée, `_scale()` est ignoré.

### 5. Encode.c — Même pattern pour T44

Même logique que CompileProcs.c pour l'encodage du token `_scale` (T44) — conditionné sur `NumberScales > 0` en WASM.

### 6. CompileGrammar.c — Forward declarations (non conditionnel)

```c
/* Forward declarations for K&R functions */
int OkBolChar(char c);
int OkBolChar2(char c);
```

**Raison** : ces fonctions K&R (sans type de retour explicite) causent des conflits de types quand utilisées avant leur définition. Le natif tolère via `-Wno-implicit-function-declaration`, mais en combinaison avec d'autres flags WASM ça génère des erreurs. Les forward declarations résolvent le problème pour les deux cibles.

## Fichiers WASM (csrc/wasm/)

### bp3_api.c — API JavaScript

| Fonction | Signature | Description |
|----------|-----------|-------------|
| `bp3_init()` | `→ int` | Initialise/réinitialise le moteur. 0=OK |
| `bp3_load_grammar(text)` | `string → int` | Charge une grammaire BP3 |
| `bp3_load_alphabet(text)` | `string → int` | Charge un alphabet |
| `bp3_load_settings(json)` | `string → int` | Charge des settings (format JSON BP3) |
| `bp3_load_settings_params(...)` | `6 ints → int` | Set 6 paramètres directement |
| `bp3_load_tonality(text)` | `string → int` | Charge un fichier tonalité |
| `bp3_load_csound_resources(text)` | `string → int` | Charge des instruments Csound |
| `bp3_set_object_duration(name, ms)` | `string, int → int` | Donne une durée à un terminal custom |
| `bp3_produce()` | `→ int` | Produit un item. 1=OK, 0=MISS, <0=erreur |
| `bp3_get_result()` | `→ string` | Résultat textuel |
| `bp3_get_messages()` | `→ string` | Messages (erreurs, warnings, trace) |
| `bp3_get_midi_events()` | `→ string` | Événements MIDI en JSON |
| `bp3_get_midi_event_count()` | `→ int` | Nombre d'événements MIDI |
| `bp3_get_timed_tokens()` | `→ string` | Tokens symboliques horodatés en JSON |
| `bp3_get_timed_token_count()` | `→ int` | Nombre de tokens horodatés |

#### bp3_init() — Reset complet

Appelé avant chaque session. Au ré-appel, il :
1. Libère `eventStack` (free + realloc)
2. Reset les compteurs d'alphabet, l'état de compilation, la structure grammaire, les gammes
3. Vide les text handles (grammar, alphabet, data, trace)
4. Appelle `ConsoleInit()`, `ConsoleMessagesInit()`, `Inits()` — fonctions de Bernard
5. Appelle `LoadSettings()` avec `{DisplayItems:1}` — **critique** : cette initialisation interne empêche des SIGSEGV sur les grammaires complexes
6. Redirige `stdout` vers `/dev/null` pendant `bp3_produce()` — empêche les `printf` du code C de traverser la frontière WASM/JS

#### bp3_load_settings() vs bp3_load_settings_params()

`bp3_load_settings(json)` passe par `LoadSettings()` de Bernard. Accepte les fichiers `-se.xxx` en format JSON BP3. C'est la méthode recommandée pour les grammaires complexes — `LoadSettings()` initialise un état interne que `Inits()` seul ne couvre pas.

`bp3_load_settings_params(noteConvention, quantize, timeRes, natureOfTime, seed, maxTime)` set directement 6 variables C. Plus simple mais ne fait pas l'initialisation interne.

**NoteConvention** : `0=English (C D E)`, `1=French (Do Ré Mi)`, `2=Indian (Sa Re Ga)`, `3=Keys`. Attention : c'est l'inverse de l'intuition (English=0, pas 1). Constantes BP3 : `ENGLISH=0, FRENCH=1, INDIAN=2`.

#### bp3_set_object_duration(name, ms)

Permet de déclarer un terminal custom (ex: `env1`, `Kick`) comme objet sonore avec une durée, sans fournir de fichier prototype MIDI (`-mi.xxx`).

Doit être appelé **après** `bp3_load_alphabet()` et **avant** `bp3_produce()`. Les durées sont stockées (pattern "deferred") puis appliquées automatiquement pendant `PlayBuffer()`, après la compilation de la grammaire quand les structures internes (`p_Bol`, `p_Dur`, `pp_MIDIcode`) sont valides.

Implémentation : alloue un `pp_MIDIcode[j]` minimal (2 entrées NoteOn/NoteOff) pour que `FillPhaseDiagram` (ligne 630) traite le terminal comme "sonnant" (`p_MIDIsize[j] > 0`).

```javascript
loadAlphabet("env1\nKick\n");
setObjectDuration("env1", 1000);
setObjectDuration("Kick", 500);
loadGrammar("S --> {C4 D4, env1 env1}");
produce();
// → env1 occupe du temps dans la polymétrie, synchronisé avec C4/D4
```

#### bp3_get_timed_tokens() — Tokens horodatés

Retourne **tous** les tokens de la production avec leur timing, en JSON. Trois sources combinées :
- **p_Instance[]** (rempli par `TimeSet`) : timing précis pour les notes et terminaux custom
- **Détection de gaps** : les silences ne sont pas stockés dans p_Instance — ils sont détectés comme des gaps entre deux objets consécutifs (`start[k] > end[k-1]`)
- **Sortie texte** (`bp3_get_result()`) : extraction des tokens de contrôle (`_vel()`, `_chan()`, etc.) qui ne sont pas dans `p_Instance`

Format :
```json
[
  {"token":"_vel(120)", "start":0, "end":0},
  {"token":"C4", "start":0, "end":1000},
  {"token":"-", "start":1000, "end":2000},
  {"token":"D4", "start":2000, "end":3000},
  {"token":"-", "start":3000, "end":4000},
  {"token":"E4", "start":4000, "end":5000}
]
```

Contenu :
- **Notes** : `object >= 16384` dans p_Instance → nom via `PrintThisNote(scale, key)` selon NoteConvention
- **Terminaux custom** : `object 2..Jbol` dans p_Instance → nom dans `p_Bol[j]` (ex: `env1`, `Kick`)
- **Silences** : détectés comme gaps temporels entre objets → `{"token":"-", "start":gap_start, "end":gap_end}`. Les doubles silences (`- -`) sont fusionnés en un seul gap.
- **Contrôles** : extraits du texte (`_vel`, `_chan`, `_script`...) → timestamp = début du prochain objet sonnant, durée = 0

**Note** : `FillPhaseDiagram` de Bernard ne crée pas d'entrée p_Instance pour les silences — ils ne consomment pas de `kobj`. Le silence est implicite dans le timing. Notre code le rend explicite.

#### Capture de la sortie

Deux mécanismes parallèles :
- **Callback C** (`wasm_message_callback`) : intercepte tous les `BPPrintMessage()` sans traverser WASM/JS. Messages `odDisplay` → `output_buffer`, reste → `message_buffer`.
- **TEH[OutputWindow]** : `PrintResult()` y écrit quand `DisplayItems=TRUE`.
- **stdout redirigé** : pendant `bp3_produce()`, stdout pointe vers `/dev/null` pour éviter les syscalls JS

`bp3_get_result()` cherche dans `TEH[OutputWindow]` d'abord, puis dans `output_buffer`.

### bp3_wasm_stubs.c — Stubs et implémentations

Remplace : `PlayThings.c`, `MakeSound.c`, `MIDIstuff.c`, `MIDIfiles.c`, `MIDIstubs.c`, `MIDIloads.c`, `Graphic.c`, `Csound.c`, `CsoundMaths.c`, `CsoundScoreMake.c`, `Ticks.c`, `HTML.c`, `Glossary.c`, etc.

**Stubs purs** (return OK/FAILED/0) :
- GUI : `BPActivateWindow`, `ShowSelect`, `FlashInfo`, `DrawItem`
- MIDI hardware : `ResetMIDI`, `ResetMIDIControllers`, `ResetMIDIfile`, `SetDriver`
- Csound : `MakeCsoundScore`, `CheckCsoundRecourses`
- Fichiers : `ImportMIDIfile`, `OpenFile`, `ClearWindow`

**Implémentations réelles** :
- `PlayBuffer()` / `PlayBuffer1()` : pipeline complet — `PolyMake()` → `MakeEventSpace()` → `CheckLoadedPrototypes()` → `TimeSet()` → extraction MIDI de `p_Instance[]` dans `eventStack[]`. Aussi : appel de `apply_deferred_durations()` pour les terminaux custom.
- `PrintThisNote()` : MIDI key → nom symbolique (C4, Do3, sa6...) selon NoteConvention et gamme microtonale active. Porté depuis `MIDIstuff.c`.
- `GetThisNote()` : nom → MIDI key. Porté depuis `MIDIstuff.c`.
- `FindScale()`, `CreateMicrotonalScale()` : support gammes microtonales (portés depuis `MIDIstuff.c`)
- `LengthOf()`, `CopyBuf()`, `SelectionToBuffer()`, `ReadToBuff()` : fonctions buffer portées depuis `CTextHandles.c`

### bp3_wasm_platform.h — Shim de plateforme

Inclus **avant** tout autre header via le flag `-include`. Rôle :
- `#undef __linux__` et `#undef _WIN64` — empêche les `#include <alsa/asoundlib.h>` et les blocs Windows
- Fournit les types C manquants : `UInt64`, `Size`, `Rect`, `MIDIPacket`, `Handle`
- `#define noErr 0`

## Makefile.emscripten

```makefile
CC = emcc
BP3_SRC = csrc/bp3
WASM_SRC = csrc/wasm

CFLAGS = -O2 -fno-common
    -include $(WASM_SRC)/bp3_wasm_platform.h   # shim avant tout
    -D__BP3_WASM__=1                            # flag conditionnel
    -I$(BP3_SRC)                                 # includes BP3

STACK_SIZE = 33554432    # 32 MB (polymétrie profonde)
INITIAL_MEMORY = 67108864  # 64 MB (doit être > STACK_SIZE)
ALLOW_MEMORY_GROWTH = 1    # heap extensible
MODULARIZE = 1              # export comme module JS
EXPORT_NAME = 'BP3Module'  # nom du module
```

Flags de tolérance pour le C K&R de Bernard :
- `-Wno-implicit-function-declaration` — fonctions utilisées avant déclaration
- `-Wno-implicit-int` — fonctions sans type de retour (`CompileGrammar(int mode)` au lieu de `int CompileGrammar(int mode)`)
- `-Wno-int-conversion` — conversions pointeur/int
- `-Wno-incompatible-pointer-types` — types de pointeurs mélangés

## Conventions BP3 importantes

| Concept | Valeurs |
|---------|---------|
| Return values | `OK=1, MISSED=0, ABORT=-4, TRUE=1, FALSE=0` (OK=1, pas 0 !) |
| Window indices | `wGrammar=0, wAlphabet=1, wStartString=2, wTrace=5, wData=7, OutputWindow=wData` |
| NoteConvention | `ENGLISH=0, FRENCH=1, INDIAN=2` |
| Token encoding | Notes = `16384 + MIDI_key`, terminaux custom = index dans `p_Bol[j]` |
| Silence dans p_Instance | Pas d'entrée propre — c'est un gap temporel entre deux objets |
| Durée | `p_Dur[j]` en ms, `p_Tref[j]` = durée de référence |
| Objet sonnant | `p_MIDIsize[j] > 0` requis pour que `FillPhaseDiagram` alloue du temps à un terminal |

## Limitations connues

### vina3 — stack overflow JS non résolvable

La grammaire vina3 (5 sous-grammaires, gamakas, résolution d'octaves) provoque "Maximum call stack size exceeded" en WASM. Le crash vient de la récursion profonde de `Compute.c` — même avec la suppression des `fprintf` et 32 MB de stack WASM, les wrappers internes d'Emscripten consomment du stack JS à chaque appel de fonction C. Le natif passe sans problème.

**Pas de fix simple** — nécessiterait `ASYNCIFY` (performance −50%) ou réécriture itérative de `Compute()`.

### Grammaires complexes et fichiers settings

Les grammaires Visser3/5, ShapesInRhythm, Watch_What_Happens nécessitent leurs fichiers settings (`-se.xxx`) chargés via `bp3_load_settings()`. Sans settings, le moteur peut crasher (SIGSEGV). C'est le même comportement que le natif — l'interface PHP/console charge toujours les settings.

### Deux formats de fichiers settings

- **JSON** (BP3, récent) : `{"Quantization":{"name":"...","value":"10",...}, ...}` — fonctionne avec `bp3_load_settings()`
- **Texte plat** (BP2, 1998) : lignes positionnelles — ne fonctionne PAS avec `bp3_load_settings()`. L'appelant JS doit convertir.

### DisplayItems et PrintResult

`DisplayItems=TRUE` est nécessaire pour que `PrintResult()` écrive le résultat texte dans `TEH[OutputWindow]`. Mais pour les grammaires complexes, le `PolyMake` dans `PrintResult` est désactivé (`#ifdef __BP3_WASM__`) pour éviter un stack overflow.

### OCT et terminaux custom — incompatibilité de durée

Quand l'alphabet contient `OCT` (ex: `C0 --> C1 --> C2 --> ...`), les notes sont encodées comme `T25` (16384 + MIDI key) et les terminaux custom comme `T3` (index dans p_Bol). Ce mélange cause un bug : les terminaux custom ont durée 0 dans `p_Instance` malgré `p_MIDIsize > 0` et `p_Dur > 0`. Le problème vient de `FillPhaseDiagram` / `TimeSet` qui traitent différemment les T3 quand des T25 sont présents.

**Solution adoptée** : ne pas utiliser `OCT` dans l'alphabet. Tous les terminaux (notes incluses) sont des bols customs. BP3 fait l'ordonnancement symbolique — le dispatcher JavaScript interprète les noms (`C2` → note MIDI 36, `env1` → ADSR filter). C'est cohérent avec la philosophie BPscript.

## Notes pour Bernard — code mort et observations

### ResizeObjectSpace : bloc `reset` jamais exécuté

Dans `GetRelease.c`, `ResizeObjectSpace()` contient un bloc de reset des prototypes (lignes ~1109-1131) qui n'est jamais exécuté :

```c
reset = 0;        // ← toujours 0
if(reset) {       // ← jamais vrai
    for(j=2; j < Jbol && j < maxsounds; j++) {
        ptr = (Handle)(*pp_MIDIcode)[j];
        MyDisposeHandle(&ptr);
        // ... libération de toutes les structures prototypes ...
    }
}
```

Ce code est-il intentionnellement désactivé ou est-ce un reste de debug ?

### vfprintf(stdout) bypasse gOutDestinations

Dans `ConsoleMessages.c`, `BPPrintMessage()` utilise `gOutDestinations[]` pour les canaux d'affichage, sauf pour `odError` et `odInfo` qui écrivent directement sur `stdout` :

```c
if(dest & odError) {
    vfprintf(stdout, format, args);  // ← bypass gOutDestinations[odiError]
}
if(dest & odInfo) {
    result = vfprintf(stdout, format, args);  // ← bypass gOutDestinations[odiInfo]
}
```

Les lignes `vfprintf(gOutDestinations[odiError], ...)` et `vfprintf(gOutDestinations[odiInfo], ...)` sont commentées. C'est probablement intentionnel (debug direct sur stdout) mais ça empêche la redirection de ces canaux.

### OCT + terminaux custom : timing incorrect

Quand un alphabet contient à la fois des entrées `OCT` (notes avec `-->`) et des terminaux simples (sans `-->`), les terminaux simples reçoivent une durée 0 dans `FillPhaseDiagram` même si `p_MIDIsize[j] > 0`. Le même terminal fonctionne correctement (durée = prodtempo) quand l'alphabet ne contient pas d'entrées `OCT`. Nous n'avons pas identifié la cause exacte dans le pipeline.

### Encode() matche les noms de notes de toutes les conventions

`Encode()` reconnaît automatiquement les noms de notes (English, French, Indian) suivis d'un chiffre d'octave, indépendamment du `NoteConvention` actif et de l'alphabet chargé. Par exemple, `re4` est toujours reconnu comme la note indienne "re" octave 4 et encodé comme T25, même si `NoteConvention = ENGLISH` et que `re4` est déclaré comme terminal custom dans l'alphabet.

Le pattern problématique : **exactement 1-2 lettres matchant un nom de note + chiffre d'octave**. Les noms de 3+ lettres qui ne commencent pas par un nom de note sont safe.

Noms de notes reconnus par `Encode()` :
- English : `C, D, E, F, G, A, B` + altérations `C#, Db, Eb, F#, Gb, Ab, Bb`
- French : `do, re, mi, fa, sol, la, si` + altérations
- Indian : `sa, re, ga, ma, pa, dha, ni` + altérations `rek, gak, dhak, nik, ma#, pa#, dha#`

**Question pour Bernard** : est-ce que `Encode()` est censé matcher les notes de toutes les conventions simultanément, ou seulement celle indiquée par `NoteConvention` ? Si c'est intentionnel, existe-t-il un mécanisme pour forcer un terminal à être traité comme un bol custom et non comme une note ?

### Sound objects custom : durée 0 au-delà de ~5 terminaux

Quand on crée des sound objects custom via `bp3_set_object_duration()` (qui alloue un `pp_MIDIcode[j]` minimal avec `p_MIDIsize[j] = 2` et `p_Dur[j] > 0`), les premiers terminaux (indices 2-6 environ) reçoivent une durée correcte dans `p_Instance`, mais les suivants ont `endtime == starttime` (durée 0).

Vérification : juste avant `TimeSet`, tous les indices ont bien `p_MIDIsize = 2` et `p_Dur = 1000`. Le problème est dans `FillPhaseDiagram` ou `TimeSet` qui ne propagent pas la durée pour tous les objets.

Testé avec des noms neutres (`bol1..bol12`, aucun match note) :
- 3 terminaux : tous OK
- 5 terminaux : tous OK
- 8 terminaux : indices 2-5 OK, indices 6-9 durée 0
- 12 terminaux : seuls 3-4 ont une durée non-nulle

Ce comportement se produit aussi bien en WASM qu'en natif (non vérifié — à confirmer avec Bernard).

**Question pour Bernard** : est-ce que les sound objects nécessitent une initialisation supplémentaire au-delà de `p_MIDIsize > 0` et `p_Dur > 0` pour que `FillPhaseDiagram` leur alloue du temps ? Peut-être un flag dans `p_Type[j]`, ou une structure `p_Tpict[j]`, ou un prototype complet chargé via `LoadObjectPrototypes()` ?

## Suite de tests

```bash
cd bp3-engine
node scripts/test-sequence.js        # 7 grammaires en séquence (Ames, Mozart, Visser3...)
node scripts/test-reinit.js          # Isolation entre grammaires
node scripts/test-midi-reinit.js     # MIDI après re-init
node scripts/test-repro-exact.js     # Bug -se.drum corrigé
node scripts/test-settings-params.js # API settings
node scripts/test-all.js             # 107 grammaires
```

Données de test : `test-data/` — 514 fichiers de Bernard (107 grammaires + alphabets, settings, tonalités, csound, orchestres). Source : `bolprocessor/bolprocessor/data/`, `bolprocessor/bp3-ctests/`, `bolprocessor/php-frontend/`.

## Build natif (référence)

Le binaire natif de Bernard compile aussi depuis ce repo :

```bash
cd bp3-engine
make        # utilise source/BP2/ et le Makefile de Bernard
./bp produce -gr test-data/-gr.Visser3 -se test-data/-se.Visser3
```

C'est utile pour comparer les résultats WASM vs natif.
