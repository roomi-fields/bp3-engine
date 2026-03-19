Cher Bernard,

Comme promis, voici une description du projet et de l'état d'avancement.

## Ce qu'on a fait

On a compilé le moteur BP3 console en WebAssembly via Emscripten. Le même code C tourne dans le navigateur — dérivation, polymétrie, TimeSet, tout fonctionne. On a testé avec 107 de tes grammaires (de tes repos GitHub), la grande majorité passe.

Le portage est documenté en détail ici :
https://github.com/roomi-fields/bp3-engine/blob/wasm/WASM_PORT.md

Les modifications au code C sont minimes — 6 blocs `#ifdef __BP3_WASM__` pour désactiver les parties Mac/GUI et adapter quelques chemins. Le code métier (grammaires, dérivation, polymétrie, TimeSet) est identique.

## Notre objectif : BP3 comme ordonnanceur pur

L'idée de BPscript est d'utiliser BP3 **uniquement pour l'ordonnancement symbolique** : dériver la grammaire, résoudre la polymétrie, calculer les timestamps. Tout le reste — son, MIDI, Csound, audio — est géré à l'extérieur par JavaScript (Web Audio, MIDI externe, OSC vers SuperCollider, etc.).

Concrètement, on a besoin de récupérer une liste de terminaux horodatés :
```
[
  {"token": "C4", "start": 0, "end": 500},
  {"token": "env1", "start": 0, "end": 500},
  {"token": "D4", "start": 500, "end": 1000},
  ...
]
```

Les terminaux sont des noms symboliques — c'est le dispatcher JavaScript qui décide quoi en faire (note MIDI, enveloppe ADSR, commande DMX, message OSC...). BP3 n'a pas besoin de savoir ce que les noms signifient.

## Où on est bloqués

Pour que BP3 calcule des timestamps, un terminal doit passer par `FillPhaseDiagram` → `TimeSet`. Mais `FillPhaseDiagram` (ligne 630 de FillPhaseDiagram.c) convertit en silence tout terminal qui n'est ni une note reconnue (T25) ni un sound object avec prototype MIDI (`p_MIDIsize[j] > 0`).

On s'est retrouvés coincés dans 5 impasses :

**1. Alphabet standard (OCT)** — les notes sont reconnues et horodatées, mais `Encode()` matche les noms de notes de toutes les conventions simultanément (English + French + Indian), même quand `NoteConvention` est setté. Un terminal `re4` est toujours capturé comme note indienne. Et les terminaux custom (enveloppes, drums) mélangés dans le même alphabet ont durée 0.

**2. Sound objects simulés** — on a essayé d'allouer un `pp_MIDIcode[j]` minimal (2 événements NoteOn/NoteOff) pour simuler un prototype. Ça marche pour ~5 terminaux, mais au-delà, `FillPhaseDiagram`/`TimeSet` donne durée 0 malgré `p_MIDIsize[j] = 2` et `p_Dur[j] = 1000` vérifiés juste avant l'appel à `TimeSet`. Il manque probablement une initialisation que `LoadObjectPrototypes()` fait.

**3. Alphabet custom** — des noms comme `Kick`, `env1`, `drone` ne sont reconnus ni comme notes ni comme sound objects → `FillPhaseDiagram` les traite comme des silences → pas de timestamps.

**4. Durée absolue vs tempo** — les notes (T25) reçoivent `prodtempo` (proportionnel au tempo). Les sound objects reçoivent `p_Dur` en millisecondes absolues. À 120 BPM, une note dure 500ms mais un sound object avec `p_Dur=1000` dure 1000ms — il ne suit pas le tempo.

**5. Vrais prototypes** — le format des fichiers `-mi.xxx` est trop complexe pour être généré programmatiquement (568 lignes par terminal dans `-mi.abc`).

## Ce qu'on aimerait savoir

1. **Quel est le bon mécanisme pour qu'un terminal custom occupe du temps sans être une note ni un instrument Csound ?** Est-ce qu'il existe un chemin plus simple que les prototypes `-mi.xxx` — par exemple un flag, ou une convention d'alphabet ?

2. **Pourquoi `FillPhaseDiagram` donne durée 0 à certains indices** quand `p_MIDIsize[j] > 0` et `p_Dur[j] > 0` ? (ça marche pour les 5 premiers, pas au-delà)

3. **Est-ce que `Encode()` matche intentionnellement toutes les conventions de notes simultanément ?** Si oui, comment empêcher un terminal custom d'être interprété comme une note ?

4. **Comment donner une durée relative au tempo** (comme `prodtempo`) à un sound object, plutôt qu'une durée absolue ?

## Observations sur le code

En travaillant sur le portage, on a noté quelques choses qui pourraient t'intéresser :

- **`ResizeObjectSpace()` dans GetRelease.c** : le bloc de reset des prototypes (lignes ~1109-1131) n'est jamais exécuté (`reset = 0; if(reset) { ... }`). C'est intentionnel ?

- **`BPPrintMessage()` dans ConsoleMessages.c** : les canaux `odError` et `odInfo` écrivent directement sur `stdout` au lieu de passer par `gOutDestinations[]` (les lignes `vfprintf(gOutDestinations[...])` sont commentées). Ça empêche la redirection de ces canaux.

## Ce qui fonctionne bien

Le portage WASM est solide pour tout le reste :
- 107 grammaires testées (~100 passent, les échecs sont des dépendances de fichiers settings/alphabet)
- Polymétrie, dérivation, modes (ORD, RND, SUB1, LIN) — tout correct
- Gammes microtonales et tonalité
- Reset complet entre sessions
- Build natif (ton Makefile) et WASM depuis le même repo

Le repo est public : https://github.com/roomi-fields/bp3-engine (branche `wasm`)

Merci pour ton aide !
Romi
