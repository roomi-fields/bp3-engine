# L'instant négatif — d'où il vient, et ce que le moteur joue

Mesuré le 2026-08-12 sur le binaire gelé `bp3 3.5.1`, empreinte `fb6df5ad5ee18a0398ae3cdb1817287d`.

**Axes nommés** : jetons (`--tokensout`), liste d'événements (`--eventlistout`), fichier MIDI
(`--midiout`, décodé par `mido`).

## Le moteur ne joue rien avant zéro

Sur `transposition3`, réglage `-se.transposition3`, graine 1 :

- fichier MIDI : premier `NoteOn` à **0,0 ms** ; division 1000 ticks par noire ;
- liste d'événements : premier événement `E1` à **0,0**, fin 1310 ;
- jetons : premier `E1` à **−10**, fin 1300.

Sur `tryRagas`, les instants de la liste d'événements vont de **0,0** à 94492. Aucun instant
négatif sur les deux axes que le moteur écrit.

## Le décalage porte sur l'axe des jetons, et il vaut la quantification

Sur `transposition3`, chaque jeton est **antérieur de 10 ms** à l'événement correspondant, début et
fin, sur les 20 premiers vérifiés. L'écart entre le premier événement et le deuxième groupe vaut
2621 ms sur les deux axes : une translation, pas un étirement.

En ne faisant varier que `Quantization` dans le fichier de réglages, toutes choses égales par
ailleurs :

| `Quantization` | décalage des jetons | premier jeton |
| --- | --- | --- |
| 1 | 0 | 0 |
| 5 | 0 | 0 |
| 10 | −10 | −10 |
| 25 | −25 | +11 |
| 50 | −50 | +24 |
| 100 | −100 | −73 |

Le décalage suit la quantification. La valeur **−10** vient de `Quantization = 10`, que portent
`-se.transposition3` et `-se.tryRagas`.

Un instant **négatif** n'apparaît que lorsqu'un événement tombe à moins d'un pas de quantification
de zéro : à `Quantization = 25` le décalage vaut −25 et aucun jeton n'est négatif.

## La soustraction s'engage avec le taux de compression

Le moteur annonce le couple sur sa console : `Using quantization = <Q> ms with compression rate =
<k>` (`Polymetric.c:346`).

| grammaire | `Q` annoncé | taux annoncé | décalage mesuré |
| --- | --- | --- | --- |
| `acceleration` | 10 | 370 | −10 |
| `Djinns` | 50 | 14 | −50 |
| `765432` | 50 | 1 | 0 |
| `Nadaka-1er-essai` | 50 | 1 | 0 |
| `MyMelody` | aucune annonce | — | 0 |

La soustraction vaut `−Q` quand le taux annoncé dépasse 1, et 0 sinon.

## Les jetons à durée nulle de `tryRagas`

`tryRagas` porte trois jetons `−10 → −10`, de durée nulle, au milieu d'un morceau qui court autour
de 94 secondes. Ils suivent la même quantification : à `Quantization = 100` ils valent
`−100 → −100`, à `Quantization = 1` ils disparaissent.

Ce sont des instants **zéro** déplacés par le décalage, pas des positions avant zéro. La liste
d'événements leur oppose des instants réels autour de 94 secondes.

Ces trois jetons n'apparaissent **que lorsque `--midiout` n'est pas demandé** : le même tirage avec
`--midiout` en rend 42 dont aucun négatif.

## Ce que la graine ne fait pas

Sur `transposition3`, graine 3 : 93 jetons, premier `E1` à **+6**, aucun jeton négatif. Graines 2,
7 et 99 : aucun jeton. La valeur du décalage ne varie jamais aléatoirement — elle suit la
quantification.

## Où vit la soustraction

`source/BP3/TokensOut.c:86` : `time_offset = (Kpress >= 2.0 && Quantization > 0) ? Quantization :
0`, retranché des deux bornes en `:96-97`. C'est un portage de `bp3_get_timed_tokens()`
(`csrc/wasm/bp3_api.c`) : la voie WASM applique la même soustraction, et les flux de jetons lus par
ses consommateurs portent le même décalage.

## Portée sur la baseline v14

Sur les 63 captures de jetons scellées, **2 portent un instant négatif** : `transposition3`
(2 jetons à −10) et `tryRagas` (3 jetons à −10).

Sur les 59 captures scellées en modalité MIDI, **50 reposent sur un réglage à `Quantization ≥ 10`**.
Le décalage est vérifié présent sur `Djinns` et `acceleration`, absent sur `765432` et
`Nadaka-1er-essai`.

## Observation restée isolée

À `Quantization = 25` sur `transposition3`, la borne de fin la plus haute des jetons ressort à
38654705689 ms. Cette valeur apparaît sur un réglage modifié à la main, jamais dans le corpus
scellé.
