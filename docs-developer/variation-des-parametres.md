# La variation d'un paramètre entre deux valeurs écrites

Mesure du 2026-08-14 sur `builds/v3.5.1-iso.2/bp3`, empreinte `372dd047bc52fd152ff51ec6715fae74`,
version affichée `3.5.1 (Aug 11 2026)`, graine 1, réglages `-se.checkAllCsound`, depuis
`capture-run/`.

Six notes, la valeur écrite sur la première et sur la sixième :

```
gram#1[1] S --> <mot de mode> _volume(20) C4 C4 C4 C4 C4 _volume(120) C4
```

```
bp3 produce -e -gr <grammaire> --seed 1 -se ../test-data/-se.checkAllCsound \
    -o /dev/null --eventlistout <f> --midiout <f>
```

## La règle

La variation se répartit sur les **intervalles entre notes**, et la dernière note **porte la valeur
écrite**. Six notes de 20 à 120 donnent un pas de 20 — soit 100 ÷ 5.

Le mode **fixe** tient la valeur précédente jusqu'à l'écriture suivante, et **applique l'écriture** :
la sixième note passe à 120. **Sans mot de mode, le comportement est celui du fixe.**

## Les trois paramètres, sur deux axes chacun

| paramètre | mot paliers | valeurs en paliers | valeurs en fixe |
| --- | --- | --- | --- |
| volume | `_volumestep` | 20 40 60 80 100 120 | 20 20 20 20 20 120 |
| transposition | `_transposestep` | 0 2 4 6 8 10 | 0 0 0 0 0 10 |
| articulation | `_articulstep` | 20 40 60 80 100 120 | 20 20 20 20 20 120 |

**Volume** — liste native, colonnes `volume start`/`volume end` : `(20,40) (40,60) (60,80) (80,100)
(100,120) (120,120)`. Fichier MIDI, contrôleur 7 : `20 40 60 80 100 120`. En fixe : `20` puis `120`.

**Transposition** — colonne `transpos` : `0 2 4 6 8 10`. Notes MIDI émises : `60 62 64 66 68 70`.
En fixe : `60 60 60 60 60 70`.

**Articulation** — elle se lit sur la **durée** de chaque note. Base 1000 ms ; `_legato(50)` donne
1500 ms, `_staccato(50)` donne 500 ms. En paliers de 20 à 120 : `1200 1400 1600 1800 2000 2200`.
En fixe : `1200` cinq fois puis `2200`.

## Deux axes qui ne disent rien

- La **vélocité MIDI** reste plate quelle que soit la valeur de volume écrite. Elle porte un champ
  distinct de l'instance (`MakeSound.c:821`), passé par `ClipVelocity` ; `_volume` n'y entre pas.
  Le volume s'exprime par le **contrôleur 7**.
- La colonne **`articul`** de la liste native reste à `0` dans tous les cas, y compris quand la durée
  varie de 500 à 2200 ms. Elle ne publie pas l'articulation appliquée.

## Une valeur posée après la dernière note ne produit rien

```
gram#1[1] S --> _volume(127) C4 C4 C4 C4 C4 C4 _volume(0)
```

Le moteur émet **six** événements sonnants, tous à 127. Aucun événement ne porte la valeur finale,
ni dans la liste native, ni dans le fichier MIDI. Le jeton figure dans la sortie texte.

Les trois fichiers MIDI sont **identiques octet pour octet** :

| grammaire | empreinte du fichier MIDI |
| --- | --- |
| `… C4 C4` sans valeur finale | `df85fafd6e3ee227c14d29a6e2f5b1e3` |
| `… C4 C4 _volume(0)` | `df85fafd6e3ee227c14d29a6e2f5b1e3` |
| `… C4 C4 _volume(64)` | `df85fafd6e3ee227c14d29a6e2f5b1e3` |
| `_volume(127) C4 C4 _volume(64) C4 C4 C4 C4` | `4a67116a7c6892c15d9c1865eadd48b6` |

La quatrième ligne est le **témoin de discrimination** : la même forme posée au milieu déplace les
quatre notes suivantes à 64 et pose un message de contrôleur 7 à l'instant 2000. La mesure pouvait
donc montrer un effet.

## Lire le contrôleur 7 sans se tromper

La suite des messages de contrôleur 7 se poursuit après la sixième valeur — `120 118 117 116 115…`
Ces valeurs appartiennent à l'extinction de la dernière note. Les six premières portent la mesure.
