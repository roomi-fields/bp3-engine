# Brouillon du courrier à Bernard Bel — en attente de la relecture de Romain

État : **non envoyé**. Rendu à l'architecte le 2026-08-14 pour la relecture de Romain, conformément
à la décision `hub/decisions/2026-08-13-les-gardes-du-moteur-ne-se-remettent-pas.md`.

Rédigé en français sur arbitrage de Romain du 2026-08-14.

Le brouillon ne porte **qu'un** des deux défauts demandés. La raison figure sous le texte.

---

## Texte proposé

> Objet : BP3 3.5.1 — `--traceout` écrit un fichier image de zéro octet
>
> Bonjour Bernard,
>
> En faisant tourner le moteur en ligne de commande sous Linux, nous sommes tombés sur un
> comportement de l'option `--traceout` dont nous nous sommes dit qu'il vous intéresserait.
>
> **Version** — `Bol Processor console app, Version 3.5.1`, construite depuis le tag `v3.5.1` avec
> `gcc -O2 -g -fno-common`, liée avec `-lm -lasound -lcurl`.
>
> **Ce qui se passe** — avec `--traceout`, le moteur annonce qu'il crée une image, signale ensuite
> qu'il ne peut pas ouvrir `php/CANVAS_header.txt`, et laisse le fichier image vide. Le processus
> sort avec le code 0.
>
> **Cas minimal** — n'importe quelle grammaire dont les réglages activent l'affichage graphique.
> Avec `-gr.765432` et `-se.765432` des données de test, depuis un répertoire de travail qui
> contient le dossier `csound_resources` :
>
> ```
> bp3 produce -e -gr -gr.765432 --seed 1 -se -se.765432 -o /dev/null --traceout trace.txt
> ```
>
> Sortie console :
>
> ```
> Pianoroll graphics will be displayed
> Object graphics will be displayed
> Errors: 0
> Image width 44058 was too large: it has been cropped to 32000
> Creating image #1: trace.txt_image_001_temp.html
> => Failed to open: <répertoire courant>/php/CANVAS_header.txt in 'rb' mode.
>    Error: No such file or directory
> ```
>
> Résultat : `trace.txt_image_001_temp.html` existe et fait **0 octet**.
>
> **Où nous avons cherché** — `CANVAS_header.txt` est lu par `CreateImageFile`, dans
> `ConsoleMain.c`. Nous n'avons pas trouvé ce fichier dans le dépôt : nous avons cherché sur les
> branches `master`, `graphics-for-BP3` et `BP3-develop`, sur l'ensemble des fichiers, sans aucune
> occurrence du nom. S'il vient de la distribution web plutôt que du dépôt du moteur, alors
> l'application en ligne de commande ne peut pas produire d'image par elle-même, et le code de
> sortie 0 n'en donne aucune indication.
>
> Nous ne demandons aucune modification — nous ne voulions simplement pas garder l'observation pour
> nous.
>
> Avec nos remerciements pour le moteur,

---

## Pourquoi le second défaut ne figure pas

La demande portait aussi sur la liste d'événements vide quand elle est réclamée seule, 61 grammaires
sur 91.

**Ce défaut n'existe pas dans le moteur de Bernard.** Mesure du 2026-08-12, rejouée le 2026-08-14,
sur un binaire construit à partir du tag `v3.5.1` avec notre chaîne — empreinte
`06244c55d11bd9496c6e7187afea2787` :

```
bp3 produce -e -gr <-gr.Alarm nettoyée> --seed 1 -al ../test-data/-ho.Frenchnotes --eventlistout <f>
```

| binaire | lignes écrites |
| --- | --- |
| amont `06244c55` | 32 |
| nôtre `372dd047` | 1 — l'en-tête seul |

Le comportement décrit appartient à notre arbre, et sa cause est inscrite à
`docs-developer/inventaire-des-deltas.md` : les deux mentions de `EventListOn` perdues dans les
conditions de `PlayThings.c`. Écrire à Bernard qu'un binaire fait cela reviendrait à lui décrire un
comportement que le sien n'a pas.

## Ce qui reste du premier défaut

Le plantage sur `765432` avec `--traceout` appartient lui aussi à notre arbre : notre binaire rend
139, le sien rend 0. Ce que le courrier décrit est donc **ce que son binaire fait**, et non le
plantage — l'image de zéro octet, que les deux binaires produisent, et le gabarit absent du dépôt.
