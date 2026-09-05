#!/usr/bin/env python3
"""Le binaire oracle PRODUIT-IL vraiment depuis le répertoire de lancement publié ?

⛔ POURQUOI CE GARDE EXISTE, ET LE FAIT QUI LE REND NÉCESSAIRE. Mesuré le 2026-09-05, même
commande, même binaire :

    depuis capture-run/   code 0   1 791 octets   « Loading: ../csound_resources/… 6 instruments »
    depuis la racine      code 0   AUCUN fichier  « Failed to open: ../csound_resources/… »

⇒ ⛔ **LE CODE DE SORTIE EST 0 DANS LES DEUX CAS.** Le moteur n'échoue pas, il ne produit rien.
  ⇒ LE VERDICT SE PREND SUR LES OCTETS PRODUITS, JAMAIS SUR LE CODE DE SORTIE. Un garde qui
    jugerait sur le code serait vert en permanence, y compris le jour où la porte casse — c'est
    exactement ce qui a bloqué BPscript le 2026-09-04, sur un banc qui rendait 0 OK / 27 ÉCART.

⛔ ET IL FAUT UNE GRAMMAIRE QUI CHARGE UN FICHIER DE SON. Le moteur cherche `console_strings.json`
au répertoire courant sur un nom nu, ET préfixe en dur `../` au chemin Csound d'un `-so.*`. Une
production sans `-so` n'exerce que la première moitié : elle passerait là où un consommateur qui
sérialise Csound échoue.

⛔ IL COMPTE CE QU'IL A EXAMINÉ ET REFUSE D'AVOIR EXAMINÉ ZÉRO : un fichier de cas déplacé rendrait
zéro production tentée, et un vert sur zéro production ne prouve rien.

⚠️ CE QU'IL GARDE est que MA PORTE FONCTIONNE, pas que je sois fautif : un fichier auxiliaire
déplacé la casse pour mes voisins autant qu'un répertoire de lancement cassé.
"""
import os
import subprocess
import sys
import tempfile

RACINE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LANCEMENT = os.path.join(RACINE, "capture-run")
BINAIRE = os.path.join(RACINE, "builds", "v3.5.1-iso.2", "bp3")

# Un cas par chemin auxiliaire exercé. Les chemins sont relatifs au répertoire de LANCEMENT,
# comme chez un consommateur : c'est la résolution qui est mesurée, pas seulement la production.
CAS = [
    {
        "nom": "chaînes de console + Csound par le `../` gravé en dur",
        "args": ["-gr", "../test-data/-gr.tryKeyMap",
                 "-al", "../test-data/-ho.tryKeyMap",
                 "-so", "../test-data/-so.tryKeyMap"],
        "attendu": "../csound_resources/-cs.tryCsoundObjects",
    },
    {
        "nom": "chaînes de console seules",
        "args": ["-gr", "../test-data/-gr.transposition3",
                 "-se", "../test-data/-se.transposition3"],
        "attendu": None,
    },
]


def main():
    if not os.path.isfile(BINAIRE):
        print(f"✗ LE BINAIRE ORACLE EST ABSENT — {BINAIRE}")
        return 1
    if not os.path.isdir(LANCEMENT):
        print(f"✗ LE RÉPERTOIRE DE LANCEMENT EST ABSENT — {LANCEMENT}")
        return 1

    tentes, rouge = 0, []
    with tempfile.TemporaryDirectory(prefix="gate-production.") as tmp:
        for i, cas in enumerate(CAS):
            manque = [a for a in cas["args"][1::2]
                      if not os.path.exists(os.path.join(LANCEMENT, a))]
            if manque:
                rouge.append(f"{cas['nom']} : auxiliaire introuvable — {', '.join(manque)}")
                continue
            sortie = os.path.join(tmp, f"produit.{i}")
            tentes += 1
            r = subprocess.run([BINAIRE, "produce", *cas["args"], "--seed", "1", "-o", sortie],
                               cwd=LANCEMENT, capture_output=True, text=True, timeout=120)
            octets = os.path.getsize(sortie) if os.path.isfile(sortie) else 0
            # ⛔ LE CODE DE SORTIE N'EST PAS LU POUR TRANCHER : il vaut 0 même quand rien n'est
            #   produit. Il n'est rendu que pour nommer un plantage franc.
            if octets == 0:
                cause = ""
                for l in (r.stdout + r.stderr).splitlines():
                    if "Could not find" in l or "Failed to open" in l:
                        cause = f" — {l.strip()}"
                        break
                rouge.append(f"{cas['nom']} : 0 OCTET PRODUIT (code {r.returncode}){cause}")
                continue
            if cas["attendu"] and cas["attendu"] not in r.stdout:
                rouge.append(f"{cas['nom']} : {octets} octets, mais « {cas['attendu']} » "
                             f"n'a pas été chargé — la moitié Csound n'est pas exercée")
                continue
            print(f"  ✓ {cas['nom']} — {octets} octets")

    print(f"  {tentes} production(s) tentée(s) sur {len(CAS)} cas déclaré(s), "
          f"depuis {os.path.relpath(LANCEMENT, RACINE)}/")
    if tentes == 0:
        print("✗ ZÉRO PRODUCTION TENTÉE — un vert sur zéro production ne prouve rien.")
        return 1
    if rouge:
        print("✗ LA PORTE NE PRODUIT PAS :")
        for r in rouge:
            print(f"    {r}")
        return 1
    print("le binaire oracle produit depuis son répertoire de lancement")
    return 0


if __name__ == "__main__":
    sys.exit(main())
