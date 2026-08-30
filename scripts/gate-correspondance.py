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
import json, os, subprocess, sys

KANOPI = "/home/romi/dev/bp/kanopi/packages/library"
DEPOT_VOISIN = "/home/romi/dev/bp/kanopi"
TABLE = os.path.join(KANOPI, "test-assets", "bp3", "correspondance.json")
DIR_SCENES = os.path.join(KANOPI, "scenes", "BP3-tests")


def regime():
    """La mention de régime, qui dit ce que le verdict vaut.

    Ce garde lit l'ARBRE DE TRAVAIL d'un voisin : son verdict change quand ce voisin
    écrit, sans qu'une ligne bouge ici. Un rouge pris dans sa fenêtre d'écriture n'est
    pas reproductible, et inscrit à un registre il se lit comme un fait.

    ⛔ ELLE ÉCHOUE PLUTÔT QUE DE S'AFFICHER VIDE. Une mention muette certifierait un
    verdict sans régime — l'inverse exact de ce qu'elle sert.
    """
    def git(*a):
        r = subprocess.run(["git", "-C", DEPOT_VOISIN, *a], capture_output=True, text=True)
        if r.returncode != 0:
            raise RuntimeError(f"git {' '.join(a)} → {r.stderr.strip() or r.returncode}")
        return r.stdout.strip()

    publie = git("rev-parse", "--short", "@{u}")
    # ⛔ `--no-optional-locks` sur CE SEUL appel : `status` rafraîchit l'index de kanopi et y
    # prend `.git/index.lock`, ce que le `rev-parse` de la ligne au-dessus ne fait pas. Le poser
    # dans le helper le rendrait décoratif sur l'autre appel. Mesuré : 1 verrou → 0, sortie
    # identique sur un arbre SALE à index périmé.
    sale = "~sale" if git("--no-optional-locks", "status", "--porcelain") else ""
    return f"[regime] SOURCE VIVE : kanopi @ {publie}{sale} — arbre de travail lu directement"


def main():
    # La mention se construit AVANT toute mesure : un verdict ne sort jamais sans elle.
    try:
        mention = regime()
    except (RuntimeError, OSError) as e:
        print(f"ROUGE : le regime de lecture est indeterminable — {e}\n"
              f"   un verdict sans regime se lit comme un fait reproductible ; il ne sort pas.")
        return 1
    print(mention)

    # La bibliotheque vit dans un AUTRE depot. Si ce depot n est pas la, il n y a rien a
    # verifier et le dire est honnete. Mais si la bibliotheque EST la et que la table
    # manque, c est le defaut meme que ce garde surveille : rouge, pas de passe-droit.
    if not os.path.isdir(DIR_SCENES):
        print(f"sans objet : bibliotheque Kanopi absente de cette machine ({DIR_SCENES})")
        return 0
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
    return 1 if rouge else 0


if __name__ == "__main__":
    sys.exit(main())
