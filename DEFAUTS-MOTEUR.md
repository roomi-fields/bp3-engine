# Défauts du moteur natif BP3 — registre transverse

De quel moteur il s'agit : le **moteur natif de Bernard Bel** — `bp3` / `bp.exe` et son C
(`Compute.c`, `ProduceItems.c`, `Encode.c`), plus sa compilation WASM. Jamais BPx.

**Ce registre vit ici, bp3-engine en est responsable et le maintient, les autres viennent le
consulter ici.** Arbitrage de Romain du 2026-09-07.

> ## ⛔ IMPACT TOUS PROJETS
> **Toute validation contre les builds courants doit connaître #49, #50 et #52.** #48 est clos
> depuis le 2026-09-12, mesuré.
> Un banc qui les ignore attribue au moteur un échec qui vient d'eux.

Le **détail** de chaque entrée — reproduction, citations de code, réponses de Bernard Bel — vit
dans `hub/courrier/bp3-engine.md`, section « ▼ Registre Bernard Bel ». Ce document en est le
résumé transverse : une entrée par défaut, son état, et ce qu'il coûte à qui mesure.

Bernard Bel est mainteneur externe : les défauts lui parviennent hors de la tour, et **un constat
ne part à Bernard qu'avec un cas minimal et solide**.

---

## Ouverts

| # | ce qui casse | ouvert le |
| --- | --- | --- |
| 32 | dérive des contrôles continus | 2026-06-10 |
| 36 · 40 · 44 · 47 | gardes enfant contre drapeaux parent | 2026-06-10 |
| 49 | un terminal court masque les variables préfixées — `765432` injouable sur les builds courants. ⚠️ **NON REPRODUIT sur l'axe `produce` en v3.5.4** : voir la note ci-dessous | 2026-06-10 |
| **50** | `watch` environ deux fois plus lent : les suites tombent en dépassement de délai | 2026-06-10 |
| 51 | garde mono-item, `rc=-4`, y compris entre sous-grammaires | 2026-06-10 |
| **52** | régression look-and-say v3.4.2→v3.4.5 : « all weights are nil », zéro jeton. ⛔ **CONFIRMÉ TOUJOURS PRÉSENT en v3.5.4**, mesuré le 2026-09-12 | 2026-06-10 |
| 53 | le WASM applique l'homomorphisme autrement que le natif — mêmes 75 jetons, valeurs divergentes | 2026-07-17 |
| 54 | drapeaux et `_goto` co-localisés : appliqués en dérivation simple, sautés en énumération exhaustive. **Question ouverte à Bernard** : intentionnel, ou oubli d'ordre | 2026-07-18 |
| 56 | la limite de temps de calcul n'interrompt pas `cloches1`. Cause établie : la grammaire ne peut pas terminer, c'est un défaut de données — mais la limite existe pour reprendre la main, et elle ne le fait pas | 2026-07-19 |
| 58 | le mode « grammaire d'interprétation » est désactivé par une ligne commentée : `Jfunc` reste nul, tout ce qui en dépend est du code mort | 2026-07-19 |
| 60 | lacune de documentation : `#`, `(=` et `(:` ne sont définis nulle part. La règle disjonctive du contexte négatif n'existe que dans une ligne de code | 2026-07-20 |
| 61 | une règle portant une opération de drapeau est sélectionnée sans que son argument gauche s'apparie ; le compteur descend pour rien | 2026-07-20 |
| 63 | lacune de documentation : les opérateurs de vitesse, la normalisation en sortie, et le double sens de « scale » | 2026-07-25 |
| 64 | une valeur hors domaine de constante énumérée dégénère **en silence** — `Nature_of_time = 100` met toutes les durées à zéro, sans un mot. **Sept fichiers de réglages livrés en portent** | 2026-07-25 |
| 65 | le compilateur console rejette le vieux format BP2 (`V.2.5`) : 14 captures figées ne sont plus reproductibles. Et **aucune empreinte ne relie une capture à un binaire** | 2026-07-28 |
| 66 | l'en-tête de `-gr.12345678` sous-déclare sa dépendance aux prototypes d'objets sonores : la grammaire rend muette alors qu'elle démontre des objets sonores. Défaut de données | 2026-07-29 |
| 67 | la sortie dépend des sorties **demandées** : `--midiout` change le minutage de la liste d'événements, et `-o` réduit le nombre d'items qui l'atteignent | 2026-08-08 |
| 69 | `_stepOn` et `_stepOff` sont déclarés mais **inécrivables** : le contrôle `_step` les masque par appariement de préfixe glouton, sans garde de frontière | 2026-08-09 |
| 70 | erreur de segmentation à l'écriture `-o` d'un item à **17 groupes polymétriques imbriqués** ou plus. Seuil exact : 16 passe, 17 tombe. L'affichage terminal, lui, survit | 2026-08-09 |
| 71 | demander une seconde sortie **tronque** la trace texte, et sur trois grammaires change aussi la production. Quatre grammaires ne sont pas reproductibles à graine fixe sur l'axe MIDI | 2026-08-11 |
| 72 | un **rang de gabarit non numérique** n'est pas refusé : il dégénère en un nombre. `[1z]` devient le rang 10, `[zzz]` le rang 0 ; un message par caractère fautif, non compté aux erreurs. Même famille que #64 | 2026-09-06 |

