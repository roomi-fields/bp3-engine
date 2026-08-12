# Trois mesures du 2026-08-12

Toutes prises sur l'**archive figée** `builds/v3.5.1-iso.1/bp3`, empreinte
`fb6df5ad5ee18a0398ae3cdb1817287d`, graine 1.

## Les huit volumes de `_volumestep` — `checkAllCsound` gram#1[11]

La règle porte le poids `<0>` : la grammaire du corpus produit toujours gram#1[14], et
gram#1[11] ne joue jamais telle quelle. La mesure passe par le mécanisme de poids de la
grammaire — `gram#1[11] <1>`, toutes les autres à `<0>`.

Le score Csound porte le volume au champ `p6`/`p7`. Avec `_volumestep`, `p6 = p7` sur chaque
note :

| note | 1 `A4` | 2 `G4` | 3 `C5` | 4 `A5` | 5 `A4` | 6 `G4` | 7 `C5` | 8 `A5` |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `p6` | 24,000 | 21,688 | 18,431 | 12,899 | −0,031 | −1,179 | −2,794 | −5,547 |

Témoin de correspondance, une valeur de volume par note sur le même instrument :

| `_volume` | 127 | 111 | 95 | 79 | 63 | 47 | 31 | 15 | 0 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `p6` | 24,000 | 21,667 | 18,368 | 12,711 | −0,063 | −1,231 | −2,889 | −5,771 | −24,000 |

Les huit paliers tombent sur les huit premières valeurs de l'échelle. **Le zéro n'est porté par
aucune note** : `_volume(0)` vaut −24,000, et aucune note de gram#1[11] ne porte cette valeur.

La même règle en `_volumecont` (gram#1[10]) balaie entre les mêmes bornes, et sa huitième note va
de −5,547 à −24,000 : le zéro y est atteint à la fin de la dernière note, jamais à son début.

## `_step(param)` sur un paramètre défini par l'utilisateur — `blurb`

`-gr.blurb` gram#1[1] et `-gr.checkAllCsound` gram#1[26] portent
`_value(blurb,-211) _step(blurb)` après `_ins(Flute)`.

Cinq canaux comparés, avec et sans le contrôle — jetons, score Csound, fichier MIDI, liste
d'événements, texte : **identiques partout**, sauf la ligne de texte, qui recopie le jeton retiré.

Ce que la mesure ajoute, par contrôles positifs :

- remplacer `_step(blurb)` par `_fixed(blurb)`, par `_cont(blurb)`, ou par rien : score identique ;
- changer la **valeur** de −211 à −999 : score identique ;
- poser le contrôle sur l'instrument qui **déclare** `blurb` (`Harpsichord`, `i3`) au lieu de la
  `Flute` (`i2`) : score identique ;
- faire varier la première valeur de `blurb` — 123,42 · 0 · −211 · 50 · 1000 : le dernier champ du
  score reste **−75,938** dans les cinq cas.

Aucune valeur de `blurb` n'atteint une sortie, et aucun mode ne s'y exprime. Le canal existe pour
d'autres paramètres — `_volumestep` déplace `p6` note à note sur le même score, ligne à ligne.

## Le plantage sur l'option de trace

Le moteur ouvre `<répertoire courant>/php/CANVAS_header.txt` pour amorcer l'image
(`ConsoleMain.c:613`). L'ouverture échouée ferme le flux d'image et le remet à nul
(`ConsoleMain.c:616-620`) sans éteindre les drapeaux de dessin ; l'écriture suivante déréférence
le pointeur nul.

Mesure, avec et sans un `php/CANVAS_header.txt` factice dans le répertoire courant :

| grammaire | sans le gabarit | avec le gabarit |
| --- | --- | --- |
| `tryGOTO` | SIGSEGV | 0 |
| `765432` | SIGSEGV | 0 |
| `checkBT`, action `produce` | SIGSEGV | 0 |
| `checkBT`, action `produce-all` | 0 | 0 |
| `Alarm` | 0 | 0 |

Le plantage frappe les exécutions qui **jouent** un item avec un affichage graphique armé.
`checkBT` le montre des deux côtés selon l'action ; `Alarm`, sans fichier de réglages, n'arme
aucun affichage.

Le bloc concerné appartient au chemin d'image amont, hors des trois deltas que nous portons dans
ce fichier — `--tokensout`, `--trace-production`, et le `chmod`. Le dépôt ne porte pas de
`php/CANVAS_header.txt` ; `php/` ne contient que `console_strings.json`.

⚠️ Redirigée vers un fichier, la sortie du processus est vide : il meurt avant que les tampons ne
se vident. Le message d'ouverture ratée n'apparaît qu'en lecture non tamponnée.
