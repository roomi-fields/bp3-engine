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
import json, os, re, sys

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
    # L ecart entre en-tete et couple retenu est RECALCULE a chaque generation, et son exemple
    # avec lui. Fige a la main, il survit a l arbitrage qui le dement : le 2026-08-11 la prose
    # citait encore MyMelody comme preuve qu une en-tete ment, le jour ou son en-tete a ete
    # reconnue juste. Une ligne au present se met a jour, ou elle se calcule.
    "%%ECART_ENTETES%%",
    "",
    "AUTRE FAIT A NE PAS OUBLIER : l extension '.gr' n est PAS reconnue par le moteur BP3, dont la",
    "table d extensions dit '.bpgr' (source/BP3/-BP3main.h:397). Un '.gr' passe en argument nu est",
    "REFUSE. Tout appelant du binaire natif doit passer les drapeaux explicites ; la chaine Kanopi",
    "passe par son propre frontal, donc ca ne la mord pas — mais c est le genre de fait qu on oublie.",
    "",
    "UN AUXILIAIRE QUI NE PORTE PAS LE NOM DE SA GRAMMAIRE PORTE SON MOTIF, mesure cas par cas,",
    "dans 'pourquoi_pas_le_fichier_de_meme_nom'. Trois realites s y cachent, et un remede en bloc",
    "en casserait deux sur trois :",
    "  · le fichier de meme nom est au format 'texte BP2' : le binaire natif l ouvre, en deverse les",
    "    valeurs brutes et ne produit rien. L emprunt est indispensable.",
    "  · il est au format JSON et se charge, mais le couple retenu vient de la reference PHP et rend",
    "    une AUTRE production. Le substituer change la reference.",
    "  · ce n est pas un emprunt : c est une variante de la meme grammaire, declaree par sa propre",
    "    en-tete (ex. 'ShapesInRhythm' declare '-se.ShapesInRhythm.QTM').",
    "SEULS LES REGLAGES CONNAISSENT CES DEUX FORMES. Les 81 alphabets, csound, objets et tonalites",
    "sont du texte par nature : leur champ 'format' dit 'texte', sans opposition BP2/BP3.",
    "LE COMPTE SEUL NE TRANCHE RIEN : sur 'shapes-rhythm' les deux reglages rendent 1952 jetons et",
    "4685 mots — et les 1952 jetons different tous, d une octave et d un placement (C4key 48 vs 60,",
    "Quantization 30 vs 10). Comparer des totaux aurait conclu 'identique'.",
    "",
    "Chemins RELATIFS a packages/library, pour rester valides ou qu on clone.",
    "Regenerer avec bp3-engine/scripts/table-correspondance.py (verifie chaque chemin avant d ecrire).",
]

# -ho. est l ANCIEN prefixe de l alphabet (FileOldPrefix, -BP3main.h:394) : meme facette que -al.
FACETTES = {"-se": "reglages", "-al": "alphabet", "-cs": "csound",
            "-to": "tonalite", "-so": "objets", "-or": "orchestre"}

TD = os.path.join(ROOT, "test-data")   # corpus d origine : c est lui qui porte le format


def format_fichier(cle, chemin):
    """Format MESURE d un auxiliaire.

    Seuls les REGLAGES connaissent deux formes : le binaire natif n accepte que le JSON.
    Presente a un reglage BP2, il l ouvre, en deverse les valeurs brutes sur la sortie
    (65535 / 65535 / 0 / ...) et ne produit rien : la lecture reussit, le reglage ne prend
    pas. C est ce format, et lui seul, qui rend un emprunt indispensable.

    Les autres facettes — alphabet, csound, objets, tonalite — sont du texte par nature :
    les 81 mesurees le sont toutes. Les qualifier de 'BP2' inventerait une opposition.
    """
    try:
        d = json.load(open(chemin, encoding="utf-8"))
    except Exception:
        return "texte BP2" if cle == "-se" else "texte"
    return "JSON BP3" if isinstance(d, dict) and "header" in d else "JSON court"


def motif_du_couple(cle, utilise, stem, origine):
    """Pourquoi ce couple est celui-la, quand l auxiliaire ne porte pas le nom de la grammaire.

    Sans ce motif, un lecteur en aval retrouve le fichier de meme nom, le croit oublie, et
    rouvre la question a chaque passage.
    """
    propre = f"{cle}.{stem}"
    if utilise == propre or not os.path.isfile(os.path.join(TD, propre)):
        return None
    fmt = format_fichier(cle, os.path.join(TD, propre))
    if utilise.startswith(propre + "."):
        return (f"variante de la meme grammaire : '{utilise}' est declare par l en-tete de la "
                f"grammaire elle-meme. '{propre}' ({fmt}) existe et se charge, mais rend une "
                f"autre production.")
    if fmt == "texte BP2":
        return (f"emprunt indispensable : '{propre}' est au format {fmt}, que le binaire natif "
                f"n exploite pas — la grammaire ne produit rien avec lui.")
    return (f"emprunt atteste : '{propre}' ({fmt}) se charge, mais le couple retenu vient de "
            f"{origine} et rend une production differente. Le substituer change la reference.")


def declarations_de_l_entete(stem):
    """Ce que l en-tete de la grammaire amont annonce, par facette.

    Le moteur SAUTE ces lignes (CompileGrammar.c:251) : elles n ont aucun effet sur la
    production. On ne les lit que pour mesurer l ecart avec le couple reellement retenu.
    '-ho.' est l ancien prefixe de l alphabet : les deux nomment la meme facette.
    """
    p = os.path.join(TD, f"-gr.{stem}")
    if not os.path.isfile(p):
        return {}
    tete = open(p, encoding="utf-8", errors="replace").read()
    d = {}
    for pref in ("-se", "-al", "-ho", "-cs", "-to", "-so"):
        m = re.search(rf"^{re.escape(pref)}\.(\S+)", tete, re.M)
        if m:
            d.setdefault("-al" if pref == "-ho" else pref, f"{pref}.{m.group(1)}")
    return d


