#!/usr/bin/env bash
# PORTILLON du dépôt bp3-engine — volet 2 de la décision Romain du 2026-07-19
# (hub/decisions/2026-07-19-confronter-via-oracle-et-restaurer-tous-les-guards.md)
#
# Avant cette décision : 13 fichiers de garde portés, ZÉRO lancé par un portillon.
# Aucun hook git, aucune intégration continue, aucune cible « test » au Makefile.
#
# Deux voies, volontairement séparées :
#   RAPIDE   — gardes qui passent aujourd'hui, doivent rester verts.
#   ROUGE    — vrais gardes qui ÉCHOUENT sur un défaut réel du moteur. Ils restent
#              branchés et rouges. On ne les réécrit PAS pour faire verdir : c'est le
#              CODE qui doit bouger (règle explicite de la décision).

set -u
cd "$(dirname "$0")/.."
VOIE="${1:-rapide}"
ROUGE=0; VERT=0

# ⛔ CE PORTILLON DIT OÙ PART SON TEMPS — levier 4 de la demande de Romain du 2026-09-04.
# Sans cette mesure, personne ne cherche : un portillon lent est lent « en gros », et le maillon
# qui en mange la moitié se cache derrière vingt et un autres. Elle s'affiche à chaque course, y
# compris verte, parce qu'une régression de temps ne se voit que contre la course d'avant.
CHRONO_TOTAL=0
# ⛔ ON PAIE LE MAXIMUM, PAS LA SOMME — levier 1 de la demande de Romain du 2026-09-04.
# ⛔⛔ ET CE QUI BORNE CE PORTILLON N'EST PAS LE PROCESSEUR : c'est le DÉCOR. Cinq injections
# n'ont pas de dossier jetable à elles et écrivent DANS la copie d'injection, qui est unique.
# Les lancer ensemble les ferait se marcher dessus, et deux gardes qui se marchent dessus
# rendent VERT — parce que leur objet a disparu, pas parce qu'il tient. Elles restent en série,
# par `lancer_seul`, et c'est le fichier de garde qui le déclare, jamais une liste ailleurs.
# (Le levier prescrit — un processus partagé contre l'amorçage répété — ne mord pas ici :
# ce portillon ne lance pas un seul processus `node`. Sa dépense est du travail, pas du
# démarrage : `user`+`sys` valent 16 s sur 31 s de maillons, le reste étant de la lecture
# de disque sur les quinze états publiés.)
RES=$(mktemp -d "${TMPDIR:-/tmp}/gate-verdicts.XXXXXX")
trap 'rm -rf "$RES"' EXIT
NOMS=(); DELAIS=()

_courir() { # _courir <nom> <delai> <commande...> — écrit son verdict, jamais l'écran
  local n=$1 d=$2; shift 2
  local t0=${EPOCHREALTIME/,/.}
  timeout "$d" "$@" >"/tmp/gate.$n.log" 2>&1
  local c=$?
  printf '%s %s\n' "$c" "$(awk -v a="$t0" -v b="${EPOCHREALTIME/,/.}" 'BEGIN{printf "%.2f", b-a}')" \
    > "$RES/$n"
}

# ⛔ LE TÉMOIN QUI COMPARE LES DEUX FORMES. `GATE_SERIE=1` reproduit la forme entièrement en
# série. Sans lui, « le parallèle est plus rapide » est une croyance : les deux formes doivent
# rendre le MÊME verdict et deux durées comparables sur la même machine, au même moment.
# ⇒ MESURÉ LE 2026-09-04, CINQ PAIRES ENTRELACÉES : parallèle 35,9 · 53,5 · 46,4 · 63,6 · 57,3 s,
#   série 39,6 · 55,8 · 49,5 · 68,5 · 37,3 s. Le parallèle gagne 3 à 5 s quatre fois et perd 20 s
#   une fois, quand l'écart entre deux courses de la MÊME forme atteint 28 s.
#   ⛔ L'écart cherché est donc plus petit que le bruit, et la bonne réponse est « on ne sait
#     pas », pas un chiffre. Ce qui domine est la charge de la machine, extérieure à ce portillon.
#   ⚠️ Et la première mesure, prise sur DEUX COURSES SUCCESSIVES au lieu d'une paire, concluait
#     l'inverse — « le parallèle est plus lent » — en comparant deux instants, pas deux formes.
#   ⇒ Ce qui pesait le plus n'est plus ici : les deux maillons qui relançaient les outils du hub
#     valaient à eux seuls les deux tiers du portillon, l'un d'eux balayant 2879 fichiers sur les
#     quinze états publiés. Ils sont partis avec la voie parallèle qu'ils formaient, et ces
#     gardes-là tournent une seule fois, en tête du crochet.
lancer() {      # parallélisable : n'écrit pas dans la copie partagée
  NOMS+=("$1"); DELAIS+=("$2")
  if [ "${GATE_SERIE:-0}" = 1 ]; then _courir "$@"; else _courir "$@" & fi
}
lancer_seul() { # écrit dans la copie d'injection partagée : sa place est en série
  NOMS+=("$1"); DELAIS+=("$2")
  _courir "$@"
}

