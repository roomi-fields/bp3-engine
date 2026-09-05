#!/usr/bin/env python3
"""L'empreinte ANNONCEE d'un binaire oracle est-elle celle du binaire REEL ?

⛔ POURQUOI CE GARDE EXISTE. Le binaire natif est la piece dont dependent TOUS les oracles de la
flotte, et son empreinte est ecrite A LA MAIN dans deux documents que personne ne confronte au
disque. Mesure du 2026-09-05 : les quatre empreintes annoncees etaient justes — par soin, pas par
construction. Un voisin qui mesure contre l'empreinte que j'annonce ne verrait jamais l'ecart.
⇒ *Une description juste que rien ne confronte est juste par soin.* Regle tranchee par Romain le
  2026-09-05 : une description de porte publiee est DERIVEE du code, ou confrontee par un garde qui
  refuse. Ce garde est la seconde branche.

⛔ IL COMPTE CE QU'IL A EXAMINE ET REFUSE D'AVOIR EXAMINE ZERO. Un chemin casse, un tableau
renomme, un motif qui cesse d'apparier : chacun rendrait zero couple, et un vert sur zero couple
est un garde qui a cesse de mesurer sans le dire.

⛔ ET IL REFUSE UNE EMPREINTE SANS CHEMIN RESOLVABLE. Une ligne du tableau qui abrege son chemin —
« builds/…auto.50 » — est inconfrontable : elle passerait en silence, et c'est exactement la forme
que ce garde existe pour interdire.
"""
import hashlib
import json
import os
import re
import sys

RACINE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
GEL = os.path.join(RACINE, "baseline-native", "GEL.json")
DOC = os.path.join(RACINE, "ORACLE-BINAIRE.md")

# Le tableau « Etat courant » : | version | md5 | role qui cite `builds/<campagne>` |
LIGNE = re.compile(r"^\|\s*([0-9.]+)\s*\|\s*([0-9a-f]{32})\s*\|(.*)\|\s*$")
CHEMIN = re.compile(r"`(builds/[^`]+)`")


def empreinte(chemin):
    h = hashlib.md5()
    with open(chemin, "rb") as f:
        for bloc in iter(lambda: f.read(1 << 20), b""):
            h.update(bloc)
    return h.hexdigest()


def declarations():
    """Rend (source, md5 annonce, chemin annonce ou None). Le None est un refus, pas un saut."""
    d = []
    with open(GEL, encoding="utf-8") as f:
        b = json.load(f).get("binaire") or {}
    if b.get("md5") or b.get("archive"):
        d.append(("GEL.json", b.get("md5"), b.get("archive")))
    with open(DOC, encoding="utf-8") as f:
        for n, ligne in enumerate(f, 1):
            m = LIGNE.match(ligne.rstrip("\n"))
            if not m:
                continue
            c = CHEMIN.search(m.group(3))
            d.append((f"ORACLE-BINAIRE.md:{n}", m.group(2), c.group(1) if c else None))
    return d


def main():
    decl = declarations()
    rouge = []
    vus = 0
    for source, md5, chemin in decl:
        if not md5 or not chemin:
            rouge.append(f"{source} : empreinte ou chemin manquant — inconfrontable")
            continue
        # Le chemin nomme une campagne ; le binaire s'y appelle `bp3`.
        cible = os.path.join(RACINE, chemin)
        if os.path.isdir(cible):
            cible = os.path.join(cible, "bp3")
        if not os.path.isfile(cible):
            rouge.append(f"{source} : « {chemin} » ANNONCE et absent du disque")
            continue
        vus += 1
        reel = empreinte(cible)
        if reel != md5:
            rouge.append(f"{source} : « {chemin} » annonce {md5}, porte {reel}")
        else:
            print(f"  ✓ {source:26} {chemin}  {md5}")

    print(f"  {vus} binaire(s) confronté(s) sur {len(decl)} déclaration(s) lue(s)")
    if not decl:
        print("✗ AUCUNE DÉCLARATION LUE — le motif n'apparie plus, ce garde a cessé de mesurer.")
        return 1
    if vus == 0:
        print("✗ ZÉRO BINAIRE CONFRONTÉ — un vert sur zéro couple ne prouve rien.")
        return 1
    if rouge:
        print("✗ L'EMPREINTE ANNONCÉE N'EST PAS CELLE DU BINAIRE :")
        for r in rouge:
            print(f"    {r}")
        return 1
    print("empreintes annoncées conformes aux binaires réels")
    return 0


if __name__ == "__main__":
    sys.exit(main())
