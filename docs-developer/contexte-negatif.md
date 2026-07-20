# Le contexte négatif `#` — sens, appariement, et pourquoi une règle peut tourner à vide

Établi le 2026-07-20 par `bp3-engine`, sur `csrc/bp3/` et le moteur natif v3.4.7,
en réponse à la demande [163] (Romain bloqué sur `-gr.checkNegativeContext`).

**Axe des mesures ci-dessous : la chaîne de travail (sortie texte de `--trace-production`).**
Aucune mesure MIDI ici — les grammaires de test ne produisent pas de son.

## 1. Ce que signifie `#X`

`#X` occupe **une position** dans le motif et y **capture** le symbole réellement présent,
sous une condition de négation. Ce n'est pas un test sans consommation.

- À la compilation, `#` lève un drapeau de négation (`Encode.c:991-993`) et reste écrit
  comme jeton dans la règle.
- À l'appariement (`Compute.c:1617-1625`) : le moteur avance d'une position, refuse `#?`,
  note `nefound` si le symbole trouvé **diffère** de celui nommé, et **mémorise le symbole
  réellement présent** dans `instan[]`.
- Côté droit, `#` est un **joker** rempli depuis `instan[]` dans l'ordre
  (`Compute.c:2001-2006`). C'est ce qui permet de **réordonner** les symboles capturés.

**Preuve que `#` consomme bien une position.** Sur la chaîne d'un seul symbole `A` :

| règle | résultat |
| --- | --- |
| `#X A --> Q` | ne s'applique pas (production arrêtée) |
| `A --> Q` (témoin) | s'applique, donne `Q` |

## 2. La négation est DISJONCTIVE — le point le plus contre-intuitif

`Compute.c:1746` : `result = (!nexist || nefound);`

S'il y a au moins un `#` dans le motif, il suffit qu'**un seul** d'entre eux soit mis en
défaut pour que l'appariement réussisse. Le commentaire de fin de fonction le dit
(`Compute.c:1764`) : *« OK if there was no negative context or at least it was defeated
once »*.

Donc `#A1 #A2 #A3 A A` **ne signifie pas** « pas A1 **et** pas A2 **et** pas A3 ». Il
signifie « il est faux que les trois soient simultanément A1, A2, A3 aux trois positions ».
La négation porte sur la **conjonction**, pas sur chaque terme.

## 3. Comment lire la règle 2 de `-gr.checkNegativeContext`

```
/times > 0/  #A1 #A2 #A3 A A  -->  #A1 #A2 A A #A3  /times-1/
```

Motif de **cinq** positions : trois captures libres, puis deux `A` littéraux. Le côté droit
réémet les trois captures avec **la troisième déplacée à la fin** — d'où le glissement des
symboles non-`A` vers la droite, une position par étape.

Le `#` ne « se déplace » pas d'un côté à l'autre : à gauche il **capture**, à droite il
**restitue**. Les trois `#` de droite consomment `instan[]` dans l'ordre, et l'ordre
d'écriture est ce qui produit la permutation.

## 3 bis. Le pas #1 expliqué symbole par symbole — et la coïncidence de noms

```
avant :  A   A2  A3  A1  A  A
après :  A   A2  A3  A   A  A1
```

La fenêtre couvre les positions **2 à 6**, ce qui n'est pas une déduction : la sonde
`--> ZZZ` du §4 donne `A ZZZ`, donc la position 1 survit et les cinq suivantes sont
consommées.

| élément de la règle | apparié à | capture | négation |
| --- | --- | --- | --- |
| `#A1` | position 2 = `A2` | capture 1 = `A2` | `A2` ≠ `A1` → mise en défaut |
| `#A2` | position 3 = `A3` | capture 2 = `A3` | `A3` ≠ `A2` → mise en défaut |
| `#A3` | position 4 = `A1` | capture 3 = `A1` | `A1` ≠ `A3` → mise en défaut |
| `A` | position 5 = `A` | — | littéral |
| `A` | position 6 = `A` | — | littéral |

Côté droit, `#A1 #A2 A A #A3` réémet **capture 1, capture 2, `A`, `A`, capture 3** =
`A2 A3 A A A1`. Avec la position 1 conservée : `A A2 A3 A A A1`. C'est la trace.

**Le nom écrit dans `#Xn` ne désigne pas le symbole apparié.** Il ne sert qu'au test de
négation. Le symbole qui « se déplace » est celui qui occupait la **troisième fente**, parce
que la troisième capture est **écrite en dernier** à droite. Qu'il s'appelle `A1` est une
**coïncidence**, et c'est elle qui rend la règle illisible.

**Preuve : on casse la coïncidence.** Même règle, chaîne sans aucun `A1`/`A2`/`A3` :

| chaîne | résultat |
| --- | --- |
| `A P Q R A A` | `A P Q A A R` — puis `A P A A Q R` |

Aucun nom ne correspond, la règle s'applique quand même, et c'est la **troisième capture**
(`R`) qui part à la fin. L'appariement est **positionnel**, pas nominal.

**Les noms ne sont pas décoratifs pour autant** — ils portent la garde, et elle rejette :

| chaîne | les trois captures | résultat |
| --- | --- | --- |
| `A A1 A2 A3 A A` | égales à leurs noms | **aucun appariement** |
| `A P A2 A3 A A` | une seule diffère | `A ZZZ` — apparié |

