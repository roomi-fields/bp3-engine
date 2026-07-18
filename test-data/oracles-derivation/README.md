# Oracles natifs « dérivation » — single / produce-all

Générés par `bp3` natif v3.4.4 pour permettre une comparaison **like-with-like au niveau
dérivation** avec BPx, et non plus au niveau production répétée.

**Pourquoi** : les oracles `s3_native` existants sont capturés avec `-o` et un réglage
« Max items produced » élevé — ils contiennent donc le **même item répété N fois**
(checkBT : 4 jetons × 20 = 80). Cela mesure la production, pas la dérivation.
Demande architecte [63], suite au constat de bp3-frontend [2668].

## Contenu

Un fichier par grammaire et par mode : `<grammaire>.<mode>.json`.

| champ | sens |
|---|---|
| `mode` | `single` = 1 item (`Max items produced` forcé à 1) · `produce-all` = énumération exhaustive |
| `config` | réglages / alphabet / objets sonores / graine réellement passés |
| `items` | production texte, **un item par entrée** — c'est l'artefact de dérivation |
| `tokens` | jetons minutés `[nom, début_ms, fin_ms]`, quand le moteur en émet |

La `config` suit le bloc `php_ref` de `BPscript/test/grammars/grammars.json` (autorité),
pas les dépendances déclarées en tête de grammaire.

## Résultats

| grammaire | single | produce-all |
|---|---|---|
| `checkBT` | 1 item — `a' a' c' b` | 1 item (grammaire déterministe) |
| `checkSUB1` | 1 item — `i j` | **0 item — impossible par conception** |
| `destru` (`-gr.tryDESTRU`) | 1 item, 44 jetons minutés | 2 items |

## Deux limites à connaître avant de comparer

1. **`checkSUB1` n'a pas d'oracle `produce-all`, et ne peut pas en avoir.** Le moteur refuse
   explicitement l'énumération exhaustive sur une sous-grammaire `SUB` / `SUB1` / `POSLONG` :
   « Can't produce all items in 'SUB' or 'SUB1' or 'POSLONG' subgrammar »
   (`csrc/bp3/ProduceItems.c:770`). Ce n'est ni un bug ni un oracle manquant — comparer
   cette grammaire en mode `single` uniquement.

2. **`--tokensout` n'émet pas en mode `produce-all`.** Même configuration, `destru` donne
   44 jetons minutés en `single` et 0 en `produce-all` (le sérialiseur est appelé depuis
   `PlayBuffer1`, hors du chemin d'énumération). Les oracles `produce-all` se comparent donc
   sur `items` (texte), pas sur `tokens`.

## Regénérer

`scratchpad/genoracle.py` de la session, ou reproduire à la main :

```
bp3 produce     -e -gr <grammaire nettoyée> --seed 1 -se <réglages, MaxItemsProduce=1> \
                -al <alphabet> [-so <objets>] -o <sortie> --tokensout <jetons>
bp3 produce-all -e -gr <grammaire nettoyée> --seed 1 -se <réglages> \
                -al <alphabet> [-so <objets>] -o <sortie>
```

« Grammaire nettoyée » = lignes `INIT:` retirées et en-tête BP2 éventuel coupé, comme le fait
`s0_snapshot.cjs:186-193`.
