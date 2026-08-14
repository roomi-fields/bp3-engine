#!/usr/bin/env python3
"""Quelles grammaires tournent sur un reglage AUTRE que celui qu'elles declarent ?

bpscript a mesure que son oracle de koto1 avait ete capture sur -se.koto3, un PROXY pose « en
attendant le correctif » — et que les deux fichiers ne sont pas deux versions du meme reglage :
trente cles absentes de l'un, neuf valeurs communes divergentes. Sa question nous revient : si
d'autres entrees de l'assiette tournent sur un proxy, elles ont le meme ecart devant elles.

Ici on mesure le fait, pas l'intention : la ligne `-se.` en tete de grammaire contre l'auxiliaire
que le REGISTRE retient. Le moteur SAUTE l'en-tete (CompileGrammar.c:250) et ne charge que ce que
la ligne de commande lui donne — l'en-tete est donc un enregistrement de l'interface BP2, sans
effet, et l'ecart ne se voit nulle part a l'execution.

⚠ Un ecart n'est pas un defaut : plusieurs couplages ont ete ARBITRES. Ce qui change aujourd'hui,
c'est que le corpus ne porte plus un seul reglage illisible — un couplage choisi PARCE QUE le
declare ne se lisait pas n'a plus cette raison.
"""
import json, os, re, sys

R = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
TD = os.path.join(R, "test-data")


def declare(src):
    """La ligne `-se.` de l'en-tete, avant la premiere ligne utile."""
    p = os.path.join(TD, src)
    if not os.path.isfile(p):
        return None
    for l in open(p, encoding="utf-8", errors="replace").read().split("\n")[:12]:
        s = l.strip().lstrip("/ ").strip()
        if re.match(r"^-se\.", s):
            return s.split()[0]
    return None


def main():
    reg = json.load(open(os.path.join(TD, "REGISTRE.json"), encoding="utf-8"))["grammaires"]
    base = {x["grammaire"]: x for x in
            json.load(open(os.path.join(R, "baseline-native", "baseline.json"),
                           encoding="utf-8"))["grammaires"]}
    sc = set(json.load(open(os.path.join(R, "baseline-native", "SCELLE.json"),
                            encoding="utf-8"))["preuve"]["reproductibles_96"])

    lisible = {}
    for f in os.listdir(TD):
        if f.startswith("-se."):
            try:
                json.load(open(os.path.join(TD, f), encoding="utf-8"))
                lisible[f] = True
            except Exception:
                lisible[f] = False

    ecarts, sans, memes, absents = [], [], 0, []
    for n in sorted(reg):
        d = declare(reg[n]["source"])
        r = (reg[n].get("auxiliaires") or {}).get("-se")
        if d is None:
            sans.append(n)
        elif d == r:
            memes += 1
        elif d not in lisible:
            absents.append((n, d, r))
        else:
            ecarts.append((n, d, r, lisible[d], n in sc))

    print(f"{len(reg)} grammaires au registre\n")
    print(f"  {memes:3}  déclarent le réglage qui est retenu")
    print(f"  {len(sans):3}  ne déclarent aucun réglage")
    print(f"  {len(absents):3}  déclarent un réglage ABSENT du corpus")
    print(f"  {len(ecarts):3}  déclarent un réglage PRÉSENT et LISIBLE, et tournent sur un AUTRE")
    print()
    if absents:
        print("Déclarent un fichier absent du corpus :")
        for n, d, r in absents:
            print(f"   {n:24} déclare {d:28} retenu {r}")
        print()
    print(f"{'grammaire':24} {'déclaré':28} {'retenu':24} déclaré lisible · assiette")
    for n, d, r, lis, dans in ecarts:
        print(f"   {n:24} {d:28} {str(r):24} {'oui' if lis else 'NON':>3} · "
              f"{'ASSIETTE' if dans else '—'}")
    dans_assiette = [n for n, _, _, _, x in ecarts if x]
    print(f"\n{len(dans_assiette)} de ces écarts sont DANS l'assiette scellée : "
          f"{', '.join(dans_assiette) if dans_assiette else 'aucun'}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
