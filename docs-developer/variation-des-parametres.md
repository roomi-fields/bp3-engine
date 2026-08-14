# La variation d'un paramètre entre deux valeurs écrites

Mesure du 2026-08-14 sur `builds/v3.5.1-iso.2/bp3`, empreinte `372dd047bc52fd152ff51ec6715fae74`,
version affichée `3.5.1 (Aug 11 2026)`, graine 1, réglages `-se.checkAllCsound`, depuis
`capture-run/`.

```
bp3 produce -e -gr <grammaire> --seed 1 -se ../test-data/-se.checkAllCsound \
    -o /dev/null --eventlistout <f> --midiout <f>
```

## La loi

**La valeur d'une note vaut la valeur écrite précédente, plus l'écart multiplié par la durée écoulée
depuis cette écriture, divisée par la durée totale qui sépare les deux écritures. La valeur écrite
est portée par la PREMIÈRE NOTE QUI LA SUIT.**

Le diviseur **cumule des durées**. Il ne compte pas les notes, ni les intervalles, ni les notes de
la séquence entière.

## Le témoin qui sépare la durée du rang

Deux notes entre les écritures, la prolongation `_` allongeant l'une puis l'autre. Les deux lectures
prédisent des valeurs différentes, et le binaire tranche.

| grammaire | durées | valeurs | par le rang | par la durée |
| --- | --- | --- | --- | --- |
| `_volume(0)` `C4 _ _` `C4` `_volume(100)` `C4` | 3000 1000 1000 | 0 **75** 100 | 50 | **75** |
| `_volume(0)` `C4` `C4 _ _` `_volume(100)` `C4` | 1000 3000 1000 | 0 **25** 100 | 50 | **25** |
| `_volume(0)` `C4 C4 _ _ C4` `_volume(100)` `C4` | 1000 3000 1000 1000 | 0 **20 80** 100 | 33 66 | **20 80** |

Le calcul : durée totale entre les écritures 3+1 = 4, la seconde note commence après 3 → 100 × 3/4
= 75. Le cas miroir donne 100 × 1/4 = 25. Sur trois notes, total 5, les notes commencent après 1 et
après 4 → 20 et 80.

**Témoins de contrôle, durées égales** — les mêmes dispositions à notes de durée identique rendent
`0 50 100` et `0 33 66 100`. Durée cumulée et rang y coïncident : c'est pour cela que quatre
dispositions à durées égales ne pouvaient pas trancher.

`_vel` rend les mêmes valeurs — 75, 25, 20 et 80.

### Quatre répartitions de durée, sur les deux axes

Écart 0 → 120, trois notes entre les écritures, une note après. La colonne `volume start` de la
liste native et les vélocités du fichier MIDI rendent **les mêmes valeurs** : la mesure ne repose
pas sur un décodage.

| durées | valeurs mesurées | par le rang |
| --- | --- | --- |
| 1 3 1 | 0 · **24 96** · 120 | 40 80 |
| 3 1 1 | 0 · **72 96** · 120 | 40 80 |
| 1 1 3 | 0 · **24 48** · 120 | 40 80 |
| 1 1 1 | 0 · **40 80** · 120 | 40 80 |

La quatrième ligne est le témoin de contrôle : à durées égales, les deux lectures coïncident.

### Les mêmes témoins sur le moteur amont

La liste d'événements et le fichier MIDI sortent de la **même exécution du même binaire** : ils
partagent tout ce qui précède l'écriture. Les mêmes quatre témoins passés sur le moteur amont pur,
construit du tag `v3.5.1` avec la même chaîne de compilation, empreinte
`06244c55d11bd9496c6e7187afea2787` :

**Zéro écart sur huit témoins** — quatre répartitions de durée, sur `_volume` et sur `_vel`, valeurs
et durées identiques des deux côtés.

Ce que cela ferme : nos écarts avec l'amont ne sont pour rien dans ces valeurs. Ce que cela ne ferme
pas : les deux binaires compilent le même code pour ce chemin, et le moteur natif reste sa propre
référence — aucun oracle extérieur ne juge son arithmétique.

## Les quatre dispositions à durées égales

Volume, écart de 20 à 120, mode `_volumestep`, toutes les notes de même durée. Colonne
`volume start` de la liste native, et contrôleur 7 du fichier MIDI — les deux concordent sur les
quatre.

| grammaire | durée entre les écritures | valeurs |
| --- | --- | --- |
| `_volume(20)` 6 notes `_volume(120)` | 6 notes égales | 20 36 53 70 86 103 |
| `_volume(20)` 5 notes `_volume(120)` 1 note | 5 notes égales | 20 40 60 80 100 · **120** |
| `_volume(20)` 3 notes `_volume(120)` | 3 notes égales | 20 53 86 |
| `_volume(20)` 2 notes `_volume(120)` 1 note | 2 notes égales | 20 70 · **120** |

