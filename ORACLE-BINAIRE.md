# Le binaire oracle BP3 — où il vit, qui le monte, comment savoir quelle version on exécute

Procédure établie le 2026-08-08 par `bp3-engine` (lot [190], acte Romain). Le binaire natif est
la **pièce partagée dont dépendent TOUS les oracles de la flotte**. Une page, à jour ici.

## Où vit le binaire de référence

- **Les campagnes figées** : `builds/…/bp3`, chacune nommée par son empreinte md5. **Ce sont
  elles, l'oracle, et elles seules.** Les archives antérieures au 2026-08-11 portent un suffixe
  `-wasm.N` : c'est un compteur de construction, pas une cible.
- **Pour un voisin** : `.publie/bp3-engine/builds/…/bp3`. Les campagnes citées comme oracle sont
  déclarées par `AVANT-PUBLICATION.sh` ; les binaires n'étant pas suivis en version, une campagne
  absente de cette déclaration est atteignable ici et introuvable là-bas.
- **`/home/romi/dev/bp/bp3-engine/bp3`** est l'artefact de travail, construit sur place par
  `./build.sh` et non suivi par git. Il n'est pas une référence : voir « État courant ».

## ⛔ D'où le binaire se lance — `capture-run/`, et pas ailleurs

Le moteur cherche `console_strings.json` **au répertoire courant**, puis dans `php/`, sur un nom
nu et sans chemin de recherche (`Inits.c:753` et `756`). Il préfixe par ailleurs **en dur** `../`
au chemin Csound stocké dans un fichier `-so.*` (`SaveLoads1.c:855`), que le drapeau `-cs`
n'écrase pas.

⇒ **Le répertoire de travail est `capture-run/`** — celui du dépôt en local, celui de l'espace
publié pour un voisin. `../csound_resources/` y résout, et les chaînes de console sont à côté.
C'est ce que fait `baseline-native/capture.py`, et c'est la décision de l'architecte du
2026-07-19, option (b).

