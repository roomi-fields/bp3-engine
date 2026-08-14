#!/usr/bin/env python3
"""Un mot de controle a-t-il encore un CORPS, ou seulement une declaration ?

Trois etages, et il faut les trois pour dire « implemente » :
  1. RECONNU    — le mot figure dans la table des controles de performance, et l'analyseur le
                  traite dans CompileProcs.c ;
  2. ENCODE     — Encode.c le traduit en jeton (T<n>) ou pose un champ de regle ;
  3. CONSOMME   — quelqu'un LIT ce jeton ou ce champ ailleurs que pour l'afficher ou le tracer.

L'etage 3 est celui qui decide. Un mot reconnu et encode dont personne ne lit le jeton est un mot
sans corps : il se compile et ne fait rien.

Les fichiers d'affichage et de trace sont exclus des consommateurs : y figurer prouve que le mot
s'IMPRIME, jamais qu'il AGIT.
"""
import os, re, subprocess, sys

SRC = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "source", "BP3")
SRC = os.path.normpath(SRC)

# Les fichiers qui ne font qu'afficher : y etre lu ne prouve aucun effet.
AFFICHAGE = {"DisplayArg.c", "DisplayThings.c", "ConsoleMessages.c", "HTML.c", "Graphic.c"}
# Les fichiers d'analyse : y etre vu prouve la reconnaissance, pas le corps.
ANALYSE = {"CompileProcs.c", "Encode.c", "CompileGrammar.c"}

# mot -> (jeton ou champ de regle, nature)
MOTS = {
    "_capture":       ("T45", "jeton"),
    "_modrate":       ("T23", "jeton"),
    "_pancontrol":    ("T31", "jeton"),
    "_panrate":       ("T30", "jeton"),
    "_part":          ("T46", "jeton"),
    "_pitchrate":     ("T22", "jeton"),
    "_pressrate":     ("T24", "jeton"),
    "_rest":          ("T0",  "jeton"),
    "_srand":         ("T42", "jeton"),
    "_step":          ("T33", "jeton"),
    "_tempo":         ("T43", "jeton"),
    "_volumecontrol": ("T28", "jeton"),
    "_volumerate":    ("T27", "jeton"),
    "_printOn":       ("printon",  "champ de regle"),
    "_printOff":      ("printoff", "champ de regle"),
    "_stepOn":        ("stepon",   "champ de regle"),
    "_stepOff":       ("stepoff",  "champ de regle"),
    "_traceOn":       ("traceon",  "champ de regle"),
    "_traceOff":      ("traceoff", "champ de regle"),
    # _print est une procedure de grammaire : elle pose un champ, pas un jeton.
    "_print":         ("print", "champ de regle"),
    "_script":        ("T13", "jeton"),
}


def cherche(motif):
    r = subprocess.run(["grep", "-rn", "-E", motif] + sorted(
        os.path.join(SRC, f) for f in os.listdir(SRC) if f.endswith((".c", ".h"))),
        capture_output=True, text=True)
    out = []
    for l in r.stdout.split("\n"):
        if not l.strip():
            continue
        chemin, num, texte = l.split(":", 2)
        f = os.path.basename(chemin)
        t = texte.strip()
        if t.startswith("//") or t.startswith("/*") or t.startswith("*"):
            continue
        if "BPPrintMessage" in t or "my_sprintf" in t or "sprintf" in t:
            continue
        out.append((f, int(num), t))
    return out


print(f"perimetre de recherche : tous les .c et .h de {SRC} "
      f"({len([f for f in os.listdir(SRC) if f.endswith(('.c','.h'))])} fichiers)\n")
print(f"{'mot':16} {'porte':14} {'reconnu':8} {'encode':7} {'consomme par'}")
print("-" * 110)
verdicts = {}
for mot, (porte, nature) in sorted(MOTS.items()):
    reconnu = bool(cherche(r"/\* " + re.escape(mot) + r"(\(\))? \*/"))
    if porte is None:
        occ = cherche(re.escape(mot))
        verdicts[mot] = ("A ETABLIR", [f"{f}:{n}" for f, n, _ in occ[:4]] or ["aucune occurrence"])
        print(f"{mot:16} {'?':14} {str(reconnu):8} {'?':7} " + ", ".join(verdicts[mot][1]))
        continue
    if nature == "jeton":
        occ = cherche(r"case +" + porte + r" *:")
    else:
        occ = cherche(r"\." + porte + r"\b|->" + porte + r"\b|\b" + porte + r" *[=><!]")
    encode = any(f in ANALYSE for f, _, _ in occ) or nature == "champ de regle"
    conso = [(f, n) for f, n, _ in occ if f not in AFFICHAGE and f not in ANALYSE]
    verdicts[mot] = ("IMPLEMENTE" if conso else "SANS CORPS",
                     [f"{f}:{n}" for f, n in conso[:4]])
    marque = "" if conso else "   <<< AUCUN CONSOMMATEUR HORS ANALYSE ET AFFICHAGE"
    print(f"{mot:16} {porte:14} {str(reconnu):8} {str(encode):7} "
          + (", ".join(verdicts[mot][1]) if conso else "-") + marque)

print(f"\ndenominateur : {len(MOTS)} mots examines")
for v in ("IMPLEMENTE", "SANS CORPS", "A ETABLIR"):
    n = [m for m, (verdict, _) in verdicts.items() if verdict == v]
    print(f"  {v:12} {len(n):2}  {', '.join(sorted(n))}")
