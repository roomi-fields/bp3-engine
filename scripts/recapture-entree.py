#!/usr/bin/env python3
"""Refait la capture d'UNE poignee d'entrees nommees, et d'elles seules.

La baseline v14 est gelee. Un degel total pour corriger deux entrees ferait bouger 96
references sous les mesures de sept agents. Cet outil applique un degel PARTIEL :

  1. il empreinte toutes les captures publiees AVANT ;
  2. il refait les entrees nommees, une par une, par la chaine normale (capture.py) ;
  3. il empreinte APRES et REFUSE si un fichier hors de la liste a bouge — la baseline est
     alors restauree telle qu'elle etait ;
  4. il ne rescelle rien : le nouveau sceau est un geste separe, de Romain.

Le couple grammaire <-> auxiliaires vient du REGISTRE, comme partout ailleurs. Changer la
capture d'une entree passe donc par le REGISTRE d'abord, cet outil ensuite.

  python3 scripts/recapture-entree.py PP --autorise-par Romain --motif "reglage emprunte"
"""
import argparse, hashlib, json, os, shutil, subprocess, sys

R = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
OUT = os.path.join(R, "baseline-native")
PUB = os.path.join(OUT, "captures")
BASE = os.path.join(OUT, "baseline.json")
ZONE = "captures.recapture-unitaire"
FRAIS = os.path.join(OUT, ZONE)


def empreintes():
    """Nom ET contenu, en ordre alphabetique : un fichier RETIRE doit se voir aussi."""
    h = {}
    for f in sorted(os.listdir(PUB)):
        h[f] = hashlib.sha256(open(os.path.join(PUB, f), "rb").read()).hexdigest()
    return h


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("entrees", nargs="+")
    ap.add_argument("--autorise-par", required=True,
                    help="qui a leve le gel pour ces entrees")
    ap.add_argument("--motif", required=True)
    a = ap.parse_args()

    base = json.load(open(BASE, encoding="utf-8"))
    lignes = {x["grammaire"]: i for i, x in enumerate(base["grammaires"])}
    for n in a.entrees:
        if n not in lignes:
            print(f"« {n} » n'est pas une entree de la baseline.")
            return 2

    avant = empreintes()
    sauve = PUB + ".avant-recapture"
    if os.path.isdir(sauve):
        shutil.rmtree(sauve)
    shutil.copytree(PUB, sauve)

    touches, echecs, neuves = [], [], {}
    lg = os.path.join(OUT, "ligne.json")
    for n in a.entrees:
        shutil.rmtree(FRAIS, ignore_errors=True)
        if os.path.exists(lg):
            os.remove(lg)
        env = dict(os.environ, BP3_CAPTURE_ZONE=ZONE)
        r = subprocess.run([sys.executable, "baseline-native/capture.py", n, "--ligne", lg],
                           cwd=R, capture_output=True, text=True, env=env, timeout=600)
        print(r.stdout.strip()[-400:])
        produits = sorted(os.listdir(FRAIS)) if os.path.isdir(FRAIS) else []
        if not produits or not os.path.isfile(lg):
            echecs.append((n, "aucune capture produite"))
            continue
        neuves[n] = json.load(open(lg, encoding="utf-8"))
        os.remove(lg)
        # L'ancienne capture de cette entree sort, quel que soit son axe : une entree qui
        # passe de MIDI a TEXTE laisserait sinon son ancien fichier derriere elle.
        vieux = base["grammaires"][lignes[n]].get("capture")
        if vieux and os.path.isfile(os.path.join(OUT, vieux)):
            os.remove(os.path.join(OUT, vieux))
        # capture.py ecrit les DEUX axes ; seul celui que la ligne retient est publie.
        garde = os.path.basename(neuves[n]["capture"]) if neuves[n].get("capture") else None
        for f in produits:
            if f == garde:
                shutil.copy2(os.path.join(FRAIS, f), os.path.join(PUB, f))
        touches.append((n, [garde] if garde else []))
    shutil.rmtree(FRAIS, ignore_errors=True)

    apres = empreintes()
    attendus = set()
    for n, produits in touches:
        attendus.update(produits)
        v = base["grammaires"][lignes[n]].get("capture")
        if v:
            attendus.add(os.path.basename(v))
    derive = sorted((set(avant) | set(apres)) - attendus
                    - {f for f in avant if avant.get(f) == apres.get(f)})
    if derive:
        shutil.rmtree(PUB)
        os.rename(sauve, PUB)
        print(f"\nRECAPTURE ANNULEE — {len(derive)} capture(s) hors de la liste ont bouge :")
        for f in derive[:20]:
            print("   -", f)
        print("La baseline publiee est restauree telle qu'elle etait.")
        return 1
    shutil.rmtree(sauve)

    for n, _ in touches:
        base["grammaires"][lignes[n]] = neuves[n]

    base.setdefault("degels_partiels", []).append(
        dict(entrees=a.entrees, autorise_par=getattr(a, "autorise_par"), motif=a.motif,
             le=subprocess.run(["git", "-C", R, "log", "-1", "--format=%cs"],
                               capture_output=True, text=True).stdout.strip()))
    json.dump(base, open(BASE, "w", encoding="utf-8"), indent=1, ensure_ascii=False)

    print(f"\n{len(touches)} entree(s) refaite(s), aucune autre capture n'a bouge.")
    for n, p in touches:
        print(f"   {n} -> {', '.join(p)}")
    for n, why in echecs:
        print(f"   ECHEC {n} : {why}")
    print("\nLe sceau est perime. Il se refait par Romain :")
    print("   python3 scripts/gel-baseline.py --refaire")
    return 1 if echecs else 0


if __name__ == "__main__":
    sys.exit(main())
