# Baseline native « original » — jeu unique, daté, vérifié

## ⚠️ Lequel des trois dossiers fait autorité

**`captures/` fait autorité, et lui seul.** C'est le seul dossier suivi par git ; c'est lui que
`baseline.json` référence et que les gardes vérifient. Les deux autres sont des zones de travail
vides au repos, ignorées par git (`.gitignore`), et ne doivent jamais être lues comme une mesure :

| dossier                 | rôle                                                                             | suivi git |
| ----------------------- | -------------------------------------------------------------------------------- | --------- |
| `captures/`             | **la référence publiée** — 163 fichiers, cités par `baseline.json`                | ✅ oui    |
| `captures.en-cours/`    | zone d'écriture d'une recapture complète, renommée sur `captures/` à la fin       | ❌ non    |
| `captures-a-la-demande/`| sortie du mode mono-grammaire `capture.py <grammaire>` — vérification ponctuelle  | ❌ non    |

Les deux zones de travail existent pour une raison précise : **une recapture ne doit jamais écrire
dans le dossier publié pendant qu'elle tourne.** Le 2026-07-19, une recapture en cours a été lue
par un autre agent comme si c'était la référence, qui a conclu à 27 captures manquantes — elles ne
manquaient pas, elles n'étaient pas encore écrites. D'où la bascule atomique (`captures.en-cours/`
puis renommage, `capture.py:33`) et la zone à part du mode unitaire (`capture.py:163`), qui
n'efface rien et ne bascule rien.

**Si l'un de ces deux dossiers n'est pas vide, c'est un résidu, pas une mesure** — un travail
interrompu ou une vérification ponctuelle qu'on a oublié de balayer. On peut le supprimer sans
rien perdre : tout y est régénérable.

## 🔖 **baseline v13 — figée le 2026-07-19 — moteur v3.4.7**

**98 productibles**, **2 doublons**, **13 muettes réelles**, **113 entrées au total**.
Modes natifs : **MIDI 61** · **TEXTE 37**. Actions : **single 69** · **produce-all 30**.

### v12 → v13 : le moteur passe en v3.4.7, et **une seule entrée change de comportement**

Double comparaison contre la v12 — champ par champ sur les 113 entrées **et** empreinte par
empreinte sur les 163 captures. Une seule divergence est réelle : **`tryRotate`**.

**Ce qui change est la sérialisation TEXTE, pas le calcul.** J'avais d'abord écrit que
l'opérateur n'était plus appliqué — **c'était faux**, et bpscript me l'a fait voir en signalant
que leur mesure porte sur les jetons MIDI, l'axe que je n'avais pas regardé.

|              | v3.4.4                  | v3.4.7                                             |
| ------------ | ----------------------- | -------------------------------------------------- |
| jetons MIDI  | `E4 F4 G4 C4 D4 …`      | `E4 F4 G4 C4 D4 …` — **identiques à l'octet près** |
| sortie texte | `/6 {E4 F4 G4 C4 D4} …` | `/6 {_rotate(K1=2) C4 D4 E4 F4 G4} …`              |

**La rotation est bien appliquée** : `E4 F4 G4 C4 D4` est la rotation de `C4 D4 E4 F4 G4`, et
les 65 jetons MIDI sont identiques entre les deux versions. Ce qui change, c'est que le marqueur
`_rotate(K1=2)` n'est plus effacé du texte affiché, lequel montre les notes **avant** rotation —
alors que la musique produite, elle, est tournée. Le texte et le MIDI ne racontent plus la même
chose.

