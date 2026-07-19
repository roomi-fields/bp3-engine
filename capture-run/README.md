# `capture-run/` — répertoire de lancement du binaire natif pour les captures

Le moteur natif préfixe **en dur** `../` au chemin Csound stocké dans un fichier `-so.*`
(`csrc/bp3/SaveLoads1.c:855`). Il n'y a ni chemin de recherche, ni possibilité d'écraser ce
chemin par le drapeau `-cs` — testé.

Les fichiers `-so.tryKeyMap` et `-so.tryCsoundObjects` stockent `csound_resources/-cs.tryCsoundObjects`,
chemin correct pour la disposition de répertoires de l'installation amont. Notre arborescence
est plate, donc il ne résout pas.

**Décision architecte du 2026-07-19, option (b) — portée à ma seule capture** : on reproduit la
disposition attendue **ici**, au lieu de réécrire le chemin dans les fichiers `-so`.

- le binaire est lancé avec ce répertoire comme répertoire de travail ;
- `../csound_resources/` pointe donc sur `csound_resources/` à la racine du dépôt ;
- les fichiers `-so.*` du corpus restent **intouchés**.

Pourquoi la portée est limitée à moi : seul le binaire natif consulte ce chemin, et seul
`bp3-engine` lance le binaire natif. BPx ne sérialise pas Csound — bpx et bp3-frontend ne sont
donc pas concernés, et le corpus partagé ne bouge pas.

Réécrire le chemin dans les `-so` a été **écarté** : cela figerait dans le corpus partagé un
chemin dépendant du répertoire de travail, qui marcherait ici et casserait ailleurs.
