# Proposition : cinq grammaires peuvent revenir dans l'assiette

**État : proposition à Romain.** L'assiette scellée reste à 91. Le rescellement à 96 a été fait le
2026-08-14 puis annulé : sceller la référence est le geste de Romain.

## La cause de leur sortie est levée

`check&`, `koto1`, `koto2`, `transposition1`, `tryMIDIfile` sont sorties de l'assiette le 2026-08-12
pour une cause écrite : leur fichier de réglages déclaré était illisible par le moteur, qui rendait
`Could not parse JSON settings`.

La conversion du corpus du 2026-08-14, tranchée par Romain, passe les 22 derniers fichiers en JSON.
Ces cinq réglages en font partie. Le corpus ne porte plus un seul réglage illisible.

## Aucune seconde cause derrière la première

La cause qui tombe ne prouve pas qu'il n'y en avait qu'une. L'assiette porte les **reproductibles** :
produire ne suffit pas, la capture doit être stable.

Cinq captures par grammaire, par `baseline-native/capture.py`, empreintes comparées :

| grammaire | mode | jetons | mots | 5 essais |
| --- | --- | --- | --- | --- |
| `check&` | MIDI | 4 | 6 | une seule empreinte |
| `koto1` | TEXTE | 0 | 1 | une seule empreinte |
| `koto2` | TEXTE | 0 | 1 | une seule empreinte |
| `transposition1` | MIDI | 75 | 107 | une seule empreinte |
| `tryMIDIfile` | MIDI | 8 | 9 | une seule empreinte |

Les cinq produisent et sont reproductibles.

## Ce que l'assiette deviendrait

| | aujourd'hui | proposé |
| --- | --- | --- |
| assiette | 91 | 96 |
| sonnantes | 56 | 59 |
| en texte | 35 | 37 |

Le dégel serait **partiel** : les 91 captures actuelles sont empreintes avant et après, et
`scripts/recapture-entree.py` restaure tout si une seule d'entre elles bouge. La mesure du
2026-08-14 l'a vérifié — aucune n'avait bougé.

## Ce que les consommateurs en ont mesuré

Sur le rescellement du 2026-08-14, avant son annulation :

- **bp3-frontend** a rejoué les 98 productibles et vérifié entrée par entrée : aucune bascule parmi
  les 91 anciennes. Sur les cinq : `check&` et `tryMIDIfile` identiques d'emblée, `transposition1`
  divergente de six jetons sans cause mesurée, `koto1` et `koto2` en échec.
- **BPx** : `transposition1` et `tryMIDIfile` identiques au jeton près ; `koto1` et `koto2` en échec
  sur un défaut de substitution par joker déjà inscrit chez lui ; `check&` absente de son corpus.
- **bpscript** : les deux `koto` ont fait apparaître que son oracle tournait sur `-se.koto3`, un
  substitut du vrai `-se.koto1`. Trente clés absentes de l'un, neuf valeurs communes divergentes.

Les échecs sont nommés et appartiennent à l'aval. `check&` absente du corpus de BPx est un trou qui
resterait muet si elle entrait dans la référence.

## Aucune grammaire de ce corpus ne tourne sur un substitut

Question posée par la découverte de bpscript. Mesure sur les 113 du registre,
`scripts/declare-contre-retenu.py` :

| | |
| --- | --- |
| déclarent le réglage qui est retenu | 88 |
| ne déclarent aucun réglage | 22 |
| déclarent un réglage absent du corpus, et n'en retiennent aucun | 3 |
| déclarent un réglage présent et lisible, et tournent sur un autre | **0** |

Le moteur saute la ligne `-se.` de l'en-tête (`CompileGrammar.c:250`) : un substitut ne se voit
nulle part à l'exécution, et une capture prise sur un substitut est parfaitement stable.
