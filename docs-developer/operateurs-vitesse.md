# Les opérateurs de vitesse `/ \ * **` — deux variables, un rapport, une sortie normalisée

Établi le 2026-07-25 par `bp3-engine`, oracle du moteur natif v3.4.7, sur `csrc/bp3/`
et le binaire, en réponse à la demande [168] (Romain : « combien de choses distinctes
appelle-t-on tempo ? »).

**Axe des mesures : la sortie texte de `produce -o` (chaîne de travail sérialisée).**
Aucune mesure MIDI. Toutes les exécutions faites sur `./bp3` v3.4.7, graine `1`.

## 1. Deux variables internes, pas une — `tempo = speed / scale`

Le moteur ne connaît pas « le tempo » comme une grandeur unique. Il tient **deux**
variables et le tempo effectif en est le **rapport** :

`DisplayArg.c:82` `tempo = tempo2 = scale = speed = 1.;` — initialisées à 1.
`DisplayArg.c:450` `tempo = speed / (*p_scale);` — le rapport, recalculé à chaque marqueur.

| glyphe écrit | code jeton | effet mesuré | preuve code |
| --- | --- | --- | --- |
| `/N`  | 11 | `speed := N`     | `DisplayArg.c:448`, `Polymetric.c:1064` |
| `\N`  | 25 | `speed := 1/N`   | `DisplayArg.c:469` |
| `*N`  | 21 | `scale := N`     | `DisplayArg.c:490` |
| `**N` | 24 | `scale := 1/N`   | `DisplayArg.c:510` |

