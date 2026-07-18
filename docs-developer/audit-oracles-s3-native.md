# Audit de la baseline `s3_native` (55 oracles)

Demande architecte [78] : `s1_native` avait été audité, mais la baseline **autoritaire du
frontal** est `s3_native`, et elle ne l'avait jamais été.
**Aucun oracle re-capturé** (interdit tant que #48-#52 sont ouverts) — vérifié après coup :
`find -newermt` sur les 55 `s3_native.json` = **0 fichier modifié**.

## Le lot n'est pas homogène : deux populations, un seul vérificateur

| | n | champ `source` | vérifiée par `s3_native.cjs` ? |
|---|---|---|---|
| mode `midi` | **33** | `native --tokensout (bp3 Linux)` | **oui** |
| mode `text` | **22** | `native -o (bp3 Linux, production canonique)` | **non — le script les saute** |

`s3_native.cjs` ne traite que le MIDI : ses sélecteurs `--all` et `--campaign` filtrent sur
`production_mode === 'midi'`, et toute grammaire en mode texte sort en `SKIP (mode texte)`.
Les 22 oracles texte ont donc été produits par un **autre chemin de capture, non identifié**
(leur champ `source` diffère de celui qu'écrit `s3_native.cjs`).

**C'est le résultat principal : 22 des 55 oracles de la baseline autoritaire n'ont aucun
script qui sache les vérifier.** Ils ne peuvent ni être confirmés ni être invalidés par
l'outillage existant.

## Les 33 oracles MIDI : 32 reproductibles

Méthode : `s3_native.cjs` exécuté **tel quel** avec `--write`, `fs.writeFileSync` intercepté.
Le verdict n'est pas le mien, c'est celui de leur code — `writeNativeOracle()` renvoie
`inchangé — frais confirmé` quand les jetons calculés égalent l'oracle en place, et
`écrit (N tok)` sinon.

| verdict | n |
|---|---|
| `inchangé — frais confirmé` → **reproductible** | **32** |
| `SKIP (exclue/inconnue)` → `shapes-rhythm` | 1 |

Aucun oracle MIDI n'est ressorti divergent. Sur cette moitié du lot, la baseline est saine
vis-à-vis du binaire courant.

## Les 22 oracles texte : je ne publie pas de décompte

J'ai reproduit leur chemin de capture (`produce -o`, jetons séparés par espaces) avec la
configuration `php_ref`. Le résultat brut donnait 9 reproductibles, 9 divergents, 4 vides —
**je ne le publie pas comme un décompte**, parce que je l'ai invalidé moi-même :

> `dhati2` sortait « vide » (0 jeton contre 81 à l'oracle). Relancé sans le drapeau de
> convention de note `--indian` que `php_ref` impose : **80 jetons**. Un seul drapeau fait
> passer de 0 à 80.

La classification est donc dominée par l'incertitude sur la configuration de capture d'origine
— que je ne connais pas, puisque le script qui a produit ces 22 oracles n'est pas identifié.
Publier 9/9/4 laisserait croire à une mesure ; ce serait la même faute que celle déjà corrigée
deux fois dans cet audit.

Ce qui est **établi** sur ces 22 : elles sortent du périmètre de vérification de
`s3_native.cjs`, et leur provenance est inconnue.

## Provenance du lot

Dates de capture : **31 en 2026-06**, **24 en 2026-07**. La baseline `s3_native` est donc
nettement plus récente que `s1_native` (64 des 76 dataient de 2026-04) — c'est un point
favorable, elle a moins de risque d'être antérieure à une dérive du moteur.

## Ce qu'il faut décider

1. **Identifier le script qui a capturé les 22 oracles texte.** Sans lui, aucun décompte
   honnête n'est possible sur 40 % de la baseline autoritaire.
2. Une fois ce script connu, l'exécuter en mode intercepté comme ici — la méthode est
   rodée et ne réécrit rien.
3. `shapes-rhythm` est marquée « exclue/inconnue » par le script alors qu'elle a un oracle :
   à réconcilier.

## Comparaison avec `s1_native`

| | `s1_native` | `s3_native` |
|---|---|---|
| oracles | 76 | 55 |
| pollués par du texte de message | 13 | **0 détecté** |
| vérifiables par leur propre script | 68 | 33 |
| hors périmètre de vérification | 8 | 22 |
| dates dominantes | 2026-04 | 2026-06 / 2026-07 |

La baseline `s3_native` est en meilleur état que `s1_native` sur le critère de pollution
— aucun oracle ne commence par un message console. Son problème est ailleurs : **40 % du lot
n'est couvert par aucun vérificateur.**
