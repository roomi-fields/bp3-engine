#!/usr/bin/env python3
"""Convertit un fichier de reglages BP2 positionnel en JSON, par la carte du MOTEUR.

Decision de Romain du 2026-08-14 : on convertit les 22 fichiers restes au format BP2.

⛔ POURQUOI CE CONVERTISSEUR NE DEVINE RIEN, ET POURQUOI LE PRECEDENT AVAIT CORROMPU 40 % DU CORPUS

La conversion se fait en DEUX demi-cartes, toutes deux tirees du code, aucune retranscrite de tete :

  1. POSITION -> VARIABLE DU MOTEUR. L'ordre des appels Read* du lecteur d'origine EST la carte.
     Il est conserve tel quel dans docs-developer/format-se-bp2/LoadSettings.reference.c, extrait
     de source/BP3/SaveLoads1.c au commit e9249594, dernier etat avant le passage au JSON.
     Les blocs `if(iv > N)` et `if(jmax > N)` sont reproduits ici a l'identique : deux fichiers de
     versions differentes n'ont NI le meme nombre de champs NI les memes positions.

  2. VARIABLE DU MOTEUR -> CLE JSON. Le lecteur JSON actuel (SaveLoads1.c, la chaine de
     `strcmp(key,"...")`) donne cette moitie. La cle JSON est le nom de la variable.

Une position dont la variable n'a PAS de cle JSON n'est pas ecrite : le moteur d'aujourd'hui ne la
lit pas, et lui inventer une cle serait ajouter du faux. Une cle sans source dans le fichier ancien
est omise elle aussi : le moteur pose ses defauts en tete de LoadSettings, et une omission les
laisse jouer.

⚠ LE PIEGE DE LA VERSION : « BP2.7 » est un prefixe de « BP2.7.1 ». Prendre le prefixe donne iv=12
au lieu de 13, donc un autre agencement, et une conversion fausse que rien ne signale. La
correspondance se fait sur la version la PLUS LONGUE presente.

  python3 scripts/convertir-reglages-bp2.py --essai            tout convertir en zone d'essai
  python3 scripts/convertir-reglages-bp2.py --ecrire           remplacer les fichiers du corpus
  python3 scripts/convertir-reglages-bp2.py --essai --un -se.Alarm
"""
import argparse, json, os, sys

R = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
TD = os.path.join(R, "test-data")
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from inventaire_reglages_anciens import anciens, lignes, version  # noqa: E402

# Bornes du lecteur lui-meme : ce sont SES clauses, pas des seuils inventes.
#   MaxConsoleTime > 3600 -> 3600           reference:153
#   DeftBufferSize < 100  -> 1000           reference:141
#   C4key hors 2..127     -> 60             reference:240
#   A4freq <= 1           -> 440            reference:243
#   MaxItemsDisplay < 2   -> 20             reference:96
# Bornes de PLAUSIBILITE, appliquees en OMETTANT le champ plutot qu'en ecrivant du faux.
PLAUSIBLE = {
    "Quantization": (1, 2000),
    "Time_res": (1, 1000),
    "Pclock": (1, 100000),
    "Qclock": (1, 100000),
    "NoteConvention": (0, 3),
    "GraphicScaleP": (1, 1000),
    "GraphicScaleQ": (1, 1000),
    "DeftBufferSize": (100, 100000000),
    "MaxConsoleTime": (0, 3600),
    "C4key": (2, 127),
    "A4freq": (1.001, 20000),
}


class Flux:
    """Le fichier vu comme une suite de lignes : chaque lecture en consomme exactement une."""

    def __init__(self, L):
        self.L = L
        self.i = 0
        self.epuise = False

    def brut(self):
        if self.i >= len(self.L):
            self.epuise = True
            return ""
        v = self.L[self.i]
        self.i += 1
        return v

    def ent(self):
        s = self.brut().strip()
        try:
            return int(float(s))
        except ValueError:
            return None

    def flottant(self):
        s = self.brut().strip()
        try:
            return float(s)
        except ValueError:
            return None


