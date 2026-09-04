#!/usr/bin/env python3
"""Méta-garde ANTI-BYPASS : aucun fichier de test ne doit exister hors du portillon.

Il échoue si un fichier de test est présent sur le disque sans être NI lancé par
`scripts/gate.sh`, NI exclu nommément avec un motif écrit.

Pourquoi ce garde existe, et pourquoi il est écrit ainsi : bpscript a découvert que son
propre méta-garde était un figurant — il balayait par défaut tout le dossier des tests, donc
aucun orphelin n'y était possible par construction, et il ne pouvait jamais mordre. Il n'a
été démasqué qu'en lui injectant un faux fichier. Leçon appliquée ici : ce garde cherche les
fichiers de test PARTOUT dans le dépôt, pas seulement dans le dossier attendu — c'est
justement un test déposé AILLEURS qui est le cas dangereux.

Sa morsure est prouvée par injection, pas supposée : voir `scripts/gate-meta-injection.sh`.
"""
import os, re, sys

R = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
GATE = os.path.join(R, "scripts", "gate.sh")
IGNORE = {".git", "node_modules", "test-data", "captures", "build", "source",
          "build_v3.3.18", "build_v3.3.19", "csrc", "docs-developer"}
MOTIF = re.compile(r"(^|/)(test-|test_)[^/]*\.(js|py|sh|mjs|cjs)$")

texte = open(GATE, encoding="utf-8").read()
# `lancer` et `lancer_seul` sont deux facons de brancher un maillon, pas deux choses. Le motif
# doit les couvrir toutes deux : ecrit `lancer\s+"`, il a cesse de voir onze maillons sur
# vingt-deux le jour ou `lancer_seul` est apparu, SANS ROUGIR — le compte etant vide chez nous,
# la comparaison d ensembles etait vraie sur rien. Un garde se prouve sur la graphie que le code
# ecrit, jamais sur celle qu on croit qu il ecrit.
lances = set(re.findall(r'lancer(?:_seul)?\s+"([^"]+)"', texte))
# une exclusion ne compte QUE si elle est commentée avec un motif à sa suite
exclus = {m.group(1): m.group(2).strip()
          for m in re.finditer(r"^#\s*(\S*test[-_]\S*\.\w+)\s+(\S.*)$", texte, re.M)}

trouves, orphelins = [], []
# Le denominateur qui compte ici n'est PAS le nombre de tests trouves — il peut legitimement
# valoir zero, ce depot n'en portant aucun. C'est le nombre de fichiers PARCOURUS : sans lui,
# un garde qui ne balaie plus rien annonce « aucun orphelin » et reste vert.
fichiers_parcourus = 0
for base, dirs, fics in os.walk(R):
    dirs[:] = [d for d in dirs if d not in IGNORE and not d.startswith(".")]
    for f in fics:
        fichiers_parcourus += 1
        rel = os.path.relpath(os.path.join(base, f), R)
        if not MOTIF.search(rel.replace(os.sep, "/")):
            continue
        trouves.append(rel)
        nom = os.path.splitext(os.path.basename(rel))[0]
        if nom in lances or rel in exclus:
            continue
        orphelins.append(rel)

if orphelins:
    print(f"ANTI-BYPASS : {len(orphelins)} fichier(s) de test hors du portillon, "
          f"sans exclusion motivee :")
    for o in orphelins:
        print("   -", o)
    print("\nSoit vous le branchez dans scripts/gate.sh, soit vous l'excluez EN L'EXPLIQUANT :")
    print("   #  <chemin>   <motif de l'exclusion>")
    sys.exit(1)

if fichiers_parcourus == 0:
    print("ANTI-BYPASS : 0 fichier parcouru — le balayage ne regarde plus rien, "
          "son vert ne prouve rien.")
    sys.exit(1)

print(f"anti-bypass : {fichiers_parcourus} fichier(s) parcouru(s), "
      f"{len(trouves)} fichier(s) de test trouves — "
      f"{len(trouves) - len(exclus)} branches, {len(exclus)} exclus avec motif. Aucun orphelin.")
