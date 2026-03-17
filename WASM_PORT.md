# BP3 WASM Port — Documentation technique

## Vue d'ensemble

Le moteur BP3 de Bernard Bel (C, console) est compilé en WebAssembly via Emscripten pour tourner dans le navigateur. Ce document décrit l'architecture du port, les modifications apportées au code C, et les problèmes connus.

## Architecture

```
Source C de Bernard          Notre couche WASM
(source/BP2/ — non modifié)  (csrc/ — copies adaptées)

bolprocessor/bolprocessor    csrc/bp3/     30+ fichiers C (copies nettoyées)
  ↓ fork upstream            csrc/wasm/    3 fichiers (API, stubs, platform)
roomi-fields/bp3-engine      Makefile.emscripten
  branche: wasm
```

### Pourquoi des copies et pas les originaux ?

Les fichiers C de Bernard dans `source/BP2/` ne compilent pas en WASM :
- Headers Mac OS (`midi1.h`, `NavServWrapper.h`) avec types inexistants
- Caractères accentués Mac Roman dans `OkBolChar()` / `OkBolChar2()`
- Naming `-BP2.h` vs notre `-BP3.h`

Les fichiers dans `csrc/bp3/` sont des copies nettoyées : headers Mac supprimés, renommés `-BP3.h`, caractères accentués retirés. Quand Bernard met à jour ses sources, on compare manuellement et on applique les changements pertinents.

## Fichiers WASM (csrc/wasm/)

### bp3_api.c — API JavaScript

Interface entre le JS et le moteur BP3. Fonctions exportées :

| Fonction | Signature | Description |
|----------|-----------|-------------|
| `bp3_init()` | `→ int` | Initialise le moteur (0=OK, <0=erreur). Réutilisable. |
| `bp3_load_grammar(text)` | `string → int` | Charge une grammaire BP3 |
| `bp3_load_alphabet(text)` | `string → int` | Charge un alphabet |
| `bp3_load_settings(json)` | `string → int` | Charge des settings (format JSON BP3) |
| `bp3_load_settings_params(...)` | `6 ints → int` | Set les paramètres directement |
| `bp3_load_tonality(text)` | `string → int` | Charge un fichier tonalité |
| `bp3_load_csound_resources(text)` | `string → int` | Charge les instruments Csound |
| `bp3_produce()` | `→ int` | Produit un item (1=OK, 0=MISS, <0=erreur) |
| `bp3_get_result()` | `→ string` | Résultat textuel de la production |
| `bp3_get_messages()` | `→ string` | Messages (erreurs, warnings, trace) |
| `bp3_get_midi_events()` | `→ string` | Événements MIDI en JSON |
| `bp3_get_midi_event_count()` | `→ int` | Nombre d'événements MIDI |
| `bp3_get_timed_tokens()` | `→ string` | Tokens symboliques horodatés en JSON |
| `bp3_get_timed_token_count()` | `→ int` | Nombre de tokens |

#### bp3_init() — Détail du reset

Appelé avant chaque session. Au re-init (2e appel+), il :
1. Libère `eventStack` (free + realloc)
2. Reset les compteurs d'alphabet (`Jbol`, `Jfunc`, `Jpatt`, `Jvar`, `Jflag`, `Jhomo`)
3. Reset l'état de compilation (`CompiledGr/Al/Pt/In/CsObjects`)
4. Reset la grammaire (`MaxGram`, `MaxRul`, `Gram.*`)
5. Reset les gammes (`NumberScales`, `DefaultScaleParam`)
6. Vide les text handles (grammar, alphabet, data, trace)
7. Appelle `ConsoleInit()` + `ConsoleMessagesInit()` + `Inits()`
8. Appelle `LoadSettings()` avec un JSON minimal `{DisplayItems:1}` — **critique** : sans cet appel, les grammaires complexes (Visser3) crashent avec SIGSEGV

#### bp3_load_settings() vs bp3_load_settings_params()

`bp3_load_settings(json)` passe par `LoadSettings()` de Bernard — accepte le format JSON BP3 (les fichiers `-se.xxx`). C'est la méthode qui fonctionne pour les grammaires complexes.

`bp3_load_settings_params(noteConvention, quantize, timeRes, natureOfTime, seed, maxTime)` set directement 6 variables C. Plus simple mais ne déclenche pas l'initialisation interne de `LoadSettings()`.