def lire(L, iv):
    """Port fidele de LoadSettings.reference.c. Rend un dictionnaire variable -> valeur."""
    f = Flux(L)
    v = {}
    f.brut()                      # ligne de version         reference:43
    f.brut()                      # ligne suivante, ignoree  reference:54
    f.ent()                       # port serie, inutilise    reference:57
    f.brut()                      # ReadOne, non stocke      reference:63
    v["Quantization"] = f.ent()
    v["Time_res"] = f.ent()
    v["_MIDIsetUpTime"] = f.ent()      # pas de cle JSON
    # La cle JSON « Quantize » EST l'ancien QuantizeOK. Etabli par le commit de Bernard qui a
    # introduit le JSON, c21ba55 :  strcmp(key,"Quantize") == 0) QuantizeOK = intvalue;  — la
    # variable a ete renommee ensuite. Ne pas l'ecrire laissait jouer le defaut Quantize = TRUE
    # de LoadSettings, donc RALLUMAIT silencieusement la quantification sur un fichier qui
    # l'eteignait. Signale par bp3-frontend, portillon rouge chez eux.
    v["Quantize"] = f.ent()
    v["Nature_of_time"] = f.ent()
    v["Pclock"] = f.ent()
    v["Qclock"] = f.ent()
    jmax = f.ent()
    v["_jmax"] = jmax
    v["Improvize"] = f.ent()
    # Meme preuve, meme commit c21ba55 :  strcmp(key,"Max_items_produced") == 0) MaxItemsDisplay
    # = intvalue;  — la cle des items produits EST l'ancien MaxItemsDisplay. Valeur ecrite BRUTE :
    # le moteur d'aujourd'hui ecrete lui-meme a 1 (SaveLoads1.c:780) et 57 fichiers sains du
    # corpus portent 0. Son absence cassait aussi capture.py, dont la surcharge a un item exige
    # cette cle.
    v["MaxItemsProduce"] = f.ent()
    v["UseEachSub"] = f.ent()
    v["AllItems"] = f.ent()
    v["DisplayProduce"] = f.ent()
    v["StepProduce"] = f.ent()
    v["TraceMicrotonality"] = f.ent()
    v["TraceProduce"] = f.ent()
    v["PlanProduce"] = f.ent()
    v["DisplayItems"] = f.ent()
    v["ShowGraphic"] = f.ent()
    v["AllowRandomize"] = f.ent()
    v["DisplayTimeSet"] = f.ent()
    v["StepTimeSet"] = f.ent()
    v["TraceTimeSet"] = f.ent()
    if jmax is not None and jmax > 27:
        v["CsoundTrace"] = f.ent()
    f.ent()                            # rtMIDI, ignore       reference:114
    v["ResetNotes"] = f.ent()
    v["ComputeWhilePlay"] = f.ent()
    v["TraceMIDIinteraction"] = f.ent()
    if jmax is not None and jmax > 19:
        v["ResetWeights"] = f.ent()
    if jmax is not None and jmax > 20:
        v["ResetFlags"] = f.ent()
    if jmax is not None and jmax > 21:
        v["ResetControllers"] = f.ent()
    if jmax is not None and jmax > 22:
        v["NoConstraint"] = f.ent()
    if jmax is not None and jmax > 23:
        f.ent()                        # WriteMIDIfile, force a FALSE par le lecteur
    if jmax is not None and jmax > 24:
        f.ent()                        # ShowMessages, pas de cle JSON
    if jmax is not None and jmax > 25:
        f.ent()                        # OutCsound, pas de cle JSON
    if jmax is not None and jmax > 26:
        f.ent()                        # p_oms
    v["SplitTimeObjects"] = f.ent()
    f.ent()                            # SplitVariables, pas de cle JSON
    f.ent()                            # UseTextColor
    k = f.ent()
    v["DeftBufferSize"] = 1000 if (k is None or k < 100) else k     # reference:141
    f.ent()                            # UseGraphicsColor
    f.ent()                            # UseBufferLimit, force a FALSE
    k = f.ent()
    v["MaxConsoleTime"] = None if k is None else min(k, 3600)       # reference:153
    f.ent()                            # graine
    f.ent()                            # Token
    v["NoteConvention"] = f.ent()
    f.ent()                            # StartFromOne, pas de cle JSON
    f.ent()                            # SmartCursor
    v["GraphicScaleP"] = f.ent()
    v["GraphicScaleQ"] = f.ent()
    f.brut()                           # peripherique OMS entrant, ignore   reference:186
    if iv > 5:
        f.brut()                       # peripherique OMS sortant, ignore   reference:189
    if iv > 11:
        f.ent()                        # UseBullet, force a FALSE
    if iv > 7:
        f.ent()                        # PlayTicks, pas de cle JSON
    if iv > 10:
        f.ent()                        # FileSaveMode, force a ALLSAME
        f.ent()                        # FileWriteMode, force a NOW
    if iv > 11:
        f.ent()                        # MIDIfileType, pas de cle JSON
        f.ent()                        # CsoundFileFormat, pas de cle JSON
        f.ent()                        # ProgNrFrom, pas de cle JSON
        x = f.flottant()               # EndFadeOut, retenu seulement si iv > 19
        if iv > 19:
            v["EndFadeOut"] = x
        j = f.ent()
        v["C4key"] = j if (j is not None and 1 < j < 128) else 60   # reference:240
        x = f.flottant()
        v["A4freq"] = x if (x is not None and x > 1.) else 440.0    # reference:243
        v["StrikeAgainDefault"] = f.ent()
    if iv > 15:
        v["DeftVolume"] = f.ent()
        v["VolumeController"] = f.ent()
        v["DeftVelocity"] = f.ent()
        v["DeftPanoramic"] = f.ent()
        v["PanoramicController"] = f.ent()
        v["SamplingRate"] = f.ent()
    wmax = f.ent()                     # tailles de police des fenetres     reference:289
    if wmax is not None and wmax > 0:
        for _ in range(wmax - 1):
            f.ent()
    j = f.ent()
    v["DefaultBlockKey"] = 60 if (j is None or j <= 10 or j > 127) else j    # reference:298
    if iv > 4:
        f.ent()                        # un long, non stocke                reference:304
        for _ in range(12):
            f.ent()                    # NameChoice, pas de cle JSON
    f.ent()                            # un long, non stocke                reference:311
    if iv > 19:
        v["ShowObjectGraph"] = f.ent()
        v["ShowPianoRoll"] = f.ent()
    return v, f


