# `tryShruti` — pourquoi elle ne compile pas, et pourquoi ce n'est pas « une gamme incomplète »

Établi le 2026-07-18 par `bp3-engine`, sur le binaire `./bp3` v3.4.4, en réponse à
l'information de `bpscript` (« `-to.tryShruti` porte la gamme grama complète, 23 ratios »).

## Je corrige mon propre diagnostic

J'avais rangé `tryShruti` et `scales` dans le lot **M1** avec pour motif *« terminaux
microtonaux inconnus, la gamme est incomplète »*. **C'est faux sur le motif.** Les 23 degrés
de la gamme grama sont bien présents dans `-to.tryShruti`, avec leurs 23 rapports. `bpscript`
avait raison de le signaler.

La vraie situation est différente, et plus précise. Voici ce qui est **prouvé**, et ce qui
**reste inexpliqué** — la distinction compte, je ne comble pas le reste par une hypothèse.

## Ce qui est prouvé

### 1. Les deux fichiers de ressources de `tryShruti` ne sont pas des fichiers BP3

Un fichier de tonalité BP3 authentique (`-to.raga`, `-to.tryOneScale`) commence par
`// Bol Processor BP3` et contient une **ligne de numéros de touches** `k0 1 2 … k`.
`-to.tryShruti` n'a **ni l'un ni l'autre** : il commence directement par `_begin tables`.

`-cs.tryShruti` est dans le même cas, et son en-tête l'avoue :

```
; Csound resources for tryShruti
; Minimal file - no instruments, just scale tables
```

Ce n'est pas un fichier de ressources Csound BP3 : il n'a pas l'en-tête de version, donc
`CheckVersion()` échoue (`csrc/bp3/SaveLoads1.c:163`) et le chargement s'arrête sur
`=> Error reading Csound instruments file`. C'est **le premier message bloquant** que
rapporte la baseline pour cette grammaire.

Accessoirement, sa table ne liste que **22 degrés** contre **23** dans la tonalité — il y
manque `n4_`. Les deux fichiers ne sont donc même pas d'accord entre eux.

### 2. L'absence de la ligne `k` casse réellement la carte des touches — et je l'ai réparée

Le lecteur de tonalité lit cette ligne en `csrc/bp3/SaveLoads1.c:98-101` ; sans elle,
`key_numbers` reste vide. Effet observé en activant la trace de microtonalité :

| | carte obtenue |
|---|---|
| fichier tel quel | trou : la touche #12 n'a **aucun nom**, la gamme ne couvre qu'une partie du clavier |
| avec la ligne `k` ajoutée | carte pleine 0→127, `sa_` sur la touche **60** (= la touche de base déclarée) |

La réparation fonctionne donc, et elle est vérifiable en une commande. **Mais elle ne suffit
pas** — voir plus bas.

### 3. Les noms de degrés d'une gamme *sont* des terminaux légaux — le mécanisme n'est pas en cause

Contre-exemple décisif : `-to.tryOneScale` définit les degrés `Cj Cj# Dj …`, qui n'appartiennent
à aucune convention de notes. Une règle qui les emploie compile **sans erreur** :

```
gram#1[1] <0> S --> _scale(just intonation,Cj4) Cj4 Aj4 Gj4     →  Errors: 0
```

Donc le moteur sait résoudre un nom de degré venu d'un fichier de tonalité. Ce n'est ni un
bug général de résolution de gamme, ni une limite du langage.

### 4. Le tiret bas final n'est pas la cause

Les degrés de grama se terminent tous par `_` (`sa_`, `r1_`, `m3p1_`), et `_` est le symbole
de silence en BP — soupçon légitime. **Écarté** : en renommant les degrés `sa_` → `saz` dans
la tonalité *et* dans la grammaire, l'erreur est identique (`Can't make sense of "saz4"`).

## Ce qui reste inexpliqué — et que je ne devine pas

Même avec l'en-tête BP3 **et** la ligne `k` ajoutés, la grammaire **ne compile toujours pas** :

```
Variable must start with uppercase character or '|'. Can't make sense of "sa_4".
Error code 15: argument syntax in gram#1 rule 2
```

Il reste donc une cause que je n'ai pas isolée. Deux suspects, à instruire, **non tranchés** :

1. **23 degrés par octave contre 12 touches par octave.** Toutes les gammes qui fonctionnent
   dans le corpus ont 12 degrés, alignés sur les 12 touches. Le suffixe d'octave (`_4` dans
   `sa_4`) se dérive du numéro de touche ; avec 23 degrés par octave, la correspondance
   nom → touche → octave n'est plus celle que le compilateur attend. C'est mon hypothèse
   principale, **non vérifiée**.
2. **La notation des rapports et de la ligne `f`.** `-to.tryShruti` écrit `[ 1/1 256/243 … ]`
   avec des barres de fraction et `f 1 0 51 23 …`, là où les fichiers authentiques écrivent
   `[1 1 256 243 …]` en paires d'entiers et `f2 0 128 -51 12 …`. Le compte d'arguments tombe
   juste par coïncidence ; rien ne dit que le reste est interprété comme voulu.

## Conséquence pour le backlog

**M1 doit changer de libellé.** Le motif « nom de terminal vide sur gamme invalide » décrit un
symptôme, pas la cause. Ce qui est établi :

- `tryShruti` est bloquée d'abord par **deux fichiers de ressources non conformes**, écrits à
  la main et jamais produits par BP3 — c'est un **défaut de corpus**, réparable en données.
- Une fois ces fichiers réparés, il **subsiste** un refus de compilation sur les degrés, dont
  la cause n'est pas établie. C'est cette part-là, et elle seule, qui peut relever du moteur.

Tant que le point 1 ci-dessus n'est pas tranché, il n'y a **pas** matière à un bug moteur
remonté à Bernard Bel : je ne remonte pas un symptôme dont je n'ai pas isolé la cause.

## Reproduire

```sh
# le fichier tel quel : trou dans la carte des touches
./bp3 produce -e -gr <grammaire nettoyée> --seed 1 --indian \
     -se test-data/-se.tryShruti -to test-data/-to.tryShruti -o /tmp/out
# (mettre TraceMicrotonality à 1 dans une copie des réglages pour voir la carte)
```

La comparaison qui tranche est `-to.tryOneScale` (12 degrés, en-tête, ligne `k`) contre
`-to.tryShruti` (23 degrés, ni en-tête ni ligne `k`).