Encodage des glyphes : `Encode.c:109` (`*`=21), `:112` (`**`=24), `Encode.c:1335-1336`
(`*`=21, `\`=25) ; `/` = 11. Argument : `GetScalingValue` (`Misc.c:1193`) rend
`TOKBASE*m + p`, un **entier positif** — N entier obligatoire, conforme à l'article B12.

**La grille des quatre opérateurs de B12 est CONFIRMÉE** sur le code et le binaire, avec
une précision : `/` et `\` pilotent `speed`, `*` et `**` pilotent `scale`, et c'est leur
**rapport** qui fait le tempo. `{N,...}` est autre chose — voir §5.

## 2. `*1/4` en sortie n'est PAS une fraction — ce sont DEUX marqueurs

C'est le piège central de la question 2. La sortie normalisée d'un état de tempo est
**`*<scale>` suivi de `/<speed>`**, collés sans espace. `*1/4` se lit :

```
*1     /4          →   scale = 1 , speed = 4   →   tempo = speed/scale = 4
└scale┘└speed┘
```

**Ce n'est pas « un quart ».** C'est l'échelle 1 puis la vitesse 4. Même classe de piège
que la coïncidence de noms dans [`contexte-negatif.md`](contexte-negatif.md) §3bis : la
graphie ressemble à autre chose que ce qu'elle est.

L'imprimeur émet TOUJOURS l'état dans l'ordre canonique échelle-puis-vitesse, quel que
soit ce qui était écrit en entrée (`DisplayArg.c:611-651`) :
- part échelle : `*<scale>` si `scale ≥ 1`, sinon `**<1/scale>` (`:613`, `:622`) ;
- part vitesse : `/<speed>` si `speed ≥ 1`, sinon `\<1/speed>` (`:634`, `:643`).

Donc une grammaire qui n'écrit **que** des `/N` produit quand même des `*` en sortie :
le `*1` (scale=1) est **injecté par l'imprimeur**, il n'est pas dans l'entrée.

> Correction d'une hypothèse de la demande : `*1/4` n'est PAS « la forme normalisée de
> `**4` ». `**4` donnerait `scale = 1/4` → part échelle `**4`. `*1/4` est `scale=1`,
> `speed=4`. Deux choses différentes.

## 3. Pourquoi DEUX formes pour la même entrée `/N` — la frontière de bloc

Question 3. Ce qui discrimine n'est **ni la valeur, ni le contexte polymétrique** : c'est
la **frontière de bloc**. Le drapeau `forceshowtempo` est armé par `{`, `}`, `,`, `•`
(`DisplayArg.c:1155-1156`) :

```c
if(!datamode && (p == 12 || p == 13 || p == 14 || p == 7)) /* '{', '}', ',', '•' */
    forceshowtempo = TRUE;
```

Quand il est armé, l'imprimeur écrit l'**état complet** `*scale/speed` même si l'échelle
n'a pas changé — c'est la condition `(forceshowtempo && scale == 1.)` de `:613` qui laisse
passer le `*1`. À l'intérieur du bloc, `forceshowtempo` retombe et seule la part qui a
**changé** est réémise (la vitesse) : `scale==1` n'étant plus forcé, `*1` est omis.

C'est un **encodage delta** : état complet à chaque frontière, puis seulement les écarts.

**Pièce C — grammaire réelle MyMelody (n'écrit QUE `/1 /4 /8 /2`) :**

```
entrée : ... S --> /1 {MyMelody1,...}   MyMelody1 --> /4 mi5 ... /8 ... /4 ...
sortie : /1 {*1/4  mi4 _ _ re4 do4 - /8  re4 mi4 re4 mi4 /4  fa4 ... *1/2 {sol1,...}}
         │   └frontière { → forme pleine┘  └── deltas dans le bloc ──┘  └{ imbriqué┘
```

- `/1` avant tout bloc : marqueur de champ, style « section » (`DisplayArg.c:408-425`) ;
- `*1/4` juste après `{` : forme pleine (forceshowtempo) ;
- `/8`, `/4` dans le bloc : delta, seule la vitesse ;
- `*1/2` après le `{` imbriqué : de nouveau la forme pleine.

**Pièce C — témoin construit :** grammaire `S --> /2 do re /3 mi fa {do re /2 mi fa}`
donne `/2 do3 re3 /3 mi3 fa3{do3 re3 *1/2 mi3 fa3}`. Le `/2` écrit **dans** le bloc
ressort `*1/2` : le `*1` apparaît exactement à la frontière, jamais ailleurs.

## 4. `/N` nu est ABSOLU — le moteur le dit dans ses propres commentaires

Question 4, le point le plus lourd. Le code tranche par ses commentaires, dans le cas
d'un `/N` **hors** ratio structurel (`Polymetric.c:1059-1065`) :

```c
speed = speed * h; /* only temporary and relative change of speed */   // cas {n,...}
...
(*p_fixtempo) = TRUE;
speed = h;         /* absolute value */                                 // cas /N nu
```

Un `/N` nu fait `speed := h` (**assignation absolue**) et lève `fixtempo`. Il ne
**compound pas** la vitesse courante. Cela **confirme mot pour mot** la décision
2026-06-10 : « /N nu = absolu + fixtempo + persistance jusqu'à fin de champ ».

**Pièce C — témoin non ambigu :** `S --> /2 do re /3 mi fa ...` donne `/2 ... /3 ...`.
Si `/N` était compoundé sur la vitesse courante, `/2 /3` donnerait `/2 /6` (2 puis 2×3).
Mesuré : **2 puis 3**. Absolu.

**Écrit de Bernard, pièce 0.B :** `BP3_help.txt:533-536` — pour `... /4 ... /3 ... /1`,
*« starts at speed 4, goes on at speed 3 and ends up at speed 1 »*. La valeur N EST la
vitesse, lue directement. L'aide elle-même décrit `/N` comme absolu.

**Réconciliation avec le « /N multiplie la vitesse par N » de B12.** Les deux lectures
sont vraies sur des axes différents et ne se contredisent pas :
- **mécanisme** : `/N` ASSIGNE `speed := N` (absolu, non cumulatif) ;
- **effet** : le tempo local vaut `speed/scale = N/1 = N` fois la base (scale=1 par
  défaut) — d'où « multiplie » la base.

« Multiplier la BASE » n'est pas « multiplier la valeur COURANTE ». `/4 /8` donne les
vitesses 4 puis 8, jamais 4 puis 32. Pour nous, la vérité opératoire est celle de la
décision : **absolu**. Le « multiplie » de B12 décrit le rapport à la base, pas un cumul.

## 5. `{N,...}` n'est pas du tempo — ratio structurel local, rationnel

B12 le dit et le code le confirme : dans `{n,...}` (branche `newg`, `Polymetric.c:1059`)
le moteur fait `speed = speed * h` marqué *« only temporary and relative »*, avec
`MakeRatio` (`:1053`) qui accepte les **rationnels** `g/h`. C'est une dilatation de
**portée locale**, temporaire, distincte des deux variables `speed`/`scale`. `BP3_help.txt:526`
l'appelle « dilation ratio ». À ne pas ranger avec les opérateurs de vitesse.

## 6. Combien de mécanismes distincts derrière le mot « tempo » ?

Réponse à l'intention de Romain — **trois familles**, à ne pas confondre :

1. **`speed`** — vitesse, pilotée par `/N` (÷ absolu = N) et `\N` (= 1/N) ;
2. **`scale`** — échelle, pilotée par `*N` (= N) et `**N` (= 1/N) ;
   le tempo effectif = `speed / scale`.
3. **`{N,...}`** — ratio de dilatation structurel, local, temporaire, rationnel ; PAS
   une des deux variables ci-dessus.

Et deux « faux amis » à écarter absolument :
- **`_tempo(x)`** (contrôle de performance) — MULTIPLIE le tempo, se combine en
  polymétrie ; Bernard écrit qu'il **n'est pas** l'équivalent strict de `/x`
  (`BP3_help.txt:1650`). Axe différent des marqueurs `/ \ * **`.
- **`_scale(name,blockkey)`** (`BP3_help.txt:497`) — sélection d'une **gamme
  microtonale** (tonalité). Aucun rapport avec la variable interne `scale` du tempo,
  malgré le nom identique. Piège de vocabulaire.

## 7. Lacune de documentation

`BP3_help.txt` documente `/N` (marqueur de tempo, déclaré obsolète `:1096-1101`,
`:1650`) et le remplace par `_tempo(x)`. Mais :
- **`\N`, `*N`, `**N` ne sont définis nulle part** comme opérateurs de vitesse/échelle ;
- la **normalisation en sortie** (`*scale/speed`, injection de `*1` aux frontières de
  bloc) n'est écrite nulle part — un utilisateur qui lit `*1/4` en sortie n'a aucun moyen
  de savoir que ce sont deux marqueurs et non une fraction ;
- le double sens du mot **`scale`** (variable de tempo vs gamme microtonale `_scale()`)
  n'est signalé nulle part.

Même nature que la lacune #60 (voir [`contexte-negatif.md`](contexte-negatif.md) §6 et
[`marqueurs-structurels.md`](marqueurs-structurels.md)). Candidat à remonter à Bernard Bel.
