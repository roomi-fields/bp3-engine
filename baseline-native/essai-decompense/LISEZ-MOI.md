# Captures d'essai décompensées

Prises sur le binaire `bp3` md5 `372dd047bc52fd152ff51ec6715fae74`, archive
`builds/v3.5.1-iso.2/bp3`, dont `TokensOut.c` ne retranche plus la quantification.

Elles servent de témoin avant la recapture de l'assiette. Elles ne font pas partie de la
référence scellée.

| grammaire | quantification | jetons | écart contre la capture scellée |
| --- | --- | --- | --- |
| `acceleration` | 10 | 78 | +10 sur les deux bornes, tous les jetons |
| `Djinns` | 50 | 895 | +50 sur les deux bornes, tous les jetons |
| `kss2` | 10 | 97 | aucun |
| `765432` | 50 | 823 | aucun |
| `Nadaka-1er-essai` | 50 | 4 | aucun |

L'écart vaut la quantification du réglage quand le taux de compression annoncé par le moteur
dépasse 1, et zéro sinon. Il est uniforme sur toute la grammaire.
