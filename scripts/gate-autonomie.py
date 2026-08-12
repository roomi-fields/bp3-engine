#!/usr/bin/env python3
"""Garde d'AUTONOMIE : aucun outil de mesure ne lit hors de ce depot.

Le 2026-08-12, six grammaires du scelle ont cesse de produire sans qu'une ligne ait bouge
ici : capture.py lisait le couple grammaire<->auxiliaires dans le registre de BPscript, et
ils l'avaient allege pendant la nuit — a raison. La reference etait intacte ; l'instrument
ne savait plus la reproduire.

Romain a tranche : le corpus et son couplage vivent ICI, et les mesures se prennent
dessus. Ce garde le rend opposable. Une dependance externe ne se voit pas a l'oeil : elle
marche jusqu'au jour ou le voisin a raison de changer.

Il n'interdit pas de LIRE un depot voisin depuis un script d'analyse jetable — il interdit
qu'un OUTIL DE MESURE en dependent.
"""
import os, re, sys

R = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
# Les outils qui PRODUISENT une mesure d'oracle. Leur entree doit etre entierement locale.
#
# table-correspondance.py n'y est PAS, et c'est un choix motive : il ne mesure rien, il
# LIVRE la table chez kanopi. Sa cible d'ecriture est chez le destinataire par nature, et
# ce garde, qui lit des chemins sans savoir si on les ouvre en lecture ou en ecriture,
# rougirait sur un livrable legitime. Son entree a lui — baseline.json, test-data — est
# deja locale ; gate-correspondance.py verifie ses chemins.
SURVEILLES = ["baseline-native/capture.py", "scripts/gel-baseline.py",
              "scripts/gate-baseline.py"]
# Un chemin absolu qui sort du depot, ou qui remonte au-dessus de lui.
DEHORS = re.compile(r"""["']((?:/home/[^"']*|/Users/[^"']*|\.\./\.\./[^"']*))["']""")

fautes = []
for rel in SURVEILLES:
    p = os.path.join(R, rel)
    if not os.path.isfile(p):
        fautes.append(f"{rel} : surveille mais absent du depot")
        continue
    for n, ligne in enumerate(open(p, encoding="utf-8"), 1):
        code = ligne.split("#", 1)[0]
        for m in DEHORS.finditer(code):
            chemin = m.group(1)
            if os.path.normpath(chemin).startswith(R + os.sep) or os.path.normpath(chemin) == R:
                continue
            fautes.append(f"{rel}:{n} lit hors du depot — {chemin}")

if fautes:
    print(f"AUTONOMIE ROMPUE — {len(fautes)} dependance(s) hors depot :")
    for f in fautes:
        print("   -", f)
    print("\nUn outil de mesure qui lit chez un voisin rend une reference que le voisin peut")
    print("casser sans le savoir. Rapatriez la donnee, ou sortez le fichier de la liste.")
    sys.exit(1)
print(f"autonomie : {len(SURVEILLES)} outils de mesure, aucune lecture hors du depot.")