population() {
  # ⛔ LA LISTE ATTENDUE, CONFRONTÉE PAR NOM. Un maillon retiré de ce fichier-ci sort des deux
  # côtés d'une comparaison interne et ne rougit nulle part : la trace se tient donc DEHORS,
  # dans scripts/MAILLONS.txt. Les deux sens refusent — le retrait silencieux comme l'ajout non
  # inscrit — et le refus NOMME, parce qu'un compte qui bouge ne dit pas lequel a bougé.
  local liste="$PWD/scripts/MAILLONS.txt" attendus lances manquants surnumeraires
  if [ ! -f "$liste" ]; then
    echo "  ✗ population des maillons — liste attendue introuvable : $liste"
    echo "    Sans elle, un maillon disparu rend un vert de moins et rien de plus."
    ROUGE=$((ROUGE+1)); return
  fi
  attendus=$(sed -e 's/#.*//' -e 's/[[:space:]]//g' -e '/^$/d' "$liste" | sort)
  lances=$(printf '%s\n' "${NOMS[@]}" | sort)
  # Un lot vide REFUSE : zéro maillon exécuté n'est pas un portillon vert.
  if [ -z "$attendus" ] || [ ${#NOMS[@]} -eq 0 ]; then
    echo "  ✗ population des maillons — liste vide ou aucun maillon lancé ; un lot vide refuse."
    ROUGE=$((ROUGE+1)); return
  fi
  manquants=$(comm -23 <(printf '%s\n' "$attendus") <(printf '%s\n' "$lances"))
  surnumeraires=$(comm -13 <(printf '%s\n' "$attendus") <(printf '%s\n' "$lances"))
  if [ -n "$manquants" ] || [ -n "$surnumeraires" ]; then
    [ -n "$manquants" ] && echo "  ✗ maillon(s) ATTENDU(S) et non lancé(s) : $(echo $manquants)"
    [ -n "$surnumeraires" ] && echo "  ✗ maillon(s) lancé(s) et non inscrit(s) : $(echo $surnumeraires)"
    echo "    → inscrire ou retirer dans scripts/MAILLONS.txt, dans le même geste."
    ROUGE=$((ROUGE+1)); return
  fi
  echo "  ✓ population — ${#NOMS[@]} maillon(s) lancé(s), nom pour nom, conformes à scripts/MAILLONS.txt"
}

verdicts() {
  wait
  local i n d c dt
  for i in "${!NOMS[@]}"; do
    n=${NOMS[$i]}; d=${DELAIS[$i]}
    printf '  %-26s ' "$n"
    # ⛔ L'ABSENCE DE VERDICT REFUSE. Un maillon qui n'a pas déposé son code n'a pas fini, ou il
    # est mort avant d'écrire — les deux sont des refus, jamais un vert par défaut.
    if [ ! -f "$RES/$n" ]; then
      printf '%-14s\n' "ROUGE (sans verdict)"; ROUGE=$((ROUGE+1)); continue
    fi
    read -r c dt < "$RES/$n"
    CHRONO_TOTAL=$(awk -v a="$CHRONO_TOTAL" -v b="$dt" 'BEGIN{printf "%.2f", a+b}')
    # ⛔ LE REFUS NOMME QUI REFUSE : un lot parallèle qui rend « 1 » sans nom est
    # indistinguable d'un refus survenu ailleurs.
    if [ "$c" -eq 0 ]; then
      printf '%-14s %6s s\n' "vert" "$dt"; VERT=$((VERT+1))
    elif [ "$c" -eq 124 ]; then
      printf '%-14s %6s s\n' "DÉPASSE $d s" "$dt"; ROUGE=$((ROUGE+1))
    else
      printf '%-14s %6s s\n' "ROUGE (sortie $c)" "$dt"; ROUGE=$((ROUGE+1))
    fi
    # ⛔ LA MENTION DE RÉGIME REMONTE, VERT COMME ROUGE. Le portillon retient la sortie de
    # chaque maillon dans un journal ; une mention qui y reste ne qualifie rien, puisque
    # personne ne lit le journal quand tout est vert. Elle s'affiche sous son maillon.
    grep -h '^\[regime\]' "/tmp/gate.$n.log" 2>/dev/null | sed 's/^/    /' || true
  done
}

if [ "$VOIE" = rapide ] || [ "$VOIE" = tout ]; then
  echo "── voie RAPIDE ───────────────────────────────"
  # ⛔ LES INJECTIONS S'ÉPROUVENT DANS UNE COPIE, JAMAIS DANS L'ARBRE DE TRAVAIL.
  # Mesuré le 2026-08-21 : elles écrivaient sept fichiers ici, dont `source/BP3/PlayThings.c`
  # — le code de Bernard Bel — et le binaire oracle. Un voisin qui lisait l'arbre pendant
  # une poussée voyait l'apparence exacte de la faute la plus grave de la charte.
  # Sans copie, PAS D'INJECTION : un repli sur l'arbre réel rendrait le défaut invisible.
  # La pose de la copie est hors maillon et se chronomètre à part : c'est un décor, pas un garde,
  # et il pèse. Le confondre avec un maillon ferait chercher la lenteur dans le mauvais objet.
  T_COPIE0=${EPOCHREALTIME/,/.}
  COPIE="$(./scripts/copie-injection.sh poser)" || {
    echo "  ✗ la copie d'injection n'a pas pu être posée — les morsures ne s'éprouvent pas ici"
    exit 1
  }
  T_COPIE=$(awk -v a="$T_COPIE0" -v b="${EPOCHREALTIME/,/.}" 'BEGIN{printf "%.2f", b-a}')
  # Listés un par un, et non par une boucle : le méta-garde anti-bypass doit pouvoir
  # lire ce fichier sans interpréter du shell. Un garde qui doit deviner ne garde rien.
  #
  # ⛔ `lancer_seul` = ce maillon travaille DANS la copie d'injection, qui est unique et partagée.
  # Le critère n'est pas « il écrit » mais « son objet est la copie » : cinq d'entre eux y écrivent
  # sans dossier jetable à eux, et les deux gardes de l'oracle figé LISENT l'état de cette même
  # copie. Un lecteur de la copie lancé pendant qu'un autre la réécrit rend un verdict sur un décor
  # à moitié défait.
  lancer "baseline-integrite" 60 python3 scripts/gate-baseline.py
  lancer "anti-bypass"        60 python3 scripts/gate-meta.py
  lancer_seul "anti-bypass-morsure" 90 "$COPIE/scripts/gate-meta-injection.sh"
  lancer "anti-retrocompat"   60 python3 scripts/gate-legacy.py
  lancer_seul "anti-retro-morsure" 90 "$COPIE/scripts/gate-legacy-injection.sh"
  lancer "ancrages-locaux"    60 python3 scripts/gate-ancrages.py
  lancer_seul "ancrages-morsure"   90 "$COPIE/scripts/gate-ancrages-injection.sh"
  lancer_seul "effondrement-morsure" 90 "$COPIE/scripts/gate-effondrement-injection.sh"
  lancer "non-retour-bug55"   60 ./scripts/verif-bug55.sh
  lancer_seul "sonde-morsure"     120 "$COPIE/scripts/gate-sonde-injection.sh"
  lancer "correspondance"     60 python3 scripts/gate-correspondance.py
  lancer_seul "correspondance-morsure" 90 "$COPIE/scripts/gate-correspondance-injection.sh"
  lancer "gel-baseline"       60 python3 scripts/gel-baseline.py
  lancer_seul "gel-morsure"        90 "$COPIE/scripts/gate-gel-injection.sh"
  lancer "autonomie"          60 python3 scripts/gate-autonomie.py
  lancer_seul "autonomie-morsure"  90 "$COPIE/scripts/gate-autonomie-injection.sh"
  # ⛔ Le garde du RETARD DE PUBLICATION vit en tête du crochet, et sa ligne se
  # retirait sans que rien ne rougisse — mesuré : 21 verts sur un crochet amputé. Ce maillon
  # tourne DANS L'ARBRE parce que son sujet est le crochet que GIT EXÉCUTE ici, lu par
  # core.hooksPath ; depuis la copie il prouverait le crochet de la copie. Il n'écrit rien :
  # ses leurres vivent dans un dossier jetable, atteints en substituant HOME.
  lancer "retard-morsure"     60 ./scripts/gate-retard-injection.sh
  # Le garde du COURRIER NON LU vit en tête du crochet, avant tout le reste. Sa ligne se retire
  # sans que rien ne rougisse — c'est le même défaut, et il se couvre de la même façon. Ce maillon
  # tourne DANS L'ARBRE pour la même raison que le précédent : son sujet est le crochet d'ici.
  lancer "courrier-morsure"   60 ./scripts/gate-courrier-injection.sh
  # L'oracle figé est atteint par lien symbolique depuis la copie : une écriture dessus
  # aurait touché l'original. Le vérifier fait partie du portillon, pas d'un journal.
  # L'oracle-figé vérifie que le binaire n'a pas BOUGÉ pendant les injections ; celui-ci vérifie
  # que l'empreinte ANNONCÉE dans mes documents est la sienne. Deux questions distinctes : une
  # description juste que rien ne confronte est juste par soin, pas par construction.
  lancer "empreinte-oracle"   60 python3 scripts/gate-empreinte-oracle.py
  lancer_seul "empreinte-morsure"  90 "$COPIE/scripts/gate-empreinte-injection.sh"
  lancer_seul "oracle-fige-intact" 30 ./scripts/copie-injection.sh verifier
  lancer_seul "oracle-fige-morsure" 60 "$COPIE/scripts/gate-oracle-injection.sh"
  ./scripts/copie-injection.sh retirer
  # ⛔ LES GARDES DU HUB NE SONT PLUS RELANCÉS ICI. Ils vivaient dans ce portillon, dérivés de
  # `hub/tools/PORTILLON.txt` — trois noms. Depuis le 2026-09-04 le hub porte un POINT D'ENTRÉE
  # unique, appelé en tête de mon crochet, qui lance ces trois-là et trois de plus, et qui nomme
  # à chaque passage ceux qu'il n'appelle pas. Les relancer ici ferait de PORTILLON.txt une
  # seconde autorité sur la même liste, et deux listes divergent toujours : celle du hub en
  # nommait trois quand son point d'entrée en lançait quatre, le même jour.
  # ⇒ Leur branchement est prouvé par `retard-morsure`, qui suit la chaîne crochet → point
  #   d'entrée → garde et rougit quand la ligne du crochet est amputée.
  # Les verdicts se rendent ICI, dans l'ordre déclaré et jamais dans l'ordre d'arrivée : un
  # portillon dont la sortie change de forme d'une course à l'autre ne se compare plus.
  verdicts
  population
fi

# La voie ROUGE porte les défauts MOTEUR connus et non corrigés. On ne les maquille jamais :
# ils restent branchés et rouges jusqu'à ce que le moteur bouge.
# Note historique : son premier occupant, test-settings-params, n'était pas rouge
# à cause du moteur mais à cause de LUI-MÊME — il passait la convention 1 (= FRANÇAIS) à
# une grammaire en notes anglaises. Aligné sur la vérité du moteur et RENFORCÉ (il exige
# désormais la symétrie des conventions), il est vert et vit en voie rapide. Voir BPE-21.
# La voie reste déclarée : le jour où un vrai défaut moteur apparaît, il a sa place.
if [ "$VOIE" = rouge ] || [ "$VOIE" = tout ]; then
  echo "── voie ROUGE (défauts moteur connus, NE PAS faire verdir) ──"
  echo "  (aucun garde dans cette voie — #55, son dernier occupant, est corrige"
  echo "   depuis la v3.4.7 et garde desormais sa non-reapparition en voie rapide)"
fi

echo "─────────────────────────────────────────────"
echo "  $VERT vert(s), $ROUGE rouge(s)"
if [ "${T_COPIE:-}" != "" ]; then
  echo "  temps : ${CHRONO_TOTAL} s de maillons + ${T_COPIE} s de pose du décor d'injection"
fi
[ "$VOIE" = rouge ] && exit 0   # cette voie est informative : son rouge est attendu
exit $(( ROUGE > 0 ? 1 : 0 ))
