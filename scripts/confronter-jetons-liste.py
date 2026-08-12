#!/usr/bin/env python3
"""Confronte NOTRE flux de jetons a la liste d'evenements NATIVE, dans la meme execution.

Le flux de jetons est a nous : le moteur amont ne le connait pas, donc aucune confrontation
avec l'amont ne peut l'atteindre. Sa fidelite se mesure autrement — contre une sortie que le
moteur ecrit lui-meme, sur les memes donnees.

Les deux lisent le meme tableau : le serialiseur parcourt p_Instance[k] pour k de 2 a kmax
(TokensOut.c:86), et la liste d'evenements native publie une colonne « k ». La jointure se fait
donc sur l'index d'instance, sans appariement approximatif.

Trois verdicts par jeton :
  - concordant   : meme label, meme debut, meme fin
  - decale       : meme label, instants differents  -> le serialiseur transforme
  - absent       : k present d'un cote seulement    -> le serialiseur selectionne

La selection n'est pas un defaut : le serialiseur ne rend que les jetons sonnants. Ce qu'il
faut savoir, et que cet outil etablit, c'est que la selection est TOUT ce qu'il fait — que les
instants et les labels des jetons rendus sont ceux du moteur, sans arithmetique intermediaire.

  python3 scripts/confronter-jetons-liste.py [--seulement g1 g2] [--tout]
"""
import argparse, csv, json, os, re, subprocess, sys

ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
TD = os.path.join(ROOT, "test-data")
OUT = os.path.join(ROOT, "baseline-native")
RUN = os.path.join(ROOT, "capture-run")
TMP = os.environ.get("BP3_JETONS_TMP") or "/tmp/confronter-jetons"
os.makedirs(TMP, exist_ok=True)

MODE = ("RND", "ORD", "LIN", "SUB", "TEMPLATES", "gram#", "GRAM#")
CONV = {"english": None, "french": "--french", "indian": "--indian"}
SEED = "1"


def clean(src, dst):
    """verbatim de capture.py:52-61."""
    lines = open(src, encoding="utf-8", errors="replace").read().split("\n")
    st = 0
    for i, l in enumerate(lines):
        s = l.strip()
        if s.startswith("//") or re.match(r"^-[a-z]{2}\.", s) or s.startswith(MODE):
            st = i
            break
    open(dst, "w", encoding="utf-8").write(
        "\n".join(l for l in lines[st:] if not l.strip().startswith("INIT:")))


def se_un_item(se_rel, slug):
    """verbatim de capture.py:79-93."""
    p = os.path.join(TD, se_rel)
    try:
        d = json.load(open(p, encoding="utf-8"))
    except Exception:
        return None
    if not isinstance(d.get("MaxItemsProduce"), dict):
        return None
    if d["MaxItemsProduce"].get("value") == "1":
        return p
    d["MaxItemsProduce"]["value"] = "1"
    q = os.path.join(TMP, f"-se.{slug}.1item")
    json.dump(d, open(q, "w", encoding="utf-8"), indent=1, ensure_ascii=False)
    return q


def lire_liste(p):
    """La liste native, indexee par k. Les instants y sont en millisecondes."""
    if not os.path.isfile(p):
        return {}
    par_k = {}
    with open(p, encoding="utf-8", errors="replace", newline="") as f:
        for r in csv.DictReader(f):
            # La colonne « k » est parenthesee dans la sortie native : « (2) ».
            k = (r.get("k") or "").strip().strip("()")
            if not k.isdigit():
                continue
            par_k[int(k)] = dict(label=(r.get("label") or "").strip(),
                                 debut=(r.get("start time") or "").strip(),
                                 fin=(r.get("end time") or "").strip())
    return par_k