Les notes étant de durée égale, diviser par leur nombre donne ici le même résultat que diviser par
la durée. Ces quatre cas ne distinguent pas les deux lectures.

Dans les deux dispositions sans note après la seconde écriture, la valeur 120 **n'est jamais
atteinte**.

## Le corollaire : une valeur posée après la dernière note ne produit rien

Aucune note ne la suit, donc aucune note ne la porte. Ce n'est pas un fait séparé, c'est la même loi.

Les trois fichiers MIDI sont **identiques octet pour octet** :

| grammaire | empreinte du fichier MIDI |
| --- | --- |
| `_volume(127)` 6 notes, sans valeur finale | `df85fafd6e3ee227c14d29a6e2f5b1e3` |
| `_volume(127)` 6 notes `_volume(0)` | `df85fafd6e3ee227c14d29a6e2f5b1e3` |
| `_volume(127)` 6 notes `_volume(64)` | `df85fafd6e3ee227c14d29a6e2f5b1e3` |
| `_volume(127)` 2 notes `_volume(64)` 4 notes | `4a67116a7c6892c15d9c1865eadd48b6` |

La quatrième ligne est le **témoin de discrimination** : une note suit l'écriture, la valeur est
portée, et le fichier diffère.

## Le mode fixe, et l'absence de mot de mode

Le mode **fixe** tient la valeur précédente jusqu'à l'écriture suivante, et **applique l'écriture** :
la première note qui suit porte la valeur. Sur la disposition à cinq notes puis une :
`20 20 20 20 20 · 120`.

**Sans mot de mode, le comportement est celui du fixe.**

## Les trois paramètres suivent la même loi

| paramètre | mot paliers | 6 notes avant l'écriture | 5 notes, écriture, 1 note |
| --- | --- | --- | --- |
| volume, écart 100 | `_volumestep` | 20 36 53 70 86 103 | 20 40 60 80 100 · 120 |
| transposition, écart 12 | `_transposestep` | 0 2 4 6 8 10 | 0 2 4 7 9 · 12 |
| articulation, écart 120 | `_articulstep` | 0 20 40 60 80 100 | 0 24 48 72 96 · 120 |

La transposition se lit à la colonne `transpos` et sur les notes MIDI émises. L'articulation se lit
sur la **durée** de chaque note : base 1000 ms, `_legato(50)` donne 1500 ms, `_staccato(50)` donne
500 ms ; les durées de la troisième ligne sont `1000 1200 1400 1600 1800 2000` et
`1000 1240 1480 1720 1960 2200`.

## Deux mots, deux canaux disjoints

`_vel` écrit la **vélocité** (jeton `T11`), `_volume` écrit le **volume** (jeton `T19`). Les deux
obéissent à la même loi, et **chacun est invisible sur l'axe de l'autre** :

- `_volume` ne touche pas la vélocité MIDI, qui porte un champ d'instance distinct
  (`MakeSound.c:821`, passé par `ClipVelocity`). Il sort par le **contrôleur 7**.
- `_vel` laisse la colonne `volume start` de la liste native à `64` sur toutes les notes. Il ne se
  lit que sur la **vélocité des notes MIDI**.

Une mesure qui lit le mauvais axe voit une valeur immobile et conclut à l'absence d'effet.

**Une note écrite à `_vel(0)` écrit bien un NoteOn, de vélocité nulle.** Relevé brut, sans filtrage,
sur `_vel(0) C4` :

```
t=0      NoteOn   note=60 velocite=0
t=1000   NoteOff  note=60 velocite=0
```

Et la liste native porte l'événement sonnant `C4 0 → 1000`. Un lecteur qui écarte les vélocités
nulles — convention du note-off — compte la note **absente** alors que le moteur l'a émise. Lire les
`0x90` sans filtrer, ou lire la liste native.

## Écrire des durées inégales

La prolongation `_` allonge la note qui précède, d'une unité par occurrence. Mesuré :
`C4 C4 _ _ C4` rend des durées de 1000, 3000 et 1000 ms.

## Deux axes qui ne publient pas ce qu'ils semblent publier

- La colonne **`articul`** de la liste native reste à `0` dans tous les cas, y compris quand la durée
  varie de 500 à 2200 ms.
- La suite des messages de contrôleur 7 se poursuit après la dernière valeur — `120 118 117 116 115…`
  Ces valeurs appartiennent à l'extinction de la dernière note.
