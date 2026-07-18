# Baseline native « original » — jeu unique, daté, vérifié

## 🔖 **baseline v3 — figée le 2026-07-18 — 88 productibles** (MIDI 54 + TEXTE 34), 25 muettes, 113 au total

| version | figée le | productibles | commit |
|---|---|---|---|
| v1 | 2026-07-18 | 74 (MIDI 51 + TEXTE 23) | `579ca59` |
| v2 | 2026-07-18 | 86 (MIDI 52 + TEXTE 34) | `7a970ac` |
| **v3** | **2026-07-18** | **88 (MIDI 54 + TEXTE 34)** | ce commit |

**+12 depuis v1, 0 perdue.** Lot : piste BP2, 34 fichiers de réglages convertis.
Ajoutées : `dhati2`, `dhati3`, `gramgene1`, `gramgene2`, `polyphony1`, `simpletemplates`,
`tryGOTO`, `tryLIN`, `tryflags2`, `tryflags3`, `trytemplates`, `trytemplates2`.

La baseline grandit **par lots signalés**, pas en continu : chaque version est figée, datée et
annoncée. Une mesure de conformité doit citer la version sur laquelle elle s'appuie.


Étape 1 du plan de reconstruction (demande architecte [80]). Remplace le fouillis
`s1_native` / `s2_orig` / `s3_native`. **Aucun ancien oracle n'a été touché** : tout est créé
ici, sous `baseline-native/`.

- **Binaire** : `./bp3` v3.4.4, issu de l'intégration Bernard `graphics-for-BP3` (commit `b094e18`).
- **Date** : 2026-07-18 · **graine** : 1 · **113 grammaires** (toutes les entrées de
  `grammars.json` hors `_comment`).
- **Configuration** : déterministe, type S0 — `php_ref` fait autorité (alphabet / réglages /
  tonalité / Csound + convention de note) ; à défaut, les dépendances déclarées en tête de
  grammaire. `-ho.<X>` est traité comme l'ancien nom de l'alphabet.
- **Fichiers** : `baseline.json` (données), `TABLEAU.md` (tableau lisible), `captures/`
  (les captures elles-mêmes).

## Compte par modalité

| | n |
|---|---|
| **MIDI** (émet des jetons minutés) | **52** |
| **TEXTE** (production symbolique seule) | **34** |
| ne produit pas | **27** |
| **total** | **113** |

## La modalité est établie sur pièces, pas sur le champ déclaré

Chaque grammaire est lancée **une fois avec les deux sorties** (`--tokensout` *et* `-o`), et la
modalité retenue est celle qui produit réellement quelque chose.

⚠ **Nuance importante, à ne pas perdre** : `MIDI pur = 0`. Les 51 grammaires « MIDI » émettent
**aussi** du texte — la sortie `-o` existe dès que la production aboutit. Le discriminant réel
est donc : *émet-elle des jetons minutés en plus du texte ?* Les 23 « TEXTE » n'en émettent
aucun.

**9 grammaires avaient une modalité déclarée fausse** :

| grammaire | déclaré | réel | jetons | mots |
|---|---|---|---|---|
| `Alarm` | midi | **TEXTE** | 0 | 26 |
| `PP` | text | **MIDI** | 26 | 73 |
| `checkSUB` | text | **MIDI** | 10 | 13 |
| `checkSUB.new` | text | **MIDI** | 10 | 13 |
| `koto3` | text | **MIDI** | 22 | 266 |
| `major-minor` | text | **MIDI** | 24 | 2 |
| `negative-context` | text | **MIDI** | 6 | 6 |
| `transposition3` | text | **MIDI** | 66 | 30 |
| `tunings` | text | **MIDI** | 16 | 16 |

(`testHO2`, cité comme exemple dans la demande, est en réalité correctement déclarée `text` —
et elle produit bien du texte.)

## Les 39 qui ne produisent pas, par cause

| n | cause | récupérable ? |
|---|---|---|
| **13** | réglages en ancien format, non convertis (lot en HOLD de BPE-7) | **oui**, dès la conversion finie |
| 11 | erreurs de compilation | à trier une par une |
| 5 | blocage > 90 s sans rendre la main | non — cf. BPE-11 |
| 3 | aucune sortie, aucun message discriminant | à instruire |
| 2 | bug moteur #51/#52 (« all weights are nil ») — `Nadaka1`, `look-and-say` | non, amont |
| 2 | boucle de dérivation (« Calculation overflow, 10000 derivations ») — `checkcontext`, `tryConsoleMaxTime` | non |
| 2 | fichier Csound déclaré introuvable — `scales`, `tryShruti` | oui, corpus |
| 1 | mojibake corpus (`Æ1`) — `trySerial` | oui, corpus |

**Le premier gisement est identifié et chiffré : 13 grammaires reviendront dès que les 56
fichiers de réglages en HOLD seront convertis** (23 au format BP3-128 + 34 suspects de
plausibilité). C'est le lien direct entre cette baseline et la piste BP2 restée ouverte.

