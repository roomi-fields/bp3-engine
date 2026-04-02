# Changelog — Moteur BP3 (csrc/bp3/)

Modifications au code moteur de Bernard, appliquées dans `csrc/bp3/` (branche `wasm`).
Ces changements affectent le natif ET le WASM. L'objectif est que Bernard les intègre dans son `source/BP3/`.

Chaque section référence le point correspondant dans `FEEDBACK_BERNARD.md` (test/grammars/ du repo BPscript).

---

## Bugs corrigés

### SaveLoads1.c — Clés JSON inversées (FEEDBACK #21)

```c
// AVANT (bugué) :
else if(strcmp(key,"Max_items_produced") == 0) MaxItemsProduce = intvalue;
else if(strcmp(key,"MaxItemsProduce") == 0) UseEachSub = intvalue;

// APRÈS :
else if(strcmp(key,"MaxItemsProduce") == 0) MaxItemsProduce = intvalue;
else if(strcmp(key,"UseEachSub") == 0) UseEachSub = intvalue;
```

**Impact :** `MaxItemsProduce` du fichier `-se.` JSON n'était jamais chargé. `UseEachSub` recevait une valeur erronée.

### SaveLoads1.c — Priorité seed `--seed` vs fichier `-se.` (FEEDBACK #22)

Le seed `--seed 1` en ligne de commande était écrasé par le seed du fichier `-se.`. Maintenant :
- `ConsoleMain.c:874` : `Seed = 0L` au début du parsing
- `ConsoleMain.c:1009` : `Seed = opts->seed` immédiat au parsing `--seed`
- `SaveLoads1.c:666` : si `Seed > 0` (déjà positionné), ignorer le seed du fichier

### CompileProcs.c — Poids infini `<inf>` (FEEDBACK #16)

Le `°` (poids infini BP2) ne passe plus en UTF-8. Ajout de `<inf>` comme alternative :
```c
if(c == 'i' && *((*qq)+1) == 'n' && *((*qq)+2) == 'f') {
    (*qq) += 3;  // skip "inf"
    n = INT_MIN;  // infinite weight
}
```

### cJSON.c — Buffer overflow snprintf (FEEDBACK #29)

`snprintf` avec taille hardcodée `5` → `sizeof(output_pointer)`.

---

## Refactorings

### Polymetric.c — Conversion récursive → itérative + fix use-after-free (FEEDBACK #18)

La réécriture itérative de `PolyExpand()` utilise un stack explicite (`_PolyFrame`). Le `realloc` du stack invalidait les pointeurs `pp_a`, `p_pos`, `p_P`, `p_Q`, `p_fixtempo`, `p_onefielduseful`, `p_maxid`.

Fix : `_refs_frame_idx` stocke l'index du frame référencé. Après chaque `realloc`, les 7 pointeurs sont recalculés depuis l'index. Pré-allocation à 256 frames (au lieu de 16).

### FillPhaseDiagram.c + TimeSet.c — `MakeEmptyTokensSilent()` (FEEDBACK #23)

Code inline dans `FillPhaseDiagram()` (~ligne 619) qui convertissait T4 → silent sound objects extrait dans une fonction dédiée, appelée dans `TimeSet.c` AVANT `FillPhaseDiagram()`. Évite les incohérences de `Jbol` pendant le parcours du phase diagram.

### Compute.c + ProduceItems.c + MakeSound.c — ItemNumber / MaxItemsProduce (FEEDBACK #25)

Refactoring complet du comptage de production :

| Fichier | Changement |
|---------|-----------|
| Compute.c:162 | `ItemNumber = 1` forcé → commenté |
| Compute.c:793 | `BalancedPoly()` check + `ItemNumber++` avant `PrintResult()` |
| Compute.c:830 | Condition `changed` ajoutée pour éviter les doublons |
| ProduceItems.c:53 | Guard `!WriteMIDIfile` sur message improvisation |
| ProduceItems.c:200 | Guard `MaxItemsProduce > 0` avant comparaison |
| ProduceItems.c:283 | Logique séparée pour WriteMIDIfile/rtMIDI/texte |
| MakeSound.c:122 | `ItemNumber++` et check `MaxItemsProduce` en début de MakeSound |

---

## Nouvelles fonctions

### DisplayThings.c — `BalancedPoly()` (FEEDBACK #24)

```c
int BalancedPoly(tokenbyte ***pp_a);
```

Vérifie qu'un buffer a des accolades polymétriques équilibrées (T0/12 ouvrante, T0/13 fermante) et au moins un terminal ou variable. Utilisée dans `Compute.c` pour filtrer les items intermédiaires vides pendant `UseEachSub`.

