# Vingt-deux réglages restés dans leur écriture d'origine, et la table qui les apparie

Repris de `~/dev/bp/kanopi/packages/library/test-assets/bp3/` le 2026-09-09, à l'entrée de Kanopi
dans le dépôt unique. Décision de Romain, même jour : cette matière est du moteur, elle vit chez
lui, avec sa divergence nommée.

## Ce qui est ici, et pourquoi seulement ça

Kanopi portait 542 fichiers de grammaires BP3. Mesuré fichier par fichier contre `../` :

| | |
| --- | --- |
| identiques au moteur | 355 |
| identiques au retour chariot près (Kanopi écrivait en CRLF) | 40 |
| **réglages que le moteur porte en JSON et Kanopi en écriture d'origine** | **22** |
| produits par BPScript et régénérables (`silent.al`, `silent.gr`, un couple par grammaire) | 123 |
| déclaration de fins de ligne, matière d'organisation | 1 |
| **la table d'appariement** | **1** |

Seules les deux lignes en gras entrent : le reste est déjà là, ou se refabrique.

## Les vingt-deux

Le moteur a converti ses cent quarante-trois réglages en JSON. Ces vingt-deux ont gardé chez Kanopi
leur écriture d'origine, celle de Bol Processor 2.6.2 : un nombre par ligne, sans nom de champ, la
position dans le fichier valant l'identité du réglage. Chaque valeur est donc lisible **ici** et
seulement ici — le JSON du moteur porte peut-être les mêmes, peut-être pas : personne ne l'a mesuré.

⛔ On ne les efface pas et on ne les convertit pas à la légère. Ce que devient chacun de ces
réglages est ouvert : ticket bp-mono-jdf.6 côté dépôt unique, à lier à la fiche du projet.

## La table d'appariement

`correspondance.json` est la seule pièce qui dise quelle grammaire va avec quels auxiliaires. Le
partage de nom qui portait cette information (`-gr.trial.mohanam` avec `-se.trial.mohanam`) a été
détruit par le renommage en `.gr`, nécessaire pour que la bibliothèque voie les fichiers.

Et l'en-tête d'une grammaire ne la rend pas : le moteur lit ces lignes **pour les sauter**
(`source/BP3/CompileGrammar.c:251`, « Skip headers »). Mesure inscrite dans le fichier lui-même :
sur 113 grammaires, 33 déclarent une facette différente de celle retenue et 12 en utilisent une que
leur en-tête ne mentionne pas — 39 en-têtes sur 113 induisent en erreur.
