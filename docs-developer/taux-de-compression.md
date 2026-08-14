# Le taux de compression `Kpress`

## Il est calculé, jamais réglé

Aucun fichier de réglages ne le porte. Le moteur le calcule à chaque expansion polymétrique, dans
`Polymetric.c`, sous l'étiquette `FINDCOMPRESSION` (`:330`).

```c
Kpress = 1.;                                                        /* :333 */
if(Pclock > 0.) {
    kpress = 1. + (((double)Quantization) * Qclock * Ratio) / Pclock / 1000.;   /* :335 */
    kpress = floor(1.00001 * kpress);                               /* :336 */
    if(Quantize && kpress > 1.) { /* Ratio et Prod réajustés */ }   /* :337-343 */
    if(Quantize) {
        Kpress = kpress;                                            /* :345 */
        BPPrintMessage(... "Using quantization = %ld ms with compression rate = %.0f" ...); /* :346 */
        }
    else { /* armement automatique, voir plus bas */ }              /* :348-355 */
    }
```

Soit, en clair :

```
Kpress = plancher( 1 + (Quantization × Qclock × Ratio) / (Pclock × 1000) )
```

## D'où vient chaque terme

| terme | origine | pièce |
| --- | --- | --- |
| `Quantization` | réglage, en millisecondes, défaut 10 | `SaveLoads1.c:561` ; réglé par `ScriptUtils.c:935` |
| `Qclock`, `Pclock` | l'horloge P/Q, réglée par le script ou par un changement d'horloge | `ScriptUtils.c:818-819` ; `Misc.c:773-774` ; défaut 1 et 1, `Inits.c:288` |
| `Ratio` | **calculé sur la scène** : le produit de l'expansion polymétrique | `Polymetric.c:316`, `Ratio = Prod` |

## Deux conditions qui décident de sa valeur

**`Kpress` vaut 1 tant que la quantification est éteinte.** L'affectation `Kpress = kpress` vit sous
`if(Quantize)` (`:344-345`). Sans quantification, `Kpress` garde sa valeur initiale de 1, quelle que
soit la valeur calculée pour `kpress`.

**Le moteur allume la quantification de lui-même.** Quantification éteinte et `kpress >= 4` à la
première rencontre, ou `kpress >= 100` à chaque fois : le moteur annonce `Forcing quantization to
<Q> ms`, pose `Quantize = TRUE` et **recommence le calcul** (`:349-353`).

## La quantification annoncée peut différer du réglage

Quand l'expansion dépasse la limite de mémoire, le moteur **augmente `Quantization` lui-même** —
`newquantize` arrondi à la dizaine supérieure (`:650-651`), plafonné à 2000 ms (`:676`), affecté en
`:729` — puis retourne à `FINDCOMPRESSION`. Le message
`Quantization of <ancien> ms will be increased to reduce memory requirement (<nouveau> ms might work)`
le dit (`:688`).

**La valeur à reproduire est celle que la ligne `Using quantization = <Q> ms with compression rate =
<K>` annonce**, jamais celle du fichier de réglages.
