#!/usr/bin/env python3
"""Confronte notre moteur au moteur amont pur, sur les axes que les DEUX savent produire.

Notre arbre porte 15 fichiers d'ecart avec le tag amont (docs-developer/inventaire-des-deltas.md).
La question que cet outil tranche est la seule qui compte pour l'oracle : ces ecarts changent-ils
ce que le moteur PRODUIT ?

L'axe des jetons est hors de portee — il est a nous, l'amont ne le connait pas. La confrontation
porte donc sur les axes NATIFS, presents des deux cotes : sortie texte, liste d'evenements,
fichier MIDI, console. Si les quatre sont identiques octet pour octet sur toute l'assiette, nos
ecarts n'atteignent pas la production, et le flux de jetons est une vue d'un moteur intact.

L'invocation est celle de baseline-native/capture.py — meme nettoyage d'en-tete, meme couplage
lu au REGISTRE, meme surcharge d'un item, meme graine, meme repertoire courant. Seul le binaire
change, et --tokensout cede la place aux axes natifs.

  python3 scripts/confronter-amont.py <binaire-amont> [--assiette|--tout] [--limite N]
"""
import argparse, hashlib, json, os, re, subprocess, sys

ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
TD = os.path.join(ROOT, "test-data")
OUT = os.path.join(ROOT, "baseline-native")
RUN = os.path.join(ROOT, "capture-run")
REG = os.path.join(TD, "REGISTRE.json")
TMP = os.environ.get("BP3_CONFRONT_TMP") or "/tmp/confronter-amont"
os.makedirs(TMP, exist_ok=True)

# --- verbatim de capture.py:41-43 ---
MODE = ("RND", "ORD", "LIN", "SUB", "TEMPLATES", "gram#", "GRAM#")
CONV = {"english": None, "french": "--french", "indian": "--indian"}
SEED = "1"

AXES = ("texte", "evenements", "midi")


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


def bruit(txt):
    """Retire de la console ce qui varie sans que le moteur ait rien produit d'autre.

    Trois sources, toutes exterieures a la production : l'horodatage de construction du
    binaire, les noms des fichiers de sortie — que l'appelant impose, et qui portent la
    marque du cote mesure — et les durees d'execution, qui mesurent la machine.
    """
    txt = txt.replace(TMP, "<tmp>")
    txt = re.sub(r"\.(notre|amont)\.(texte|evenements|midi)\b", r".<cote>.\2", txt)
    txt = re.sub(r"Version ([\d.]+) \([^)]*\)", r"Version \1 (<construit>)", txt)
    txt = re.sub(r"\b\d+(\.\d+)?\s*(ms|sec|seconds|second)\b", "<duree>", txt)
    # « Production time » et « Total computation time » ne s'impriment qu'au franchissement
    # d'une seconde entiere : la ligne apparait ou disparait d'un essai a l'autre sur le
    # MEME binaire (mesure du 2026-08-12, six essais par cote sur Alarm). C'est l'horloge.
    txt = "\n".join(l for l in txt.split("\n")
                    if not re.match(r"^(Production time|Total computation time):", l))
    return txt