Ces deux lignes prouvent à la fois que la garde mord et qu'elle est **disjonctive** (§2) :
une seule mise en défaut suffit.

## 4. Pourquoi la chaîne cesse de changer aux étapes 4 et 5

**Réponse : `A A A A2 A3 A1` est un point fixe — le motif ne s'y apparie plus nulle part.**
Le motif exige deux `A` littéraux aux positions 4-5 de sa fenêtre ; dans cette chaîne, les
seules paires `A A` adjacentes sont en tête, trop à gauche pour tomber en position 4-5.

**Preuve, avec un côté droit reconnaissable** (`#A1 #A2 #A3 A A --> ZZZ`) :

| chaîne de départ | résultat |
| --- | --- |
| `A A A A2 A3 A1` | jamais de `ZZZ` — aucun appariement |
| `A A2 A3 A1 A A` | `A ZZZ` — apparié à coup sûr |

**Pourquoi cette précaution était nécessaire.** Une chaîne inchangée ne prouve **pas** un
point fixe : en mode `RND` la position est tirée au hasard (`BP3_help.txt:300-302`), et un
tirage malheureux donne une étape sans effet. Mesuré sur `A2 A3 A1 A A A` : inchangée aux
étapes 1, 2, 3 — puis **modifiée aux étapes 4 et 5, sur la même chaîne**. Les deux causes
d'immobilité se ressemblent et se distinguent seulement par une sonde.

Confirmation complémentaire : `A A A A2 A3 A1` reste identique sur **20 graines**.

## 5. Anomalie : une règle est « sélectionnée » alors que son argument gauche est absent

`BP3_help.txt:308` définit les règles éligibles comme celles **« whose left argument is
found in the work string »**. Aux étapes 4 et 5, la règle est pourtant annoncée
`Selected:` et son compteur décroît, alors que le §4 prouve que son argument gauche ne
s'apparie nulle part.

**Comparaison contrôlée, même chaîne de départ `A A A A2 A3 A1`, deux grammaires :**

| règle | comportement observé |
| --- | --- |
| `#A1 #A2 #A3 A A --> ZZZ` (sans drapeau) | production **arrêtée** immédiatement — conforme |
| `/times>0/ … --> … /times-1/` (avec drapeaux) | **sélectionnée 5 fois**, compteur décrémenté, chaîne jamais modifiée |

La différence est la présence des drapeaux. Deux témoins montrent que le test d'éligibilité
fonctionne par ailleurs : une règle `ZZZ --> QQQ /times-1/` dont le symbole est absent
n'est **pas** sélectionnée, et `#A1 A A --> …` non plus quand le littéral `A A` manque.

Ce qui est **certain** : les étapes 4 et 5 sont des passages à vide, le compteur descend et
rien n'est réécrit. C'est la réponse à la question posée.

Ce qui **reste à trancher par l'amont** : le fait qu'une règle portant une opération de
drapeau soit sélectionnée et voie son compteur décrémenté sans que son argument gauche
s'apparie est-il voulu, ou l'éligibilité est-elle évaluée avant l'appariement dans ce cas ?
Je n'ai pas trouvé de source qui le définisse. **Question pour Bernard Bel.**

## 6. Lacune de documentation

`BP3_help.txt` ne définit **ni `#`, ni `(=`, ni `(:`** — vérifié par recherche. Les seules
lignes voisines (`:97-99`) listent les glyphes `+ : ; =` comme « structural markers » sans
leur donner de sens, et ne mentionnent pas `#`.

Ce sont des mécanismes **centraux** : `#` est présent dans les grammaires de test, et le
marqueur après parenthèse ouvrante est **obligatoire**, avec un message d'erreur dédié
(`Encode.c:1659`). Un utilisateur qui écrit `( A )` se voit refuser sa grammaire par un
message qui exige un marqueur dont le sens n'est écrit nulle part.

Voir aussi [`marqueurs-structurels.md`](marqueurs-structurels.md) pour `=` et `:`.

## 7. La correspondance annoncée avec BPScript ne tient pas

**Axe : moteur BP3 natif v3.4.7, chaîne de travail.** Je n'ai pas mesuré BPScript ; ce qui
suit porte sur ce que fait BP3, confronté à ce que leur spécification annonce.

`BPscript/docs/EBNF.md:1256` donne la correspondance `#X -> #X, identique`, et
`LANGUAGE.md` (section « Contextes `()` et `#` ») définit le contexte négatif comme une
**garde** : `#(X Y) Z -> W` signifie « `Z` **non précédé** de `X Y` ». Une garde ne consomme
rien et ne se réécrit pas.

**En BP3, ce n'est pas ce que fait `#`** — mesuré aux §1 et §3 bis :

| | garde (spéc. BPScript) | `#` en BP3 (mesuré) |
| --- | --- | --- |
| consomme une position | non | **oui** (§1) |
| capture le symbole présent | non | **oui**, dans `instan[]` |
| apparaît à droite | non | **oui**, comme joker |
| peut réordonner la chaîne | non | **oui** (§3 bis) |

Les deux mécanismes partagent la notation et l'idée de négation, mais pas la sémantique :
en BP3 le contexte négatif **fait partie de ce qui est réécrit**. La correspondance « `#X` →
`#X`, identique » est donc trop forte — à vérifier côté BPScript, qui seul peut mesurer le
sien.
