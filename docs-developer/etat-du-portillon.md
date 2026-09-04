# L'état du portillon — vingt maillons, sept secondes

Mesuré le 2026-09-05. La source de vérité est `scripts/gate.sh` : ce que le portillon **lance**,
et non ce qui réside dans `scripts/`. Un garde hors du portillon ne prévient jamais.

Le crochet que git exécute se lit par `core.hooksPath` — `scripts/githooks/pre-push`. Il appelle
dans l'ordre `hub/tools/garde-courrier-non-lu.sh`, puis `hub/tools/gardes-du-portillon.sh`, puis
`scripts/gate.sh rapide`.

## Le courrier non lu refuse la poussée

Un geste qui sort d'ici part sur un état que je n'ai pas fini de lire. Le lot d'affichage de la
boîte est borné à quatre : « 0 non-lu » est le seul verdict, jamais l'écran.

Ce refus vit au geste de **poussée**, jamais à un site de bascule — le portillon dure des minutes
et le courrier arrive toutes les une à deux minutes ; branché ailleurs, il mesure un autre instant
que le geste. Le maillon `courrier-morsure` prouve son branchement, et sa place en tête.

## Le point d'entrée du hub porte les gardes partagés

Une seule ligne du crochet les atteint tous, avec le nom de ce dépôt en argument. Le hub y tient
la navigation, les copies diffusées, le retard de publication, les sources voisines et la
traversée ; ce qu'il y ajoute arrive sans geste ici, et il nomme à chaque passage les gardes qu'il
n'appelle pas.

Ces gardes vivent **en tête** parce qu'ils décident si la poussée a le droit d'avoir lieu : ils
refusent avant que le portillon ne dépense son temps. Le garde du retard de publication, en
particulier, ne peut pas vivre dans le portillon — le maillon qui prouve son branchement relance
ce crochet, donc le portillon.

Le maillon `retard-morsure` suit la chaîne entière — crochet → point d'entrée → garde — et rougit
quand la ligne du crochet est amputée.

## Deux espèces de maillons

| espèce | nombre | ce qu'elle fait |
| --- | --- | --- |
| garde | 9 | il examine le dépôt et refuse |
| injection | 11 | il fabrique une faute et vérifie qu'un garde la refuse |

52 assertions au total, 19 fichiers distincts. Ce compte suit les motifs `assert`, `exit 1`,
`sys.exit(1)` et `⛔` : il vaut ce que vaut un comptage par motif.

**Les neuf gardes** : `gate-baseline.py` · `gate-meta.py` · `gate-legacy.py` · `gate-ancrages.py` ·
`verif-bug55.sh` · `gate-correspondance.py` · `gel-baseline.py` · `gate-autonomie.py` ·
`copie-injection.sh verifier`.

**Les onze injections** portent le suffixe `-injection.sh` et nomment dans leur texte le garde
qu'elles éprouvent. Deux d'entre elles éprouvent des gardes qui vivent hors de `scripts/` :
`gate-effondrement-injection.sh` et `gate-sonde-injection.sh` visent `baseline-native/capture.py`,
aux lignes 163, 334, 348 pour l'effondrement et 161 à 190 pour la sonde.

## La liste attendue vit hors de `gate.sh`

`scripts/MAILLONS.txt` porte les vingt noms, un par ligne. `gate.sh` confronte à cette liste ce
qu'il a réellement lancé, nom pour nom, et refuse dans les deux sens : le retrait silencieux comme
l'ajout non inscrit.

La comparaison se tient **hors** des deux ensembles comparés. Confronter ce que `gate.sh` déclare à
ce que `gate.sh` lance ne voit rien : un maillon effacé sort des deux côtés, et le garde reste vert
en ayant cessé de mesurer. Le refus est par **nom** et jamais sur un total, qu'un retrait
redéfinirait et qu'un ajout ailleurs compenserait.

## Ce qui atteste qu'un garde mord

Le portillon ne journalise pas ses échecs. Un garde qui refuse une poussée empêche le commit :
l'événement ne laisse aucune trace. **Le nombre de gardes ayant rougi n'existe nulle part.**

Deux pièces se mesurent à la place.

| pièce | compte |
| --- | --- |
| une injection dédiée, rejouable à chaque poussée | 7 gardes sur 9 |
| une date dans les trente premières lignes du fichier | 6 sur 9 |

Les deux gardes sans injection : `baseline-integrite`, `non-retour-bug55`.

Les trois dont l'en-tête énonce une règle sans dater l'événement qui l'a fait naître :
`gate-baseline.py`, `gate-meta.py`, `gate-correspondance.py`. Le second porte aussi le plus faible
compte d'assertions, à égalité avec `gate-autonomie.py`.

Chercher dans les messages de commit donne un signal bruyant : le radical `baseline` ramène
54 commits et les mêmes ressortent pour deux gardes distincts. Cette piste ne prouve rien.

## Le temps, maillon par maillon

Le temps de chaque maillon se prend sur son journal `/tmp/gate.<nom>.log`. Les maillons dont
l'objet n'est pas la copie d'injection partagée courent **en parallèle** ; les dix autres courent
en série, parce qu'un lecteur de la copie lancé pendant qu'un autre la réécrit rend un verdict sur
un décor à moitié défait. `GATE_SERIE=1` force la forme sérielle, et sert de témoin de comparaison.

Course du 2026-09-05, machine à douze cœurs :

| maillon | secondes | maillon | secondes |
| --- | --- | --- | --- |
| baseline-integrite | 0,06 | gel-baseline | 0,12 |
| anti-bypass | 0,09 | gel-morsure | 0,89 |
| anti-bypass-morsure | 0,20 | autonomie | 0,08 |
| anti-retrocompat | 0,10 | autonomie-morsure | 0,29 |
| anti-retro-morsure | 0,40 | retard-morsure | 0,22 |
| ancrages-locaux | 0,09 | courrier-morsure | 0,22 |
| ancrages-morsure | 0,37 | oracle-fige-intact | 0,10 |
| effondrement-morsure | 0,23 | oracle-fige-morsure | 0,39 |
| non-retour-bug55 | 0,18 | *pose du décor* | *0,64* |
| sonde-morsure | 0,76 | | |
| correspondance | 0,08 | **total** | **6,60** |
| correspondance-morsure | 1,09 | | |

Le temps au mur d'une course mesure la charge de la machine autant que le travail : deux courses
successives de la même forme s'écartent de plus que ne les sépare le passage du parallèle au série.

## Trois maillons à connaître

`gel-baseline.py` a mordu sur du réel : un mot du texte du sceau corrigé après scellement a rendu
le portillon rouge, et a évité la publication d'une référence dont l'empreinte ne correspondait
plus à son contenu.

`gate-correspondance.py` lit l'espace publié de kanopi à chaque poussée — la table de
correspondance et l'existence de 113 fichiers de scène. Un renommage chez kanopi refuse la poussée
d'ici, pour une cause qui n'est pas ici.

`retard-morsure` et `courrier-morsure` tournent **dans l'arbre**, quand les autres injections
tournent dans la copie : leur sujet est le crochet que git exécute ici, lu par `core.hooksPath`.
Depuis la copie ils prouveraient le crochet de la copie. Ils n'écrivent rien — leurs leurres vivent
dans un dossier jetable, atteints en substituant `HOME`.
