# Les vingt et un mots de contrôle, et les cinq cadences du continu

Mesures du 2026-08-14. Lecture du C sur `source/BP3/` à `HEAD`. Mesures de production sur
`builds/v3.5.1-iso.2/bp3`, empreinte `372dd047bc52fd152ff51ec6715fae74`, graine 1, réglages
`-se.checkAllCsound`, depuis `capture-run/`.

## Les vingt et un mots ont un corps

`scripts/mots-encore-implementes.py` établit les trois étages : **reconnu** par l'analyseur,
**encodé** en jeton ou en champ de règle, **consommé** par du code de production. Les fichiers
d'affichage et de trace sont exclus des consommateurs : y figurer prouve que le mot s'imprime.

Périmètre : les 54 fichiers `.c` et `.h` de `source/BP3/`. Dénominateur : 21 mots examinés,
**21 implémentés**, 0 sans corps.

| mot | porte | premier consommateur hors analyse et affichage |
| --- | --- | --- |
| `_capture` | `T45` | `FillPhaseDiagram.c:1556` |
| `_modrate` | `T23` | `Compute.c:1650` |
| `_pancontrol` | `T31` | `Compute.c:1658` |
| `_panrate` | `T30` | `Compute.c:1657` |
| `_part` | `T46` | `Compute.c:1664` |
| `_pitchrate` | `T22` | `Compute.c:1649` |
| `_pressrate` | `T24` | `Compute.c:1651` |
| `_print` | champ `print` | `Compute.c:233` |
| `_printOff` | champ `printoff` | `Compute.c:244` |
| `_printOn` | champ `printon` | `Compute.c:243` |
| `_rest` | `T0` | `Compute.c:1627` |
| `_script` | `T13` | `ProduceItems.c:1210` |
| `_srand` | `T42` | `FillPhaseDiagram.c:1553` |
| `_step` | `T33` | `Compute.c:1660` |
| `_stepOff` | champ `stepoff` | `Compute.c:246` |
| `_stepOn` | champ `stepon` | `Compute.c:245` |
| `_tempo` | `T43` | `Polymetric.c:486` |
| `_traceOff` | champ `traceoff` | `Compute.c:248` |
| `_traceOn` | champ `traceon` | `Compute.c:247` |
| `_volumecontrol` | `T28` | `Compute.c:1655` |
| `_volumerate` | `T27` | `Compute.c:1654` |

### La portée exacte de ce verdict

Il porte sur le **code**, et il dit une chose précise : le jeton est lu par du code de production.
Il ne dit pas que le mot **change la sortie**.

`_step` le montre. Il figure au tableau avec quatre consommateurs, et la mesure du 2026-08-12 sur un
paramètre défini par l'utilisateur — `blurb` — trouve **cinq axes identiques** avec et sans le
contrôle : jetons, score Csound, fichier MIDI, liste d'événements, texte. Voir
`docs-developer/volumestep-step-et-plantage-trace.md`.

Un mot du tableau se déclare comme **existant dans le moteur**. Chaque effet demande sa propre
mesure.

## Les cinq cadences du continu

`_modrate` `_panrate` `_pitchrate` `_pressrate` `_volumerate`.

### Le plafond : 1000

`CompileProcs.c:1149-1173` porte la même condition pour les cinq : `k < 0 || k > 1000`. Le message
en `:1207-1210` est suivi de `return(ABORT)` : la compilation **s'arrête**, la valeur n'est jamais
écrêtée.

Mesuré sur les cinq, quatre valeurs chacun :

| valeur | résultat |
| --- | --- |
| 1000 | accepté |
| 1001 | refusé — `<Nom> rate range is 0..1000 samples/sec. Can't accept '<mot>(1001)'` |
| 0 | accepté, et n'émet aucun flux continu |
| −1 | refusé, même message |

### La cadence par défaut : 50 par seconde

Témoin : deux notes, volume de 20 à 120 en mode continu, 2000 ms au total.

| écrit | messages de contrôleur 7 | écart entre deux messages |
| --- | --- | --- |
| aucun mot de cadence | 152 | 20 ms |
| `_volumerate(50)` | 152 | 20 ms |
| `_volumerate(1)` | 103 | 1000 ms |
| `_volumerate(10)` | 112 | 100 ms |
| `_volumerate(200)` | 302 | 5 ms |
| `_volumerate(1000)` | 1102 | 1 ms |
| `_volumerate(0)` | 102 | aucun flux continu |

Sans mot de cadence, le compte et l'écart sont **exactement** ceux de `_volumerate(50)`.

### L'unité : des émissions par seconde

L'écart mesuré vaut `1000 / cadence` millisecondes, sur toute la plage. La valeur est donc un
nombre d'émissions par seconde, et le moteur la respecte à la milliseconde.

### Les cinq se comportent pareil

Même témoin, cinq paramètres, deux cadences contrastées :

| cadence | sortie observée | écart à 10 | écart à 100 |
| --- | --- | --- | --- |
| `_volumerate` | contrôleur 7 | 100 ms | 10 ms |
| `_panrate` | contrôleur 10 | 100 ms | 10 ms |
| `_modrate` | contrôleur 1 | 100 ms | 10 ms |
| `_pitchrate` | pitchbend | 100 ms | 10 ms |
| `_pressrate` | pression de canal | 100 ms | 10 ms |

Aucune ne diffère.
