# Inventaire des écarts avec le moteur de Bernard

Établi le 2026-08-12 par comparaison de `HEAD` avec le tag amont `v3.5.1`, sur `source/BP3/`.

```
git diff v3.5.1 HEAD -- source/BP3/
```

15 fichiers, 244 insertions, 67 suppressions. Le tag n'est pas un ancêtre de notre branche : notre
arbre a été construit par reprise de fichiers, et la comparaison porte sur le contenu.

## Nos fichiers — créés ici, modifiables librement

| fichier | ce qu'il porte | depuis |
| --- | --- | --- |
| `TokensOut.c` | sérialiseur des jetons minutés, sortie `--tokensout` | 2026-06-14, `0e01dcd` |
| `bp3_timed_events.c` | structures du même sérialiseur | 2026-06-14 |
| `bp3_timed_events.h` | leurs déclarations | 2026-06-14 |

`TokensOut.c` porte aujourd'hui le retrait de la soustraction de quantification — décision de
Romain du 2026-08-12, arbitrage relayé par l'architecte. **Le fichier est à nous.**

## Nos ajouts dans les fichiers de Bernard — déclarés

| fichier | écart | accord |
| --- | --- | --- |
| `ConsoleMain.c` | déclaration de `TokensOutFile` | 2026-06-14, chantier oracle |
| `ConsoleMain.c` | option `--tokensout` dans l'analyse des arguments | 2026-06-14, chantier oracle |
| `PlayThings.c` | appel de `EmitTimedTokensItem` après `TimeSet` | 2026-06-14, chantier oracle |
| `CompileProcs.c` · `ConsoleMessages.c` · `Encode.c` · `Misc.c` · `ProduceItems.c` · `ConsoleMain.c` | retrait des conditionnelles `__BP3_WASM__` | 2026-08-11, sortie du portage WASM, `CHANGELOG_ENGINE.md` |

## Écarts non déclarés jusqu'ici, trouvés par cet inventaire

Ils portent tous la même signature : l'amont a **ajouté** du code que notre reprise n'a pas gardé.

### `Graphic.c` et `ConsoleMain.c` — cinq gardes de pointeur nul manquants

L'amont teste `imagePtr == NULL` en cinq points : `DrawItem:131`, `DrawObject:391`,
`DrawItemBackground:1077`, `DrawPianoNote:1242`, `DrawNoteScale:1293`. Notre arbre n'en porte
aucun.

Et dans `CreateImageFile`, l'amont éteint le dessin sur chaque échec —
`imagePtr = NULL; ShowGraphic = FALSE; return;` — là où notre arbre écrit `imagePtr = NULL` seul,
sans éteindre le drapeau et sans sortir.

**C'est la cause du plantage sur l'option de trace** décrit dans
`volumestep-step-et-plantage-trace.md` : le gabarit `php/CANVAS_header.txt` manque, l'ouverture
échoue, le dessin reste armé, et l'écriture suivante déréférence un pointeur nul. Le moteur de
Bernard s'en garde ; le nôtre non.

Le gabarit `CANVAS_header.txt` n'existe dans **aucune** branche amont — ni `master`, ni
`graphics-for-BP3`, ni `BP3-develop — ni nulle part dans la tour. Le fichier manquant n'est donc
pas une lacune de notre copie : c'est un fichier de la distribution web, hors dépôt moteur. Le
défaut est le garde manquant, et il est à nous.

### `PlayThings.c` — deux conditions sur la liste d'événements

L'amont porte `if(!ShowPianoRoll && !onlypianoroll && !EventListOn)` et
`else if(OutCsound || WriteMIDIfile || EventListOn || rtMIDI || OutBPdata)`. Notre arbre a perdu
les deux mentions de `EventListOn`.

Mesure du 2026-08-12 : `--eventlistout` produit sa liste, avec ou sans `--midiout`. L'effet de
l'écart n'est pas établi.

### `MIDIdriver.c` — un bloc de reprise du serveur CoreMIDI

Notre arbre relance `MIDIServer` par `system("killall MIDIServer")` là où l'amont v3.5.1 rend un
message d'erreur et abandonne. Code macOS, sans effet sur la construction Linux.

### `PlayThings.c` et `ConsoleMain.c` — deux écarts mineurs

Un bloc de terminaison de production mis en commentaire dans `PlayBuffer`, et un message de
`CreateImageFile` passé de `odError` à `odInfo`.

## Écarts de droits seuls

`EventListfiles.c`, `Polymetric.c`, `cJSON.c` : passage de `100755` à `100644`, contenu identique.