⚠️ **#68 n'est pas dans cette liste, et l'entrée reste instructive.** Il avait été inscrit comme
une régression v3.5.0→v3.5.1 sur `--eventlistout` ; l'attribution était fausse — les deux
versions committées exigent `-o`, et le binaire de comparaison n'était pas reproductible depuis
sa source. Ce qui en reste appartient à #65 : un oracle non rattachable à sa source.

## Clos

| # | issue |
| --- | --- |
| 55 | **résolu en v3.4.7**, vérifié empiriquement : un fichier `-cs` dont la section de tables n'est pas fermée ne fait plus tourner le moteur sans fin |
| 57 | **retiré des défauts**, tranché par Bernard Bel : le glyphe `¬` est une erreur de documentation, pas une régression. La notation réelle est `3+4+2/4 … /3 … /1` |
| 59 | **diagnostic corrigé** : `_rotate` est bien appliqué — les jetons MIDI le prouvent. Ce qui change en v3.4.7 est la sérialisation **texte** |
| 62 | **corrigé en amont** le jour même : `--traceout` ne fait plus tomber le moteur. Republié **sous le même numéro de version** |
| **48** | **CORRIGÉ entre v3.4.2 et v3.5.1**, mesuré le 2026-09-12 sur trois binaires. Un terminal à tiret final dans une **chaîne** d'alphabet — `OCT` / `ta --> ki --> zo-` — faisait tomber v3.4.2 (code 139, signal 11). v3.5.1-iso.1 et v3.5.4-iso.1 refusent proprement : *« Found '-' in terminal symbol »*, *« Error code 27: terminal symbol contains unwanted character »*, code 0. ⚠️ Un tiret sur un terminal **isolé** (`ta- --> ta-`) est refusé proprement sur les trois : ce n'est pas le cas déclenchant |

⚠️ **Deux binaires au comportement différent portent l'étiquette `3.4.7`** : seule la date de
compilation les distingue. Une mesure cite **numéro + date de compilation**, jamais le seul
numéro.

## Ce que ce registre impose à toute mesure

