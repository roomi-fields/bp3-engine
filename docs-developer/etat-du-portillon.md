# L'état du portillon — vingt-et-un maillons, dix-sept secondes

Mesuré le 2026-08-31. La source de vérité est `scripts/gate.sh` : ce que le portillon **lance**,
et non ce qui réside dans `scripts/`. Un garde hors du portillon ne prévient jamais.

Le crochet que git exécute se lit par `core.hooksPath` — `scripts/githooks/pre-push`. Il appelle
`hub/tools/garde-fenetre.sh` **en tête**, avant le premier maillon, puis `scripts/gate.sh rapide`.

## Deux espèces de maillons

| espèce | nombre | ce qu'elle fait |
| --- | --- | --- |
| garde | 10 | il examine le dépôt et refuse |
| injection | 11 | il fabrique une faute et vérifie qu'un garde la refuse |

56 assertions au total, 22 fichiers distincts. Ce compte suit les motifs `assert`, `exit 1`,
`sys.exit(1)` et `⛔` : il vaut ce que vaut un comptage par motif.

**Les dix gardes** : `gate-baseline.py` · `gate-meta.py` · `gate-legacy.py` · `gate-ancrages.py` ·
`verif-bug55.sh` · `gate-correspondance.py` · `gel-baseline.py` · `gate-autonomie.py` ·
`copie-injection.sh verifier` · `garde-documentaires.sh`.

**Les onze injections** portent le suffixe `-injection.sh` et nomment dans leur texte le garde
qu'elles éprouvent. Trois d'entre elles éprouvent des gardes qui vivent hors de `scripts/` :
`gate-effondrement-injection.sh` et `gate-sonde-injection.sh` visent `baseline-native/capture.py`,
aux lignes 163, 334, 348 pour l'effondrement et 161 à 190 pour la sonde ;
`gate-fenetre-injection.sh` vise `hub/tools/garde-fenetre.sh`, et prouve ses deux sites d'appel.

## Le maillon documentaire dérive sa liste

`garde-documentaires.sh` lance les outils du hub que `hub/tools/PORTILLON.txt` nomme. La liste fait
autorité chez l'architecte et se dérive : une liste écrite ici protégerait de la **disparition**
d'un outil et serait aveugle à son **apparition**.

Une liste dérivée perd le refus de zéro qu'une liste en dur donne gratuitement. Trois morts
silencieuses refusent donc explicitement, et le maillon **affirme** le nombre d'outils lancés :

| cas | verdict |
| --- | --- |
| la liste d'autorité est introuvable | refus, le fichier nommé |
| la liste ne nomme aucun outil | refus |
| un outil est nommé et absent du disque | refus, l'outil nommé |
| le nominal | passe, et affirme son compte |

`gate-documentaires-injection.sh` éprouve les quatre, plus le branchement : un leurre nommé par la
seule liste dépose un marqueur, et son témoin non nul est le même leurre qui laisse passer.

## Ce qui atteste qu'un garde mord

Le portillon ne journalise pas ses échecs. Un garde qui refuse une poussée empêche le commit :
l'événement ne laisse aucune trace. **Le nombre de gardes ayant rougi n'existe nulle part.**

Deux pièces se mesurent à la place.

| pièce | compte |
| --- | --- |
| une injection dédiée, rejouable à chaque poussée | 8 gardes sur 10 |
| une cause nommée dans l'en-tête | 10 sur 10, dont 9 datée |

Les deux gardes sans injection : `baseline-integrite`, `non-retour-bug55`.

Le seul dont l'en-tête énonce une règle sans nommer l'événement qui l'a fait naître :
`gate-meta.py`. Il porte aussi le plus faible compte d'assertions, à égalité avec
`gate-autonomie.py`, et aucun commit n'atteste qu'il ait mordu.

Une troisième piste — chercher dans les messages de commit — donne un signal bruyant : le radical
`baseline` ramène 54 commits et les mêmes ressortent pour deux gardes distincts. Elle ne prouve
rien.

## Le temps, maillon par maillon

Le temps de chaque maillon se prend sur la date d'écriture de son journal `/tmp/gate.<nom>.log`,
que `gate.sh` remplit en séquence. Le témoin est la somme : elle vaut le temps mural du crochet.

| maillon | secondes | maillon | secondes |
| --- | --- | --- | --- |
| *tête du crochet* | *1,76* | correspondance-morsure | 0,85 |
| baseline-integrite | 0,07 | gel-baseline | 0,07 |
| anti-bypass | 0,13 | gel-morsure | 0,36 |
| anti-bypass-morsure | 0,41 | autonomie | 0,05 |
| anti-retrocompat | 0,18 | autonomie-morsure | 0,18 |
| anti-retro-morsure | 0,53 | fenetre-morsure | 1,38 |
| ancrages-locaux | 0,06 | oracle-fige-intact | 0,03 |
| ancrages-morsure | 0,30 | oracle-fige-morsure | 0,23 |
| effondrement-morsure | 0,17 | documentaires-hub | 4,17 |
| non-retour-bug55 | 0,09 | documentaires-morsure | 4,97 |
| sonde-morsure | 0,58 | | |
| correspondance | 0,12 | **total** | **16,70** |

La tête du crochet porte le garde de fenêtre — 0,31 s — et la pose de la copie d'injection.

Les deux maillons documentaires coûtent 9,14 s, soit 55 % du total : ils lancent trois outils du
hub, dont un qui examine 3094 fichiers dans 21 dépôts, et l'injection les relance une fois.

## Trois maillons à connaître

`gel-baseline.py` a mordu sur du réel : un mot du texte du sceau corrigé après scellement a rendu
le portillon rouge, et a évité la publication d'une référence dont l'empreinte ne correspondait
plus à son contenu.

`gate-correspondance.py` lit le disque de kanopi à chaque poussée — la table de correspondance et
l'existence de 113 fichiers de scène. Un renommage chez kanopi refuse la poussée d'ici, pour une
cause qui n'est pas ici. Il coûte 0,12 s.

`garde-documentaires.sh` exécute du code pris dans l'arbre de travail du hub. Son verdict change
quand le hub écrit, sans qu'une ligne bouge ici : il porte donc une mention de régime, qui nomme
le commit publié du hub et si son arbre est sale. La mention échoue plutôt que de s'afficher vide.
