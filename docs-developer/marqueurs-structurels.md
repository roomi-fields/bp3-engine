# Les quatre marqueurs structurels `+ : ; =` — sens dédié de chacun

Établi le 2026-07-19 par `bp3-engine`, sur les sources `csrc/bp3/` et `BP3_help.txt`,
en réponse à la demande d'arbitrage langage de Romain (courrier [110]).

## Je corrige mon propre diagnostic

J'avais conclu « les quatre tombent sur le même `return TRUE` dans
`ProduceItems.c:1120`, donc ils sont interchangeables ». **C'est faux.**

`StructuralRule()` (`csrc/bp3/ProduceItems.c:1085-1133`) est un **détecteur**, pas un
interpréteur : il répond à une seule question — « cette règle construit-elle de la
structure ? » — et une réponse unique y est donc normale. Elle ne dit rien du sens de
chaque glyphe. Le sens est ailleurs, et il est **différent pour chacun**.

Ce que dit la documentation est par ailleurs minimal (`BP3_help.txt:97-99`) :

```
### Structural markers
• The glyphs '+', ':', ';', and '=' can be used in grammar rules as structural markers.
• See for instance "-gr.dhadhatite" using '+'.
```

Deux lignes, aucun sens donné. Le sens est **prouvable dans le code**, et il l'est
ci-dessous, glyphe par glyphe.

## `=` et `:` — un couple maître / esclave (le mécanisme le plus fort)

Ces deux-là ne sont pas seulement distincts : ils sont **appariés**, l'un ne va pas sans
l'autre.

- Après une parenthèse ouvrante, seuls `=` et `:` sont acceptés. Tout autre caractère fait
  de la parenthèse un **contexte distant**, légal uniquement dans l'argument gauche
  (`csrc/bp3/Encode.c:730-733`). Message d'erreur dédié n° 18 :
  `"'=' or ':' marker must follow opening bracket"` (`csrc/bp3/Encode.c:1659`).
- `( = … )` déclare un **maître** : le bloc est enregistré dans la table des maîtres
  (`csrc/bp3/Encode.c:1421-1428`), avec son début et sa fin.
- `( : … )` déclare un **esclave** : il est relié au maître correspondant par
  `Reference()` (`csrc/bp3/Encode.c:1490-1496`) ; si aucun maître ne correspond,
  la compilation échoue avec l'erreur 17.
- Le recodage est fait en amont par `Recode()` (`csrc/bp3/Encode.c:1355-1364`) :
  `=` devient la marque 0 (maître) et `:` la marque 1 (esclave).

C'est exactement l'usage de la grammaire d'exemple : `(= V8 )` … plus loin `(: V8 )`
(`test-data/-gr.dhadhatite:19`). Un motif est **déclaré une fois** et **réutilisé
à l'identique** ailleurs dans la même règle.

**Conséquence** : `=` et `:` ne sont pas substituables l'un à l'autre — les intervertir
change le maître en esclave et casse la règle.

## `;` — barrière de dérivation ; le saut de ligne est du code mort

**Correction du 2026-07-19, après test empirique** (demande [112]). J'avais écrit ici que
`;` devient un retour à la ligne. Le moteur contient bien cette règle
(`csrc/bp3/DisplayArg.c:1093`, `/* interpreting grammar: ';' becomes '\r' */`) **mais elle
ne s'exécute jamais** : elle est conditionnée au drapeau `ifunc`, levé uniquement quand
`Jfunc` est non nul, et `Jfunc` n'est affecté qu'en `csrc/bp3/CompileGrammar.c:1354` — une
ligne **commentée**. Voir le constat #58 du registre des bugs moteur.

Ce que `;` fait réellement, mesuré sur le moteur natif v3.4.4 :

```
GRAM#1[1] S --> C4 ; D4     →  sortie : C4 ; D4
GRAM#1[1] S --> C4 D4       →  sortie : C4 D4
```

Il est **transporté tel quel jusqu'à la sortie** et imprimé littéralement. Il ne produit
par lui-même **aucun son** : ici, jetons et minutage strictement identiques avec et sans
(`C4` 0→1000, `D4` 1000→2000 dans les deux cas). Attention toutefois — cela ne veut pas
dire qu'il est sans effet musical : dès qu'une règle peut s'appliquer par-dessus lui, sa
présence change la séquence produite (voir la dernière section).

