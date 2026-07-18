# Format des fichiers de réglages BP2 (`-se.*`) — carte de sérialisation

Réponse au blocage de bpscript sur `convertOldSettings` (demande architecte [68]).
Établi le 2026-07-18 par `bp3-engine`, **à partir du code du moteur**, pas du PHP.

## Le point qui débloque tout : il n'y a pas UN layout, il y en a UN PAR VERSION

Un fichier `-se` ancien commence par sa version (`V.2.4`, `BP2.9.3`, …). Le lecteur
d'origine convertit cette chaîne en un **indice `iv`**, puis lit les champs
séquentiellement en **sautant des blocs entiers selon `iv`** (`if(iv > 5)`, `if(iv > 11)`,
`if(iv > 15)`, `if(iv > 19)`…). Deux fichiers de versions différentes n'ont donc ni le
même nombre de champs, ni les mêmes positions.

Un convertisseur à positions fixes ne peut pas marcher. C'est la cause des valeurs
dégénérées constatées (`A4freq=10`, `MaxConsoleTime=1`, …) : les positions sont lues
fidèlement, mais **étiquetées avec les champs d'une autre version**.

Chaîne de code :
- `CheckVersion()` — `csrc/bp3/SaveLoads3.c:601` — extrait la version et la cherche dans
  `VersionName[]` ; **`iv` = l'indice trouvé**.
- `VersionName[]` — `csrc/bp3/-BP3main.h` — la table ci-dessous.
- `LoadSettings()` — le lecteur positionnel, disparu du tronc lors du passage au JSON.
  Extrait tel quel dans **`LoadSettings.reference.c`** (commit `e9249594`, 2024-11-27,
  dernier état avant v3.0.16).

## Table version → `iv`

Copiée telle quelle de `csrc/bp3/-BP3main.h` :

| iv | version | iv | version | iv | version | iv | version |
|---|---|---|---|---|---|---|---|
| 0 | `-` | 8 | `V.2.6` | 16 | `BP2.7.4` | 24 | `BP2.9.5` |
| 1 | `V.2.1` | 9 | `BP2.6.1` | 17 | `BP2.8.0` | 25 | `BP2.9.6beta` |
| 2 | `V.2.2` | 10 | `BP2.6.2` | 18 | `BP2.8.1` | 26 | `BP2.9.6` |
| 3 | `V.2.3` | 11 | `BP2.6.3` | 19 | `BP2.9.0` | 27 | `BP2.9.7beta` |
| 4 | `V.2.4` | 12 | `BP2.7` | 20 | `BP2.9.1` | 28 | `BP2.9.8` |
| 5 | `V.2.5` | 13 | `BP2.7.1` | 21 | `BP2.9.2` | 29 | `BP2.9.9` |
| 6 | `V.2.5.1` | 14 | `BP2.7.2` | 22 | `BP2.9.3` | 30 | `BP2.999...` |
| 7 | `V.2.5.2` | 15 | `BP2.7.3` | 23 | `BP2.9.4` | 31 | `BP3.0` |

## La carte champ → position

**Elle est dans `LoadSettings.reference.c`, et c'est volontaire.** L'ordre des appels
`ReadLong` / `ReadInteger` / `ReadUnsignedLong` / `ReadOne` **est** la carte : le n-ième
appel lit la n-ième ligne de valeurs. Les `if(iv > N)` encadrent les champs absents des
versions antérieures.

Je ne fournis pas de table champ→position retranscrite : mon extracteur automatique
n'identifiait proprement que 35 des 82 lectures (beaucoup d'affectations sont indirectes),
et livrer une table à moitié devinée reproduirait exactement le défaut qu'on corrige.
Le code fait foi — il est court (346 lignes) et se lit séquentiellement.

Attention en le lisant : `ReadOne()` consomme aussi une ligne sans forcément la stocker.
Il faut compter **tous** les appels `Read*`, pas seulement ceux qui affectent une variable.

## Corroboration empirique sur le corpus

`correlation-version-longueur.txt` donne, pour les 84 fichiers anciens de `test-data`, la
version déclarée et le nombre réel de lignes de valeurs. La corrélation est nette et
monotone — elle confirme le mécanisme et sert de jeu de validation :

| version | iv | fichiers | lignes de valeurs |
|---|---|---|---|
| `V.2.4` | 4 | 1 | 112 |
| `V.2.5` | 5 | 6 | 167-188 |
| `V.2.6` | 8 | 3 | 188-238 |
| `BP2.7` | 12 | 7 | 289-298 |
| `BP2.8.1` | 18 | 7 | 306 |
| `BP2.9.3` | 22 | 3 | 357 |
| `BP2.9.8` | 28 | 17 | 128 |

⚠ **Une anomalie que je n'explique pas** : les 17 fichiers `BP2.9.8` (iv=28, la version la
plus récente du lot) ne font que **128** lignes, là où `BP2.9.3` (iv=22) en fait 357.
Six fichiers sans version détectable font également 128. Je ne sais pas si c'est un format
compact plus récent ou un autre phénomène — **à ne pas deviner**, à instruire avant de
traiter ces 23 fichiers.

## Cas de test conseillé

- `-se.Alarm` — `V.2.4`, iv=4, 112 lignes. Le plus court, révèle tout de suite un
  convertisseur qui suppose le layout long : ses positions 62/63/65/67 valent toutes `10`.
- `-se.checkSUB1` — `BP2.9.3`, iv=22, 357 lignes. Layout long, valeurs de référence aux
  mêmes positions : `60` (C4key), `440.0000` (A4freq), `64` (DeftVelocity).

Un convertisseur correct doit rendre des valeurs plausibles sur **les deux**.
