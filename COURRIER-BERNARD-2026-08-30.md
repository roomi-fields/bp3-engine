# Courrier à Bernard Bel — écrit le 2026-08-30, **non envoyé**

État : **rédigé, remis à Romain qui l'envoie lui-même.** Décision de Romain du 2026-08-30 :
« il écrit un mail que moi j'envoie, je veux le lire ».

Rédigé en français sur son arbitrage du 2026-08-14.

Trois défauts y figurent. Ce qui a été écarté, et pourquoi, est en fin de fichier — sous le texte,
pour que le courrier se lise seul.

---

> Objet : BP3 3.5.1 — trois observations en ligne de commande sous Linux
>
> Bonjour Bernard,
>
> En construisant un corpus de référence pour le moteur en ligne de commande sous Linux, nous
> sommes tombés sur trois comportements dont nous nous sommes dit qu'ils vous intéresseraient.
> Chacun se reproduit avec une grammaire de quelques lignes, sans dépendance.
>
> **Version** — `Bol Processor console app, Version 3.5.1`, construite sous Linux avec
> `gcc -O2 -g -fno-common`, liée avec `-lm -lasound -lcurl`. Notre arbre porte quelques
> modifications locales, et nous avons vérifié fichier par fichier que **les zones en cause n'en
> portent aucune qui compte en natif** :
>
> - observation 1 — `CompileProcs.c` : notre seul écart avec l'étiquette `v3.5.1` est le retrait
>   d'un bloc `#ifdef __BP3_WASM__`, jamais compilé en natif ;
> - observation 2 — `DisplayArg.c`, qui porte `PrintArg`, est **identique** à l'étiquette ;
>   `ProduceItems.c` ne diffère que par un `#ifdef __BP3_WASM__` retiré ;
> - observation 3 — mêmes fichiers que la première.
>
> ---
>
> ## 1. `_stepOn` et `_stepOff` sont déclarés mais aucune règle qui les contient ne compile
>
> `_stepOn` et `_stepOff` sont des procédures déclarées — traitées en cas 7 et 8 de
> `CompileProcs.c`, de `CompileGrammar.c` et d'`Encode.c`, et nommées dans le message « Using
> tool(s) » de `CompileGrammar.c`. Pourtant toute règle qui les emploie est refusée, à n'importe
> quelle position — préfixe de l'argument gauche, début ou fin de l'argument droit.
>
> **Cas minimal**
>
> ```
> ORD
> gram#1[1] S --> A B
> gram#1[2] A --> _stepOn B B
> ```
>
> ```
> bp3 produce -e -gr <cette grammaire> --seed 1 -o /tmp/out.txt
> ```
>
> Sortie :
>
> ```
> => '_step' should not appear in the left argument of a rule
> Error code 15: argument syntax in gram#1 rule 2
> ```
>
> Même refus avec `_stepOff`.
>
> **Témoin** — la même grammaire avec `_traceOn` puis `_printOn` compile sans une erreur. Ces
> deux-là ne sont préfixés par aucun contrôle de performance.
>
> **Où nous avons cherché** — `GetPerformanceControl`, dans `CompileProcs.c`. Le scanner compare
> chaque nom de contrôle par préfixe et retient le plus long qui s'apparie, sans vérifier que le
> caractère suivant clôt l'identifiant. Le contrôle `_step` est un préfixe exact de `_stepOn` et
> de `_stepOff` ; il est reconnu d'abord, le compilateur réclame alors son argument entre
> parenthèses, et échoue. Comme `GetPerformanceControl` est consulté avant `GetProcedure` dans ce
> contexte, les deux procédures sont inatteignables.
>
> Une garde de frontière — refuser l'appariement si le caractère qui suit `_step` est encore
> alphanumérique — les rendrait accessibles.
>
> ---
>
> ## 2. L'écriture de l'item dans un fichier (`-o`) tombe à partir de dix-sept groupes
> polymétriques imbriqués
>
> **Cas minimal**, sans aucune dépendance — ni drapeau, ni alphabet, ni motif de temps :
>
> ```
> gram#1[1] S --> {A4 {A4 {A4 {A4 {A4 {A4 {A4 {A4 {A4 {A4 {A4 {A4 {A4 {A4 {A4 {A4 {A4 A4}}}}}}}}}}}}}}}}}
> ```
>
> ```
> bp3 produce -gr <cette grammaire> -o /tmp/out.txt --seed 1
> ```
>
> **Seuil exact, mesuré** :
>
> | niveaux d'imbrication | code de sortie | fichier écrit |
> | --- | --- | --- |
> | 16 | 0 | 68 octets |
> | 17 | signal 11 | 0 octet |
> | 18 | signal 11 | 0 octet |
> | 50 | signal 11 | 0 octet |
>
> **Ce qui discrimine** — sur le même item à cinquante niveaux, `produce -D` (affichage terminal)
> et `compile` rendent tous deux 0. Seule l'écriture `-o` tombe. Le chemin en cause est donc la
> sérialisation vers un fichier, ni la dérivation ni le compilateur — la signature d'un imprimeur
> récursif dont la pile suit la profondeur d'imbrication.
>
> ---
>
> ## 3. `SUB` produit moins que `SUB1`, alors que l'aide décrit l'inverse
>
> `BP3_help.txt`, section « SUB [Subgrammar type] » :
>
> > A substitution is the simultaneous application of all candidate rules in the "subgrammar"
> > **until no rule is candidate**.
>
> et section « SUB1 [Subgrammar type] » :
>
> > **Similar to SUB, but substitutions are performed only once.**
>
> **Cas minimal** — une seule sous-grammaire, aucun alphabet, aucun fichier annexe : les
> terminaux sont des notes, qui ne passent pas par l'alphabet. Seul le type de la première ligne
> change d'une exécution à l'autre.
>
> ```
> <TYPE>
> gram#1[1] S --> C4 X
> gram#1[2] X --> D4 Y
> gram#1[3] Y --> E4
> ```
>
> ```
> bp3 produce -e -gr <cette grammaire> --seed 1 -o /tmp/out.txt
> ```
>
> | type | sortie |
> | --- | --- |
> | `ORD` | `C4 D4 E4` |
> | `SUB1` | `C4 D4 E4` |
> | `SUB` | `C4 X` |
>
> Sous `SUB`, la production s'arrête après la **première** règle : `X` reste dans la chaîne alors
> qu'une règle le prend pour argument gauche. Sous `SUB1` — décrit comme « SUB, mais une seule
> fois » — les trois règles s'appliquent. Les deux comportements semblent échangés par rapport au
> texte de l'aide.
>
> `ORD` sert de témoin : il rend bien la forme complètement dérivée, donc la grammaire n'est pas
> muette et la comparaison porte. La même observation se reproduit sur une grammaire à deux
> règles et sur des terminaux de silence (`-`), qui existent dans toute portée.
>
> Nous ne savons pas lequel des deux — le code ou l'aide — porte l'intention d'origine, et nous
> n'avons pas localisé la cause dans les sources. Nous vous rendons l'écart.
>
> ---
>
> ## Une observation annexe, sur laquelle nous ne demandons rien
>
> Avec `--traceout`, `CreateImageFile` (`ConsoleMain.c`) crée le fichier image, puis cherche le
> gabarit `CANVAS_header.txt` dans un dossier `php` relatif au répertoire de travail. Quand le
> gabarit manque, la fonction referme le fichier et éteint le dessin — proprement — mais **le
> fichier image reste sur le disque à zéro octet, et aucun message ne le signale** : la ligne qui
> l'annonçait est commentée.
>
> Nous n'avons trouvé `CANVAS_header.txt` **nulle part** : cherché par son nom sur la totalité de
> l'arbre de cinq branches amont — `master`, `BP3-develop`, `graphics-for-BP3`,
> `CoreMIDI-for-BP3`, `untested-BP2-changes` — et des cinq étiquettes `v3.4.5` à `v3.5.1`, soit
> des arbres de 114 à 645 fichiers. Zéro occurrence partout.
>
> S'il vient de la distribution web plutôt que du dépôt du moteur, alors l'application en ligne
> de commande ne peut pas produire d'image par elle-même, et rien dans sa sortie ne le dit.
>
> ---
>
> Avec nos remerciements pour le moteur,