def tirer(binaire, action, gpath, cfg, conv, se_over, slug, marque, demandes=AXES):
    """Une execution. `demandes` dit quelles sorties natives sont reclamees.

    Ce choix n'est pas cosmetique. Notre arbre a perdu deux mentions de `EventListOn` dans
    les conditions de PlayThings.c qui decident d'appeler MakeSound. Reclamer le fichier MIDI
    en meme temps que la liste d'evenements arme `WriteMIDIfile`, qui SATISFAIT la condition
    a lui seul et masque la mention manquante. L'ecart ne peut se voir qu'en reclamant la
    liste d'evenements SEULE.
    """
    f = {a: os.path.join(TMP, f"{slug}.{marque}.{a}") for a in demandes}
    for p in f.values():
        if os.path.exists(p):
            os.remove(p)
    args = [binaire, action, "-e", "-gr", gpath, "--seed", SEED]
    fl = CONV.get(conv) if conv else None
    if fl:
        args.append(fl)
    for flag, v in cfg.items():
        args += [flag, se_over if (flag == "-se" and se_over) else os.path.join(TD, v)]
    if "texte" in f:
        args += ["-o", f["texte"]]
    if "evenements" in f:
        args += ["--eventlistout", f["evenements"]]
    if "midi" in f:
        args += ["--midiout", f["midi"]]
    try:
        r = subprocess.run(args, capture_output=True, timeout=120, cwd=RUN)
        console = (r.stdout + r.stderr).decode("utf-8", "replace")
        code = r.returncode
    except subprocess.TimeoutExpired:
        console, code = "", "DELAI"
    empreintes = {}
    for a, p in f.items():
        empreintes[a] = (hashlib.sha256(open(p, "rb").read()).hexdigest()[:16]
                         if os.path.exists(p) else None)
    empreintes["console"] = hashlib.sha256(bruit(console).encode()).hexdigest()[:16]
    return empreintes, console, code


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("amont", help="chemin du binaire amont pur")
    ap.add_argument("--notre", default=os.path.join(ROOT, "bp3"))
    ap.add_argument("--tout", action="store_true", help="les 113 entrees, pas la seule assiette")
    ap.add_argument("--limite", type=int, default=0)
    ap.add_argument("--seulement", nargs="+", help="ne confronter que ces grammaires")
    ap.add_argument("--axes", nargs="+", default=list(AXES), choices=list(AXES),
                    help="sorties natives reclamees ; « evenements » seul isole la condition perdue")
    a = ap.parse_args()

    G = json.load(open(REG, encoding="utf-8"))["grammaires"]
    base = {x["grammaire"]: x for x in
            json.load(open(os.path.join(OUT, "baseline.json"), encoding="utf-8"))["grammaires"]}
    sc = json.load(open(os.path.join(OUT, "SCELLE.json"), encoding="utf-8"))
    noms = sorted(G) if a.tout else sorted(sc["preuve"]["reproductibles_96"])
    if a.seulement:
        noms = [n for n in a.seulement if n in G]
    if a.limite:
        noms = noms[:a.limite]

    print(f"notre moteur : {hashlib.md5(open(a.notre,'rb').read()).hexdigest()}")
    print(f"amont pur    : {hashlib.md5(open(a.amont,'rb').read()).hexdigest()}")
    print(f"{len(noms)} grammaires, axes reclames : {', '.join(a.axes)} + console\n")

    ecarts, absents, rapport = [], [], []
    for i, n in enumerate(noms, 1):
        gd, bl = G[n], base.get(n, {})
        gsrc = os.path.join(TD, gd["source"])
        if not os.path.isfile(gsrc):
            absents.append(n)
            continue
        slug = re.sub(r"[^A-Za-z0-9_.-]", "_", n)
        g = os.path.join(TMP, f"g.{slug}")
        clean(gsrc, g)
        cfg = dict(gd.get("auxiliaires") or {})
        conv = gd.get("convention")
        # L'action est celle que la baseline a deja tranchee : « single » est une etiquette,
        # le verbe du moteur est « produce » avec MaxItemsProduce=1.
        etiquette = bl.get("action") or "single"
        verbe = "produce" if etiquette == "single" else "produce-all"
        se_over = se_un_item(cfg["-se"], slug) if ("-se" in cfg and etiquette == "single") else None

        e_n, c_n, r_n = tirer(a.notre, verbe, g, cfg, conv, se_over, slug, "notre", a.axes)
        e_a, c_a, r_a = tirer(a.amont, verbe, g, cfg, conv, se_over, slug, "amont", a.axes)

        diff = [ax for ax in list(a.axes) + ["console"] if e_n[ax] != e_a[ax]]
        if r_n != r_a:
            diff.append(f"code-de-sortie({r_n} vs {r_a})")
        rapport.append(dict(grammaire=n, action=etiquette, identique=not diff,
                            axes_divergents=diff, notre=e_n, amont=e_a,
                            code_notre=r_n, code_amont=r_a))
        if diff:
            ecarts.append((n, diff))
            open(os.path.join(TMP, f"{slug}.console.notre.txt"), "w").write(c_n)
            open(os.path.join(TMP, f"{slug}.console.amont.txt"), "w").write(c_a)
        print(f"[{i}/{len(noms)}] {n:26} {'identique' if not diff else 'ECART: ' + ','.join(diff)}",
              flush=True)

    dest = os.path.join(TMP, "confrontation.json")
    json.dump(dict(notre_md5=hashlib.md5(open(a.notre, "rb").read()).hexdigest(),
                   amont_md5=hashlib.md5(open(a.amont, "rb").read()).hexdigest(),
                   n=len(rapport), identiques=len([r for r in rapport if r["identique"]]),
                   ecarts=len(ecarts), sources_absentes=absents, detail=rapport),
              open(dest, "w", encoding="utf-8"), indent=1, ensure_ascii=False)

    print(f"\n=== {len(rapport) - len(ecarts)}/{len(rapport)} identiques sur les quatre axes")
    if absents:
        print(f"  {len(absents)} source(s) absente(s) du corpus : {', '.join(absents)}")
    for n, d in ecarts:
        print(f"  ECART  {n:26} {', '.join(d)}")
    print(f"\ndetail : {dest}")
    return 1 if ecarts else 0


if __name__ == "__main__":
    sys.exit(main())
