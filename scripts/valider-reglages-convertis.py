#!/usr/bin/env python3
"""Les reglages convertis sont-ils LUS par le moteur, et font-ils PRODUIRE ?

Trois epreuves, dans cet ordre, parce qu'une seule ne suffit pas :

  1. LECTURE  — le moteur charge le fichier sans erreur, avec une grammaire minimale.
  2. PRODUCTION — les grammaires que le registre couple a ces reglages produisent.
  3. TEMPS DE CALCUL — un temps de 0 ou 1 seconde sur une grammaire qui devrait travailler est
     le signe d'une production degeneree : bpscript a refuse une carte champ-vers-ligne pour
     cette raison exacte, et un vert obtenu la-dessus vaudrait moins que son rouge.

  python3 scripts/valider-reglages-convertis.py [--zone test-data/converti.en-essai]
"""
import argparse, json, os, re, subprocess, sys

R = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
TD = os.path.join(R, "test-data")
RUN = os.path.join(R, "capture-run")
BIN = os.path.join(R, "builds", "v3.5.1-iso.2", "bp3")
TMP = os.environ.get("BP3_VALID_TMP") or "/tmp/valider-reglages"
os.makedirs(TMP, exist_ok=True)
MODE = ("RND", "ORD", "LIN", "SUB", "TEMPLATES", "gram#", "GRAM#")
CONV = {"english": None, "french": "--french", "indian": "--indian"}


def clean(src, dst):
    """verbatim de baseline-native/capture.py:52-61."""
    L = open(src, encoding="utf-8", errors="replace").read().split("\n")
    st = 0
    for i, l in enumerate(L):
        s = l.strip()
        if s.startswith("//") or re.match(r"^-[a-z]{2}\.", s) or s.startswith(MODE):
            st = i
            break
    open(dst, "w", encoding="utf-8").write(
        "\n".join(l for l in L[st:] if not l.strip().startswith("INIT:")))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--zone", default=os.path.join(TD, "converti.en-essai"))
    # Une liste separee par des virgules, et non plusieurs arguments : un nom de fichier -se
    # commence par un tiret, et l'analyseur d'arguments le prendrait pour une option.
    ap.add_argument("--liste", help="fichiers -se separes par des virgules ; sans lui, toute la zone")
    a = ap.parse_args()
    # Le moteur tourne depuis capture-run/ : un chemin de zone RELATIF y est introuvable, et le
    # garde rendait « Could not open settings file » sur des fichiers parfaitement lisibles.
    a.zone = os.path.abspath(a.zone)

    fichiers = ([x.strip() for x in a.liste.split(",")] if a.liste
                else sorted(f for f in os.listdir(a.zone) if f.startswith("-se.")))
    reg = json.load(open(os.path.join(TD, "REGISTRE.json"), encoding="utf-8"))["grammaires"]

    # ── 1. LECTURE, avec une grammaire minimale : le fichier se charge-t-il ?
    g = os.path.join(TMP, "-gr.minimal")
    open(g, "w").write("// lecture des reglages\nRND\ngram#1[1] S --> C4 D4 E4\n")
    print(f"══ 1. LECTURE — {len(fichiers)} fichier(s) charges avec une grammaire minimale\n")
    illisibles = []
    for f in fichiers:
        r = subprocess.run([BIN, "produce", "-e", "-gr", g, "--seed", "1",
                            "-se", os.path.join(a.zone, f), "-o", os.devnull],
                           capture_output=True, timeout=120, cwd=RUN)
        txt = (r.stdout + r.stderr).decode("utf-8", "replace")
        mauvais = [l.strip() for l in txt.split("\n")
                   if "Could not" in l or "Error reading" in l or "no 'value' field" in l
                   or "Unsupported" in l or "Could not parse" in l]
        if mauvais or r.returncode != 0:
            illisibles.append(f)
            print(f"  ⛔ {f:28} code={r.returncode}  {mauvais[0][:70] if mauvais else ''}")
        else:
            print(f"  ✓  {f:28} charge")

    # ── 2 et 3. PRODUCTION et TEMPS DE CALCUL, sur les grammaires qui les designent
    couples = [(n, (gd.get("auxiliaires") or {})) for n, gd in reg.items()
               if (gd.get("auxiliaires") or {}).get("-se") in fichiers]
    print(f"\n══ 2. PRODUCTION — {len(couples)} grammaire(s) designent un fichier converti\n")
    muettes = []
    for n, cfg in sorted(couples):
        gd = reg[n]
        src = os.path.join(TD, gd["source"])
        if not os.path.isfile(src):
            print(f"  —  {n:22} source absente du corpus")
            continue
        # La production passe par l'outil du depot, jamais par une invocation refaite ici.
        # Une invocation reecrite a la main est un AUTRE instrument : la mienne rendait zero sur
        # des grammaires que capture.py fait produire, y compris sur des reglages jamais touches.
        # Un validateur qui rend un faux rouge coute plus qu'il ne rapporte.
        env = dict(os.environ, BP3_CAPTURE_ZONE="valider-conversion")
        try:
            r = subprocess.run([sys.executable,
                                os.path.join(R, "baseline-native", "capture.py"), n],
                               capture_output=True, timeout=300, cwd=R, env=env)
        except subprocess.TimeoutExpired:
            print(f"  ⛔ {n:22} DELAI dépassé")
            muettes.append(n)
            continue
        txt = (r.stdout + r.stderr).decode("utf-8", "replace")
        m = re.search(r"jetons=(\d+)\s+mots=(\d+)\s+items=(\d+)", txt)
        nt, nm = (int(m.group(1)), int(m.group(2))) if m else (0, 0)
        mode = re.search(r"mode=(\w+)", txt)
        marque = ""
        if nt == 0 and nm == 0:
            muettes.append(n)
            marque = "   ⛔ NE PRODUIT RIEN"
        print(f"  {'✓ ' if not marque else '⛔'} {n:22} jetons={nt:5d} mots={nm:5d} "
              f"mode={mode.group(1) if mode else '—':6}{marque}")

    print(f"\n{len(fichiers) - len(illisibles)}/{len(fichiers)} fichier(s) lus par le moteur")
    print(f"{len(couples) - len(muettes)}/{len(couples)} grammaire(s) produisent")
    if illisibles:
        print(f"  illisibles : {', '.join(illisibles)}")
    if muettes:
        print(f"  muettes    : {', '.join(muettes)}")
    return 1 if (illisibles or muettes) else 0


if __name__ == "__main__":
    sys.exit(main())