---

## Ce qui a été écarté du courrier, et pourquoi

**Le plantage sur `--traceout` — il est à nous, pas à lui.** Notre binaire rend le signal 11 sur
`-gr.765432` avec `--traceout`. Mesuré au source, contre notre propre étiquette :

| | `imagePtr == NULL` dans `Graphic.c` |
| --- | --- |
| `v3.5.1` (l'étiquette) | 5 |
| `upstream/graphics-for-BP3` | 5 |
| notre branche `wasm` | **0** |

Et dans `CreateImageFile`, l'amont éteint le dessin et sort à chaque échec — `imagePtr = NULL;
ShowGraphic = FALSE; return;` — en trois points où notre arbre a retiré les deux dernières
instructions. Le gabarit manquant laisse donc le dessin armé chez nous, et l'écriture suivante
déréférence un pointeur nul.

C'est une **régression de notre arbre contre notre propre étiquette**, déjà inscrite à
`docs-developer/inventaire-des-deltas.md`. Écrire à Bernard qu'un binaire tombe reviendrait à lui
décrire un comportement que le sien n'a pas.

**Un quatrième défaut ne s'y trouve pas non plus : je n'ai pas su le rejouer aujourd'hui.** Le
constat #61 — une règle portant une opération de drapeau annoncée `Selected:` alors que son
argument gauche ne s'apparie nulle part. Ma sonde du 2026-08-30 est **muette** : son témoin
positif, une règle à drapeaux dont l'argument gauche est bien présent, n'a pas produit non plus.
Trois lignes identiques ne mesurent rien. Un constat ne part à Bernard qu'avec un cas minimal et
solide ; celui-ci attend d'être remesuré.
