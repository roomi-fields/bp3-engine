# La variation d'un paramètre entre deux valeurs écrites

Mesure du 2026-08-14 sur `builds/v3.5.1-iso.2/bp3`, empreinte `372dd047bc52fd152ff51ec6715fae74`,
version affichée `3.5.1 (Aug 11 2026)`, graine 1, réglages `-se.checkAllCsound`, depuis
`capture-run/`.

```
bp3 produce -e -gr <grammaire> --seed 1 -se ../test-data/-se.checkAllCsound \
    -o /dev/null --eventlistout <f> --midiout <f>
```

## La loi

**Le pas vaut l'écart divisé par le nombre de notes situées ENTRE les deux écritures, et la valeur
écrite est portée par la PREMIÈRE NOTE QUI LA SUIT.**

Le nombre de notes de la séquence n'entre pas dans le calcul, et le nombre d'intervalles non plus.
Seules comptent les notes qui séparent les deux écritures.

## Les quatre dispositions qui séparent les lectures

Volume, écart de 20 à 120, mode `_volumestep`. Colonne `volume start` de la liste native, et
contrôleur 7 du fichier MIDI — les deux concordent sur les quatre.

| grammaire | notes entre les écritures | pas | valeurs |
| --- | --- | --- | --- |
| `_volume(20)` 6 notes `_volume(120)` | 6 | 100 ÷ 6 | 20 36 53 70 86 103 |
| `_volume(20)` 5 notes `_volume(120)` 1 note | 5 | 100 ÷ 5 | 20 40 60 80 100 · **120** |
| `_volume(20)` 3 notes `_volume(120)` | 3 | 100 ÷ 3 | 20 53 86 |
| `_volume(20)` 2 notes `_volume(120)` 1 note | 2 | 100 ÷ 2 | 20 70 · **120** |

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

## Deux axes qui ne publient pas ce qu'ils semblent publier

- La colonne **`articul`** de la liste native reste à `0` dans tous les cas, y compris quand la durée
  varie de 500 à 2200 ms.
- La suite des messages de contrôleur 7 se poursuit après la dernière valeur — `120 118 117 116 115…`
  Ces valeurs appartiennent à l'extinction de la dernière note.
