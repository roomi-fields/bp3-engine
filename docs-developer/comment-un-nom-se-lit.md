# Comment le moteur lit un nom

Mesuré les 2026-08-16, 17 et 18 sur le binaire natif figé, md5
`372dd047bc52fd152ff51ec6715fae74`. Cas fabriqués, contre-épreuve sans le caractère étudié à
chaque ligne.

## La casse commande tout

| première lettre | ce qu'est le nom | ce qui le déclare |
| --- | --- | --- |
| minuscule | terminal | l'alphabet, et lui seul |
| majuscule ou `\|` | variable | sa graphie, sans aucune règle |

Un nom minuscule absent de l'alphabet est refusé : « Variable must start with uppercase character
or `'` ». Un nom majuscule sans règle traverse la production intact et reste muet.

**La position ne déclare rien.** Poser un nom minuscule à gauche d'une règle ne le crée pas : la
règle elle-même est refusée. Sans alphabet, même un terminal connu ailleurs est rejeté.

## Un nom collé est une suite, jamais un mot

Le moteur décompose à la **compilation**, avant que la grammaire ne travaille. Le mot collé
n'existe déjà plus dans la chaîne de travail : une règle visant un sous-bol mord dessus, et un
membre gauche écrit collé se dissout de la même façon.

`S --> dhagenateena` et `S --> dha ge na tee na` produisent le même fichier MIDI, octet pour
octet.

**La règle de segmentation est le plus long préfixe, glouton, sans retour arrière.** Sur un
alphabet portant `ta`, `tak` et `ka` : `takka` rend `tak ka` ; `taka` est **refusé** — le moteur
prend `tak`, il reste `a`, et il ne revient pas sur la lecture `ta ka` qui aurait réussi.

La segmentation porte sur les terminaux de l'alphabet chargé, jamais sur les composés d'une
grammaire. Une variable ne se segmente pas : `ZzzYyy` reste entier là où `Zzz Yyy` se réécrit.

## Ce qui gouverne la lecture d'un nom absent

Aucune propriété du fichier alphabet ne la change. Marqueur de section varié — aucun, `*`, `OCT`,
`TRANS`, `TR`, `H`, `sync` — la segmentation est identique. Le marqueur contraint la **forme** du
fichier : `*` exige des lignes à flèche, son absence les interdit.

Sur 61 fichiers d'alphabet du corpus, 38 se chargent et **les 38 segmentent**. Aucun ne refuse par
principe, aucun ne compose. Les 18 qui ne se chargent pas refusent le **fichier**, jamais le nom :
8 sur le caractère `:` d'un en-tête BP2, 4 sur un `.` dans un terminal, 2 sur une ligne trop
longue, 2 sur un `*` suivi de termes nus, 1 sur un tiret cadratin, 1 sur une ligne `-or.`.

## La liste d'un alphabet est l'union de ses deux colonnes

Une flèche `a --> a'` déclare **deux termes**, pas une correspondance : les noms à apostrophe
n'apparaissent que dans la colonne droite et le moteur les accepte tous. Les lignes nues déclarent
un terme aussi.

**Le compilateur d'alphabet enregistre ses propres marqueurs de section comme terminaux.** Prouvé
par présence et par absence sur alphabets fabriqués, pour `*` comme pour `sync` : avec la ligne,
le marqueur est accepté ; sans elle, refusé. Ils sont à retirer d'une liste écrite à la main.

Un nom accepté par un alphabet doit être repassé sur un alphabet neutre qui ne le contient pas :
ce qui y passe encore est une variable, pas un terme. Le témoin par la règle ne discrimine pas —
une règle mord sur une variable autant que sur un terminal.

## Les notes ne passent pas par l'alphabet

Une note est lue sans aucun fichier alphabet. Ce qui la gouverne est le réglage `NoteConvention`,
cinq valeurs : 0 anglaise, 1 italienne/française, 2 indienne, 3 touches, 4 gammes tonales seules.
Un drapeau de ligne de commande le double — `--french`, `--indian`.

Le moteur **calcule** la hauteur et la réécrit : `dob5` sort `si4`, `sib4` sort `la#4`. Les doubles
altérations sont refusées, le registre est borné.

Chaque convention ne lit que ses propres noms. Hors de la sienne, un nom à majuscule traverse
comme une variable **muette** : la sortie texte ne le distingue pas d'une note, seul le fichier
MIDI le fait.

Une troisième source de terminalité existe : la **tonalité**. `mozart-dice` et `nadaka` n'ont aucun
alphabet et perdent toutes leurs notes quand `-to` est retiré.

## Les caractères qui ne sont pas des lettres

| caractère | après une minuscule | après une majuscule |
| --- | --- | --- |
| `'` `-` `#` `"` chiffres | détaché du nom | **dans le nom** |
| `_` `.` `+` `*` | détaché | détaché |

Un caractère détaché d'une minuscule n'est lu que si l'alphabet le déclare : `-al.checkhomo`
déclare `a`, `a'` et `a"` comme trois termes distincts.

L'apostrophe ne porte **aucune fonction** — ni hauteur, ni octave. Déclarée séparément ou reliée
par une flèche, même comportement. Deux noms qui ne diffèrent que par elle reçoivent deux
prototypes de son distincts, dont le contenu n'est pas dérivé l'un de l'autre.

Non déclarée après une minuscule, l'apostrophe devient un **délimiteur apparié** : une seule est
refusée, deux dans le même item forment un groupe et passent.

## Le temps que prend un caractère

`-` et `_` prennent une unité et ne sonnent pas : ce sont des silences. `.` n'en prend aucune. Un
chiffre isolé prolonge d'autant d'unités qu'il vaut. Une unité vaut 4000 tics.
