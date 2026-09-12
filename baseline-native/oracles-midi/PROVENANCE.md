# Provenance — oracles MIDI de parité

`<grammaire>/s1_native.json` porte l'**oracle** de parité MIDI de chacune des 30 grammaires
originales BP3 jouées en mode `midi` : la sortie MIDI du binaire natif, copie gelée d'un instantané
BPscript (`7367434`). Ces oracles vivaient chez runtime-midi ; ils sont chez le natif depuis le
2026-09-09 (Romain : une grammaire originale BP3 et sa référence vivent chez le moteur). Le lecteur
est la parité de runtime-midi, dans le dépôt unique (`packages/runtime-midi/test/parity/parite.mjs`) :
elle projette chaque grammaire par la chaîne vivante (bpscript, bpx, kairos) et compare la sortie MIDI
à l'oracle. Les jetons temporels du natif se lisent à côté, sous `../captures/`.

## Ce que ces fichiers déclarent

Un nom dit un **niveau** de la chaîne, pas un **producteur**. Aucun champ de version ici, et le
mot `wasm` n'apparaît dans aucun fichier. Mais **la forme d'un champ est une déclaration** :

- les 30 `s1_native.json` ne déclarent **aucun** producteur, ni par un champ ni par une forme.
  Ils portent en revanche **deux mises en page distinctes** — 24 rangent `mode` avant `midi`,
  6 l'inverse, et ces six-là sont exactement le lot daté du 2026-04-01. Deux écritures, donc,
  pour un jeu de références qu'on lit comme un seul.

## Qualification des 30 entrées — chacune reproduite au binaire nommé

Un indéterminé se qualifie en le **reproduisant**, jamais en le rangeant par ressemblance. Les 27
grammaires non protégées ont été rejouées au binaire nommé, deux passages chacune. Chaque entrée
porte son verdict dans son propre en-tête, champ `qualification`.

| verdict | n | grammaires |
| --- | --- | --- |
| **REPRODUITE** — jetons identiques un à un | 15 | acceleration, acceleration_v2, ames, bells, drum, graphics, livecode1, mozart-dice, MyMelody, not-reich, time-patterns, transposition1, tryRotate, vina, visser3 |
| **SANS AUTORITÉ** — non reproduite, écart nommé | 12 | alan-dice, beatrix-dice, doeslittle, harmony, kss2, one-scale, ruwet, simpletemplates, tryMIDIfile, visser-shapes, visser-waves, visser5 |
| **PROTÉGÉE** — ne se reproduit pas sur un build courant | 2 | 765432, watch |
| **SANS PRODUCTION** — le binaire n'émet rien | 1 | tryShruti |

Une entrée reproduite est une référence **valide quel que soit son producteur** : une référence
vaut par ce qu'elle contient. Une entrée sans autorité n'est pas fautive pour autant — elle dit
qu'elle ne vaut pas la mesure d'aujourd'hui, et son écart est nommé (compte de jetons,
orthographe enharmonique, granularité de capture).

Conditions de la mesure : binaire `bp3 3.5.1`, md5 `9081f9a6d6cd68669e052e22eaf0102d`, graine 1,
protocole `bp3-engine/baseline-native/capture.py <grammaire>` en mode unitaire. **L'empreinte md5 du
binaire est relevée avant et après chaque passage** : une mesure antérieure a été jetée parce que
le binaire a été reconstruit pendant qu'elle courait. Les deux binaires successifs du jour
(`3a6fa3e7` puis `9081f9a6`) rendent le même tri.

**Verdicts tenus** : le rejeu de neutralité est rendu, le retrait des conditionnelles de
compilation est sans effet sur l'oracle. Le tri est le même sur les trois binaires du jour.

`transposition1` et `tryMIDIfile` sont sorties de l'assiette native depuis. Leur verdict de
qualification dit ce que ma chaîne a mesuré ; il ne leur rend pas une référence.

## Trois grammaires sans équivalent natif

- `765432` et `watch` — **protégées** : leur référence ne se recapture pas sur un build courant.
- `tryShruti` — le binaire courant ne produit rien pour elle : ni jeton, ni texte.

## Autorité

BPscript reste l'autorité des instantanés `7367434` ; ces copies sont un instantané daté, à
re-synchroniser explicitement quand ses références évoluent — jamais l'inverse. Les captures du
2026-08-11 viennent du binaire natif, par `bp3-engine`.

**Re-sync 2026-06-14** (BPscript `3c10f6a`) : `alan-dice`, `beatrix-dice`, `mozart-dice`
(5049/10113 → 269) et `livecode1` (540 → 27) re-synchronisées en forme compacte (pré-MakeSound).

Les verdicts de parité sur la chaîne vivante, mesurés à l'entrée le 2026-09-09, sont au registre
d'exceptions, `test/registre-exceptions.txt`.