- **Une capture de référence n'est comparable qu'à une autre prise avec les mêmes drapeaux de
  sortie** (#67, #71) : un oracle porte la **commande complète**, pas seulement la graine.
- **Le verdict se prend sur les octets produits**, jamais sur le code de sortie : le moteur rend
  zéro même quand il ne produit rien.
- **Re-capture interdite tant que #49 à #52 sont ouverts** : la baseline documente le réel des
  données livrées, défauts compris. ⚠️ **#48 sort de cette liste le 2026-09-12** — il est corrigé et
  mesuré ; les trois autres restent.

## Ce que la montée en v3.5.4 a mesuré sur ces défauts — 2026-09-12

Trois binaires : `v3.4.2` reconstruit du tag amont avec notre chaîne (md5 `bc948176…`),
`builds/v3.5.1-iso.1` (`fb6df5ad…`), `builds/v3.5.4-iso.1` (`9bab33d1…`).

| # | verdict en v3.5.4 | cas minimal | témoin positif |
| --- | --- | --- | --- |
| **48** | ✅ **corrigé** | alphabet `OCT` / `ta --> ki --> zo-` | oui — v3.4.2 rend 139, signal 11 |
| **49** | ⚠️ **non reproduit**, pas « corrigé » | `-gr.765432` nettoyée, `--seed 1`, `-se.765432` | **non** |
| **52** | ⛔ **toujours présent** | `-gr.look-and-say` nettoyée, `--seed 1`, `-se.look-and-say`, `-o` | oui — v3.4.2 produit 25 octets |

⚠️ **#49 : l'absence de symptôme n'est pas une correction.** Les trois binaires produisent **8788
octets de texte et 7971 octets de MIDI, identiques octet pour octet**. Le registre dit « injouable »,
ce qui peut viser l'axe temps réel — non éprouvé. **Sans témoin positif, le défaut reste ouvert.**

⛔ **#52 : la mesure atteint le point.** v3.4.2 produit 25 octets et `Errors: 0` ; v3.5.1-iso.1 et
v3.5.4-iso.1 rendent **zéro octet**, *« Cannot produce items because all weights are nil in
gram#1 »*, *« => result was: -4 »*. ⇒ **Regraver `look-and-say` contre v3.5.4 inscrirait la
régression du moteur comme référence de parité.**

## Ce que la montée en v3.5.4 déplace dans les sorties — 2026-09-12

Mesuré par `scripts/confronter-amont.py` sur l'assiette scellée de 96 grammaires. L'axe console
diverge sur les 93 dans tous les cas : il porte le numéro de version, il ne dit rien.

| saut | grammaires dont le TEXTE change | dont le MIDI change |
| --- | ---: | ---: |
| 3.4.2 → 3.5.4 | 7 | 23 |
| 3.5.1 → 3.5.4 | 6 | 17 |

⇒ **L'essentiel du déplacement est entre 3.5.1 et 3.5.4**, pas avant.
⚠️ Trois des grammaires MIDI — `dhin`, `tryAllItems0`, `tryhomomorphism` — sont **non
déterministes** et tirent du même vivier des deux côtés : leur écart n'est pas imputable à la
version. Écart MIDI attribuable : **~14**.

Qui bouge entre 3.5.1 et 3.5.4 — texte : `tryKeyMap`, `tryKeyXpand`, `tryRotate`, `visser-shapes`,
`visser-waves`, `visser5`. MIDI : `Alarm`, `Mozartexpression`, `checkHomo`, `dhin`, `dhin1`,
`livecode2`, `polyphony1`, `tryAllItems0`, `tryKeyMap`, `tryKeyXpand`, `tryRagas`,
`tryhomomorphism`, `vina3`, `visser-shapes`, `visser-waves`, `visser5`, `watch`.

⚠️ **Cause LUE dans le diff, non mesurée par mécanisme** : `Zouleb()` — le moteur des outils
sériels — est réécrit en entier (+908 lignes), l'ancien conservé sous `ZoulebOld()` et atteint par
le réglage neuf `IgnoreFields`. `tryRotate` et les `visser*` sont de cette famille. Pclock, Qclock,
`Nature_of_time` et le tirage à graine fixe **n'ont pas été isolés sur des cas dédiés**.
