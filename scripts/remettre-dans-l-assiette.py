#!/usr/bin/env python3
"""Remet des entrees dans l'assiette scellee, quand la cause de leur sortie est levee.

L'inverse de scripts/sortir-de-l-assiette.py. Une entree sortie pour une cause NOMMEE peut y
revenir quand cette cause tombe — mais elle n'y revient pas sur la disparition de la cause seule :
l'assiette porte les REPRODUCTIBLES, et il faut mesurer qu'aucune SECONDE cause ne se cachait
derriere la premiere.

Le geste refuse donc une entree qui :
  · ne figure pas dans la baseline, ou n'y produit pas ;
  · n'a pas de capture sur le disque ;
  · est deja dans la liste.

Il ne rescelle rien : le sceau est un geste separe, et il s'annonce a la tour.

  python3 scripts/remettre-dans-l-assiette.py koto1 koto2 \\
      --cause "..." --decide-par Romain --mesure "5 captures identiques par grammaire"
"""
import argparse, json, os, subprocess, sys

R = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
OUT = os.path.join(R, "baseline-native")
BASE = os.path.join(OUT, "baseline.json")
SCELLE = os.path.join(OUT, "SCELLE.json")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("entrees", nargs="+")
    ap.add_argument("--cause", required=True, help="la cause de sortie qui est levee")
    ap.add_argument("--decide-par", required=True)
    ap.add_argument("--mesure", help="ce qui a ete mesure pour ecarter une seconde cause")
    ap.add_argument("--recompter", action="store_true",
                    help="recalculer les seuls compteurs d'en-tete de baseline.json")
    a = ap.parse_args()

    base = json.load(open(BASE, encoding="utf-8"))
    sc = json.load(open(SCELLE, encoding="utf-8"))
    lignes = {x["grammaire"]: x for x in base["grammaires"]}
    liste = sc["preuve"]["reproductibles_96"]

    # Les compteurs d'en-tete se comptent sur TOUTES les lignes, produites ou non : c'est la
    # definition que gate-baseline.py verifie et celle de capture.py. Les laisser derriere une
    # remise en assiette rend le garde d'integrite rouge, et il a raison — l'en-tete annoncerait
    # un compte que les entrees ne portent pas.
    def recompter():
        G = base["grammaires"]
        base["productibles"] = len([x for x in G if x.get("produit")])
        base["single"] = len([x for x in G if x.get("action") == "single"])
        base["produce_all"] = len([x for x in G if x.get("action") == "produce-all"])
        return base["productibles"], base["single"], base["produce_all"]

    if a.recompter:
        p, s1, pa = recompter()
        json.dump(base, open(BASE, "w", encoding="utf-8"), indent=1, ensure_ascii=False)
        print(f"compteurs recalcules : productibles={p} single={s1} produce_all={pa}")
        return 0
    if not a.mesure:
        print("--mesure est requis pour une remise en assiette")
        return 2

    refus = []
    for n in a.entrees:
        x = lignes.get(n)
        if x is None:
            refus.append(f"{n} : inconnue de la baseline")
        elif n in liste:
            refus.append(f"{n} : deja dans l'assiette")
        elif not x.get("produit"):
            refus.append(f"{n} : ne produit pas")
        elif not x.get("capture") or not os.path.isfile(os.path.join(OUT, x["capture"])):
            refus.append(f"{n} : aucune capture sur le disque")
    if refus:
        print("REFUSE — une entree au moins ne remplit pas les conditions :")
        for r in refus:
            print("   -", r)
        return 2

    for n in a.entrees:
        liste.append(n)
        x = lignes[n]
        x.pop("hors_assiette", None)
    liste.sort()

    recompter()
    sonnantes = len([n for n in liste if lignes[n].get("modalite") == "MIDI"])
    texte = len([n for n in liste if lignes[n].get("modalite") == "TEXTE"])
    sc["preuve"]["reproductibles_96"] = liste
    sc["preuve"]["assiette"] = len(liste)
    sc["preuve"].setdefault("retours_dans_l_assiette", []).append(
        dict(entrees=sorted(a.entrees), cause_levee=a.cause,
             mesure=a.mesure, decide_par=getattr(a, "decide_par"),
             le=subprocess.run(["git", "-C", R, "log", "-1", "--format=%cs"],
                               capture_output=True, text=True).stdout.strip()))
    json.dump(base, open(BASE, "w", encoding="utf-8"), indent=1, ensure_ascii=False)
    json.dump(sc, open(SCELLE, "w", encoding="utf-8"), indent=1, ensure_ascii=False)

    print(f"{len(a.entrees)} entree(s) remise(s) : {', '.join(sorted(a.entrees))}")
    print(f"assiette : {len(liste)} grammaires — {sonnantes} sonnantes, {texte} en texte")
    print("\nLe sceau est perime. Il se refait par : python3 scripts/gel-baseline.py --refaire")
    print("et il s'ANNONCE a la tour : c'est la reference de plusieurs agents.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
