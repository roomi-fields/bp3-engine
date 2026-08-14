#!/usr/bin/env python3
"""Quels fichiers de reglages restent au format BP2 positionnel, et quels agencements portent-ils ?

La conversion de 2026-07-18 a corrompu 34 fichiers sur 84 parce que l outil supposait UN agencement
alors que le corpus en porte plusieurs. Cet inventaire etablit les agencements AVANT toute ecriture :
il compte les lignes, releve les premieres, et regroupe les fichiers par silhouette.

  python3 scripts/inventaire_reglages_anciens.py [--detail=<fichier>]

Le nom porte des soulignes et non des tirets : convertir-reglages-bp2.py l'importe comme module,
et un tiret rend un module inimportable.
"""
import argparse, json, os, sys
from collections import defaultdict

R = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
TD = os.path.join(R, "test-data")


def anciens():
    out = []
    for f in sorted(os.listdir(TD)):
        if not f.startswith("-se."):
            continue
        p = os.path.join(TD, f)
        try:
            json.load(open(p, encoding="utf-8"))
        except Exception:
            out.append(f)
    return out


def lignes(f):
    return open(os.path.join(TD, f), encoding="utf-8", errors="replace").read().split("\n")


# La table version -> iv est celle du moteur, copiee de -BP3main.h et conservee dans
# docs-developer/format-se-bp2/README.md. Le lecteur d'origine saute des blocs entiers selon iv :
# deux fichiers de versions differentes n'ont ni le meme nombre de champs ni les memes positions.
VERSIONS = ["-", "V.2.1", "V.2.2", "V.2.3", "V.2.4", "V.2.5", "V.2.5.1", "V.2.5.2", "V.2.6",
            "BP2.6.1", "BP2.6.2", "BP2.6.3", "BP2.7", "BP2.7.1", "BP2.7.2", "BP2.7.3", "BP2.7.4",
            "BP2.8.0", "BP2.8.1", "BP2.9.0", "BP2.9.1", "BP2.9.2", "BP2.9.3", "BP2.9.4",
            "BP2.9.5", "BP2.9.6beta", "BP2.9.6", "BP2.9.7beta", "BP2.9.8", "BP2.9.9",
            "BP2.999...", "BP3.0"]


def version(f):
    """La version declaree, et son indice iv. Rendue telle qu'elle est ecrite, jamais devinee.

    Un fichier ecrit par BP3 annonce une COMPATIBILITE, pas sa version d'ecriture — sa premiere
    ligne porte « Bol Processor BP3 ». Le distinguer ici evite de lui appliquer la carte BP2.
    """
    L = lignes(f)
    tete = L[0].strip()
    if "Bol Processor BP3" in tete:
        return "ecrit par BP3", None, tete
    # les fichiers a en-tete de commentaire portent la version sur la ligne suivante
    cand = [tete] + [l.strip() for l in L[1:3]]
    for c in cand:
        c2 = c.lstrip("/ ").strip()
        for i, v in enumerate(VERSIONS):
            if c2 == v:
                return v, i, tete
    # La correspondance se fait sur la version la PLUS LONGUE qui apparait : « BP2.7 » est un
    # prefixe de « BP2.7.1 », et prendre le prefixe donne iv=12 au lieu de 13 — donc un autre
    # agencement, et une conversion fausse dont rien ne signalerait l'erreur.
    meilleur = None
    for c in cand:
        for i, v in enumerate(VERSIONS):
            if v != "-" and v in c:
                if meilleur is None or len(v) > len(meilleur[0]):
                    meilleur = (v, i)
    if meilleur:
        return meilleur[0], meilleur[1], tete
    return None, None, tete


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--detail")
    a = ap.parse_args()

    vieux = anciens()
    if a.detail:
        L = lignes(a.detail)
        print(f"{a.detail} — {len(L)} lignes")
        for i, l in enumerate(L):
            print(f"  {i:3} | {l}")
        return 0

    # Qui les designe, et est-ce dans l assiette scellee ?
    reg = json.load(open(os.path.join(TD, "REGISTRE.json"), encoding="utf-8"))["grammaires"]
    base = {x["grammaire"]: x for x in
            json.load(open(os.path.join(R, "baseline-native", "baseline.json"),
                           encoding="utf-8"))["grammaires"]}
    sc = set(json.load(open(os.path.join(R, "baseline-native", "SCELLE.json"),
                            encoding="utf-8"))["preuve"]["reproductibles_96"])
    porteurs = defaultdict(list)
    for n, g in reg.items():
        se = (g.get("auxiliaires") or {}).get("-se")
        if se in vieux:
            porteurs[se].append(n)

    silhouettes = defaultdict(list)
    print(f"{len(vieux)} fichier(s) au format BP2 positionnel, sur "
          f"{len([f for f in os.listdir(TD) if f.startswith('-se.')])} fichiers -se\n")
    print(f"{'fichier':28} {'version':14} {'iv':>3} {'lignes':>6}  grammaires qui le designent")
    for f in vieux:
        L = lignes(f)
        nb = len(L)
        v, iv, _ = version(f)
        g = porteurs.get(f, [])
        marque = "".join(" ⛔SCELLE" if n in sc else "" for n in g)
        silhouettes[(v, iv)].append((f, nb))
        print(f"{f:28} {str(v):14} {str(iv) if iv is not None else '—':>3} {nb:>6}  "
              f"{', '.join(g) if g else '—'}{marque}")

    print(f"\nversions distinctes : {len(silhouettes)}  — une carte de lecture PAR version")
    for (v, iv), fs in sorted(silhouettes.items(), key=lambda x: (x[0][1] is None, x[0][1])):
        longueurs = sorted({n for _, n in fs})
        print(f"  {str(v):14} iv={str(iv):>4}  {len(fs):2} fichier(s), "
              f"{longueurs[0] if len(longueurs) == 1 else str(longueurs)} lignes"
              f"  — {', '.join(n for n, _ in fs)}")

    designes = sorted({n for g in porteurs.values() for n in g})
    print(f"\n{len(designes)} grammaire(s) designent un ancien : {', '.join(designes)}")
    print(f"dont dans l assiette scellee : "
          f"{sorted(n for n in designes if n in sc) or 'aucune'}")
    print(f"{len(vieux) - len(porteurs)} fichier(s) ancien(s) ne sont designes par AUCUNE grammaire "
          f"du registre")
    return 0


if __name__ == "__main__":
    sys.exit(main())
