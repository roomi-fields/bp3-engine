# L'état du portillon — dix-sept maillons, cinq secondes

Mesuré le 2026-08-18. La source de vérité est `scripts/gate.sh` : ce que le portillon **lance**,
et non ce qui réside dans `scripts/`. Un garde hors du portillon ne prévient jamais.

## Deux espèces de maillons

| espèce | nombre | ce qu'elle fait |
| --- | --- | --- |
| garde | 9 | il examine le dépôt et refuse |
| injection | 8 | il fabrique une faute et vérifie qu'un garde la refuse |

57 assertions au total, 17 fichiers distincts. Ce compte suit les motifs `assert`, `exit 1`,
`sys.exit(1)` et `⛔` : il vaut ce que vaut un comptage par motif.

**Les neuf gardes** : `gate-baseline.py` · `gate-meta.py` · `gate-legacy.py` · `gate-ancrages.py` ·
`verif-bug55.sh` · `gate-correspondance.py` · `gel-baseline.py` · `gate-autonomie.py` ·
`garde-documentaires.sh`.

**Les huit injections** portent le suffixe `-injection.sh` et nomment dans leur texte le garde
qu'elles éprouvent. Deux d'entre elles — `gate-effondrement-injection.sh` et
`gate-sonde-injection.sh` — éprouvent des gardes qui vivent dans `baseline-native/capture.py`,
aux lignes 163, 334, 348 pour l'effondrement et 161 à 190 pour la sonde.

## Ce qui atteste qu'un garde mord

Le portillon ne journalise pas ses échecs. Un garde qui refuse une poussée empêche le commit :
l'événement ne laisse aucune trace. **Le nombre de gardes ayant rougi n'existe nulle part.**

Deux pièces se mesurent à la place.

| pièce | compte |
| --- | --- |
| une injection dédiée, rejouable à chaque poussée | 6 gardes sur 9 |
| une cause nommée dans l'en-tête | 9 sur 9, dont 8 datée |

Les trois gardes sans injection : `baseline-integrite`, `non-retour-bug55`, `documentaires-hub`.

Le seul dont l'en-tête énonce une règle sans nommer l'événement qui l'a fait naître :
`gate-meta.py`. Il porte aussi le plus faible compte d'assertions, à égalité avec
`gate-autonomie.py`, et aucun commit n'atteste qu'il ait mordu.

Une troisième piste — chercher dans les messages de commit — donne un signal bruyant : le radical
`baseline` ramène 54 commits et les mêmes ressortent pour deux gardes distincts. Elle ne prouve
rien.

## Le temps, maillon par maillon

| maillon | secondes | maillon | secondes |
| --- | --- | --- | --- |
| baseline-integrite | 0,07 | correspondance | 0,12 |
| anti-bypass | 0,06 | correspondance-morsure | 1,00 |
| anti-bypass-morsure | 0,39 | gel-baseline | 0,08 |
| anti-retrocompat | 0,07 | gel-morsure | 0,50 |
| anti-retro-morsure | 0,43 | autonomie | 0,05 |
| ancrages-locaux | 0,09 | autonomie-morsure | 0,29 |
| ancrages-morsure | 0,46 | documentaires-hub | 0,36 |
| effondrement-morsure | 0,13 | | |
| non-retour-bug55 | 0,16 | **total** | **5,12** |
| sonde-morsure | 0,85 | | |

Les neuf gardes coûtent 1,06 s ; les huit injections en coûtent 4,06 — quatre fois plus que ce
qu'elles protègent.

## Deux maillons à connaître

`gel-baseline.py` a mordu sur du réel : un mot du texte du sceau corrigé après scellement a rendu
le portillon rouge, et a évité la publication d'une référence dont l'empreinte ne correspondait
plus à son contenu.

`gate-correspondance.py` lit le disque de kanopi à chaque poussée — la table de correspondance et
l'existence de 113 fichiers de scène. Un renommage chez kanopi refuse la poussée d'ici, pour une
cause qui n'est pas ici. Il coûte 0,12 s.
