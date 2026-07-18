# Audit des oracles `s1_native` — provenance et fiabilité

Demande architecte [71], après la trace `asymmetric1` [69]. Établi le 2026-07-18 par `bp3-engine`.
**Aucun oracle n'a été re-capturé** (interdit tant que #48-#52 sont ouverts) : vérification et
provenance seulement.

## Verdict : l'écart `asymmetric1` n'est PAS isolé, il est SYSTÉMATIQUE

**13 des 76 oracles `s1_native` (17 %) commencent par un mot de message console**, pas par un
symbole de production. Ils ont capturé la sortie de diagnostic du moteur comme s'il s'agissait
de jetons.

| oracle | ce que contient son début |
|---|---|
| `asymmetric1` | `Only 10 items will be produced.` puis `b b a b a a` |
| `gramgene1` | `Only 10 items will be produced.` puis `'-ho.abc' ; 'RND'` |
| `dhin1` | `Variable must start with uppercase character or '\|'. Can't…` — **message d'erreur de compilation** |
| `csound` | `??? gram#1[1] <1-1> S --> _ins(3)` — **message d'erreur** |
| `checkNegativeContext` | `S [Step #1] Selected: gram#1[1] <127:127>` — **sortie de trace** |
| `checkVolChan` | `>>> Script aborted on: Wait for` |
| `tryConsoleMaxTime` | `=> Calculation overflow (10000 derivations): task` |
| `dhin` | `Using quantization = ms compression rate` |
| `vina3` | `Loading tonality: /mnt/d/Claude/bp3-engine/test-data/-to.Vina` |
| `tryObjects`, `blurb`, `dhati2`, `dhati3` | idem, tête polluée |

Un oracle qui commence par un message d'erreur de compilation (`dhin1`, `csound`) n'est pas un
oracle affaibli : c'est l'enregistrement d'un **échec**, pris pour une référence.

## Cause : le filtre de diagnostic est incomplet

`BPscript/test/s1_native.cjs`, constante `DIAG_RE`. Testé ligne à ligne :

| ligne du moteur | filtrée ? |
|---|---|
| `Only 10 items will be produced.` | **non** — le motif est `items? (have\|has) been produced`, il ne couvre pas `will be produced` |
| `Variable must start with uppercase character or '\|'.` | **non** — aucun motif ne la couvre |
| `Csound tables{a h` | oui |
| `=> Problem compiling` | oui |

Deux trous, donc, et ils expliquent les 13 cas.

## Provenance

- Dates de capture : **64 en 2026-04**, 11 en 2026-06, 1 en 2026-07.
- `vina3` contient un chemin **`/mnt/d/Claude/…`** : capturé sur la machine d'**avant** la
  migration PC2 du 2026-06-14. Marqueur matériel, pas une interprétation.

## `asymmetric1` : la comparaison S0 demandée est impossible

L'idée était : si l'oracle S0 (config forcée par `php_ref`, déterministe) matche le
`a b a a b b` du binaire, alors S0 est fiable et `s1_native` était mal configuré.

**`asymmetric1` n'a pas d'oracle S0.** Son dossier `snapshots/` ne contient que `s1_native.json`
et `s2_orig.json`. Sur les 76 grammaires, 70 ont un `s0_php.json` — pas celle-là.
La question ne peut donc pas être tranchée par S0 pour cette grammaire.

Ce qui EST établi : le binaire natif courant produit `a b a a b b` de façon déterministe à
`--seed 1`, avec une chronologie de tirages `b, b, a, a, b, a` et 325 appels `bp3_rand`
(cf. `docs-developer/traces/asymmetric1-seed1-rand.txt`). L'oracle `s1_native` d'`asymmetric1`
étant pollué en tête, son alignement est douteux et il ne peut pas servir à juger BPx.

## Filet de sécurité : 8 des 13 n'ont aucun oracle S0 de secours

| avec S0 de secours (5) | sans aucun secours (8) |
|---|---|
| `dhati2`, `dhati3`, `dhin1`, `gramgene1`, `tryObjects` | `asymmetric1`, `blurb`, `checkNegativeContext`, `checkVolChan`, `csound`, `dhin`, `tryConsoleMaxTime`, `vina3` |

## Ce qui reste à faire, et par qui

1. **bpscript** — compléter `DIAG_RE` (les deux trous ci-dessus). C'est leur fichier.
2. **Ne pas re-capturer** tant que #48-#52 sont ouverts. Les 13 oracles doivent être
   **marqués non fiables**, pas écrasés.
3. Les 8 sans secours sont à traiter comme **sans référence**, au même titre que les
   grammaires « native-broken » : aucun verdict de conformité ne peut s'appuyer dessus.

## Limite de cet audit

J'ai aussi lancé une comparaison oracle-vs-binaire sur les 38 oracles en mode texte. Je n'en
publie pas le décompte : mon extracteur ne prenait que la **première ligne** de production,
alors que les oracles couvrent plusieurs lignes, ce qui produit de faux « différents »
(`all-items`, `templates`, `checktemplates`, `tryAllItems*`…). Les 13 cas ci-dessus, eux, sont
établis sur un critère non ambigu — le premier jeton est un mot de message — et ne dépendent
pas de cette comparaison.
