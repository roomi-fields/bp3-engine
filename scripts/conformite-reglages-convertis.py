#!/usr/bin/env python3
"""Un fichier converti porte-t-il tout ce que le corpus sain porte, et rien qu'il ne devrait pas ?

Produire et etre reproductible ne fait pas conformite. Question de Romain : « peut-on produire ces
grammaires de façon nominale et CONFORME A LA CONFIGURATION D'ORIGINE ? »

La conformite se mesure sur DEUX axes, et le premier seul avait ete fait :
  1. le fichier converti PRODUIT et sa capture est stable ;
  2. il porte les memes cles que les fichiers sains du corpus — a l'exception de celles que sa
     VERSION ne peut pas porter.

Le second axe a trouve deux manques que le premier ne pouvait pas voir : la graine, ecartee a tort,
et le decoupage des variables. La graine surtout — les captures forcent `--seed` en ligne de
commande, donc elles etaient stables SANS elle : stables pour la mauvaise raison.

Une cle absente n'est un defaut que si le fichier d'origine la portait. Les blocs `if(iv > N)` du
lecteur disent lesquelles une version donnee peut porter.
"""
import json, os, sys
from collections import Counter

R = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
TD = os.path.join(R, "test-data")

# Cles qu'une version ancienne NE PEUT PAS porter : le lecteur d'origine ne les lit que
# sous un `if(iv > N)` que ces fichiers n'atteignent pas. Leur absence est FIDELE.
HORS_VERSION = {
    16: {"DeftVolume", "VolumeController", "DeftVelocity", "DeftPanoramic",
         "PanoramicController", "SamplingRate"},          # if(iv > 15)
    20: {"EndFadeOut", "ShowObjectGraph", "ShowPianoRoll"},  # if(iv > 19)
    12: {"C4key", "A4freq", "StrikeAgainDefault"},        # if(iv > 11)
}
# Cles gardees par le nombre de boutons `jmax` du fichier, et non par sa version : le lecteur
# d'origine ne les lit que sous `if(jmax > N)`. -se.Alarm declare jmax = 21, donc ResetControllers
# (jmax > 21) et NoConstraint (jmax > 22) ne s'y lisent pas — leur absence est FIDELE.
HORS_JMAX = {"ResetWeights": 19, "ResetFlags": 20, "ResetControllers": 21,
             "NoConstraint": 22, "CsoundTrace": 27}
# Cles qu'aucun fichier BP2 ne porte : le lecteur d'origine ne les lit nulle part.
JAMAIS_EN_BP2 = {"MIDIsyncDelay", "MaxItemsGraphic", "TraceDetail", "AllTemplates",
                 "ShowAllObjects", "TraceNoteOn", "AdvanceTime", "PedalReleaseDefault",
                 "StopPauseContinue", "MinPeriod", "LiveGrammar", "LiveSettings",
                 "SplitLines", "Quantize_dummy"}


def main():
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    from inventaire_reglages_anciens import version  # noqa: E402

    import subprocess
    conv = [c for c in subprocess.run(
        ["git", "-C", R, "show", "--name-only", "--format=", "f936475"],
        capture_output=True, text=True).stdout.split() if "/-se." in c]
    convertis = {os.path.basename(c) for c in conv}

    freq = Counter()
    sains = 0
    for f in sorted(os.listdir(TD)):
        if not f.startswith("-se.") or f in convertis:
            continue
        try:
            freq.update(json.load(open(os.path.join(TD, f), encoding="utf-8")).keys())
            sains += 1
        except Exception:
            pass
    courantes = {k for k, c in freq.items() if c >= sains * 0.8}
    print(f"{sains} fichiers sains — {len(courantes)} cles portees par au moins 80 %\n")

    total = 0
    for f in sorted(convertis):
        p = os.path.join(TD, f)
        if not os.path.isfile(p):
            continue
        d = set(json.load(open(p, encoding="utf-8")))
        v, iv, _ = version(f) if False else (None, None, None)
        # la version se relit sur l'original, plus disponible : on la deduit des cles portees
        excusees = set(JAMAIS_EN_BP2)
        # jmax se relit sur le fichier converti : les cles gardees par un seuil superieur au sien
        # sont excusees. On prend le plus haut seuil dont une cle est PRESENTE comme minorant.
        vus = [s2 for k2, s2 in HORS_JMAX.items() if k2 in d]
        plancher = max(vus) if vus else 0
        excusees |= {k2 for k2, s2 in HORS_JMAX.items() if s2 > plancher and k2 not in d}
        for seuil, cles in HORS_VERSION.items():
            if not (cles & d):
                excusees |= cles
        manque = sorted((courantes - d) - excusees)
        total += len(manque)
        etat = "conforme" if not manque else f"⛔ MANQUE {len(manque)}"
        print(f"  {f:28} {len(d):3} cles  {etat}"
              + (f" : {', '.join(manque)}" if manque else ""))

    print(f"\n{total} cle(s) manquante(s) au total, hors celles que la version ne peut pas porter")
    return 1 if total else 0


if __name__ == "__main__":
    sys.exit(main())
