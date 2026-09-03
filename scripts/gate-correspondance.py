#!/usr/bin/env python3
"""Garde : la table de correspondance de la bibliotheque Kanopi reste-t-elle vraie ?

Trois volets, tous echouants :
  1. CHEMIN MORT   — la table reference un fichier qui n existe pas dans la bibliotheque.
  2. ORPHELINE     — une grammaire de scenes/BP3-tests/ n a aucune entree dans la table.
  3. FANTOME       — la table decrit une grammaire absente de la bibliotheque.

Pourquoi les trois : une table qui ment est pire que pas de table, parce qu elle se lit
comme une verite. Le couple grammaire/auxiliaires n est porte par RIEN d autre depuis le
renommage (voir l en-tete de correspondance.json), donc sa corruption est silencieuse.

Sortie 0 = vert. Sortie 1 = rouge.
"""
import json, os, sys

# ⛔ Ce garde lit l ESPACE PUBLIE de kanopi, jamais son arbre de travail : sous enveloppe
# le dossier du voisin N EXISTE PAS, et un arbre de travail n a de toute facon pas de
# reference citable — il bouge sous la mesure.
RACINE_PUBLIEE = "/home/romi/dev/bp/.publie/kanopi"

# ⛔ SEULE PORTE D EPREUVE, et elle NE REND JAMAIS ZERO (code 3 quand tout est vert).
# Un garde qu on peut mettre au vert par sa porte d epreuve n est pas un garde : l espace
# publie etant en lecture seule, l injection travaille sur une copie, et cette copie ne
# doit pas pouvoir certifier un portillon.
EPREUVE = os.environ.get("BP3E_KANOPI_EPREUVE") or ""
RACINE = EPREUVE or RACINE_PUBLIEE
VERT = 3 if EPREUVE else 0

KANOPI = os.path.join(RACINE, "packages", "library")
TABLE = os.path.join(KANOPI, "test-assets", "bp3", "correspondance.json")
DIR_SCENES = os.path.join(KANOPI, "scenes", "BP3-tests")


def regime():
    """La mention de régime, qui dit ce que le verdict vaut.

    L'état publié porte son EMPREINTE : un commit, et la branche dont il vient. C'est ce
    qui rend le verdict citable — il vaut pour cette empreinte-là, et pour elle seule.

    ⛔ ELLE ÉCHOUE PLUTÔT QUE DE S'AFFICHER VIDE. Une mention muette certifierait un
    verdict sans régime — l'inverse exact de ce qu'elle sert.
    """
    chemin = os.path.join(RACINE, "EMPREINTE")
    with open(chemin, encoding="utf-8") as f:
        lignes = [l.strip() for l in f if l.strip()]
    if not lignes:
        raise RuntimeError(f"EMPREINTE vide — {chemin}")
    commit = lignes[0]
    detail = f" ({lignes[1]})" if len(lignes) > 1 else ""
    if EPREUVE:
        return (f"[regime] EPREUVE : copie de kanopi @ {commit}{detail} — "
                f"porte d epreuve, ce chemin ne rend jamais zero")
    return (f"[regime] ETAT PUBLIE : kanopi @ {commit}{detail} — "
            f"lu a l espace publie, jamais a l arbre de travail")


def main():
    # La mention se construit AVANT toute mesure : un verdict ne sort jamais sans elle.
    try:
        mention = regime()
    except (RuntimeError, OSError, IndexError) as e:
        print(f"ROUGE : le regime de lecture est indeterminable — {e}\n"
              f"   un verdict sans regime se lit comme un fait reproductible ; il ne sort pas.")
        return 1
    print(mention)

    # La bibliotheque vit dans un AUTRE depot. Si ce depot n est pas la, il n y a rien a
    # verifier et le dire est honnete. Mais si la bibliotheque EST la et que la table
    # manque, c est le defaut meme que ce garde surveille : rouge, pas de passe-droit.
    if not os.path.isdir(DIR_SCENES):
        print(f"sans objet : bibliotheque Kanopi absente de l espace publie ({DIR_SCENES})")
        return VERT
    if not os.path.isfile(TABLE):
        print(f"ROUGE : la bibliotheque est la mais la table manque — {TABLE}")
        return 1
    t = json.load(open(TABLE, encoding="utf-8"))
    entrees = t["grammaires"]

    morts, orphelines, fantomes = [], [], []

    for e in entrees:
        if not os.path.isfile(os.path.join(KANOPI, e["grammaire"])):
            fantomes.append(f'{e["nom"]} -> {e["grammaire"]}')
        for cle, a in e["auxiliaires"].items():
            if not os.path.isfile(os.path.join(KANOPI, a["chemin"])):
                morts.append(f'{e["nom"]} [{cle}] -> {a["chemin"]}')

    if os.path.isdir(DIR_SCENES):
        decrites = {e["grammaire"].rsplit("/", 1)[-1] for e in entrees}
        for f in sorted(os.listdir(DIR_SCENES)):
            if f.endswith(".gr") and f not in decrites:
                orphelines.append(f)

    rouge = False
    for titre, liste in (("CHEMIN MORT", morts),
                         ("GRAMMAIRE ORPHELINE (aucune entree dans la table)", orphelines),
                         ("ENTREE FANTOME (grammaire absente de la bibliotheque)", fantomes)):
        if liste:
            rouge = True
            print(f"ROUGE — {titre} : {len(liste)}")
            for x in liste[:15]:
                print("   " + x)
            if len(liste) > 15:
                print(f"   … et {len(liste) - 15} autre(s)")

    if not rouge:
        n_aux = sum(len(e["auxiliaires"]) for e in entrees)
        print(f"vert : {len(entrees)} grammaires, {n_aux} references auxiliaires, "
              f"0 chemin mort, 0 orpheline, 0 fantome")
    return 1 if rouge else VERT


if __name__ == "__main__":
    sys.exit(main())
