#!/usr/bin/env python3
"""Sort des entrees nommees de l'assiette scellee.

Une grammaire dont le fichier de reglages DECLARE est illisible par le moteur — vieux format
texte, ou absent du corpus — n'a pas de production qui lui soit propre : la capture qu'on en
tirerait repose sur un reglage emprunte, choisi par nous. Elle sort de la reference.

Le geste retire la ligne de la liste scellee, efface sa capture, et inscrit la cause dans la
ligne de baseline. Il ne rescelle rien : le sceau est un geste separe.

  python3 scripts/sortir-de-l-assiette.py check& koto1 --cause "..." --decide-par Romain
"""
import argparse, json, os, subprocess, sys

R = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
OUT = os.path.join(R, "baseline-native")
BASE = os.path.join(OUT, "baseline.json")
SCELLE = os.path.join(OUT, "SCELLE.json")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("entrees", nargs="+")
    ap.add_argument("--cause", required=True)
    ap.add_argument("--decide-par", required=True)
    a = ap.parse_args()

    base = json.load(open(BASE, encoding="utf-8"))
    sc = json.load(open(SCELLE, encoding="utf-8"))
    lignes = {x["grammaire"]: x for x in base["grammaires"]}
    liste = sc["preuve"]["reproductibles_96"]

    manquantes = [n for n in a.entrees if n not in lignes]
    if manquantes:
        print("inconnues de la baseline :", ", ".join(manquantes))
        return 2

    sortis = []
    for n in a.entrees:
        x = lignes[n]
        cap = x.get("capture")
        if cap and os.path.isfile(os.path.join(OUT, cap)):
            os.remove(os.path.join(OUT, cap))
        # Une ligne qui ne produit pas ne garde AUCUNE mesure : un compteur laisse derriere
        # se relit comme une production, et le garde d'integrite le dit.
        for k in list(x):
            if k not in ("grammaire", "source"):
                del x[k]
        x["action"] = None
        x["modalite"] = None
        x["produit"] = False
        x["raison"] = a.cause
        x["capture"] = None
        x["hors_assiette"] = a.cause
        if n in liste:
            liste.remove(n)
        sortis.append(n)

    sc["preuve"]["reproductibles_96"] = liste
    sc["preuve"]["assiette"] = len(liste)
    sc["preuve"].setdefault("sorties_de_l_assiette", []).append(
        dict(entrees=sortis, cause=a.cause, decide_par=getattr(a, "decide_par"),
             le=subprocess.run(["git", "-C", R, "log", "-1", "--format=%cs"],
                               capture_output=True, text=True).stdout.strip()))
    # Les compteurs d'action se comptent sur TOUTES les lignes, produites ou non : c'est la
    # definition que le garde d'integrite verifie, et cloches1 la rend visible — elle porte
    # une action « single » et ne produit pas (elle depasse le delai).
    G = base["grammaires"]
    base["productibles"] = len([x for x in G if x.get("produit")])
    base["single"] = len([x for x in G if x.get("action") == "single"])
    base["produce_all"] = len([x for x in G if x.get("action") == "produce-all"])
    json.dump(base, open(BASE, "w", encoding="utf-8"), indent=1, ensure_ascii=False)
    json.dump(sc, open(SCELLE, "w", encoding="utf-8"), indent=1, ensure_ascii=False)

    print(f"{len(sortis)} entree(s) sortie(s) : {', '.join(sortis)}")
    print(f"assiette : {len(liste)} grammaires")
    print(f"productibles : {base['productibles']}")
    print("\nLe sceau est perime. Il se refait par : python3 scripts/gel-baseline.py --refaire")
    return 0


if __name__ == "__main__":
    sys.exit(main())
