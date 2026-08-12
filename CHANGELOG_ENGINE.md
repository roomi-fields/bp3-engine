# Changelog — Moteur BP3 (source/BP3/)

Modifications au code moteur de Bernard, appliquées dans `source/BP3/` (branche `wasm`).
L'objectif est que Bernard les intègre dans son propre arbre.

Les entrées antérieures au 2026-08-11 nomment `csrc/bp3/` : c'était l'arbre partagé avec le
portage WASM, replié depuis dans `source/BP3/`.

Chaque section référence le point correspondant dans `FEEDBACK_BERNARD.md` (test/grammars/ du repo BPscript).

---


## 2026-08-12 — la mesure se prend avant la compensation de gigue (`TokensOut.c`)

Décision de Romain : la capture doit porter les instants que le moteur **produit**, pas ceux
qu'une compensation a corrigés.

`TokensOut.c` retranchait la quantification des deux bornes de chaque jeton quand le taux de
compression dépassait 2 — portage de `wasm_kpress_offset` (#35). Cette soustraction est retirée :
`start_ms` et `end_ms` sortent tels que `p_Instance` les porte.

**Effet mesuré**, binaire à binaire, corpus à graine figée :

- `transposition3` : les jetons passent de `E1 −10 → 1300` à `E1 0 → 1310`, et coïncident
  désormais **exactement** avec la liste d'événements et avec le premier `NoteOn` du fichier MIDI,
  tous deux à 0 ms. Plus aucun instant négatif.
- L'écart est **uniforme par grammaire** et vaut la quantification du réglage, quand le taux de
  compression annoncé par le moteur dépasse 1 : `acceleration` +10 sur les 78 jetons, `Djinns` +50
  sur les 895.
- Les grammaires dont le taux annoncé vaut 1 sont **inchangées** : `kss2` 97 jetons, `765432`
  823 jetons, `Nadaka-1er-essai` 4 jetons, écart nul sur les deux bornes.

Mesure et preuves : `docs-developer/instant-negatif.md`.

Binaire : `Version 3.5.1`, md5 `372dd047bc52fd152ff51ec6715fae74`, archive
`builds/v3.5.1-iso.2/bp3`. Le précédent reste `fb6df5ad5ee18a0398ae3cdb1817287d`
(`builds/v3.5.1-iso.1/bp3`). **La chaîne de version affichée est identique dans les deux** — seule
l'empreinte les distingue.


## 2026-08-08 — passage du moteur amont v3.5.0 → v3.5.1

Amont : Bernard publie **v3.5.1** (tag `v3.5.1`, `4897d7d`, ligne graphics-for-BP3). Diff
`v3.5.0`→`v3.5.1` = 16 fichiers source, ~484 insertions, dont du **code de minutage**
(`TimeSet.c`, `TimeSetFunctions.c`, `MakeSound.c`, `SetObjectFeatures.c`, `SoundObjects2/3.c`,
`FillPhaseDiagram.c`, `GetRelease.c`) + `EventListfiles.c`, `SaveLoads1.c`.

Portage : les 13 fichiers partagés changés étaient identiques à l'amont v3.5.0 chez nous →
repris tels quels dans `csrc/bp3/`. `EventListfiles.c` (natif-seul) repris tel quel. Seul
`Graphic.c` (natif-seul, notre delta graphique) fusionné à trois voies, propre. Aucun renommage
de struct cette fois.

**Effet mesuré sur le minutage — RIEN.** Non-régression `bp3-3.5.0` vs `bp3-3.5.1`, corpus
entier à graine figée, comparaison texte + jetons minutés : **identiques partout**. Seuls
`cloches1` (timeout des deux côtés, grammaire à limite de calcul) et `watch` (variance de charge
en parallèle ; **identique** vérifié en série : 2105 jetons des deux côtés) sortent, aucun n'est
une divergence de version. En particulier **Visser.Waves = 366 événements, fin 186 291 ms,
identique en 3.5.0 et 3.5.1** (`--eventlistout` seul, graine 1) — les chiffres de la flotte du
2026-08-08 restent valides, rien à remesurer.

Binaire : `Version 3.5.1`, md5 `963c1ff9512b453e97bdbbbd5f8aae4a`. Oracles précédents préservés
(3.5.0 `5877fa2…`, 3.4.7 figé `0fa0f3d…`). Procédure de montée + traçabilité : `ORACLE-BINAIRE.md`.

## 2026-08-04 — passage du moteur amont v3.4.7 → v3.5.0 (liste d'événements)

Amont : Bernard publie **BP3 v3.5.0**, première version à produire une **liste détaillée
d'événements sonores en texte** (option `--eventlistout`, CSV) plus un **JSON de description des
prototypes d'objets sonores**. But annoncé : remplacer à terme les sorties MIDI et Csound pour
connecter des dispositifs sonores.

Portage sur notre arbre restructuré (`csrc/bp3/` partagé + `source/BP3/` natif), diff amont
`9b68cfe`→`v3.5.0` = 25 fichiers, ~458 insertions. Méthode : mesure de divergence par fichier,
reprise directe des fichiers sans delta local, fusion à trois voies (`git merge-file`) pour les 3
qui portent nos deltas.

- **15 fichiers partagés repris tels quels** dans `csrc/bp3/` (identiques à l'amont 3.4.7 chez
  nous) : `-BP3.h -BP3.proto.h -BP3decl.h -BP3main.h FillPhaseDiagram.c Inits.c MakeSound.c Misc.c
  ProduceItems.c SaveLoads1.c SetObjectFeatures.c SoundObjects2.c TimeSet.c TimeSetFunctions.c
  Zouleb.c`.
- **3 fichiers fusionnés** (nos deltas + 3.5.0) :
  - `csrc/bp3/ConsoleMain.c` : garde nos options `--tokensout`/`--trace-production`/chmod, ajoute
    l'option amont `--eventlistout`.
  - `source/BP3/PlayThings.c` (natif-seul) : garde notre hook `EmitTimedTokensItem` (oracle
    `--tokensout`), prend la ligne de trace amont.
  - `source/BP3/Graphic.c` (natif-seul) : fusion propre.
- **Nouveau fichier** `source/BP3/EventListfiles.c` (natif-seul, auto-globé par le Makefile).
  ⚠️ Pas encore ajouté à la liste WASM (`WASM_BP3_SRCS`) : `--eventlistout` est **natif seulement**
  pour l'instant.
- **3 fichiers natif-seul repris** : `CsoundScoreMake.c MIDIfiles.c MIDIstuff.c`.
- **Renommage de struct amont absorbé** : `s_SoundObjectInstanceParameters.lastistranspose`
  → `transposefirst` (3.5.0). Impact sur NOS fichiers qui lisent ce champ :
  `source/BP3/TokensOut.c` (natif) et `csrc/wasm/bp3_api.c`, `csrc/wasm/bp3_wasm_stubs.c` (voir
  CHANGELOG_WASM.md). Pur renommage, sémantique inchangée.

Vérifs : natif construit `Version 3.5.0`, `--eventlistout` présent ; **non-régression 111/113
identiques** au corpus (graine figée) vs 3.4.7 — les 2 écarts sont des non-régressions
(`cloches1` timeout des deux côtés ; `trySerial` ordre non-déterministe déjà marqué
`capture_comparable:false`). WASM construit. 21 gardes vertes après commit (le canari
`gate-legacy-injection.sh` = `csrc/bp3/Misc.c` exige que le changement soit committé).

## 2026-07-19 — passage du moteur amont v3.4.4 → v3.4.7

Fusion à trois versions (base de fork `b094e18` / notre arbre / amont `39512c9`) via
`git merge-file` : **39 fichiers repris de l'amont tels quels, 1 fusionné, zéro conflit**.

**Nos modifications locales à `csrc/bp3/` se réduisent à 14 lignes dans un seul fichier** —
`ConsoleMain.c`, la déclaration et l'analyse du drapeau `--tokensout`. Elles sont intactes.
`bp3_timed_events.c/.h` nous sont propres et n'existent pas en amont.

Deux obstacles hors des fichiers partagés, à connaître pour la prochaine montée de version :

- **Les fichiers natif-seul de `source/BP3/` ne suivent pas automatiquement.** `IN` et `OUT`
  étaient des `#define` en v3.4.4 (`-BP3.h:146-147`) et ont disparu en v3.4.7 : `MIDIstuff.c`
  et `MIDIdriver.c` ne compilaient plus. Quatre fichiers amont mis à jour (`Graphic.c`,
  `MIDIdriver.c`, `MIDIstuff.c`, `PlayThings.c`). `TokensOut.c` est le nôtre et reste.
- **Nouvelle dépendance libcurl**, inconditionnelle (`-BP3.h:97`), pour la seule fonction
  `enter_notes` (`ConsoleMain.c:307`). Côté natif : `libcurl4-openssl-dev` et un passage par
  `pkg-config` dans le `Makefile` — pas de chemin d'inclusion figé, l'en-tête est au chemin
  multiarch. Côté WASM : voir `CHANGELOG_WASM.md`.

**Bug moteur #55 résolu par cette montée**, vérifié sur pièces avec `scripts/verif-bug55.sh` :
un fichier `-cs` privé de sa seule ligne `_end tables` faisait boucler la v3.4.4 sans retour
après 45 s ; la v3.4.7 rend la main en 0 s, `Errors: 0`.

**Bug #56 : la limite de temps réactivée n'interrompt pas `-gr.cloches1`** — mesuré sur v3.4.7,
graines 1 et 2, plus de 80 s. Retour transmis à Bernard Bel.

## 2026-06-14 — Sérialiseur timed-tokens NATIF `--tokensout` (oracle unique)

Cap : `hub/decisions/2026-06-14-oracle-natif-trois-voies.md` (oracle = bp3 natif).
Le dump JSON des timed-tokens n'existait qu'en API WASM (`bp3_get_timed_tokens`,
`csrc/wasm/bp3_api.c:760`). Port fidèle en sortie native :

- **`ConsoleMain.c`** (partagé) : flag CLI `--tokensout <fichier>` → global `TokensOutFile`.
  Symbole défini ici donc présent aussi dans le build WASM (inutilisé) — pas de rupture de lien.
- **`PlayThings.c`** (natif-only) : appel après `TimeSet` (AVANT `MakeSound`), au même point
  que le WASM (où MakeSound est désactivé) → iso par construction.
- **`TokensOut.c`** (NOUVEAU, natif-only) : sérialiseur, port de `bp3_get_timed_tokens` en
  verbose=0 (tokens sonnants — niveau des snapshots `s3_timed`). Reprend : scan T47/SSO depuis
  `pp_buff`, offset Kpress `#35` (`Kpress>=2 → −Quantization`), résolution de nom via
  `PrintThisNote`/`ExpandKey`/`TransposeKey`, filtre contrôles/non-sonnants. Format JSON
  identique : `[{"token","start","end"}, …]`. Items concaténés (process CLI mono-coup).

Build natif linux OK (TokensOut.o linké). Dépendance de build : `libasound2-dev`
(installée sur PC2 ; `-BP3.h` inclut `<alsa/asoundlib.h>` sans condition côté Linux).

**Parité de timing natif↔WASM confirmée** (`BPscript/test/s3_native.cjs`, lecture seule,
sur les snapshots `s3_timed` existants — AUCUNE re-capture, #48-#52 ouverts) :
- **12 MATCH exacts** dont not-reich (580), visser3 (401), mozart-dice (269), acceleration
  (Kpress, 78), drum, graphics, time-patterns, livecode1, ames, harmony, vina.
- **7 DIFF expliqués, hors sérialiseur** : visser5/visser-waves/visser-shapes = couches de
  correction WASM NON portées (#33 dedup keep-longest, #35) — le natif émet TimeSet brut et
  fait foi ; kss2/ruwet = divergences moteur connues (budget séparé) ; alan/beatrix-dice =
  Improvize (±1). À réconcilier lors de la re-génération des oracles (après #48-#52).
- **Note « durées à méfiance / ConsoleStubs » TRANCHÉE** : les durées natives sont fidèles ;
  les écarts viennent de correctifs post-hoc côté WASM, pas du timing. Note périmée.
- **Divergence d'AFFICHAGE de nom** (one-scale, tryShruti) : sur gamme invalide
  (`i_scale > NumberScales`), `PrintThisNote` natif n'écrit rien (nom vide) là où le WASM
  rendait `<keynum>`. Timing identique. `note_name` est désormais initialisé à `""` avant
  `PrintThisNote` (comme le WASM) pour éviter un buffer non initialisé. Le natif fait foi.

---

## 2026-06-14 — Intégration upstream Bernard v3.4.4 (`graphics-for-BP3`) + solde du sous-module

Le working-tree était SALE (43 fichiers, ~846 lignes, non committés) depuis la session
moteur-wasm antérieure. Enquête de provenance : ces modifications portent le moteur de
**v3.4.2 (HEAD `f3fd899`) à v3.4.4** (`upstream/graphics-for-BP3` @ `d23b8c4`).

- **17 fichiers /19 byte-identiques à l'upstream v3.4.4** : adoption propre (Compute.c,
  DisplayThings.c, FillPhaseDiagram.c, GetRelease.c, ProduceItems.c, SetObjectFeatures.c,
  TimeSet.c, DisplayArg.c, SaveLoads1.c, Polymetric.c, Strings.c, Inits.c, Interface2.c,
  et les 4 en-têtes `-BP3*.h`).
- **2 fichiers gardent un delta local** (working-tree plus ancien que v3.4.4) :
  - `ConsoleMain.c` — `chmod 0775 → 0777` sur écriture de fichier (ajustement droits
    système de fichiers natif). Bénin, conservé en l'état.
  - `CompileGrammar.c` — ⚠️ **réactive `ReleaseAlphabetSpace()`** que Bernard a désactivé
    le 2026-05-08 dans v3.4.4 (chemin du crash **#48** sur alphabets à tiret final `do4-`) ;
    réactive aussi les messages « Alphabet is incorrect… » ; conserve la borne `MAXLIN`
    au lieu de `strlen`. **Divergence connue vs v3.4.4 — à réconcilier lors d'une prochaine
    synchro Bernard ; touche au comportement moteur, donc hors du présent solde.**

`csrc/bp3/` et `source/BP3/` portent un jeu de modifications identique (miroir vérifié).
**Aucun rebuild** : commit de la source uniquement, pour solder le sous-module sale.
Le `dist` actuellement déployé provient déjà de cet arbre. Re-capture S0/snapshots
interdite tant que les bugs #48-#52 ne sont pas résolus.

---

> **2026-04-05 — TOUS LES FIXES CI-DESSOUS ONT ÉTÉ INTÉGRÉS PAR BERNARD DANS SA V3.3.19**
>
> `csrc/bp3/` = `source/BP3/` (diff = 0). Ce changelog est maintenant un historique.
> Les points ouverts non résolus sont dans FEEDBACK_BERNARD.md (#32, #33, #35, #36, #38, #39).

---

## Bugs corrigés (post v3.3.19)

### CompileGrammar.c — copy_grammar alloue de "faux Handles" → crash MyGetHandleSize (#45)

**Root cause :** `copy_grammar()` dans `CompileGrammar.c` alloue 4 buffers de règle
(`p_leftarg`, `p_rightarg`, `p_leftcontext->p_arg`, `p_rightcontext->p_arg`) avec
`malloc(sizeof(tokenbyte*))` puis `malloc(count * sizeof(tokenbyte))` — un vrai
"handle Mac-style" (pointeur vers pointeur), PAS un Handle Anthony (`s_handle_priv*`).

Du coup, tout appel ultérieur à `MyGetHandleSize()` sur ces buffers lit `h->size` à
l'offset 8 octets **hors du malloc de 8 octets** → heap-buffer-overflow. Confirmé par
AddressSanitizer sur Bernard :
```
READ of size 8 at ... (0 bytes after 8-byte region)
    #0 MyGetHandleSize ConsoleMemory.c:120
    #1 LengthOf PlayThings.c:1005
    #2 StructuralRule ProduceItems.c:1082
    #3 LastStructuralSubgrammar ProduceItems.c:1055
    allocated by: malloc+copy_grammar CompileGrammar.c:1999
```

**Symptôme :** Crash systématique du mode `templates` dès qu'une règle contient un
marqueur structurel (T2, T5, ou opérateurs `+ : ; = / \`) — dépend de l'ASLR ailleurs,
mais ASan le détecte toujours.

**Fix (csrc/bp3/CompileGrammar.c) :** Remplacement des 4 paires `malloc/malloc` par un
seul `GiveSpace()` qui construit un vrai `s_handle_priv` :

```c
// AVANT (×4) :
dest_rule->p_X = (tokenbyte **)malloc(sizeof(tokenbyte *));
*dest_rule->p_X = (tokenbyte *)malloc(count * sizeof(tokenbyte));
memcpy(*dest_rule->p_X, *src_rule->p_X, count * sizeof(tokenbyte));

// APRÈS (×4) :
dest_rule->p_X = (tokenbyte **)GiveSpace((Size)(count * sizeof(tokenbyte)));
if (dest_rule->p_X == NULL) { ... return; }
memcpy(*dest_rule->p_X, *src_rule->p_X, count * sizeof(tokenbyte));
```

Fonctionnellement identique pour le code appelant (`**p_X` donne toujours les données,
car `*p_X == h->memblock`), mais maintenant `MyGetHandleSize()` renvoie correctement
`count * sizeof(tokenbyte)`.

Le bloc de libération miroir (`free(*rule->p_X); free(rule->p_X);`) était déjà
commenté ("Proposed by Claude AI, not used"). Rien à faire côté dealloc.

**Affecte les 3 targets** (linux, windows, wasm) via `csrc/bp3/CompileGrammar.c`.

---

### FillPhaseDiagram.c — Plot(ANYWHERE) écrase les sentinelles -1 (#42)

**Root cause :** `Plot(ANYWHERE)` cherche un slot libre dans le diagramme de phase avec
`if(oldk > 1) continue;`. Or le terminateur de séquence `-1` satisfait `oldk <= 1`,
donc `ANYWHERE` le traite comme un slot libre et l'écrase par un objet `_script()`.

**Symptôme :** Sans terminateur `-1`, la boucle `while(seq[++inext] == 0)` dans
`Calculate_alpha()` (SetObjectFeatures.c:975) dépasse le buffer → **segfault en natif**,
**timestamps=0 en WASM** (le crash est attrapé silencieusement).
Se manifeste quand le diagramme est assez dense (ex: visser-shapes avec 26+ tags `_script(CT N)`).

**Fix (FillPhaseDiagram.c:1995) :**
```c
// AVANT :
if(oldk > 1) continue;
// APRÈS :
if(oldk > 1 || oldk == -1) continue; /* Don't overwrite end-of-sequence sentinel */
```

**Affecte les 3 targets** (linux, windows, wasm) via `csrc/bp3/FillPhaseDiagram.c`.

---

### ScriptUtils.c + console_strings.json — CT catchall pour _script(CT N) (#43)

**Ajout :** `"193 CT _any_"` dans `console_strings.json` (ScriptCommand table) et `case 193: break;`
dans `DoScript()` (ScriptUtils.c). Permet au moteur d'accepter `_script(CT N)` comme commande
valide (no-op passthrough) au lieu de les rejeter comme commande inconnue.

**Affecte :** natif (`csrc/bp3/ScriptUtils.c`) + WASM (`csrc/wasm/console_strings.json`).

---

### GetRelease.c — Mémoire non initialisée p_DefaultChannel (#39)

**Root cause :** `CreateObjectSpace()` n'initialise `p_DefaultChannel` que pour j=0,1 (boucle ligne 939).
Les indices 2..jmax restent non initialisés après `GiveSpace`. De plus, `ResizeObjectSpace()` n'initialise
les nouveaux slots que si `Nature_of_time == SMOOTH` (condition 2024-07-25), excluant les grammaires STRIATED.

**Symptôme :** Avec ASLR, `p_DefaultChannel[j]` contient des valeurs aléatoires (64, 96...) →
`'X' has channel 64. Should be 1..16` → crash MIDI intermittent (~30-40% des runs).

**Fix (3 points dans GetRelease.c) :**
1. `MakeSoundObjectSpace()` : ajout `(*p_DefaultChannel)[j] = 0` dans la boucle j=2..jmax (ligne 936)
2. `ResizeObjectSpace()` : `memset(*p_DefaultChannel, 0, maxsounds)` après `MySetHandleSize` (ligne 1099).
   Nécessaire car `Jbol` est déjà mis à jour quand on arrive dans ResizeObjectSpace — la boucle d'init
   conditionnelle (j=Jbol..maxsounds) ne couvre pas les slots fraîchement alloués.
3. `ResizeObjectSpace()` : suppression de la condition `Nature_of_time == SMOOTH` (ligne 1142) pour que
   l'init complète des propriétés s'exécute pour toutes les grammaires, pas seulement SMOOTH.

**Grammaires corrigées :** kss2 (50/50 déterministe), look-and-say (50/50 déterministe).
Workaround `setarch x86_64 -R` retiré de s1_native.cjs.

**Affecte les 3 targets** (linux, windows, wasm) via `csrc/bp3/GetRelease.c`.
Le bug ne se manifeste pas en WASM (Emscripten zero-init le heap) mais le fix est correct partout.

---

## Bugs corrigés (intégrés dans v3.3.19)

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

### SetObjectFeatures.c — Pitchbend 16384→16383 (fix Bernard, 2026-04-02)

`_pitchbend(+200)` pouvait atteindre la valeur 16384 (hors range MIDI 0–16383). Le moteur retournait `Infpos` (erreur fatale).

Fix de Bernard : clamp `16384→16383`, erreur non-fatale (retourne la valeur clampée au lieu de `Infpos`).

```c
if(x == 16384) x = 16383;
// ... range check ...
if(x < 0) x = 0;
if(x >= 16384) x = 16383;
return(x);  // au lieu de return(Infpos)
```

### ProduceItems.c — Variable `force` non initialisée (2026-04-02)

`force` déclarée mais non initialisée dans `AllFollowingItems()`. En natif (`source/BP3/`), `force = FALSE;` est présent ligne 764. Dans `csrc/bp3/` cette initialisation manquait → valeur garbage → items supplémentaires produits (off-by-one, ex: asymmetric S2=339 vs S1=318).

Fix : ajout `force = FALSE;` après la ligne d'initialisation des autres variables.

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
