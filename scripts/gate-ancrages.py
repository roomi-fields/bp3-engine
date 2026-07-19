#!/usr/bin/env python3
"""Garde SYNCHRO NATIF-SEUL : nos ajouts doivent survivre aux montées de version amont.

Le 2026-07-19, la montée du moteur en v3.4.7 a fait disparaître l'appel au sérialiseur
`--tokensout`. Il vivait dans `source/BP3/PlayThings.c`, un fichier **natif-seul** : mon
inventaire des modifications locales ne couvrait que `csrc/bp3/`, et j'ai repris quatre
fichiers natif-seul tels quels depuis l'amont pour corriger une erreur de compilation.
L'appel est parti avec.

Le binaire construisait, tournait, sortait `Errors: 0` — et n'émettait plus rien. Une
recapture entière a rendu 0 jeton MIDI sur 113 grammaires avant que le défaut ne se voie.

J'avais NOMMÉ ce risque une heure avant de tomber dedans. Nommer un risque ne le traite pas :
il faut un mécanisme qui morde. Le voici. Un commentaire dans le fichier ne suffit pas —
c'est de la prose, et la prose ne bloque pas une synchronisation.
"""
import json, os, sys

R = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
MANIFESTE = os.path.join(R, "scripts", "ancrages-locaux.json")
ecarts = []

for chemin, spec in json.load(open(MANIFESTE, encoding="utf-8")).items():
    if chemin.startswith("_"):
        continue
    p = os.path.join(R, chemin)
    if not os.path.isfile(p):
        ecarts.append(f"« {chemin} » a DISPARU — il portait : {spec['pourquoi']}")
        continue
    contenu = open(p, encoding="utf-8", errors="replace").read()
    perdus = [m for m in spec["marqueurs"] if m not in contenu]
    if perdus:
        ecarts.append(f"« {chemin} » a perdu {perdus} — probablement repris tel quel depuis "
                      f"l'amont.\n      Ce que ça casse : {spec['pourquoi']}")

if ecarts:
    print(f"ANCRAGES LOCAUX : {len(ecarts)} perte(s) :")
    for e in ecarts:
        print("   -", e)
    print("\nRestaurez l'ajout local, puis relancez. Ne retirez une entrée du manifeste que si")
    print("l'ajout a été supprimé VOLONTAIREMENT.")
    sys.exit(1)

n = sum(1 for k in json.load(open(MANIFESTE, encoding="utf-8")) if not k.startswith("_"))
print(f"ancrages locaux : {n} fichier(s) verifie(s), tous nos ajouts sont en place.")