⛔ **Lancé d'ailleurs, le binaire AFFICHE SA VERSION ET NE PRODUIT RIEN** : `=> Could not find
file "console_strings.json"`, aucune sortie, code 0. *Afficher sa version et produire sont deux
chemins de code ; seul le second ouvre ses fichiers auxiliaires.* Un témoin qui se contente de
lancer le binaire ne peut pas montrer cet écart — il faut une **production**.

## Qui le monte — UNE SEULE main

**Seul l'agent `bp3-engine` monte le binaire.** Personne d'autre ne l'édite, ne le construit, ni
ne se sert dans ce dépôt. Un voisin qui a besoin d'une version l'attend de `bp3-engine` — il ne
la fabrique pas lui-même (conduite correcte constatée le 2026-08-08 : bp3-frontend a refusé de se
servir dans le dépôt d'un autre, d'où ce lot).

## Comment un voisin sait quelle version il exécute

1. `./bp3 --version` → `Version X.Y.Z (Mon JJ AAAA - HH:MM:SS)`.
2. ⚠️ **Le numéro de version seul n'est PAS une empreinte** (constat #65) : c'est un `#define`
   incrémenté à la main, et l'horodatage vient d'une seule unité de compilation (deux binaires
   distincts peuvent l'afficher identique). **La seule empreinte de contenu fiable est le md5** :
   `md5sum bp3`. Un même binaire peut même afficher **deux horodatages selon le chemin** : sur
   `b100125b`, la bannière de `produce` rend `19:18:22`, `--version` rend `19:18:21` — deux unités
   compilées à une seconde d'écart. Le md5 est identique ; c'est lui qui tranche.
3. **Toute mesure publiée cite : version + md5 + LA COMMANDE COMPLÈTE** (pas seulement la graine).
   La sortie dépend des sorties demandées : `koto3` rend une fin à 28 734 ms avec `--eventlistout`
   seul, 35 470 ms dès qu'on ajoute `--midiout` (constat #67, amont Bernard). Une référence
   d'oracle sans sa commande complète est ambiguë.
   ⚠️ **`--eventlistout` seul rend 0 ligne (constat #68, corrigé)** : silencieux (Errors:0), il faut
   lui adjoindre `-o` (ou `--midiout`) pour peupler la liste. **Ce n'est PAS une régression 3.5.1** :
   le 3.5.0 committé (rebuild de `31b37fd`) exige `-o` autant que le 3.5.1 — le gate d'émission de
   `MakeSound.c` est identique entre les deux. Toujours passer `-o` avec `--eventlistout`.
   ⚠️ **`--eventlistout` dépose AUSSI un JSON de prototypes à côté du fichier `-so` chargé**
   (`SaveLoads1.c:821-856`, sous `EventListOn`) : nommé d'après le `-so`, préfixe `-so.` retiré +
   `.json` (`-so.abc1` → `abc1.json`), dans le dossier du `-so`. Il porte **la hauteur** — octets MIDI
   bruts par prototype (`byte_1/2/3`) — que la liste d'événements ne porte pas ; appariement par
   identifiant de prototype. Le natif l'annonce sur stdout (`👉 Creating json file of prototypes:`
   puis `Closing file:`) ; ce n'est PAS silencieux, mais le flux message séparé par `-o`
   (`ConsoleMain.c:134`) peut le masquer d'une lecture partielle.

## Procédure de montée de version (par `bp3-engine`)

1. `git fetch upstream --tags` ; repérer le tag `vX.Y.Z` (ligne `graphics-for-BP3`).
2. Mesurer le diff amont par fichier ; reprendre tel quel les fichiers sans delta local, fusionner
   à trois voies (`git merge-file`) ceux qui portent nos deltas. Tout va dans `source/BP3/`,
   l'arbre unique.
3. `./build.sh linux`.
4. **Non-régression AVANT tout** : dériver le corpus à graine figée avec l'ANCIENNE et la NOUVELLE
   version, comparer texte + jetons minutés production par production. Toute divergence est un FAIT
   à rapporter, jamais à absorber. Ne rien re-capturer (gel #48-#52).
5. `scripts/gate.sh` → toutes vertes.
6. Changelog obligatoire : `source/BP3/` → `CHANGELOG_ENGINE.md`. Committer, pousser
   `origin/wasm`.
7. **ACTION DE FRONTIÈRE, À LA FRAPPE** : annoncer la nouvelle version (numéro **+ md5**) aux
   dépôts qui mesurent contre le natif — **bp3-frontend, BPx, kairos, kanopi** — via
   `tour send`. Une montée non annoncée fait mesurer un voisin contre une version qu'il n'énonce
   pas (cause du lot [190]).

## État courant

| version | md5 | rôle |
|---|---|---|
| 3.5.1 | fb6df5ad5ee18a0398ae3cdb1817287d | oracle figé, campagne `builds/v3.5.1-iso.1` |
| 3.5.1 | 372dd047bc52fd152ff51ec6715fae74 | oracle figé COURANT, campagne `builds/v3.5.1-iso.2` |
| 3.5.0 | 53eae9c6c987b3cd5aec7a90e2b7c925 | précédent, campagne `builds/v3.4.2-wasm.2_auto.50` |
| 3.4.7 | 0fa0f3d466613974b4ea2f1c78548955 | oracle ISO figé, campagne `builds/v3.4.2-wasm.2_auto.31` |

Les deux campagnes 3.5.1 sont publiées dans `.publie/bp3-engine/builds/`, déclarées par
`AVANT-PUBLICATION.sh` : c'est par là qu'un voisin sous enveloppe atteint le natif.

⛔ **`./bp3` À LA RACINE N'EST PAS UNE RÉFÉRENCE, ET SON EMPREINTE NE SE COMPARE À RIEN.** Le
binaire grave sa date et son heure de construction : la campagne figée annonce
`Version 3.5.1 (Aug 11 2026 - 13:16:56)`, l'artefact de travail `Version 3.5.1 (Sep  4 2026 -
16:50:13)`. Deux constructions complètes des mêmes sources rendent donc deux empreintes, alors
qu'une reconstruction partielle — celle qui ne recompile pas le fichier portant la date — peut
rendre la même. C'est un artefact de travail, reconstructible à volonté par `./build.sh`. Toute
mesure de référence se prend sur une campagne figée de `builds/`, nommée avec son empreinte.