def nombre(s):
    try:
        return float(s)
    except Exception:
        return None


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--binaire", default=os.path.join(ROOT, "bp3"))
    ap.add_argument("--seulement", nargs="+")
    ap.add_argument("--tout", action="store_true")
    a = ap.parse_args()

    G = json.load(open(os.path.join(TD, "REGISTRE.json"), encoding="utf-8"))["grammaires"]
    base = {x["grammaire"]: x for x in
            json.load(open(os.path.join(OUT, "baseline.json"), encoding="utf-8"))["grammaires"]}
    sc = json.load(open(os.path.join(OUT, "SCELLE.json"), encoding="utf-8"))
    noms = a.seulement or (sorted(G) if a.tout else sorted(sc["preuve"]["reproductibles_96"]))

    tot = dict(concordants=0, decales=0, jeton_seul=0, liste_seule=0)
    suspects, rapport = [], []
    for i, n in enumerate([x for x in noms if x in G], 1):
        gd, bl = G[n], base.get(n, {})
        gsrc = os.path.join(TD, gd["source"])
        if not os.path.isfile(gsrc):
            continue
        slug = re.sub(r"[^A-Za-z0-9_.-]", "_", n)
        g = os.path.join(TMP, f"g.{slug}")
        clean(gsrc, g)
        cfg = dict(gd.get("auxiliaires") or {})
        etiquette = bl.get("action") or "single"
        verbe = "produce" if etiquette == "single" else "produce-all"
        se_over = se_un_item(cfg["-se"], slug) if ("-se" in cfg and etiquette == "single") else None
        ft, fe = os.path.join(TMP, f"{slug}.tokens"), os.path.join(TMP, f"{slug}.ev")
        for p in (ft, fe):
            if os.path.exists(p):
                os.remove(p)
        args = [a.binaire, verbe, "-e", "-gr", g, "--seed", SEED]
        fl = CONV.get(gd.get("convention")) if gd.get("convention") else None
        if fl:
            args.append(fl)
        for flag, v in cfg.items():
            args += [flag, se_over if (flag == "-se" and se_over) else os.path.join(TD, v)]
        # Les DEUX sorties dans la MEME execution : deux lectures d'un seul calcul, sinon
        # une grammaire non deterministe ferait passer son alea pour une infidelite.
        args += ["-o", os.devnull, "--tokensout", ft, "--eventlistout", fe]
        try:
            subprocess.run(args, capture_output=True, timeout=150, cwd=RUN)
        except subprocess.TimeoutExpired:
            continue

        jetons = json.load(open(ft)) if os.path.isfile(ft) else []
        liste = lire_liste(fe)
        if not jetons or not liste:
            print(f"[{i}] {n:26} sans matiere (jetons={len(jetons)} liste={len(liste)})")
            continue

        # Les deux sorties parcourent p_Instance dans l'ORDRE DES k CROISSANTS. L'appariement
        # se fait donc par avancee monotone, pas par recherche de label : le serialiseur rend
        # un SOUS-ENSEMBLE des instances — il ecarte les silences et les bols non sonnants —
        # et le pointeur cote liste avance jusqu'a retrouver les instants du jeton courant.
        #
        # Le label ne peut PAS servir de cle. La liste native ecrit le prototype tel qu'il est
        # ecrit (EventListfiles.c:152, sans transposition) ; le serialiseur nomme la note apres
        # TransposeKey et ExpandKey. Sur mohanam, transpos = -24 : la liste dit « ga6 », le
        # jeton dit « ga4 », et le fichier MIDI joue 64 — c'est le jeton qui nomme ce qui sonne.
        conc = dec = 0
        details = []
        ks = sorted(liste)
        p = 0
        for t in jetons:
            av = p
            while p < len(ks):
                e = liste[ks[p]]
                d, f = nombre(e["debut"]), nombre(e["fin"])
                if d is not None and f is not None and int(d) == t["start"] and int(f) == t["end"]:
                    break
                p += 1
            if p >= len(ks):
                p = av
                tot["decales"] += 1
                dec += 1
                details.append(dict(jeton=t["token"], debut=t["start"], fin=t["end"],
                                    cause="aucun evenement natif ne porte ces instants,"
                                          " a partir de la position courante"))
                continue
            conc += 1
            tot["concordants"] += 1
            p += 1
        tot["liste_seule"] += len(ks) - conc
        rapport.append(dict(grammaire=n, jetons=len(jetons), evenements=len(liste),
                            concordants=conc, decales=dec,
                            evenements_non_rendus=len(ks) - conc, details=details[:8]))
        marque = "" if dec == 0 else f"  <<< {dec} DECALE(S)"
        if dec:
            suspects.append(n)
        print(f"[{i}] {n:26} jetons={len(jetons):5d} liste={len(liste):5d} "
              f"concordants={conc:5d} non-rendus={len(ks)-conc:5d}{marque}", flush=True)

    dest = os.path.join(TMP, "jetons-contre-liste.json")
    json.dump(dict(total=tot, suspects=suspects, detail=rapport),
              open(dest, "w", encoding="utf-8"), indent=1, ensure_ascii=False)
    print(f"\n=== {tot['concordants']} jeton(s) concordants, {tot['decales']} decale(s)")
    print(f"    {tot['jeton_seul']} jeton(s) sans evenement de meme label")
    print(f"    {tot['liste_seule']} evenement(s) natifs non rendus en jeton (la selection)")
    if suspects:
        print("    grammaires ou un instant differe : " + ", ".join(suspects))
    print(f"\ndetail : {dest}")
    return 1 if tot["decales"] else 0


if __name__ == "__main__":
    sys.exit(main())
