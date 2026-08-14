# Brouillon du courrier à Bernard Bel — en attente de la relecture de Romain

État : **non envoyé**. Rendu à l'architecte le 2026-08-14 pour la relecture de Romain, conformément
à la décision `hub/decisions/2026-08-13-les-gardes-du-moteur-ne-se-remettent-pas.md`.

Le brouillon ne porte **qu'un** des deux défauts demandés. La raison figure sous le texte.

---

## Texte proposé

> Subject: BP3 3.5.1 — `--traceout` writes a zero-byte image file
>
> Dear Bernard,
>
> While running the BP3 console application on Linux we came across a behaviour of the `--traceout`
> option that we thought you would want to know about.
>
> **Version** — `Bol Processor console app, Version 3.5.1`, built from the `v3.5.1` tag with
> `gcc -O2 -g -fno-common`, linked with `-lm -lasound -lcurl`.
>
> **What happens** — with `--traceout`, the engine announces that it is creating an image, then
> reports that it cannot open `php/CANVAS_header.txt`, and leaves the image file empty. The process
> exits with status 0.
>
> **Minimal case** — any grammar whose settings enable the graphic display. With `-gr.765432` and
> `-se.765432` from the standard test data, run from a working directory that contains the
> `csound_resources` folder:
>
> ```
> bp3 produce -e -gr -gr.765432 --seed 1 -se -se.765432 -o /dev/null --traceout trace.txt
> ```
>
> Console output:
>
> ```
> Pianoroll graphics will be displayed
> Object graphics will be displayed
> Errors: 0
> Image width 44058 was too large: it has been cropped to 32000
> Creating image #1: trace.txt_image_001_temp.html
> => Failed to open: <cwd>/php/CANVAS_header.txt in 'rb' mode. Error: No such file or directory
> ```
>
> Result: `trace.txt_image_001_temp.html` exists and is **0 bytes**.
>
> **What we looked for** — `CANVAS_header.txt` is read by `CreateImageFile` in `ConsoleMain.c`. We
> could not find the file in the repository: we searched the `master`, `graphics-for-BP3` and
> `BP3-develop` branches, across all files, and found no match for the name. If it is meant to come
> from the web distribution rather than from the engine repository, then the console application
> cannot produce an image on its own, and the exit status of 0 gives no indication of that.
>
> We are not asking for a change — we simply did not want to keep the observation to ourselves.
>
> With our thanks for the engine,

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