**NoteConvention** : `0=English (C D E)`, `1=French (Do Re Mi)`, `2=Indian (Sa Re Ga)`. Attention : c'est contre-intuitif (English=0, pas 1).

#### bp3_get_timed_tokens() — Tokens horodatés

Corrèle la sortie texte (`bp3_get_result()`) avec les timings de `p_Instance[]` :
- Parse le texte en tokens (espace-séparés)
- Chaque token "sonnant" (note, silence `-`) consomme une entrée de `p_Instance`
- Les contrôles (`_vel()`, `_chan()`, etc.) sont instantanés (start=end=timestamp du prochain son)
- Les délimiteurs polymétriques (`{`, `}`, `,`) sont filtrés

Format : `[{"token":"_vel(120)","start":0,"end":0}, {"token":"C4","start":0,"end":1000}, ...]`

#### Capture de la sortie

La sortie BP3 est capturée via deux mécanismes :
- **Callback** `wasm_message_callback` : intercepte tous les `BPPrintMessage()`. Les messages `odDisplay` vont dans `output_buffer`, tout le reste dans `message_buffer`.
- **TEH[OutputWindow]** : `PrintResult()` y écrit le résultat final quand `DisplayItems=TRUE`.

`bp3_get_result()` cherche d'abord dans `TEH[OutputWindow]`, puis dans `output_buffer`.

### bp3_wasm_stubs.c — Stubs et implémentations

Remplace les fichiers exclus du build : `PlayThings.c`, `MakeSound.c`, `MIDIstuff.c`, `MIDIfiles.c`, `Graphic.c`, `Csound.c`, etc.

**Stubs purs** (return OK/FAILED sans rien faire) :
- Fonctions GUI : `BPActivateWindow`, `ShowSelect`, `FlashInfo`, `DrawItem`
- Fonctions MIDI hardware : `ResetMIDI`, `ResetMIDIControllers`, `ResetMIDIfile`
- Fonctions Csound : `MakeCsoundScore`, `CheckCsoundRecourses`
- Fonctions fichiers : `ImportMIDIfile`, `OpenFile`, `ClearWindow`

**Implémentations réelles** :
- `PlayBuffer()` / `PlayBuffer1()` : pipeline MIDI WASM. Appelle `PolyMake()` → `TimeSet()` → extraction des événements MIDI de `p_Instance[]` dans `eventStack[]`
- `PrintThisNote()` : conversion MIDI key → nom symbolique (C4, Do3, sa6...) selon NoteConvention et gamme active
- `GetThisNote()` : conversion nom → MIDI key
- `FindScale()`, `CreateMicrotonalScale()` : support des gammes microtonales
- Fonctions buffer : `LengthOf()`, `CopyBuf()`, `SelectionToBuffer()`, `ReadToBuff()`

### bp3_wasm_platform.h — Shim de plateforme

Inclus avant tout autre header via `-include`. Rôle :
- `#undef __linux__` et `#undef _WIN64` — empêche les includes ALSA/Windows
- Fournit les types manquants : `UInt64`, `Size`, `Rect`, `MIDIPacket`, `Handle`
- `#define noErr 0`

## Modifications au code C de Bernard (csrc/bp3/)

### ConsoleMessages.c

```c
// WASM: skip vfprintf(stdout) — tout passe par le callback
#ifdef __BP3_WASM__
    FILE* dest = NULL;  // au lieu de stdout
#endif
```

Chaque `BPPrintMessage()` faisait un `vfprintf(stdout)` qui en WASM traverse la frontière WASM→JS (syscall `fd_write`). Avec 118 appels dans `Compute.c` × profondeur de récursion, ça explose le stack JS. Le callback C capture tout — les `fprintf` sont redondants.

Les blocs `odError` et `odInfo` qui utilisent `vfprintf(stdout)` directement (sans passer par `gOutDestinations`) sont aussi guardés par `#ifndef __BP3_WASM__`.

### ProduceItems.c

```c
#ifdef __BP3_WASM__
    expand = FALSE;  // skip PolyMake in PrintResult
#endif
```

`PrintResult()` appelle `PolyMake()` pour "expandre" les expressions polymétriques avant affichage. Sur les grammaires complexes (Visser3, 7593 tokens), ce 2e appel à `PolyMake` cause un stack overflow. En WASM on saute cette expansion — le résultat textuel montre la forme non-expansée, qui est la représentation correcte.

