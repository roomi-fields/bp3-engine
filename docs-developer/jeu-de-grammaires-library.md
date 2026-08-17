# Le jeu de grammaires `library`

La branche `library` porte 91 fichiers organisés en quatre familles — `examples/`,
`experimental/`, `tabla/`, `western/` — et un `index.json`. Chaque dossier porte une grammaire
`grammar.gr`, ses réglages `settings.json`, et pour quatre d'entre eux un alphabet `alphabet.al`.
44 grammaires au total.

C'est une branche orpheline : elle n'a aucun parent et ne porte rien du moteur. `master` et `wasm`
l'ignorent l'une comme l'autre.

## Ce que la branche donne

Les scènes traduites citent leur grammaire source sous la forme
`bp3-engine/library/<famille>/<nom>/grammar.gr`. La branche est l'endroit où ce chemin se résout.

Les 44 grammaires sont identiques, octet pour octet, à une grammaire de `test-data/`. La
correspondance passe par le contenu : la convention de nommage est incomplète, et
`library/tabla/ek-do-tin/grammar.gr` est `test-data/-gr.12345678`.

## Les trois gestes

```
scripts/library.sh construire    fabrique la branche depuis origin/wasm-deprecated
scripts/library.sh poser         pose le dossier library/ à la racine, par arbre rattaché
scripts/library.sh retirer       retire ce dossier ; la branche reste
```

`poser` est optionnel. Un clone frais porte la branche et rien sur le disque : le dossier se pose
à la demande, pour ouvrir les fichiers et les comparer.

## L'alphabet d'une grammaire du jeu

`test-data/REGISTRE.json` porte le couple grammaire ↔ auxiliaires, et c'est lui qui fait autorité.
L'en-tête d'une grammaire cite parfois un auxiliaire : le moteur saute cette ligne, elle désigne
autre chose que le couple retenu pour 22 des 113 grammaires, et quatre des fichiers qu'elle nomme
sont absents du corpus.
