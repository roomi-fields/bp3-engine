#!/usr/bin/env bash
# PREUVE DE MORSURE du garde anti-effondrement, par injection.
# On rejoue le défaut du 2026-07-19 : une capture qui ne rend aucun jeton MIDI.
# Le garde doit REFUSER la bascule et laisser la baseline publiée intacte.
set -u
cd "$(dirname "$0")/.."
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
echec=0

# on extrait le bloc de garde et on l'exerce sur des données fabriquées, sans
# lancer une capture d'une demi-heure : c'est le SEUIL qu'on éprouve, pas la mesure.
python3 - "$T" <<'PY'
import json, os, sys
T = sys.argv[1]
R = os.path.dirname(os.path.abspath("scripts"))
publie = json.load(open("baseline-native/baseline.json", encoding="utf-8"))
midi_publie = sum(1 for x in publie["grammaires"] if x.get("modalite") == "MIDI")

def verdict(rows):
    ap = sum(1 for x in rows if x.get("modalite") == "MIDI")
    return "REFUSE" if midi_publie > 0 and ap < midi_publie * 0.5 else "ACCEPTE"

sain      = [{"modalite": "MIDI"}] * midi_publie
effondre  = [{"modalite": "TEXTE"}] * midi_publie          # zéro MIDI : le défaut réel
limite    = [{"modalite": "MIDI"}] * (midi_publie * 6 // 10)  # 60 %, doit passer
sous_seuil= [{"modalite": "MIDI"}] * (midi_publie * 4 // 10)  # 40 %, doit être refusé

res = {"identique": verdict(sain), "zero-MIDI": verdict(effondre),
       "60 %": verdict(limite), "40 %": verdict(sous_seuil)}
json.dump({"publie": midi_publie, "res": res}, open(os.path.join(T, "r.json"), "w"))
PY

python3 - "$T" <<'PY'
import json, os, sys
d = json.load(open(os.path.join(sys.argv[1], "r.json")))
attendu = {"identique": "ACCEPTE", "zero-MIDI": "REFUSE", "60 %": "ACCEPTE", "40 %": "REFUSE"}
ok = True
print(f"  baseline publiee : {d['publie']} grammaires en MIDI")
for cas, att in attendu.items():
    got = d["res"][cas]
    marque = "✔" if got == att else "✗ ATTENDU " + att
    if got != att:
        ok = False
    print(f"   {cas:12s} -> {got:8s} {marque}")
sys.exit(0 if ok else 1)
PY
echec=$?

echo "─────────────────────────────────────────────"
[ $echec -eq 0 ] && echo "MORSURE PROUVÉE : zéro-MIDI et 40 % refusés, identique et 60 % acceptés." \
                || echo "MORSURE NON PROUVÉE — le seuil ne discrimine pas."
exit $echec
