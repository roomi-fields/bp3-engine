# Sorties de référence de v3.5.4 — produites par Bernard Bel

Trois fichiers reçus de Bernard Bel le 2026-09-12, produits par son binaire `v3.5.4` avec :

```
./bp play -se ./ctests/Imported_MusicXML/-se.Ombres_errantes -da <chemin>/0.bpda \
   -to ./tonality_resources/-to.tryTunings --eventlistout ./my_output/Ombres_errantes.csv
```

⚠️ **Les entrées de cette ligne ne sont dans aucune branche amont** — ni `-to.tryTunings`, ni
`ctests/Imported_MusicXML/`, ni le `.bpda`. Ce sont des ressources de son poste. **La ligne ne se
rejoue pas ici**, et ces trois fichiers sont donc des sorties à lire, pas un cas reproductible.

| fichier | ce qu'il porte |
| --- | --- |
| `Ombres_errantes.csv` | une liste d'événements v3.5.4 complète, **56 colonnes** |
| `rameau_en_sib.scl` | une gamme au format Scala, avec les noms de degrés en français |
| `rameau_en_sib.kbm` | la correspondance de clavier associée |

## Ce qu'ils ont servi à établir

L'en-tête de `Ombres_errantes.csv` a été comparé colonne à colonne à celui que **notre** binaire
`builds/v3.5.4-iso.1/bp3` écrit : **56 colonnes, identiques, dans le même ordre**. C'est une
confirmation indépendante de la relève de format, prise sur une sortie que nous n'avons pas produite.

Les deux autres donnent la forme exacte des fichiers que `ExportSCL()` et `ExportKBM()`
(`Tonality.c:99-150`) écrivent : les commentaires d'en-tête, l'ordre des champs du KBM, et le fait
que le SCL porte le **nom du degré** après la valeur en cents.
