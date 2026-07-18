# Baseline native « original » — jeu unique, daté, vérifié

## 🔖 **baseline v5 — figée le 2026-07-18 — capture PAR ACTION**

**89 productibles** (dont 1 sous réserve → **88 utilisables**), **24 muettes**, **113 au total**.
Modes natifs : **MIDI 54** · **TEXTE 35**. Actions : **single 59** · **produce-all 30**.

| version | figée le | productibles | MIDI | capture | commit |
|---|---|---|---|---|---|
| v1 | 2026-07-18 | 74 | 51 | répétition (N items) | `579ca59` |
| v2 | 2026-07-18 | 86 | 52 | répétition (N items) | `7a970ac` |
| v3 | 2026-07-18 | 88 | 54 | répétition (N items) | `b59091c` |
| **v5** | **2026-07-18** | **89** | **54** | **par action** | ce commit |

**v3 → v5 : +1 productible, 0 perdue, 0 changement de mode natif.** La seule grammaire
gagnée est `look-and-say`, et elle est **sous réserve** (voir plus bas) : la baseline
utilisable est donc **strictement identique en couverture** à v3, mais capturée correctement.

> **Il n'y a pas de v4.** Une passe v4 a été produite puis **jetée sans être diffusée** :
> elle faisait tomber le MIDI de 54 à 17. La raison est expliquée en fin de document —
> c'est le fait technique le plus important de cette version.

---

## Ce qui change avec v5 : la capture se fait **par action**

Application de la décision `2026-07-18-cardinalite-produce-all-settings-existant-scales`
(ratifiée, GO Romain), volet ① : *les deux voies répliquent l'**action** du natif.*

`baseline.json` expose donc, pour chaque grammaire, un champ **`action`** :

| action | sens | capture |
|---|---|---|
| **`single`** | la grammaire **joue** un morceau | **une** réalisation, **1 item**, graine 1 |
| **`produce-all`** | production purement **symbolique** | **l'ensemble** énuméré par le moteur |

Champs d'accompagnement, pour que le consommateur voie *pourquoi* :
`joue`, `items_enumeres`, `enumeration_refusee_par_le_moteur`.

### Le choix de l'action n'est pas une heuristique : c'est le moteur qui tranche

1. On demande d'abord **le jeu** (`produce`, un seul item). Si des jetons minutés sortent,
   la grammaire joue → **`single`**.
2. Sinon, production purement symbolique : on demande au moteur d'**énumérer**
   (`produce-all`). S'il accepte → **`produce-all`**, on capture l'ensemble.