Son effet réel est d'être une **barrière dans la dérivation** — il empêche une règle de
s'appliquer à cheval sur lui :

```
GRAM#1[1] S --> A ; B        GRAM#1[1] S --> A B
---  ORD                     ---  ORD
GRAM#2[1] A B --> C4         GRAM#2[1] A B --> C4
GRAM#2[2] A --> D4           GRAM#2[2] A --> D4
GRAM#2[3] B --> E4           GRAM#2[3] B --> E4

→ sortie : D4 ; E4           → sortie : C4
```

Sans le marqueur, `A B` s'apparie et donne `C4`. Avec lui, l'appariement est bloqué. Les
trois autres marqueurs se comportent **exactement pareil** sur ce test (`D4 +E4`,
`D4 = E4`, `D4 : E4`) : en tant que barrières de dérivation, les quatre sont bien
équivalents. C'est dans leurs **contextes dédiés** — parenthèses pour `=`/`:`, en-tête de
section pour `+` — qu'ils se distinguent.

## `+` — séparateur de mesure additive

`+` a un sens dédié dans l'**en-tête de section métrique**, la forme `4+4+4+4/4` que porte
`test-data/-gr.dhadhatite:16`. Quatre traitements distincts le prouvent, tous conditionnés
au contexte « section de réglage » :

| lieu | ce que `+` y déclenche |
|---|---|
| `csrc/bp3/Polymetric.c:181` | mémorise qu'une mesure additive a été vue, et insère un marqueur de vitesse `/1` implicite si aucun n'est donné |
| `csrc/bp3/DisplayArg.c:408` | ouvre une nouvelle sous-section dans la table des sections |
| `csrc/bp3/DisplayArg.c:98`, `:153`, `:223` | est sauté lors de la lecture du tempo |
| `csrc/bp3/ProduceItems.c:1204` | est sauté par l'effacement des marqueurs |

`4+4+4+4/4` se lit donc « quatre groupes de quatre, sur une pulsation de 4 » — une mesure
**additive**, pas une multiplication.

## Ce que Bernard Bel dit lui-même de l'usage

Le commentaire d'en-tête de la grammaire d'exemple (`test-data/-gr.dhadhatite:9-13`) :

> « I have used the '+' sign to mark contexts and decide which variant of the pattern has
> been found. »

Autrement dit, au-delà du sens que le moteur leur donne, l'auteur d'une grammaire s'en sert
aussi comme **étiquettes de sa propre invention** pour départager des variantes ambiguës.
Les deux niveaux coexistent.

## Deux points à signaler pour l'arbitrage

