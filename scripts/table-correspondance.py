#!/usr/bin/env python3
"""Produit la table de correspondance grammaire <-> auxiliaires pour la bibliotheque Kanopi.

Source : baseline-native/baseline.json, champ 'config' de chaque grammaire — la seule
trace ecrite du couple, etablie grammaire par grammaire lors des captures.

Cible : <kanopi>/packages/library/test-assets/bp3/correspondance.json

Ce script VERIFIE chaque chemin sur le disque avant d ecrire. Un chemin mort dans la
table est pire que pas de table : il se lit comme une verite. Si une seule reference
manque, on n ecrit RIEN et on sort en erreur.

Usage : scripts/table-correspondance.py [--verifier-seulement]
"""
import json, os, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
KANOPI = "/home/romi/dev/bp/kanopi/packages/library"
BASELINE = os.path.join(ROOT, "baseline-native", "baseline.json")
CIBLE = os.path.join(KANOPI, "test-assets", "bp3", "correspondance.json")

DIR_SCENES = "scenes/BP3-tests"
DIR_AUX = "test-assets/bp3/commun"

POURQUOI = [
    "CETTE TABLE EST LA SEULE PORTEUSE DU COUPLE GRAMMAIRE <-> AUXILIAIRES. Ne pas la supprimer.",
    "",
    "Avant le versement, la correspondance survivait dans le nom partage : '-gr.trial.mohanam'",
    "allait avec '-se.trial.mohanam'. Le renommage en 'mohanam.gr' — obligatoire pour que le scan",
    "de la bibliotheque voie les fichiers — a DETRUIT cette correspondance. Plus rien dans les",
    "fichiers ne dit lequel va avec lequel.",
    "",
    "ON POURRAIT CROIRE QUE LES .gr LE DISENT : ils s ouvrent sur des lignes comme '-ho.trial.mohanam',",
    "'-cs.trial.mohanam', '-se.trial.mohanam'. C EST UN PIEGE. Le moteur BP3 LIT CES LIGNES POUR LES",
    "SAUTER : source/BP3/CompileGrammar.c:251 porte le commentaire '/* Skip headers */' et chaque ligne",
    "reconnue fait 'goto NEXTLINE' (l. 252-296). Ce sont des vestiges de l ancienne interface graphique.",
    "La seule voie qui charge reellement un auxiliaire est le drapeau de ligne de commande",
    "(ConsoleMain.c:951-963), dont le chemin est arbitraire.",
    "",
    "ET CES EN-TETES SONT PARFOIS FAUSSES — mesure du 2026-07-20 sur les 113 :",
    "  · 7 grammaires declarent un reglage DIFFERENT du reglage reellement utilise",
    "    (ex. 'MyMelody' declare '-se.MyMelody', le vrai est '-se.765432')",
    "  · 13 grammaires utilisent une facette que leur en-tete ne mentionne pas du tout",
    "  · soit 20 grammaires sur 113 ou l en-tete induit en erreur",
    "Pire : les fichiers nommes par ces en-tetes EXISTENT. Reconstruire le couple depuis les en-tetes",
    "donnerait donc une reponse plausible et silencieusement FAUSSE pour une grammaire sur six.",
    "",
    "AUTRE FAIT A NE PAS OUBLIER : l extension '.gr' n est PAS reconnue par le moteur BP3, dont la",
    "table d extensions dit '.bpgr' (source/BP3/-BP3main.h:397). Un '.gr' passe en argument nu est",
    "REFUSE. Tout appelant du binaire natif doit passer les drapeaux explicites ; la chaine Kanopi",
    "passe par son propre frontal, donc ca ne la mord pas — mais c est le genre de fait qu on oublie.",
    "",
    "Chemins RELATIFS a packages/library, pour rester valides ou qu on clone.",
    "Regenerer avec bp3-engine/scripts/table-correspondance.py (verifie chaque chemin avant d ecrire).",
]

# -ho. est l ANCIEN prefixe de l alphabet (FileOldPrefix, -BP3main.h:394) : meme facette que -al.
FACETTES = {"-se": "reglages", "-al": "alphabet", "-cs": "csound",
            "-to": "tonalite", "-so": "objets", "-or": "orchestre"}


def construire():
    base = json.load(open(BASELINE, encoding="utf-8"))
    entrees, absents = [], []

    for g in base["grammaires"]:
        nom = g["grammaire"]
        rel_gr = f"{DIR_SCENES}/{nom}.gr"
        if not os.path.isfile(os.path.join(KANOPI, rel_gr)):
            absents.append(f"grammaire {nom} -> {rel_gr}")

        aux = {}
        for cle, fichier in (g.get("config") or {}).items():
            rel = f"{DIR_AUX}/{fichier}"
            if not os.path.isfile(os.path.join(KANOPI, rel)):
                absents.append(f"{nom} [{cle}] -> {rel}")
            aux[cle] = {"role": FACETTES.get(cle, cle), "chemin": rel, "nom_amont": fichier}

        entrees.append({
            "nom": nom,
            "grammaire": rel_gr,
            "nom_amont": g["source"],
            "auxiliaires": aux,
            "produit": g.get("produit"),
            "convention": g.get("convention"),
        })

    return base, entrees, absents


def main():
    base, entrees, absents = construire()

    if absents:
        print(f"ECHEC : {len(absents)} reference(s) morte(s) — rien n a ete ecrit.", file=sys.stderr)
        for a in absents[:20]:
            print("   " + a, file=sys.stderr)
        return 1

    n_aux = sum(len(e["auxiliaires"]) for e in entrees)
    print(f"verifie : {len(entrees)} grammaires, {n_aux} references auxiliaires, 0 chemin mort")

    if "--verifier-seulement" in sys.argv:
        return 0

    table = {
        "pourquoi_ce_fichier_existe": POURQUOI,
        "produit_par": "bp3-engine/scripts/table-correspondance.py",
        "source": f"bp3-engine/baseline-native/baseline.json (baseline v{base['version']}, {base['figee_le']})",
        "moteur": base["binaire"],
        "racine_des_chemins": "packages/library",
        "n": len(entrees),
        "n_references_auxiliaires": n_aux,
        "grammaires": entrees,
    }
    os.makedirs(os.path.dirname(CIBLE), exist_ok=True)
    with open(CIBLE, "w", encoding="utf-8") as f:
        json.dump(table, f, ensure_ascii=False, indent=1)
        f.write("\n")
    print(f"ecrit : {CIBLE}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
