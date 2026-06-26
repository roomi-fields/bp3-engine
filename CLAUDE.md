# bp3-engine — moteur BP3 de Bernard (session moteur-wasm)

## Règle de boucle — courrier d'abord, rapport avant idle (hub/README.md §1-2, 2026-06-16)
⚠️ **OBLIGATOIRE à chaque activité.**
1. **RÉVEIL = COURRIER D'ABORD** : première action à tout réveil (démarrage de session ou ping) =
   `BP_AGENT=bp3-engine ~/dev/bp/hub/tour inbox`. Traiter, puis `tour inbox --ack`.
2. **RAPPORT AVANT IDLE** : ne jamais s'arrêter en silence. Dernière action avant de rendre la main =
   `tour send architecte "FINI: <quoi> + commit"` ou `tour send architecte "BLOQUÉ: <sur quoi>"`.
   Pas de stop-hook : l'architecte pilote les réveils, l'utilisateur monitore via la tour.

## Tour de contrôle — outil CLI `hub/tour` (OBLIGATOIRE, 2026-06-14)
⚠️ **Une seule boîte = `bp3-engine`** (fusion moteur+bernard, 2026-06-26). L'agent qui travaille
le moteur prend l'identité `bp3-engine` (`export BP_AGENT=bp3-engine`). Bernard Bel = mainteneur
amont **externe** : il **ne lit pas la tour** ; les bugs se lui remontent à la main.
- Coordination = dépôt privé `/home/romi/dev/bp/hub`, mécanisée par `~/dev/bp/hub/tour`
  (plus d'édition markdown des boîtes).
- Remonter un bug moteur à l'amont : l'inscrire dans `constats/bugs-moteur-bp3.md` (résumé) +
  la section « ▼ Registre Bernard Bel » de `courrier/bp3-engine.md` (détail), puis transmettre
  à Bernard Bel hors-tour.
- Demander un arbitrage : `tour send architecte "..."` ; décision : `tour decide <slug> --impacts ...`.
- Fin de session : MAJ ma propre ligne TABLEAU + ma fiche `projets/<moi>.md` + ma colonne
  `baseline-status.json`. La fiche `projets/bp3-engine.md` (oracle, pas de colonne testée) est
  tenue par l'agent qui fait le travail moteur. **Le code fait foi.**

## Backlog (décision Romain, 2026-06-17 — hub/projets/backlog-STRUCTURE.md)
- Je maintiens un `BACKLOG.md` à la RACINE du dépôt (dette technique INTERNE, un id + statut par item).
- Tout item qui touche le **langage** (syntaxe/sémantique) → backlog CENTRAL
  `hub/projets/backlog-langage-bps.md` via `tour` (pas dans le local).
- Vue globale = `tour backlog` (hub). Aucun backlog parallèle ailleurs.

## Règles moteur
- Changelogs OBLIGATOIRES après toute modif : `csrc/bp3/` → `CHANGELOG_ENGINE.md` ;
  `csrc/wasm/` → `CHANGELOG_WASM.md` ; nouveau bug → `hub/constats/bugs-moteur-bp3.md` (+ détail
  dans la section « ▼ Registre Bernard Bel » de `hub/courrier/bp3-engine.md`).
- Build : `./build.sh` (jamais `make`/`cp` manuel). Natif dépend de `libasound2-dev`.
  Gotcha : la cible `sync` (csrc→source) modifie après l'éval du DAG → double-passage requis.
- **UN seul arbre** depuis le dé-submodule (2026-06-16) : `/home/romi/dev/bp/bp3-engine` est le clone
  canonique unique. Éditer ici, pousser origin/wasm. (Fichiers PARTAGÉS = `csrc/bp3/` : éditer là,
  pas les copies `source/BP3/` qui sont écrasées par la cible `sync`. Natif-only = `source/BP3/` direct.)
- Oracle = bp3 natif : minutage via `--tokensout` ; ORDRE des jetons texte via `produce -o <fichier>`
  (sortie brute lossless, pas de flag dédié — cf. memory oracle-texte-option-o). Re-capture interdite
  tant que #48-#52 ouverts.

## RTFM — Indexed Knowledge Base

This project has been indexed with RTFM.

For any **exploratory search** (finding which files/modules/classes are relevant
to a topic), use `rtfm_search` instead of Glob, find, ls, or broad Grep.
Then use `rtfm_expand` to read easily most relevant files/sections.