1. **Un cinquième marqueur non documenté.** `StructuralRule()` reconnaît aussi `\`
   (`csrc/bp3/ProduceItems.c:1127`), qui est le marqueur de **ralentissement**, symétrique
   de `/` (`csrc/bp3/Polymetric.c:993`, `csrc/bp3/Zouleb.c:191`). `BP3_help.txt:98` n'en
   parle pas. Et `/` figure dans le même bloc, commenté « never found because illicit ».
2. **Les branches `case 4` / `case 6` de `StructuralRule` ne voient pas la forme parenthésée.**
   Sous la forme `(=` / `(:`, `Recode()` a déjà réécrit les jetons avant que
   `StructuralRule()` ne les examine ; ils sont alors attrapés par la branche « parenthèse »
   qui précède. Ces deux branches ne peuvent donc concerner qu'un `=` ou `:` **nu**, hors
   parenthèses. Je n'ai pas trouvé de grammaire du corpus qui les emploie ainsi — à
   instruire si Romain veut trancher cet usage.

## Réponse courte à la question posée

| glyphe | sens dédié, prouvé | où |
|---|---|---|
| `=` | ouvre un bloc **maître** (motif de référence) | `Encode.c:1355`, `:1421` |
| `:` | ouvre un bloc **esclave**, relié à son maître | `Encode.c:1362`, `:1490` |
| `;` | **barrière de dérivation** et marqueur de position : il sélectionne quelle règle s'applique où | mesuré (dernière section) ; le saut de ligne de `DisplayArg.c:1093` est du code mort (constat #58) |
| `+` | séparateur de **mesure additive** en en-tête de section | `Polymetric.c:181`, `DisplayArg.c:408` |

Nuance, après le test empirique du 2026-07-19 : dans le rôle **commun** de barrière de
dérivation, les quatre sont équivalents et interchangeables. C'est dans leurs **contextes
dédiés** qu'ils se distinguent — et pour `;` ce contexte dédié n'existe plus dans le
binaire actuel, la fonction étant désactivée par une ligne commentée (constat #58).

## Le `;` sert-il hors métaprogrammation ? — OUI, et il porte la musique

Établi le 2026-07-19 en réponse à la demande [113] : la métaprogrammation (émission de
texte de grammaire) étant **hors périmètre** par décision datée, il fallait savoir si `;`
n'a de sens **que** là — auquel cas il n'y aurait rien à porter.

**Réponse : non. `;` est porteur dans une grammaire purement musicale.**

### Une grammaire du corpus, purement musicale, l'emploie

`test-data/-gr.dhati` est une qā'ida de tabla : notes françaises, sortie MIDI (66 jetons),
aucune émission de texte. Elle emploie `;` dans **neuf** règles, et — c'est le point — en
**stricte parallèle avec `+`**, comme deux marqueurs de **position dans le cycle rythmique** :

```
gram#6 [12] LEFT A8 + <-> dhatidhagedheenagena+       ← position marquée '+'
gram#6 [13] LEFT A8 ; <-> dhatidhagedheenagena;       ← position marquée ';'
```

Les deux règles sont identiques **au marqueur près**. Même chose côté `gram#3`, où le
marqueur décide vers quel symbole on réécrit :

```
gram#3 [26] <100> LEFT N16 + <-> V8 A8 +
gram#3 [36] <100> LEFT O16 ; <-> V8 A8 ;
```

Membre droit identique, marqueur différent, **membre gauche différent** (`N16` contre
`O16`). Le marqueur est donc ce qui discrimine.

### Le retirer symétriquement ne prouve rien — le test qui tranche est asymétrique

Retirer `;` **des deux côtés** de toutes les règles ne change rien : sur dix graines, jetons
et minutage strictement identiques. C'est logique — les règles restent cohérentes entre
elles, donc elles s'apparient pareil. Ce test-là ne dit rien.

Le test qui tranche est de changer le marqueur dans **une seule** règle, en gardant tout le
reste. Dans `gram#6 [13]`, on remplace `;` par `+` :

```
gram#6 [13] LEFT A8 ; <-> dhatidhagedheenagena;      →      gram#6 [13] LEFT A8 + <-> dhatidhagedheenagena+
```

Résultat sur cinq graines : **la musique produite diffère sur deux d'entre elles**. Sur la
graine 1, le détail est sans appel :

| | jetons | fin de la sortie |
|---|---|---|
| avec `;` (original) | **66** | `… dha ge dhee na ge dha ge dha ti dha ge dhee na ge na` |
| avec `+` (marqueur changé) | **61** | `… dha ge A8}` |

Avec le mauvais marqueur, la règle **ne s'applique plus** : le symbole `A8` reste non
réécrit dans la sortie, et cinq jetons musicaux disparaissent. Le marqueur est donc
**porteur** : il sélectionne quelle règle de réécriture s'applique à quelle position du
cycle.

### Conclusion pour l'arbitrage

`;` a **deux emplois distincts**, et un seul est hors périmètre :

1. **Marqueur de position structurelle dans une grammaire musicale** — porteur, prouvé
   ci-dessus sur une grammaire réelle du corpus. **Rien à voir avec la métaprogrammation.**
   C'est cet emploi-là qu'il faut porter.
2. **Saut de ligne pour engendrer du texte de grammaire** — relèverait bien de la
   métaprogrammation exclue, mais la question ne se pose même pas : cette fonction est
   **éteinte** dans le binaire (constat #58).

Donc : **porter**, et porter le sens n° 1, qui est le seul qui existe réellement dans le
moteur d'aujourd'hui.