### CompileProcs.c

```c
#ifdef __BP3_WASM__
    if(strcmp(line,"0") == 0 || NumberScales == 0) k = 0;
#else
    if(strcmp(line,"0") == 0 || (!OutCsound && !rtMIDI && !WriteMIDIfile)) k = 0;
#endif
```

`_scale()` dans la grammaire : en WASM, on n'a pas de Csound natif, mais on a `WriteMIDIfile=TRUE`. Sans ce guard, `_scale()` était silencieusement ignoré.

### Encode.c

Même pattern pour l'encodage T44 des tokens `_scale` — conditionné sur `NumberScales > 0` en WASM.

### ConsoleMain.c

```c
#ifndef __BP3_WASM__
int main (int argc, char* args[]) { ... }
#endif
```

Le `main()` de Bernard est exclu en WASM — on a notre propre point d'entrée via `bp3_init()`.

## Makefile.emscripten

```makefile
STACK_SIZE=33554432    # 32 MB (était 2 MB, augmenté pour polymétrie profonde)
INITIAL_MEMORY=67108864  # 64 MB (doit être > STACK_SIZE)
ALLOW_MEMORY_GROWTH=1    # Le heap peut grandir au-delà de INITIAL_MEMORY
```

Flags de compilation :
- `-Wno-implicit-function-declaration` — vieux C K&R sans prototypes
- `-Wno-implicit-int` — fonctions sans type de retour
- `-Wno-int-conversion` — conversions pointeur/int implicites
- `-Wno-incompatible-pointer-types` — types de pointeurs mélangés

## Conventions BP3 importantes

### Return values
```
OK = 1, MISSED = 0, ABORT = -4, ZERO = 0L, TRUE = 1, FALSE = 0
```
**Attention** : `OK = 1`, pas 0 comme en C standard.

### Window indices
```
wGrammar=0, wAlphabet=1, wStartString=2, wTrace=5, wData=7, OutputWindow=wData
```
`TEH[w]` = text handle pour la fenêtre `w`.

### NoteConvention
```c
#define ENGLISH 0
#define FRENCH 1
#define INDIAN 2
```

### Token encoding
Les notes sont encodées comme `16384 + MIDI_key` dans le buffer tokenbyte. Les terminaux custom (bols, symboles) sont indexés dans `p_Bol[j]` avec `j < 16384`.

## Problèmes connus

### vina3 — stack overflow JS

La grammaire vina3 (5 sous-grammaires, résolution d'octaves + gamakas) provoque un "Maximum call stack size exceeded" même avec 32 MB de stack WASM. Le crash vient de la récursion profonde de `Compute.c` qui traverse la frontière WASM→JS à chaque appel de fonction émis par emscripten. Le natif passe sans problème.

**Pas de fix simple** — nécessiterait `ASYNCIFY` (lourd) ou réécriture itérative de `Compute()`.

### Grammaires complexes nécessitent les settings

Les grammaires Visser3/5, ShapesInRhythm, Watch_What_Happens fonctionnent **seulement** quand les fichiers settings (`-se.xxx`) sont chargés avant la grammaire. Sans settings, le moteur crashe (SIGSEGV). Le natif a le même comportement — les settings sont toujours chargées par l'interface PHP/console.

### Fichiers `-se.` — deux formats

- **JSON** (BP3, récent) : `{"Quantization":{"name":"...","value":"10",...}, ...}` → fonctionne avec `bp3_load_settings()`
- **Texte plat** (BP2, ancien) : lignes positionnelles → ne fonctionne PAS avec `bp3_load_settings()`. L'appelant doit convertir via `convertOldSettings()` ou utiliser `bp3_load_settings_params()`.

## Suite de tests

```bash
node scripts/test-sequence.js      # 7 grammaires en séquence (Ames, Mozart, Visser3...)
node scripts/test-reinit.js        # Reset entre grammaires
node scripts/test-midi-reinit.js   # MIDI après re-init
node scripts/test-repro-exact.js   # Repro du bug -se.drum
node scripts/test-settings-params.js  # API settings directe
node scripts/test-all.js           # 107 grammaires (nécessite chargement settings+alphabets)
```

Données de test : `test-data/` — 514 fichiers de Bernard (107 grammaires + alphabets, settings, tonalités, csound).
