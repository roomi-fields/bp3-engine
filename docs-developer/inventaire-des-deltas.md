# Inventaire des écarts avec le moteur de Bernard

Établi le 2026-08-12 par comparaison de `HEAD` avec le tag amont `v3.5.1`, sur `source/BP3/`.

```
git diff v3.5.1 HEAD -- source/BP3/
```

15 fichiers, 244 insertions, 67 suppressions. Le tag n'est pas un ancêtre de notre branche : notre
arbre a été construit par reprise de fichiers, et la comparaison porte sur le contenu.

## Ce que ces écarts changent à la production — mesuré

Le moteur amont pur se construit avec notre chaîne, à partir d'un arbre de travail sur le tag :
`git worktree add --detach <zone> v3.5.1`, puis notre `Makefile` et notre `build.sh`. Mêmes
drapeaux, même compilateur, seule la source diffère. Empreinte du binaire amont ainsi obtenu :
`06244c55d11bd9496c6e7187afea2787`. Le nôtre : `372dd047bc52fd152ff51ec6715fae74`.

`scripts/confronter-amont.py` fait tourner les deux sur l'assiette scellée, avec l'invocation de
`baseline-native/capture.py`, et compare octet pour octet les axes que les deux savent produire.

| axes réclamés | résultat sur les 91 |
| --- | --- |
| texte + liste d'événements + fichier MIDI + console | **86 identiques**, 4 non déterministes, 1 ligne de durée |
| liste d'événements **seule** | **61 divergentes** — notre liste est vide, celle de l'amont est pleine |

Les 4 non déterministes — `Nadaka-1er-essai`, `dhin`, `tryAllItems0`, `tryhomomorphism` — tirent
leurs empreintes du **même vivier des deux côtés** : 20 essais par binaire donnent les mêmes
valeurs dominantes dans les mêmes proportions. La cinquième porte
`Phase-diagram filling time`, ligne qui ne s'imprime qu'au franchissement d'une seconde.

Sur les 61, le rapport est unanime : **61 fois notre liste vide contre une liste pleine, zéro fois
l'inverse, zéro liste pleine des deux côtés mais différente.** Une cause unique.

## Le retrait des conditionnelles WASM ne touche pas le natif

Chacun des six retraits garde la branche `#else` — celle que le natif compilait — mot pour mot.
`CompileProcs.c:1328` et `Encode.c:321` le montrent : seule la branche `__BP3_WASM__` disparaît.

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

Cas minimal, depuis `capture-run/`, mêmes réglages et même graine des deux côtés :

```
bp3 produce -e -gr <-gr.765432 nettoyée> --seed 1 -se ../test-data/-se.765432 \
    -o /dev/null --traceout <fichier>
```

| binaire | code de sortie |
| --- | --- |
| amont `06244c55` | 0 |
| nôtre `372dd047` | 139 — signal 11 |

Le gabarit `CANVAS_header.txt` n'existe dans **aucune** branche amont — ni `master`, ni
`graphics-for-BP3`, ni `BP3-develop — ni nulle part dans la tour. Le fichier manquant n'est donc
pas une lacune de notre copie : c'est un fichier de la distribution web, hors dépôt moteur. Le
défaut est le garde manquant, et il est à nous.

### `PlayThings.c` — deux conditions sur la liste d'événements

L'amont porte `if(!ShowPianoRoll && !onlypianoroll && !EventListOn)` et
`else if(OutCsound || WriteMIDIfile || EventListOn || rtMIDI || OutBPdata)`. Notre arbre a perdu
les deux mentions de `EventListOn`. Ces conditions décident d'appeler `MakeSound`, et c'est
`MakeSound` qui remplit la liste (`MakeSound.c:856`, `AddEventToList`).

**Notre arbre rend une liste d'événements vide quand elle est la seule sortie réclamée.**
61 grammaires de l'assiette sur 91. Cas minimal, depuis `capture-run/` :

```
bp3 produce -e -gr <-gr.Alarm nettoyée> --seed 1 -al ../test-data/-ho.Frenchnotes \
    --eventlistout <fichier>
```

| binaire | lignes écrites |
| --- | --- |
| amont `06244c55` | 32 |
| nôtre `372dd047` | 1 — l'en-tête seul |

Réclamer **une seconde sortie** rétablit la liste : `-o`, ou `--midiout`, ou `--csoundout` arme
une des autres mentions de la condition et masque celle qui manque. La mesure qui réclame
plusieurs axes à la fois ne peut donc pas voir cet écart.

### `MIDIdriver.c` — un bloc de reprise du serveur CoreMIDI

Notre arbre relance `MIDIServer` par `system("killall MIDIServer")` là où l'amont v3.5.1 rend un
message d'erreur et abandonne. Code macOS, sans effet sur la construction Linux.

### `PlayThings.c` et `ConsoleMain.c` — deux écarts mineurs

Un bloc de terminaison de production mis en commentaire dans `PlayBuffer`, et un message de
`CreateImageFile` passé de `odError` à `odInfo`.

## Ce que le flux de jetons doit au moteur, et ce qu'il nous doit

Le flux de jetons est à nous : l'amont ne le connaît pas, aucune confrontation avec lui ne
l'atteint. Sa fidélité se mesure contre la liste d'événements native, écrite par le moteur sur les
mêmes données et dans la même exécution — `scripts/confronter-jetons-liste.py`.

**Les instants viennent du moteur, sans arithmétique.** Les deux sorties parcourent `p_Instance`
dans l'ordre des `k` croissants ; appariés dans cet ordre, les instants concordent exactement.
`kss2` : 97 jetons, 97 événements, **97 débuts et 97 fins identiques**. Une soustraction de la
quantification vivait dans le sérialiseur jusqu'au 2026-08-12 ; elle en est sortie.

**Le nom vient de nous.** La liste native écrit le prototype tel qu'il est écrit
(`EventListfiles.c:152`, sans transposition) ; le sérialiseur applique `TransposeKey` puis
`ExpandKey` et nomme la note obtenue. Sur `mohanam`, la colonne `transpos` vaut −24 : la liste dit
`ga6`, le jeton dit `ga4`, et le fichier MIDI joue 64. **C'est le jeton qui nomme ce qui sonne.**

**La sélection vient de nous.** Le sérialiseur écarte les silences, les jetons dont le nom
commence par `_`, `/` ou `?`, et les bols sans prototype MIDI sauf objet sonore silencieux. Le
moteur n'a pas cette notion : la liste native porte les instances écartées.

**Réclamer la liste d'événements change le flux de jetons.** `mohanam` rend 755 jetons quand
`--tokensout` est seul, 783 quand `--eventlistout` l'accompagne ; `ruwet`, 2528 contre 2655. Le
flux seul est stable — cinq essais, même compte. C'est le constat #71 sur l'axe des jetons : les
deux sorties ne se lisent pas d'une seule exécution sans se perturber.

## Écarts de droits seuls

`EventListfiles.c`, `Polymetric.c`, `cJSON.c` : passage de `100755` à `100644`, contenu identique.
