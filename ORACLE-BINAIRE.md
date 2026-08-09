# Le binaire oracle BP3 — où il vit, qui le monte, comment savoir quelle version on exécute

Procédure établie le 2026-08-08 par `bp3-engine` (lot [190], acte Romain). Le binaire natif est
la **pièce partagée dont dépendent TOUS les oracles de la flotte**. Une page, à jour ici.

## Où vit le binaire de référence

- **Natif** : `/home/romi/dev/bp/bp3-engine/bp3` — dépôt `bp3-engine`, branche `wasm`. C'est
  l'oracle de la campagne ISO. Il est **construit sur place** par `./build.sh` et n'est **pas**
  suivi par git (chaque version figée est archivée dans `builds/`).
- **WASM** : `build/bp3.js` + `build/bp3.wasm`, déployés par `build.sh` dans `BPscript/dist/`.
- **Versions figées archivées** : `builds/…/bp3` (ex. l'oracle 3.4.7 `md5 0fa0f3d…`).

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
   `md5sum bp3`.
3. **Toute mesure publiée cite : version + md5 + LA COMMANDE COMPLÈTE** (pas seulement la graine).
   La sortie dépend des sorties demandées : `koto3` rend une fin à 28 734 ms avec `--eventlistout`
   seul, 35 470 ms dès qu'on ajoute `--midiout` (constat #67, amont Bernard). Une référence
   d'oracle sans sa commande complète est ambiguë.
   ⚠️ **`--eventlistout` seul rend 0 ligne (constat #68, corrigé)** : silencieux (Errors:0), il faut
   lui adjoindre `-o` (ou `--midiout`) pour peupler la liste. **Ce n'est PAS une régression 3.5.1** :
   le 3.5.0 committé (rebuild de `31b37fd`) exige `-o` autant que le 3.5.1 — le gate d'émission de
   `MakeSound.c` est identique entre les deux. Toujours passer `-o` avec `--eventlistout`.

## Procédure de montée de version (par `bp3-engine`)

1. `git fetch upstream --tags` ; repérer le tag `vX.Y.Z` (ligne `graphics-for-BP3`).
2. Mesurer le diff amont par fichier ; reprendre tel quel les fichiers sans delta local, fusionner
   à trois voies (`git merge-file`) ceux qui portent nos deltas. **Partagé → `csrc/bp3/` ;
   natif-seul → `source/BP3/`** (dont `Graphic.c`, `PlayThings.c`, `TokensOut.c`,
   `EventListfiles.c`).
3. `./build.sh linux` **deux fois** (la cible `sync` copie `csrc→source` après l'éval du DAG).
   Idem WASM si les fichiers partagés changent.
4. **Non-régression AVANT tout** : dériver le corpus à graine figée avec l'ANCIENNE et la NOUVELLE
   version, comparer texte + jetons minutés production par production. Toute divergence est un FAIT
   à rapporter, jamais à absorber. Ne rien re-capturer (gel #48-#52).
5. `scripts/gate.sh` → 21/21 vertes (le canari anti-legacy est `csrc/bp3/Misc.c` : committer
   avant de lancer les gardes).
6. Changelog obligatoire : `csrc/bp3/`→`CHANGELOG_ENGINE.md`, `csrc/wasm/`→`CHANGELOG_WASM.md`.
   Committer, pousser `origin/wasm`.
7. **ACTION DE FRONTIÈRE, À LA FRAPPE** : annoncer la nouvelle version (numéro **+ md5**) aux
   dépôts qui mesurent contre le natif — **bp3-frontend, BPx, kairos, kanopi** — via
   `tour send`. Une montée non annoncée fait mesurer un voisin contre une version qu'il n'énonce
   pas (cause du lot [190]).

## État courant

| version | md5 | rôle |
|---|---|---|
| 3.5.1 | 963c1ff9512b453e97bdbbbd5f8aae4a | **courant** (`./bp3`, 2026-08-08) |
| 3.5.0 | 5877fa2d4c05beb651a9d3bac30b50c4 | précédent |
| 3.4.7 | 0fa0f3d466613974b4ea2f1c78548955 | oracle ISO figé (`builds/…auto.31`) |