def gabarit():
    """Les metadonnees name/boolean/unit, relevees sur les fichiers DEJA en JSON du corpus."""
    meta = {}
    for f in sorted(os.listdir(TD)):
        if not f.startswith("-se."):
            continue
        try:
            d = json.load(open(os.path.join(TD, f), encoding="utf-8"))
        except Exception:
            continue
        for k, val in d.items():
            if k not in meta and isinstance(val, dict):
                meta[k] = {a: b for a, b in val.items() if a != "value"}
    return meta


def convertir(nom, meta):
    L = lignes(nom)
    ver, iv, tete = version(nom)
    if iv is None:
        return None, f"version indetectable — {tete[:50]}", None
    vals, flux = lire(L, iv)
    reste = len(L) - flux.i
    ecarte = []
    sortie = {}
    for k, val in vals.items():
        if k.startswith("_") or val is None:
            continue
        if k not in meta:
            continue
        if k in PLAUSIBLE:
            bas, haut = PLAUSIBLE[k]
            if not (bas <= val <= haut):
                ecarte.append(f"{k}={val}")
                continue
        txt = (f"{val:.4f}" if isinstance(val, float) else str(val))
        sortie[k] = dict(name=meta[k].get("name", k), value=txt,
                         **{a: b for a, b in meta[k].items() if a != "name"})
    diag = (f"{ver} iv={iv}  {len(sortie)} champ(s), {len(L)} lignes lues jusqu'a {flux.i}, "
            f"{reste} restante(s)" + (f"  ECARTES: {', '.join(ecarte)}" if ecarte else "")
            + ("  ⛔ FLUX EPUISE AVANT LA FIN DE LA CARTE" if flux.epuise else ""))
    return sortie, diag, flux.epuise


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--essai", action="store_true")
    ap.add_argument("--ecrire", action="store_true")
    ap.add_argument("--un")
    a = ap.parse_args()
    if not (a.essai or a.ecrire):
        print("choisir --essai (zone a part) ou --ecrire (le corpus)")
        return 2

    zone = os.path.join(R, "test-data", "converti.en-essai")
    if a.essai:
        os.makedirs(zone, exist_ok=True)

    meta = gabarit()
    cibles = [a.un] if a.un else anciens()
    ok = rate = 0
    print(f"{len(cibles)} fichier(s) — gabarit de metadonnees : {len(meta)} cles relevees "
          f"sur les fichiers deja en JSON\n")
    for nom in cibles:
        sortie, diag, epuise = convertir(nom, meta)
        if sortie is None or epuise:
            rate += 1
            print(f"  ⛔ {nom:28} NON CONVERTI — {diag}")
            continue
        ok += 1
        print(f"  ✓  {nom:28} {diag}")
        dest = os.path.join(zone if a.essai else TD, nom)
        json.dump(sortie, open(dest, "w", encoding="utf-8"), indent=1, ensure_ascii=False)

    print(f"\n{ok} converti(s), {rate} non converti(s), sur {len(cibles)}")
    print(f"ecrits dans {zone if a.essai else TD}")
    return 1 if rate else 0


if __name__ == "__main__":
    sys.exit(main())
