#!/usr/bin/env python3
"""Garde d'intégrité de la baseline native.

Ce garde existe parce que la v10 a été publiée avec un en-tête qui annonçait 5 captures
texte structurées alors que ses propres entrées en portaient 8. Personne ne l'a vu pendant
une version entière. La règle qu'on s'était donnée — « les champs font foi, pas le résumé »
— n'était vérifiée par rien. Elle l'est maintenant.

Il ne mesure PAS la justesse musicale (c'est le rôle de la capture) : il vérifie que la
baseline est cohérente AVEC ELLE-MÊME et que ce qu'elle promet existe sur le disque.
"""
import json, os, sys

R = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
P = os.path.join(R, "baseline-native", "baseline.json")
ecarts = []


def verifie(nom, attendu, calcule):
    if attendu != calcule:
        ecarts.append(f"en-tete « {nom} » annonce {attendu}, les entrees en portent {calcule}")


d = json.load(open(P, encoding="utf-8"))
G = d["grammaires"]

verifie("n", d.get("n"), len(G))
verifie("productibles", d.get("productibles"), sum(1 for x in G if x["produit"]))
verifie("single", d.get("single"), sum(1 for x in G if x.get("action") == "single"))
verifie("produce_all", d.get("produce_all"), sum(1 for x in G if x.get("action") == "produce-all"))
verifie("doublons", d.get("doublons"), sum(1 for x in G if x.get("doublon_de")))
verifie("captures_texte_structurees", d.get("captures_texte_structurees"),
        sum(1 for x in G if x.get("texte_structure")))

# Toute capture promise doit exister — une reference vers un fichier absent est un oracle creux.
for x in G:
    c = x.get("capture")
    if c and not os.path.isfile(os.path.join(R, "baseline-native", c)):
        ecarts.append(f"{x['grammaire']} : capture annoncee « {c} » absente du disque")

# Une entree qui « produit » doit avoir produit quelque chose de mesurable.
for x in G:
    if x["produit"] and x["jetons_midi"] == 0 and x["mots_texte"] == 0:
        ecarts.append(f"{x['grammaire']} : marquee produit=true mais 0 jeton ET 0 mot")
    if not x["produit"] and (x["jetons_midi"] or x["mots_texte"]):
        ecarts.append(f"{x['grammaire']} : marquee produit=false mais porte des mesures")

# Les noms doivent etre uniques : deux entrees homonymes rendent la baseline inexploitable.
vus = {}
for x in G:
    vus.setdefault(x["grammaire"], 0)
    vus[x["grammaire"]] += 1
for nom, n in vus.items():
    if n > 1:
        ecarts.append(f"{nom} : {n} entrees portent le meme nom")

if ecarts:
    print(f"baseline {d.get('version')} — {len(ecarts)} incoherence(s) :")
    for e in ecarts:
        print("   -", e)
    sys.exit(1)
print(f"baseline {d.get('version')} coherente : {len(G)} entrees, en-tetes conformes, "
      f"captures presentes.")