Question ouverte pour Bernard Bel (constat #59), beaucoup plus étroite que ce que j'avais
d'abord écrit : la sortie texte doit-elle montrer l'expression avant ou après application des
outils sériels ? **Rien n'est cassé dans la production musicale.**

### ⚠️ Six grammaires portent une valeur hors-domaine dans leurs réglages LIVRÉS — marquées « non référence musicale »

Constat #64 (2026-07-25). Leurs fichiers de réglages livrés portent `Nature_of_time`
**hors du domaine `{0,1}`** (`SMOOTH=0` / `STRIATED=1`). Le moteur ne le contrôle pas au
chargement (`SaveLoads1.c:643`) et **dégénère en silence** : tout le minutage tombe à zéro.
Mesuré sur témoin (`Nature_of_time` = 0 → 1000 ms/note, = 1 → identique, = 100 → durées nulles).

**On ne corrige RIEN ici** — décision de l'architecte : la donnée est **livrée par l'amont**, la
baseline reste **fidèle** à « natif + réglages livrés », et l'avertissement voyage avec elle.
La capture est correcte ; c'est la donnée d'entrée qui est fausse. Rien à re-capturer (gel
#48-#52). Le défaut est remonté à Bernard Bel (registre, constat #64).

| grammaire         | `Nature_of_time` | mode  | conséquence |
| ----------------- | ---------------- | ----- | ----------- |
| `simpletemplates` | `100`            | MIDI  | **musicalement CASSÉE** — 7 jetons tous à durée nulle. **N'EST PAS une référence musicale.** |
| `polyphony1`      | `200`            | TEXTE | dégénérescence non entendue (pas de MIDI émis) |
| `tryGOTO`         | `100`            | TEXTE | dégénérescence non entendue |
| `tryLIN`          | `100`            | TEXTE | dégénérescence non entendue |
| `trytemplates`    | `100`            | TEXTE | dégénérescence non entendue |
| `trytemplates2`   | `100`            | TEXTE | dégénérescence non entendue |

Marquées aussi dans `baseline.json` (champ `avertissement_donnee_livree` sur chacune de ces
entrées) pour qu'un outil qui lit une entrée voie l'avertissement sans passer par ce README.
Un 7ᵉ fichier livré porte la même valeur (`-se.gramgene`, `100`) mais sa grammaire n'est **pas**
dans le corpus des 113.

Les trois autres écarts ne sont pas des changements de comportement :

- `trySrand` et `trySerial` — les deux captures **non comparables**, dont l'ordre varie à graine
  fixe par construction (voir plus bas).
- `visser-shapes` et `visser-waves` — leur énumération, qui dépassait la limite de temps lors de
  la capture précédente, a abouti cette fois. Le **jeu mesuré est identique** ; seul le champ
  `items_enumeres` se remplit.

### Ce qui a failli être publié à la place

La première recapture sur v3.4.7 a rendu **98 TEXTE et zéro MIDI**. Cause : l'appel au
sérialiseur de jetons vivait dans un fichier **natif-seul** (`source/BP3/PlayThings.c`) qui a été
repris tel quel depuis l'amont pendant la montée de version. Le binaire construisait, tournait,
sortait `Errors: 0` — et n'émettait plus rien.

Trois mécanismes empêchent désormais que ça se reproduise, chacun prouvé par injection :
une **sonde d'entrée** qui abandonne en quelques secondes si la chaîne est muette, un **garde
d'ancrages** qui refuse qu'un ajout local disparaisse d'un fichier natif-seul, et un **garde
anti-effondrement** qui bloque la publication si la modalité MIDI s'effondre.

### Historique — v9 → v10 : ma configuration de capture ignorait les objets sonores

Signalé par bp3-frontend sur `tryKeyMap` (diagnostic bpx) : ma capture donnait 392 jetons là où
BPx en dérive 410. **Ce n'était pas un écart entre implémentations, mais entre configurations** —
et c'est la mienne qui était incomplète : elle ne chargeait pas le fichier d'objets sonores.

⚠ **Deux références changent. Ne mesurez plus contre les anciennes :**

| grammaire   | avant      | après                                  |
| ----------- | ---------- | -------------------------------------- |
| `tryKeyMap` | 392 jetons | **410** — exactement ce que dérive BPx |
| `dhati`     | 23 jetons  | **66**                                 |

`tryCsoundObjects` est inchangée (son fichier d'objets sonores n'ajoute pas de jetons minutés).
Ce sont les **3 seules** grammaires du corpus disposant d'un `-so`.

**Aucune grammaire ne déclare son `-so`** — ni la référence `php_ref`, ni l'en-tête de la
grammaire. Ils suivent la convention de nom `-so.<grammaire>`, exactement comme `-ho.<X>` pour
l'alphabet. La capture applique désormais la même règle de nommage, et le tableau marque d'un
🔊 les grammaires concernées.

### Le chemin Csound : pourquoi `capture-run/` existe

Le moteur préfixe **en dur** `../` au chemin Csound stocké dans un `-so`
(`csrc/bp3/SaveLoads1.c:855`) — pas de chemin de recherche, et le drapeau `-cs` ne l'écrase pas.
Les `-so` du corpus stockent `csound_resources/-cs.tryCsoundObjects`, chemin correct pour la
disposition de l'installation amont mais pas pour notre arborescence plate.

Décision architecte, **portée à la seule capture** : on reproduit la disposition attendue au lieu
de réécrire le corpus. Le binaire est lancé depuis `capture-run/`, donc `../csound_resources/`
résout sur `csound_resources/` à la racine du dépôt. **Les fichiers `-so` restent intouchés** —
réécrire leur chemin figerait dans le corpus partagé une valeur dépendante du répertoire de
travail, qui marcherait ici et casserait ailleurs.

Le changement de répertoire de travail a été **vérifié sans effet** sur les grammaires sans
objets sonores : `mohanam`, `ruwet`, `all-items`, `tunings` et `koto3` rendent des comptes
strictement identiques.

### v8 → v9 : `checkHomo` et `checkhomo2` récupérées — la cause tient en un caractère

Les deux échouaient sur `=> Can't compile alphabet`, sans plus de détail. Le message précis,
une fois isolé, est sans ambiguïté :

```
Can't accept character ":" in alphabet
```

Or leur alphabet `-ho.checkhomo` ne contient **qu'un seul** `:` — dans sa ligne d'en-tête BP2
`Date: Lun 17 Avr 1995 -- 22:18`. Le compilateur d'alphabet ne saute pas cet en-tête et refuse
le caractère. Deux lignes bloquaient les deux grammaires.

Correction en **données, sans rien détruire** : un alphabet dérivé `-al.checkhomo` est ajouté,
identique au corps près des deux lignes d'en-tête. L'original `-ho.checkhomo` est conservé tel
quel. C'est le même procédé que les 5 alphabets dérivés créés précédemment.
Résultat : **0 erreur de compilation**, `checkHomo` (8 mots) et `checkhomo2` (23 mots, 6 items)
produisent.

**Balayage complet plutôt que le seul cas signalé** : les 11 alphabets `-ho.` à en-tête BP2 ont
tous ce `:` en ligne 2. Six avaient déjà un dérivé ; j'ai créé les **cinq manquants**
(`MyAlphabet`, `Rajeev`, `abc2`, `checkhomo`, `kathak`). Seul `checkhomo` était référencé par
des grammaires — les quatre autres sont orphelins, mais le piège est désormais désamorcé pour
eux aussi.

⚠ **Ce n'est pas la cause de `Rajeev`** : testée avec et sans son alphabet dérivé, elle donne
**27 erreurs dans les deux cas**. Sa cause est ailleurs.

### v7 → v8 : mon détecteur de refus ne connaissait qu'un message sur trois

Signalé par bpx via bp3-frontend sur `koto2`, et **arbitré contre ma baseline** : c'est elle qui
avait tort. En vérifiant, le défaut est plus large que le cas signalé.

Le moteur refuse l'énumération par **trois messages distincts**, et le détecteur n'en connaissait
qu'un :

| message                                                                     | fichier              | connu de v5-v7 ? |
| --------------------------------------------------------------------------- | -------------------- | ---------------- |
| `Can't produce all items in 'SUB' or 'SUB1' or 'POSLONG' subgrammar gram#N` | `ProduceItems.c:770` | oui              |
| `You cannot produce all items in a 'SUB' subgrammar`                        | `Compute.c:1156`     | **non**          |
| `Cannot produce all items because this grammar contains a '…' instruction`  | `CompileProcs.c:568` | **non**          |

Les 30 grammaires classées `produce-all` ont été **toutes** re-vérifiées avec les trois messages.
**Trois étaient mal classées**, pas une : `koto1`, `koto2`, `look-and-say`. Elles passent en
`single` avec `enumeration_statut = refusée (SUB, Compute.c:1156)`.

**`checkBT` a été vérifiée explicitement** (elle aussi affichait `produce-all` / 1 item) : aucun
message de refus, son énumération de taille 1 est **réelle**. Elle ne bouge pas.

### L'artefact du « 1 item » — et ce qu'il coûtait

Quand le moteur refuse l'énumération, `-o` écrit quand même un **résidu de tampon** sur le
disque. Compter les lignes du fichier donne alors « 1 item » là où le moteur en a produit **zéro**.
C'est ce résidu qui masquait les trois refus.

Conséquence directe : **`look-and-say` n'a jamais produit.** Son « gain » annoncé en v5 était
entièrement cet artefact — en action `single` elle ne produit rien du tout. Elle redevient muette,
sur le bug moteur **#51**. La réserve que je lui avais mise était donc justifiée, mais trop douce :
ce n'était pas une production dégénérée, c'était une non-production.

> **La règle qui en découle, et qui vaut pour les deux voies** : ne pas faire émettre le
> résidu-au-refus pour « faire coïncider » le compte. Reproduire un artefact d'interface, c'est
> masquer le refus. BPx a raison de renvoyer un refus franc.

### v6 → v7 : le lot des blocages — 5 récupérées sur 6, cause trouvée

Les 6 grammaires qui « bloquaient > 90 s » n'étaient **pas** une seule famille. La trace, sortie
non tamponnée, montre deux signatures nettes :

**Cinq s'arrêtaient au même point exact** — juste après `N Csound instrument(s) found`, sans un
message de plus : `blurb`, `csound`, `vina`, `vina2`, `vina3`. Cause trouvée : le lecteur de
ressources Csound boucle sans fin quand la section `_begin tables` n'est pas fermée
(`csrc/bp3/SaveLoads1.c:434-448` — les seules sorties sont `_end tables` ou une ligne vide ; à la
vraie fin de fichier, rien). Or `-cs.Vina` et `-cs.tryCsound` avaient **perdu leur `_end tables`**
dans un habillage HTML de l'époque BP2 (dernière ligne ` </html>`).

> **Contre-exemple qui confirme le mécanisme** : `-cs.tryCsoundObjects` n'a pas non plus de
> `_end tables` et pourtant ne bloquait pas — parce qu'il finit par une **ligne vide**, qui
> déclenche la sortie de secours. La terminaison ne tenait qu'à un hasard de mise en forme.

Corpus corrigé (dés-habillage HTML + marqueur rétabli sur les 3 fichiers) : les 5 grammaires
passent de **plus de 90 s de blocage à une production en 1 seconde**. Le défaut **moteur**
subsiste et est remonté à Bernard Bel — bug **#55** : une entrée malformée doit échouer fort,
pas faire tourner le processus sans fin ni message. Résout **BPE-11** et **BPE-13**.

**La sixième n'était pas bloquée du tout.** `cloches1` *produit* — son tampon croît
géométriquement (6876 → 10300 → 15452 → 23180 jetons). C'est une dérivation qui explose. Deux
choses distinctes, à ne pas confondre : son réglage `MaxConsoleTime` converti vaut **59944 s**
(16 h 39), valeur jamais plausible — défaut de corpus ; mais même ramené à 30 s avec un seul
item, le moteur **ne s'arrête pas** — la limite de temps de calcul ne coupe rien pendant
l'expansion du tampon. Bug **#56**, nouvel item **BPE-14**. Elle reste muette.

### v5 → v6 : le lot annoncé « tri des 11 erreurs de compilation »

**Deux entrées ne sont pas des grammaires à réparer : ce sont des doublons.**
`-gr.a.html` et `-gr.tryflags3.html` sont des exports HTML de l'époque BP2. Une fois le
balisage retiré, leurs règles sont **identiques** à celles de grammaires déjà présentes et
productibles : `a.html` ≡ **`checkSUB1`** (10 règles sur 10), `tryflags3.html` ≡
**`tryflags3`** (7 sur 7). Les réparer créerait une seconde référence pour la même grammaire.
Elles sortent donc du dénominateur (champ `doublon_de`) — **les muettes réelles sont 21, pas 24**.

**Une grammaire récupérée : `testTie7`** (MIDI, 2 jetons, 40 mots). Son `php_ref` ne déclare
**aucune** convention de notes ; la baseline n'en passait donc aucune, et le moteur échouait
sur `do4___&`. Avec la convention française : **1 erreur → 0**. La règle appliquée est
explicite et enregistrée dans le champ `convention_source` : *quand `php_ref` est muet sur la
convention, on retient celle qui compile* — `php_ref` reste autoritaire **quand il se prononce**.

Les autres pistes ont été essayées et **écartées sur mesure**, sans être devinées : changer la
convention ne corrige ni `Rajeev` (27 erreurs), ni `checkrests` (12, identiques en français),
ni `dhin` (22), ni `checkVolChan` (6), ni `checkAllCsound` (30). Leur cause est ailleurs.

| version | figée le       | productibles | MIDI   | capture                     | commit    |
| ------- | -------------- | ------------ | ------ | --------------------------- | --------- |
| v1      | 2026-07-18     | 74           | 51     | répétition (N items)        | `579ca59` |
| v2      | 2026-07-18     | 86           | 52     | répétition (N items)        | `7a970ac` |
| v3      | 2026-07-18     | 88           | 54     | répétition (N items)        | `b59091c` |
| v5      | 2026-07-18     | 89           | 54     | par action                  | `8dd3ec5` |
| v6      | 2026-07-19     | 90           | 55     | par action                  | `5dd8c41` |
| v7      | 2026-07-19     | 95           | 60     | par action                  | `cc7912f` |
| v8      | 2026-07-19     | 94           | 60     | par action                  | `2740868` |
| v9      | 2026-07-19     | 96           | 60     | par action                  | `b06ec47` |
| **v10** | **2026-07-19** | **96**       | **60** | par action + objets sonores | ce commit |

| version | figée le       | productibles | MIDI   | capture              | commit    |
| ------- | -------------- | ------------ | ------ | -------------------- | --------- |
| v1      | 2026-07-18     | 74           | 51     | répétition (N items) | `579ca59` |
| v2      | 2026-07-18     | 86           | 52     | répétition (N items) | `7a970ac` |
| v3      | 2026-07-18     | 88           | 54     | répétition (N items) | `b59091c` |
| **v5**  | **2026-07-18** | **89**       | **54** | **par action**       | ce commit |

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

| action            | sens                               | capture                                   |
| ----------------- | ---------------------------------- | ----------------------------------------- |
| **`single`**      | la grammaire **joue** un morceau   | **une** réalisation, **1 item**, graine 1 |
| **`produce-all`** | production purement **symbolique** | **l'ensemble** énuméré par le moteur      |

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

| `enumeration_statut`                              | n   |
| ------------------------------------------------- | --- |
| sans objet : la grammaire joue, on capture le jeu | 54  |
| acceptée par le moteur                            | 30  |
| refusée par le moteur (`SUB`/`SUB1`/`POSLONG`)    | 3   |
| blocage > 90 s — `gramgene2`                      | 1   |
| aucun item produit, sans message — `asymmetric`   | 1   |

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

| grammaire   | `produce-all`         | `produce`     |
| ----------- | --------------------- | ------------- |
| `tunings`   | 0 jeton, 1 item       | **16 jetons** |
| `koto3`     | 0 jeton, 0 item       | **2 jetons**  |
| `mohanam`   | 0 jeton, 16 items     | **27 jetons** |
| `all-items` | 0 jeton, **12 items** | 0 jeton       |

La dernière ligne montre la coupure : `all-items` est purement symbolique, l'énumération
est **sa** vraie action ; les trois autres jouent, et l'énumération leur ferait perdre le jeu.

Le diagnostic vient de **bp3-frontend**, qui avait posé la bonne question avant la mesure :
« capture d'`asymmetric` vide, MIDI déclaré mais énumération symbolique ? ». Réponse : oui.

---

## Concordance indépendante avec BPx

BPx avait porté le dédoublonnage natif (`csrc/bp3/ProduceItems.c:1975-2038`) et refusait de
réconcilier ses tests sur sa propre sortie. Les captures v5 tranchent, **au terminal près** :

| grammaire           | natif v5           | mesure BPx  | ancienne référence |
| ------------------- | ------------------ | ----------- | ------------------ |
| `tryAllItems0`      | 8 items / 20 term. | **8 / 20**  | 16 / 40            |
| `tryAllItems1`      | 12 / 36            | **12 / 36** | 42 / 134           |
| `tryPatternGrammar` | 4 / 52             | **4 / 52**  | 24 / 312           |

Trois concordances exactes sur deux implémentations indépendantes : ce ne sont pas les
sorties de BPx qui ont dérivé, ce sont les anciennes références qui étaient périmées.

⚠ **Piège** : `gramgene2` et `tryGOTO` ressortent en **`single`**, pas en `produce-all` —
le moteur ne les énumère pas. Ne pas les traiter comme des ensembles.

---

## Forme canonique de la capture TEXTE : **brute, structure comprise**

Question posée par bp3-frontend sur `Alarm`, tranchée ici puisque la baseline est la référence.

La capture TEXTE est la **sortie brute** de `produce -o`, sans retouche. Sur une grammaire
polymétrique elle porte donc la structure, et c'est **voulu** :

```
do3 1000{2,{{2,fa3,la3}{sol3,re4},re5 fa5 re5 fa5 si4 re5}{do3 sol2 do2,do5 _ -}}300 …
```

Ce n'est pas de la décoration. En Bol Processor, un item **est** une expression polymétrique :
`{a,b}` dit la simultanéité, `1000{…}300` l'échelle de tempo, `_` la prolongation, `-` le
silence. **Aplatir en liste de jetons détruit la simultanéité et les durées, et n'est pas
réversible.** Une référence qui aplatit ne peut plus arbitrer quoi que ce soit sur la structure
— elle cesse d'être une référence. La capture reste donc lossless.

**5 captures TEXTE sur 35** sont concernées (champ `texte_structure`) : `Alarm`, `ek-do-tin`,
`polyphony1`, `tryCsoundObjects`, `tryObjects`.

### Comment comparer avec une voie qui aplatit

Pas en changeant la référence. Si une voie rend des jetons plats, c'est la **couche de
comparaison** qui doit appliquer un aplatissement **déclaré et déterministe** aux **deux**
côtés — jamais un côté brut contre un côté aplati. Cet aplatissement appartient au harnais,
pas à la capture.

⚠ **`mots_texte` n'est pas un compte de jetons.** C'est un découpage sur les espaces, et sur
un texte polymétrique il ne veut rien dire : `Alarm` donne 26 « mots » là où un aplatissement
correct donne un autre nombre. Ne jamais opposer `mots_texte` au compte de jetons d'une voie —
c'est comparer deux grandeurs différentes.

## La modalité est établie sur pièces, pas sur le champ déclaré

La modalité retenue est celle qui produit réellement quelque chose. **9 grammaires avaient
une modalité déclarée fausse** (inchangé depuis v1) : `Alarm` (midi → TEXTE), `PP`,
`checkSUB`, `checkSUB.new`, `koto3`, `major-minor`, `negative-context`, `transposition3`,
`tunings` (toutes text → MIDI).

⚠ Nuance : **MIDI pur = 0**. Les 54 grammaires « MIDI » émettent **aussi** du texte. Le
discriminant réel est : *émet-elle des jetons minutés en plus du texte ?*

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