## Ce que cette baseline est, et ce qu'elle n'est pas

**Elle est** : un état de référence reproductible du binaire courant, à configuration explicite
et graine fixe, avec une modalité établie sur pièces et un statut motivé pour chaque grammaire.

**Elle n'est pas** : une certification de justesse. Elle dit ce que le moteur produit
aujourd'hui, pas ce qu'il devrait produire. Les grammaires touchées par les bugs #48-#52
produisent une sortie *capturée ici* mais dont la valeur reste sujette à caution — la re-capture
des anciens oracles reste interdite tant que ces bugs sont ouverts, et cette baseline ne les
remplace pas sur ce point.

## Reproduire

`scratchpad/baseline.py` de la session. Le protocole tient en trois points : grammaire nettoyée
(en-tête BP2 coupé, lignes `INIT:` retirées), configuration `php_ref`, un seul run par grammaire
avec `-o` et `--tokensout` simultanés.

## Deux captures tronquées

`livecode2` (815 Mo) et `tryRagas` (76 Mo) produisent un volume pathologique — déjà signalé
en alerte volume. Leur capture est **tronquée à 2 Mo** pour rester versionnable ; un fichier
`.TRONQUEE.txt` à côté donne la taille réelle et l'empreinte sha256 du fichier complet.
Ces deux-là ne doivent pas servir de référence en l'état : le volume est à instruire d'abord.

## MAJ 2026-07-18 — piste BP2 : 12 grammaires récupérées

34 fichiers de réglages convertis : les **23 au format BP3-128** puis les **11** dont dépendaient
les grammaires muettes. Résultat : **51/23/39 → 52/34/27**, soit **+12 productrices, 0 régression**.

Revenues : `dhati2`, `dhati3` (80 mots), `gramgene1` (884), `gramgene2` (372), `polyphony1` (73),
`simpletemplates` (**MIDI**, 16 jetons), `tryGOTO`, `tryLIN`, `tryflags2` (25 chacune),
`tryflags3` (2), `trytemplates` (442), `trytemplates2` (660).

**Plus aucune grammaire n'est bloquée par le format des réglages.** Le 13ᵉ attendu, `blurb`,
a bien vu ses réglages convertis mais bascule sur une autre cause : blocage > 90 s.

⚠ **Réserve à connaître sur ces 11 fichiers** : leurs layouts sont anciens (`V.2.5`, `BP2.6.1`)
et ne correspondent pas à la carte du convertisseur. La garde de plausibilité de bpscript a donc
**écarté 5 à 6 champs par fichier** (`MaxConsoleTime`, `C4key`, `A4freq`, `VolumeController`,
`SamplingRate`, parfois `DefaultBlockKey`), qui retombent sur les défauts du moteur — lesquels
sont les valeurs standard (C4key 60, A4freq 440). Les grammaires produisent, mais ces réglages
sont **partiels**, pas intégralement fidèles à l'original. Une conversion complète exigerait les
cartes par version (`if(iv > N)`), cf. `docs-developer/format-se-bp2/`.

Le décalage de 2 lignes dû à l'en-tête `V.x`/`Date:` a été testé et **écarté** : il ne rend pas
les valeurs plausibles sur ces fichiers. Le problème est bien le layout, pas un offset.

## MAJ v3 — mojibake du corpus : +2 grammaires

Deux corruptions d'encodage corrigées dans les grammaires, cibles **documentées**, pas devinées :

- `Æ` → `t` — noms de motifs temporels. `BP3_help.txt:620` : « Time patterns always start with
  't' followed with digits », et `BP3_help.txt:1581` donne l'exemple **identique** à la ligne
  corrompue : `a b _retro {t1 t2 t3,f g}`. (`-gr.trySerial`)
- `¥` → `.` — délimiteur de temps. C'est la substitution que le harnais S0 applique déjà
  (`replace(/¥/g,'.')` dans `s0_snapshot.cjs`), et le point est documenté comme délimiteur de
  battement. (`-gr.trySerial`, `-gr.doeslittle`)

Revenues : **`trySerial`** (MIDI, 8 jetons), **`doeslittle`** (MIDI, 7 jetons).
Plus aucun `Æ` ni `¥` dans le corpus.

### Correction d'une catégorisation erronée de v2

v2 annonçait « 2 fichiers Csound introuvables — récupérables ». **C'est faux, et je le corrige :**
`-cs.tryShruti` et `-cs.tryScales` existent bien (ils viennent de l'arbre amont de Bernard), mais
sont dans un format textuel que le moteur ne lit pas. Surtout, ce n'était pas la vraie cause :
sans le Csound, `tryShruti` et `scales` échouent quand même sur des terminaux microtonaux
inconnus (`sa_4`, `fap3`) que le fichier de tonalité ne résout pas non plus.
**Ces deux-là relèvent de M1** (backlog : « nom de terminal vide sur gamme invalide »), déjà
ouvert et en attente d'arbitrage. Ce ne sont **pas** des gains rapides.