def meme_contenu(a, b):
    """Deux noms d auxiliaire designent-ils la meme chose ?

    Le nom seul ne suffit pas : '-ho.X' et '-al.X' sont l ancien et le nouveau prefixe de
    l alphabet. Sur les 21 radicaux ou les deux existent, 4 portent le meme contenu octet
    pour octet et 17 different — le prefixe ne dit donc RIEN, ni dans un sens ni dans
    l autre. Seul le contenu tranche.
    """
    if a == b:
        return True
    pa, pb = os.path.join(TD, a), os.path.join(TD, b)
    if not (os.path.isfile(pa) and os.path.isfile(pb)):
        return False
    return open(pa, "rb").read() == open(pb, "rb").read()


def ecart_des_entetes(base):
    """Compte les grammaires dont l en-tete induit en erreur, et rend un exemple vivant."""
    divergentes, muettes, exemple = [], [], None
    for g in base["grammaires"]:
        src = g["source"]
        stem = src[4:] if src.startswith("-gr.") else src
        dec = declarations_de_l_entete(stem)
        cfg = g.get("config") or {}
        ecarts = [k for k, v in cfg.items() if k in dec and not meme_contenu(dec[k], v)]
        if ecarts:
            divergentes.append(g["grammaire"])
            # On prefere illustrer par un ecart de NOM : '-ho.abc' contre '-al.abc' est un
            # vrai ecart de contenu, mais il se lit comme une coquille de prefixe et ferait
            # douter le lecteur de la mesure elle-meme.
            franc = [k for k in ecarts
                     if dec[k].split(".", 1)[-1] != cfg[k].split(".", 1)[-1]]
            if franc and (exemple is None or not exemple[3]):
                exemple = (g["grammaire"], dec[franc[0]], cfg[franc[0]], True)
            elif exemple is None:
                exemple = (g["grammaire"], dec[ecarts[0]], cfg[ecarts[0]], False)
        if any(k not in dec for k in cfg):
            muettes.append(g["grammaire"])
    total = len(set(divergentes) | set(muettes))
    ex = (f" (ex. '{exemple[0]}' declare '{exemple[1]}', le couple retenu porte '{exemple[2]}')"
          if exemple else "")
    return [
        f"ET CES EN-TETES SONT PARFOIS FAUSSES — mesure sur les {len(base['grammaires'])} :",
        f"  · {len(divergentes)} grammaires declarent une facette DIFFERENTE de celle retenue{ex}",
        f"  · {len(muettes)} grammaires utilisent une facette que leur en-tete ne mentionne pas du tout",
        f"  · soit {total} grammaires sur {len(base['grammaires'])} ou l en-tete induit en erreur",
        "Pire : les fichiers nommes par ces en-tetes EXISTENT. Reconstruire le couple depuis les",
        "en-tetes donnerait donc une reponse plausible et silencieusement FAUSSE.",
    ]


def construire():
    base = json.load(open(BASELINE, encoding="utf-8"))
    entrees, absents = [], []

    for g in base["grammaires"]:
        nom = g["grammaire"]
        src = g["source"]
        stem = src[4:] if src.startswith("-gr.") else src
        rel_gr = f"{DIR_SCENES}/{nom}.gr"
        if not os.path.isfile(os.path.join(KANOPI, rel_gr)):
            absents.append(f"grammaire {nom} -> {rel_gr}")

        aux = {}
        for cle, fichier in (g.get("config") or {}).items():
            rel = f"{DIR_AUX}/{fichier}"
            if not os.path.isfile(os.path.join(KANOPI, rel)):
                absents.append(f"{nom} [{cle}] -> {rel}")
            amont = os.path.join(TD, fichier)
            if not os.path.isfile(amont):
                absents.append(f"{nom} [{cle}] amont -> {amont}")
            aux[cle] = {"role": FACETTES.get(cle, cle), "chemin": rel, "nom_amont": fichier,
                        "format": format_fichier(cle, amont) if os.path.isfile(amont) else None}
            motif = motif_du_couple(cle, fichier, stem, g.get("config_source"))
            if motif:
                aux[cle]["pourquoi_pas_le_fichier_de_meme_nom"] = motif

        entrees.append({
            "nom": nom,
            "grammaire": rel_gr,
            "nom_amont": src,
            "auxiliaires": aux,
            "produit": g.get("produit"),
            "convention": g.get("convention"),
            "origine_du_couple": g.get("config_source"),
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

    prose = []
    for ligne in POURQUOI:
        prose.extend(ecart_des_entetes(base) if ligne == "%%ECART_ENTETES%%" else [ligne])

    table = {
        "pourquoi_ce_fichier_existe": prose,
        "produit_par": "bp3-engine/scripts/table-correspondance.py",
        "source": f"bp3-engine/baseline-native/baseline.json (baseline v{base['version']}, {base['figee_le']})",
        # Sans ses conditions, une donnee ne dit pas contre quoi elle a ete prise : elle ne
        # rougit jamais et derive en silence.
        "conditions_de_mesure": {
            "binaire": base["binaire"],
            "empreinte": base.get("binaire_md5"),
            "archive": base.get("binaire_archive"),
            "graine": base.get("seed"),
            "commande": base.get("commande"),
            "scelle": base.get("scelle"),
        },
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