### FillPhaseDiagram.c — `MakeEmptyTokensSilent()` (FEEDBACK #23)

```c
int MakeEmptyTokensSilent(tokenbyte ***pp_buff);
```

Convertit les variables non résolues (T4) en silent sound objects avant le parcours du phase diagram. Extrait du code inline de `FillPhaseDiagram()`.

---

## Initialisations et protections

### GetRelease.c — Initialisation sound objects (FEEDBACK #26)

`MakeSoundObjectSpace()` : initialisation de 36+ champs par sound object (pointeurs MIDI/Csound → NULL, flags → FALSE/TRUE, bornes → Infpos, etc.). Avant : seuls `p_MIDIsize` et `p_CsoundSize` étaient initialisés.

### ConsoleMessages.c — NULL checks destinations (FEEDBACK #27)

Chaque `vfprintf(gOutDestinations[...])` vérifie que le pointeur n'est pas NULL. Appliqué à 6 destinations. `NumberMessages++` déplacé dans le bloc `odInfo` / non-WASM.

### ConsoleMain.c — `NoTracePath` + guard graphiques (FEEDBACK #28)

Variable globale `NoTracePath` (déclarée dans `-BP3decl.h`). Protège contre les écritures graphiques quand aucun chemin trace n'est fourni. `CreateImageFile()` met `N_image = 0` au lieu de désactiver `ShowGraphic`.

**Fix 2026-04-02 :** Guard `NoTracePath` ajouté dans `ConsoleMain.c` après `PrepareTraceDestination()` et avant le switch d'action :
```c
if(NoTracePath) {
    ShowObjectGraph = ShowPianoRoll = ShowGraphic = FALSE;
}
```
Le guard dans `SaveLoads1.c` (ligne 704, précédemment commenté) a aussi été décommenté, mais il est insuffisant seul car `LoadSettings()` est appelé **avant** `PrepareTraceDestination()` — donc `NoTracePath` n'est pas encore TRUE quand `LoadSettings()` s'exécute.

**Cause racine :** Les settings JSON (ex: `-se.Vina`) peuvent avoir `ShowObjectGraph=1`, ce qui force `ShowGraphic=TRUE` (ligne 758). Sans trace path, `imagePtr` reste NULL → crash dans `Graphic.c:1388` (`fputs(line, imagePtr)`) ou boucle infinie dans le pipeline graphique.

**Grammaires corrigées :** vina (segfault), vina2 (segfault), Watch_What_Happens (timeout infini).

---

### bp3_random.c/.h — RNG portable MSVC (FEEDBACK #31)

Nouveau fichier `bp3_random.c` + `bp3_random.h` : LCG identique à MSVC (`seed * 214013 + 2531011`, `RAND_MAX = 32767`). Remplace tous les appels `rand()`/`srand()`/`RAND_MAX` dans le moteur.

Fichiers modifiés : `Misc.c` (6× srand, 2× rand), `Compute.c` (3× rand, 4× RAND_MAX), `Zouleb.c` (2× rand, 2× RAND_MAX), `SetObjectFeatures.c` (1× rand, 1× RAND_MAX), `MakeSound.c` (1× rand, 1× RAND_MAX), `ScriptUtils.c` (1× srand).

**Impact :** bp3 Linux/WASM produit maintenant les mêmes séquences aléatoires que bp.exe Windows pour le même seed. Score S0=S1 : 26/30 EXACT (était ~18/30).

---

## Headers modifiés

| Fichier | Changement |
|---------|-----------|
| `-BP3.h` | `FIELDSIZE` 100 → 1000 (FEEDBACK #17), version 3.3.19, `#include "bp3_random.h"` |
| `-BP3.proto.h` | Déclarations `BalancedPoly()`, `MakeEmptyTokensSilent()`, `CheckItemProduced(force)` |
| `-BP3decl.h` | Déclaration `NoTracePath` |
| `-BP3main.h` | Définition `NoTracePath`, init `NumberMessages = 0` |

---

## Fichiers non modifiés fonctionnellement

| Fichier | Nature du diff |
|---------|---------------|
| SetObjectFeatures.c | Blancs/commentaires supprimés uniquement |
| SaveLoads3.c | Typo "BP2" → "BP3" dans commentaire |
| Strings.c | Ligne commentée supprimée |
| Inits.c | `Seed = 1` → `NumberMessages = 0` (init) |
| Misc.c | `Notify()` destination `odError` → `odInfo`, `Seed = 0L` (type) |
