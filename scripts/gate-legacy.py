#!/usr/bin/env python3
"""Garde ANTI-RÉTROCOMPATIBILITÉ — ordre Romain du 2026-07-19.

Interdiction : on ne garde jamais une voie « legacy / vouée au retrait / le temps de
migrer » en parallèle de la nouvelle. Remplacer X par Y, c'est SUPPRIMER X dans le même
mouvement. Un code marqué `legacy`/`deprecated` qui a encore des appelants vivants n'est
pas en train d'être retiré : il est réutilisé.

Ce que le garde vérifie :

1. AUCUN SYMBOLE MARQUÉ legacy/deprecated N'A D'APPELANT VIVANT, dans le code que ce dépôt
   possède. Le mal réel : `compileBPS` a été gardé « au cas où », réutilisé, puis fait
   évoluer — et la mesure de conformité tournait dessus.

2. LE BINAIRE NATIF N'EST PAS PLUS VIEUX QUE SES SOURCES. Un portillon vert contre un
   artefact périmé ne mesure pas ce qu'il annonce.

Périmètre : `scripts/`, `baseline-native/` — le code que ce dépôt écrit. `source/BP3/` est
le moteur amont de Bernard Bel : ses marqueurs ne sont pas les nôtres, et les policer ici
reviendrait à forker le moteur. Exclu délibérément, pas oublié.
"""
import os, re, subprocess, sys

# normpath OBLIGATOIRE : sans lui R contient « /.. », et le test « ignorer les
# dossiers caches » ci-dessous y voit un « /. » et saute TOUT le depot. C'est la
# faute qui rendait ce garde muet — trouvee par l'injection, pas par relecture.
R = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
POSSEDE = ["scripts", "baseline-native"]
# Exclu NOMMEMENT : ce script porte le leurre en clair pour prouver la morsure du garde.
# Le scanner sans l'exclure, c'est se mordre soi-meme et rendre la preuve impossible.
EXCLUS = {"scripts/gate-legacy-injection.sh", "scripts/gate-legacy.py"}
MARQUE = re.compile(r"\b(deprecated|legacy|obsolete|voué au retrait|voue au retrait)\b", re.I)
# un symbole déclaré sur la même ligne ou la suivante qu'un marqueur
DECL = re.compile(r"\b(?:int|void|char|long|double|float|def|function|const)\s+\**(\w+)\s*\(")
ecarts = []

# ── 1. symboles marqués legacy portant un appelant vivant ────────────────────
suspects = {}
# Un garde compte ce qu'il a examine : sans denominateur, « rien trouve » ne se distingue pas
# de « rien regarde ». Le zero se dit et se justifie.
fichiers_vus = 0
for d in POSSEDE:
    for base, _, fics in os.walk(os.path.join(R, d)):
        if any(p.startswith(".") for p in base.split(os.sep) if p):
            continue
        for f in fics:
            if not f.endswith((".c", ".h", ".py", ".sh", ".js")):
                continue
            p = os.path.join(base, f)
            if os.path.relpath(p, R) in EXCLUS:
                continue
            fichiers_vus += 1
            lignes = open(p, encoding="utf-8", errors="replace").read().split("\n")
            for i, l in enumerate(lignes):
                if not MARQUE.search(l):
                    continue
                for j in (i, i + 1, i + 2):
                    if j < len(lignes):
                        m = DECL.search(lignes[j])
                        if m:
                            # on memorise la ligne EXACTE de la declaration (j+1), pas celle
                            # du marqueur : sinon la tolerance necessaire pour les relier
                            # avale un appelant voisin. C'est la 3e faute revelee par
                            # l'injection — un appelant a 2 lignes du marqueur passait.
                            suspects[m.group(1)] = (f"{os.path.relpath(p, R)}:{i+1}", j + 1)
                            break

for sym, (ou, ligne_decl) in suspects.items():
    # grep -E : sans -E, « \s » et « ( » ne sont pas interpretes et le motif ne matche JAMAIS.
    # C'est la premiere faute qu'a revelee l'injection : le garde etait un figurant.
    r = subprocess.run(["grep", "-rnE", "--include=*.c", "--include=*.h", "--include=*.py",
                        "--include=*.sh", "--include=*.js", rf"\b{re.escape(sym)}[[:space:]]*\(",
                        *[os.path.join(R, d) for d in POSSEDE]],
                       capture_output=True, text=True)
    # On exclut LA LIGNE de declaration, pas le FICHIER entier : un appelant vivant loge
    # tres souvent dans le meme fichier que le symbole au retrait. Exclure le fichier,
    # c'etait la seconde faute revelee par l'injection.
    fic_decl = ou.rsplit(":", 1)[0]
    appels = []
    for l in r.stdout.split("\n"):
        if not l.strip():
            continue
        try:
            chemin, num, _ = l.split(":", 2)
        except ValueError:
            continue
        rel = os.path.relpath(chemin, R)
        if rel in EXCLUS:
            continue
        # la declaration elle-meme : meme fichier, a une ligne ou deux du marqueur
        if rel == fic_decl and int(num) == ligne_decl:
            continue
        appels.append(l)
    if appels:
        ecarts.append(f"« {sym} » est marqué au retrait ({ou}) mais garde "
                      f"{len(appels)} appelant(s) vivant(s) :")
        for a in appels[:4]:
            ecarts.append("      " + a.strip()[:110])

# ── 2. le binaire NATIF ne doit pas etre PLUS VIEUX que ses sources ──
# Ajoute le 2026-07-19 apres m'etre fait prendre : un portillon vert contre un artefact
# perime ne mesure pas ce qu'il annonce. L'oracle est le binaire natif, et lui seul.
ARTEFACTS = [("bp3", [os.path.join("source", "BP3")])]
for art, sources in ARTEFACTS:
    pa = os.path.join(R, art)
    if not os.path.isfile(pa):
        ecarts.append(f"l'artefact « {art} » est ABSENT — rien a mesurer, reconstruisez")
        continue
    t_art = os.path.getmtime(pa)
    plus_recents = []
    for d in sources:
        for base, _, fics in os.walk(os.path.join(R, d)):
            for f in fics:
                if f.endswith((".c", ".h")) and os.path.getmtime(os.path.join(base, f)) > t_art:
                    plus_recents.append(os.path.relpath(os.path.join(base, f), R))
    if plus_recents:
        ecarts.append(f"« {art} » est plus VIEUX que {len(plus_recents)} de ses sources "
                      f"(ex. {plus_recents[0]}) — reconstruisez, sinon les gardes mesurent "
                      f"un artefact perime")

if fichiers_vus == 0:
    print("ANTI-RÉTROCOMPAT : 0 fichier examine dans " + ", ".join(POSSEDE)
          + " — un garde qui n a rien regarde ne prouve rien.")
    sys.exit(1)

if ecarts:
    print(f"ANTI-RÉTROCOMPAT : {len(ecarts)} probleme(s) sur {fichiers_vus} fichier(s) examine(s) :")
    for e in ecarts:
        print("   -", e)
    sys.exit(1)
print(f"anti-retrocompat : {fichiers_vus} fichier(s) examine(s) dans {', '.join(POSSEDE)}, "
      f"{len(suspects)} symbole(s) marque(s) au retrait, aucun avec appelant vivant ; "
      f"le binaire natif est plus recent que ses sources.")
