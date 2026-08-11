#!/usr/bin/env python3
"""Garde de GEL de la baseline.

Le 2026-08-11 Romain a declare la v14 reference de l ecosysteme et interdit sa
modification. Une consigne portee par le seul souvenir se contourne par distraction :
une recapture lancee par habitude, un champ ajoute pour depanner un voisin. Ce garde
la rend opposable — il compare les empreintes reelles a celles que GEL.json a scellees.

Il ne juge pas le CONTENU de la baseline : gate-baseline.py s en charge. Il juge qu elle
n a pas bouge.

  gel-baseline.py            verifie (defaut ; code 1 si une empreinte a change)
  gel-baseline.py --refaire  regenere les empreintes — degel, decision de Romain
"""
import hashlib, json, os, sys

R = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "baseline-native")
GEL = os.path.join(R, "GEL.json")


def sceau_captures(rep):
    """Une empreinte par fichier ne suffit pas : un fichier RETIRE passerait inapercu.
    On scelle le nom AVEC le contenu, dans l ordre, donc l ensemble."""
    acc = hashlib.sha256()
    noms = sorted(os.listdir(rep))
    for n in noms:
        acc.update(n.encode())
        acc.update(open(os.path.join(rep, n), "rb").read())
    return acc.hexdigest(), len(noms)


def sceau(f):
    return hashlib.sha256(open(os.path.join(R, f), "rb").read()).hexdigest()


def mesure():
    c, n = sceau_captures(os.path.join(R, "captures"))
    return {"baseline.json": sceau("baseline.json"), "SCELLE.json": sceau("SCELLE.json"),
            "captures": c, "captures_n": n}


if not os.path.isfile(GEL):
    print("GEL.json absent : la baseline n est pas gelee.")
    sys.exit(0)

d = json.load(open(GEL, encoding="utf-8"))
vu = mesure()

if "--refaire" in sys.argv:
    d["empreintes"].update(vu)
    json.dump(d, open(GEL, "w", encoding="utf-8"), ensure_ascii=False, indent=1)
    open(GEL, "a").write("\n")
    print("GEL.json regenere sur l etat actuel. Le degel est une decision de Romain :")
    print("annoncez-le a la tour, sans quoi sept agents mesurent contre une reference morte.")
    sys.exit(0)

ecarts = [(k, d["empreintes"].get(k), v) for k, v in vu.items() if d["empreintes"].get(k) != v]
if ecarts:
    print(f"BASELINE GELEE LE {d['decide_le']} PAR {d['decide_par']} — ELLE A BOUGE.")
    for k, att, ok in ecarts:
        print(f"   {k}\n     scellee : {att}\n     actuelle: {ok}")
    print("\n" + d["pour_degeler"])
    sys.exit(1)
print(f"gel v14 intact : {vu['captures_n']} captures, baseline et scelle conformes "
      f"(decide le {d['decide_le']}).")
