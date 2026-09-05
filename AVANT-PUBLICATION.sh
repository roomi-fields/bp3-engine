#!/usr/bin/env bash
# CE QUE CE DÉPÔT DÉCLARE À LA PUBLICATION — décision de l'architecte du 2026-09-04.
#
# Les binaires natifs figés ne sont pas suivis en version : l'archive publiée ne les porte donc
# pas, et depuis le cloisonnement un voisin ne les atteint plus dans cet arbre. BPscript tranche
# ses questions de comportement sur le binaire natif ; sans cette déclaration, ce n'est pas un
# banc de moins chez lui, c'est l'instrument de référence qui sort.
#
# ⛔ CE QUI EST DÉCLARÉ EST LE PÉRIMÈTRE DES CAMPAGNES CITÉES COMME ORACLE, PAS `builds/` ENTIER.
# `builds/` pèse 730 Mo et porte 160 campagnes, dont la quasi-totalité sont des constructions
# automatiques sans lecteur. L'espace publié est lu par les quinze autres dépôts : y déposer
# 730 Mo pour 5 Mo d'oracle est un coût porté par tout le monde et une charge pour personne.
# La décision autorise nommément ce resserrement : « publier le seul répertoire de campagne que
# l'oracle nomme répond à la décision. »
#
# Les deux campagnes déclarées, et qui les nomme :
#   v3.5.1-iso.1  — l'oracle que BPscript lit, et celui de docs-developer/volumestep-step-et-
#                   plantage-trace.md
#   v3.5.1-iso.2  — l'oracle courant de ce dépôt : scripts/copie-injection.sh, le maillon
#                   « oracle-fige-intact » du portillon, et toute mesure de référence prise
#                   depuis le 2026-08-14
#
# ⛔ UNE CAMPAGNE QUI DEVIENT UN ORACLE S'AJOUTE ICI DANS LE MÊME GESTE. Un binaire cité par un
# document et absent de cette liste est atteignable ici et introuvable chez le voisin, et rien
# ne le dit : le défaut n'apparaît que chez celui qui lit, plus tard.
#
# `builds/LAST` est le raccourci que `BPscript/test/resolve_bin.cjs:6` résout pour la valeur
# `last`. Il porte le NOM d'une campagne, sur une ligne.
# ⛔ IL DOIT NOMMER UNE CAMPAGNE DÉCLARÉE CI-DESSOUS : pointé sur une campagne absente de cette
# liste, il se résout ici et rend un chemin mort chez le voisin. Le changer et changer cette
# liste sont un seul geste.
set -eu

printf '%s\n' builds/v3.5.1-iso.1 >> "$PUBLIER_DECLARE"
printf '%s\n' builds/v3.5.1-iso.2 >> "$PUBLIER_DECLARE"
printf '%s\n' builds/LAST >> "$PUBLIER_DECLARE"
