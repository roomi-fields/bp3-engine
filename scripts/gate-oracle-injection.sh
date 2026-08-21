#!/usr/bin/env bash
# PREUVE DE MORSURE du maillon `oracle-fige-intact`, par injection.
#
# Ce maillon relève l'empreinte du binaire natif figé avant les injections et la revérifie
# après : la copie atteint `builds/` par lien symbolique, donc une écriture depuis la copie
# atteindrait l'original. Sans preuve, c'est une hypothèse.
#
# ⛔ ON N'ÉCRIT JAMAIS DANS L'ORACLE POUR LE PROUVER. L'injection monte un dépôt jetable
# dont le rôle d'oracle est tenu par un fichier quelconque, y copie `copie-injection.sh`
# — qui déduit sa racine de son propre emplacement — et écrit dans CE fichier-là. Le code
# éprouvé est le même, l'écriture est réelle, le binaire de référence n'est pas touché.
set -u
cd "$(dirname "$0")/.."
VRAI_ORACLE="builds/v3.5.1-iso.2/bp3"
EMPREINTE_AVANT=$(git hash-object "$VRAI_ORACLE")
echec=0

T=$(mktemp -d)
nettoie() { rm -rf "$T"; }
trap nettoie EXIT

echo "1. montage d'un dépôt jetable dont l'oracle est un leurre"
mkdir -p "$T/depot/scripts" "$T/depot/builds/v3.5.1-iso.2"
cp scripts/copie-injection.sh "$T/depot/scripts/"
printf 'binaire de substitution, pas un oracle\n' > "$T/depot/builds/v3.5.1-iso.2/bp3"
echo "rien" > "$T/depot/marqueur.txt"
( cd "$T/depot" && git init -q . && git add -A \
  && git -c user.email=x@y -c user.name=x commit -qm "socle" ) || {
    echo "   ÉCHEC : le dépôt jetable n'a pas pu être monté"; exit 1; }

export BP3_COPIE_RACINE="$T/copie"

echo "2. état de départ — l'oracle de substitution est intact, le maillon doit être VERT"
bash "$T/depot/scripts/copie-injection.sh" poser >/dev/null 2>&1 || {
  echo "   ÉCHEC : la copie ne se pose pas"; exit 1; }
if bash "$T/depot/scripts/copie-injection.sh" verifier >/dev/null 2>&1; then
  echo "   vert ✔"
else
  echo "   ÉCHEC : déjà rouge sans écriture — la preuve serait sans valeur"; exit 1
fi

echo "3. injection — on écrit dans l'oracle de substitution, comme le ferait une injection égarée"
printf 'un octet de plus\n' >> "$T/depot/builds/v3.5.1-iso.2/bp3"
sortie=$(bash "$T/depot/scripts/copie-injection.sh" verifier 2>&1); code=$?
if [ $code -eq 0 ]; then
  echo "   ÉCHEC : le maillon reste vert alors que l'oracle a été écrit — figurant"; echec=1
elif ! printf '%s' "$sortie" | grep -q "$VRAI_ORACLE"; then
  echo "   ÉCHEC : rouge mais sans nommer le fichier touché"; echec=1
elif ! printf '%s' "$sortie" | grep -q "attendu"; then
  echo "   ÉCHEC : rouge mais sans rendre les deux empreintes"; echec=1
else
  echo "   rouge, il nomme le fichier et rend les deux empreintes ✔"
fi

echo "4. retrait — l'oracle de substitution restauré, le maillon doit redevenir VERT"
printf 'binaire de substitution, pas un oracle\n' > "$T/depot/builds/v3.5.1-iso.2/bp3"
if bash "$T/depot/scripts/copie-injection.sh" verifier >/dev/null 2>&1; then
  echo "   vert ✔"
else
  echo "   ÉCHEC : reste rouge après restauration"; echec=1
fi

echo "5. ⛔ le binaire de référence n'a pas été touché par cette preuve"
if [ "$(git hash-object "$VRAI_ORACLE")" = "$EMPREINTE_AVANT" ]; then
  echo "   intact ($EMPREINTE_AVANT) ✔"
else
  echo "   ÉCHEC : l'injection a modifié l'oracle réel — c'est exactement ce qu'elle interdit"; echec=1
fi

echo "─────────────────────────────────────────────"
[ $echec -eq 0 ] && echo "MORSURE PROUVÉE : une écriture sur l'oracle figé fait échouer, et le nomme." \
                || echo "MORSURE NON PROUVÉE — le maillon ne protège pas ce qu'il annonce."
exit $echec