3. S'il **refuse** — `Can't produce all items in 'SUB' or 'SUB1' or 'POSLONG'`,
   `csrc/bp3/ProduceItems.c:770` — → **`single`** sur l'item unique.

Aucune décision de notre part à aucune de ces trois étapes.

**Le refus n'est pas le seul échec possible.** Une demande d'énumération peut aussi *bloquer*
ou *ne rien rendre*, sans message. Le champ **`enumeration_statut`** dit lequel des cas
s'applique, pour chaque grammaire qui produit :

| `enumeration_statut` | n |
|---|---|
| sans objet : la grammaire joue, on capture le jeu | 54 |
| acceptée par le moteur | 30 |
| refusée par le moteur (`SUB`/`SUB1`/`POSLONG`) | 3 |
| blocage > 90 s — `gramgene2` | 1 |
| aucun item produit, sans message — `asymmetric` | 1 |

Le booléen `enumeration_refusee_par_le_moteur` reste vrai **uniquement** pour le refus
explicite ; il vaut `false` pour un blocage ou une énumération vide. Lire
`enumeration_statut` pour lever l'ambiguïté — merci à bp3-frontend de l'avoir relevée.

### Fin de l'artefact de répétition

Les versions v1–v3 capturaient N items (20, 25, 40 selon les réglages). Ce N ne venait
**pas** de `-o` — qui n'est que le fichier de sortie — mais du réglage `MaxItemsProduce`
(boucle `csrc/bp3/ProduceItems.c:207`, `:295`, `:1948`).

Sur les 37 grammaires à plusieurs items en v3, **5 seulement** étaient de la vraie
répétition (`checkBT` : 20 items, 1 seul distinct ; `livecode1`, `livecode2`, `tryObjects`,
`tryMIDIfile`). Les **32 autres** donnaient des items **réellement différents** —
`mozart-dice` : 40 sur 40 distincts. Ce n'étaient pas des artefacts, c'était le même
morceau tiré N fois au hasard.

En `single`, on force **un** item via une **copie** des réglages (`MaxItemsProduce=1`) —
les fichiers d'origine ne sont jamais modifiés. **Vérifié** sur `mohanam` (série de 20),
`ruwet` (20) et `mozart-dice` (40), toutes trois en `single` : l'item unique est **exactement
le premier** de la série. Préfixe strict, aucun nouveau tirage.

> Correction : un signal antérieur citait `koto2` et `gramgene1` comme exemples ici. La
> vérification était réelle, mais l'exemple était mal choisi — ces deux-là sont en
> `produce-all`, pas en `single`. Relevé par bp3-frontend ; **les champs font foi, pas la
> prose des messages.**

### `mozart-dice` : énumère 40, capturée en `single` — c'est voulu

Elle offre 40 tirages distincts, mais le moteur **refuse** l'énumération dessus (`SUB`).
Arbitrage architecte : on mesure **le jeu** — une réalisation sous graine fixe — pas les
40 possibles. Même graine des deux côtés = même tirage = les voies doivent coïncider.
Conforme à `iso-mesure-le-play`.

---

## ⚠ Pourquoi il n'y a pas de v4 : **l'énumération ne joue pas**

Le fait technique à retenir de cette version.

**`produce-all` n'émet jamais de jetons minutés.** Il énumère des chaînes de symboles ;
il ne joue pas. La passe v4 demandait l'énumération **en premier** et gardait cette capture
dès qu'elle réussissait — elle a donc remplacé le jeu par une liste de chaînes sur toutes
les grammaires qui jouent. Résultat : **MIDI 54 → 17**, 37 grammaires privées de leur
minutage. Passe **jetée, jamais diffusée**.

Preuve — même grammaire, même graine, même configuration, seul le verbe change :

| grammaire | `produce-all` | `produce` |
|---|---|---|
| `tunings` | 0 jeton, 1 item | **16 jetons** |
| `koto3` | 0 jeton, 0 item | **2 jetons** |
| `mohanam` | 0 jeton, 16 items | **27 jetons** |
| `all-items` | 0 jeton, **12 items** | 0 jeton |

La dernière ligne montre la coupure : `all-items` est purement symbolique, l'énumération
est **sa** vraie action ; les trois autres jouent, et l'énumération leur ferait perdre le jeu.

Le diagnostic vient de **bp3-frontend**, qui avait posé la bonne question avant la mesure :
« capture d'`asymmetric` vide, MIDI déclaré mais énumération symbolique ? ». Réponse : oui.

---

## Concordance indépendante avec BPx

BPx avait porté le dédoublonnage natif (`csrc/bp3/ProduceItems.c:1975-2038`) et refusait de
réconcilier ses tests sur sa propre sortie. Les captures v5 tranchent, **au terminal près** :

| grammaire | natif v5 | mesure BPx | ancienne référence |
|---|---|---|---|
| `tryAllItems0` | 8 items / 20 term. | **8 / 20** | 16 / 40 |
| `tryAllItems1` | 12 / 36 | **12 / 36** | 42 / 134 |
| `tryPatternGrammar` | 4 / 52 | **4 / 52** | 24 / 312 |

Trois concordances exactes sur deux implémentations indépendantes : ce ne sont pas les
sorties de BPx qui ont dérivé, ce sont les anciennes références qui étaient périmées.

⚠ **Piège** : `gramgene2` et `tryGOTO` ressortent en **`single`**, pas en `produce-all` —
le moteur ne les énumère pas. Ne pas les traiter comme des ensembles.

---

## La modalité est établie sur pièces, pas sur le champ déclaré

La modalité retenue est celle qui produit réellement quelque chose. **9 grammaires avaient
une modalité déclarée fausse** (inchangé depuis v1) : `Alarm` (midi → TEXTE), `PP`,
`checkSUB`, `checkSUB.new`, `koto3`, `major-minor`, `negative-context`, `transposition3`,
`tunings` (toutes text → MIDI).

⚠ Nuance : **MIDI pur = 0**. Les 54 grammaires « MIDI » émettent **aussi** du texte. Le
discriminant réel est : *émet-elle des jetons minutés en plus du texte ?*

## Réserve sur `look-and-say`

Seule grammaire gagnée depuis v3, et **inutilisable comme référence** : sa sortie est le
seul terminal de départ (`'1'`), aucune règle n'a été appliquée. Le bug moteur **#51**
(« all weights are nil ») reste actif. Elle est marquée `reserve` dans `baseline.json`.

## Ce que cette baseline est, et ce qu'elle n'est pas

**Elle est** : un état de référence reproductible du binaire courant, à configuration
explicite et graine fixe, avec une action et une modalité établies sur pièces et un statut
motivé pour chaque grammaire.

**Elle n'est pas** : une certification de justesse. Elle dit ce que le moteur produit
aujourd'hui, pas ce qu'il devrait produire. Les grammaires touchées par les bugs #48-#52
produisent une sortie *capturée ici* mais dont la valeur reste sujette à caution — la
re-capture des anciens oracles reste interdite tant que ces bugs sont ouverts, et cette
baseline ne les remplace pas sur ce point.

## Configuration et reproduction

- **Binaire** : `./bp3` v3.4.4, intégration Bernard `graphics-for-BP3` (commit `b094e18`).
- **Graine** : 1 · **113 grammaires** (toutes les entrées de `grammars.json` hors `_comment`).
- **Configuration** : `php_ref` fait autorité (alphabet / réglages / tonalité / Csound +
  convention de note) ; à défaut, les dépendances déclarées en tête de grammaire.
  `-ho.<X>` est traité comme l'ancien nom de l'alphabet.
- **Protocole** : grammaire nettoyée (en-tête BP2 coupé, lignes `INIT:` retirées), un run
  par action, `-o` et `--tokensout` simultanés. Script : `scratchpad/baseline_action.py`.
- **Fichiers** : `baseline.json` (données), `TABLEAU.md` (tableau lisible), `captures/`.

## Deux captures tronquées

`livecode2` (815 Mo) et `tryRagas` (76 Mo) produisent un volume pathologique — déjà signalé
en alerte volume. Leur capture est **tronquée à 2 Mo** pour rester versionnable ; un fichier
`.TRONQUEE.txt` à côté donne la taille réelle et l'empreinte sha256 du fichier complet.
Ces deux-là ne doivent pas servir de référence en l'état.

## Les 24 muettes

Le détail motivé, grammaire par grammaire, est dans `TABLEAU.md`. Le prochain lot annoncé
reste le **tri des 11 erreurs de compilation**.
