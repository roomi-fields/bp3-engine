#!/usr/bin/env python3
"""Baseline v4 — capture PAR ACTION (decision 2026-07-18-cardinalite).

Pour chaque grammaire on demande d'abord au moteur d'ENUMERER (produce-all).
C'est LE MOTEUR qui tranche :
  - s'il refuse ("Can't produce all items in 'SUB' or 'SUB1' or 'POSLONG'",
    ProduceItems.c:770) ou n'enumere rien  -> action = single
  - s'il enumere                            -> action = produce-all

En 'single' on ne veut QU'UN item : on surcharge MaxItemsProduce=1 dans les
reglages (copie temporaire, l'original n'est jamais touche). Sans cela le
moteur rejoue N fois le meme morceau (artefact de repetition) et --tokensout
concatene les N passes.

N'ECRIT QUE dans baseline-native/.
"""
import sys
import hashlib, json, os, re, subprocess, datetime, collections, shutil

ROOT = "/home/romi/dev/bp/bp3-engine"
TD = os.path.join(ROOT, "test-data")
BP3 = os.path.join(ROOT, "bp3")
OUT = os.path.join(ROOT, "baseline-native")
CAP_PUBLIE = os.path.join(OUT, "captures")
# Une recapture complete dure une demi-heure. Si elle ecrivait DANS le repertoire publie,
# l'oracle resterait incoherent pendant tout ce temps — a moitie efface, a moitie reecrit —
# et tout consommateur qui le lit pendant ce laps rendrait des faux resultats. C'est
# exactement ce qui est arrive a bpscript le 2026-07-19 : leur comparateur a lu 27 captures
# manquantes et les a comptees comme des divergences, alors que la recapture etait en cours.
# On ecrit donc dans une zone de travail, et on BASCULE d'un coup a la fin. Meme propriete
# que baseline.json, qui n'est ecrit qu'une fois tout mesure : en cas d'arret, le publie est
# intact.
CAP = os.path.join(OUT, "captures.en-cours")
RUN = os.path.join(ROOT, "capture-run")  # cwd du binaire : ../csound_resources/ y resout
GRJ = "/home/romi/dev/bp/BPscript/test/grammars/grammars.json"
TMP = "/tmp/claude-1000/-home-romi-dev-bp-bp3-engine/2886bb74-5c18-4f37-8f64-8d3075d1375c/scratchpad/v4"
os.makedirs(TMP, exist_ok=True)
if os.path.isdir(CAP):
    shutil.rmtree(CAP)
os.makedirs(CAP, exist_ok=True)
MODE = ("RND", "ORD", "LIN", "SUB", "TEMPLATES", "gram#", "GRAM#")
CONV = {"english": None, "french": "--french", "indian": "--indian"}
SEED = "1"
REFUS_MSGS = ["Can't produce all items in 'SUB' or 'SUB1' or 'POSLONG'",
              "You cannot produce all items in a 'SUB' subgrammar",
              "Cannot produce all items because this grammar contains"]
TRUNC = 2 * 1024 * 1024

G = {k: v for k, v in json.load(open(GRJ)).items() if isinstance(v, dict) and k != "_comment"}


def clean(src, dst):
    lines = open(src, encoding="utf-8", errors="replace").read().split("\n")
    st = 0
    for i, l in enumerate(lines):
        s = l.strip()
        if s.startswith("//") or re.match(r"^-[a-z]{2}\.", s) or s.startswith(MODE):
            st = i
            break
    open(dst, "w", encoding="utf-8").write(
        "\n".join(l for l in lines[st:] if not l.strip().startswith("INIT:")))


def config(gd, raw):
    pr = gd.get("php_ref") or {}
    cfg, src = {}, "php_ref" if pr else "en-tete"
    for key, flag in (("settings", "-se"), ("alphabet", "-al"), ("tonality", "-to"), ("csound", "-cs")):
        v = pr.get(key)
        if v and os.path.isfile(os.path.join(TD, v)):
            cfg[flag] = v
    for pref in ("-se", "-al", "-to", "-cs"):
        if pref in cfg:
            continue
        m = re.search(rf"^{re.escape(pref)}\.(\S+)", raw, re.M)
        if m and os.path.isfile(os.path.join(TD, f"{pref}.{m.group(1)}")):
            cfg[pref] = f"{pref}.{m.group(1)}"
    if "-al" not in cfg:
        m = re.search(r"^-ho\.(\S+)", raw, re.M)
        if m:
            for cand in (f"-al.{m.group(1)}", f"-ho.{m.group(1)}"):
                if os.path.isfile(os.path.join(TD, cand)):
                    cfg["-al"] = cand
                    break
    conv = (pr.get("note_convention") or "").lower() or None
    return cfg, conv, src


def add_so(cfg, bern):
    """Objets sonores : aucune grammaire ne les declare, ils suivent la convention de nom
    -so.<nom de la grammaire>. Meme regle que -ho.<X> pour l'alphabet."""
    if "-so" not in cfg and os.path.isfile(os.path.join(TD, f"-so.{bern}")):
        cfg["-so"] = f"-so.{bern}"
    return cfg


def se_un_item(se_rel, slug):
    """Copie des reglages avec MaxItemsProduce=1. None si format non-JSON."""
    p = os.path.join(TD, se_rel)
    try:
        d = json.load(open(p, encoding="utf-8"))
    except Exception:
        return None
    if not isinstance(d.get("MaxItemsProduce"), dict):
        return None
    if d["MaxItemsProduce"].get("value") == "1":
        return p
    d["MaxItemsProduce"]["value"] = "1"
    q = os.path.join(TMP, f"-se.{slug}.1item")
    json.dump(d, open(q, "w", encoding="utf-8"), indent=1, ensure_ascii=False)
    return q


def run(action, gpath, cfg, conv, se_over, toks, text):
    for p in (toks, text):
        if os.path.exists(p):
            os.remove(p)
    args = [BP3, action, "-e", "-gr", gpath, "--seed", SEED]
    fl = CONV.get(conv) if conv else None
    if fl:
        args.append(fl)
    for flag, v in cfg.items():
        args += [flag, se_over if (flag == "-se" and se_over) else os.path.join(TD, v)]
    args += ["-o", text, "--tokensout", toks]
    try:
        r = subprocess.run(args, capture_output=True, timeout=90, cwd=RUN)
        return (r.stdout + r.stderr).decode("utf-8", "replace"), False
    except subprocess.TimeoutExpired:
        return "", True


def mesure(toks, text):
    ntok = 0
    if os.path.exists(toks):
        try:
            ntok = len(json.load(open(toks)))
        except Exception:
            ntok = 0
    prod = ""
    if os.path.exists(text):
        if os.path.getsize(text) <= TRUNC * 8:
            prod = open(text, encoding="utf-8", errors="replace").read()
        else:
            prod = open(text, encoding="utf-8", errors="replace").read(TRUNC)
    items = [l for l in prod.split("\n") if l.strip()]
    return ntok, len(prod.split()), items


# ── MODE UNITAIRE ────────────────────────────────────────────────────────────
# `capture.py <grammaire>` capture UNE grammaire a la demande, dans un dossier a
# part, et NE TOUCHE PAS a la baseline publiee. C'est volontaire : un oracle frais
# sert a comparer, pas a redefinir la reference en douce. Republier reste un acte
# explicite — `capture.py` sans argument, suivi de la double comparaison.
# Demande par bpscript le 2026-07-19, apres la suppression de son pipeline S0-S5 :
# ses consommateurs ont besoin d'un oracle frais sans attendre notre version suivante.
UNE = None
if len(sys.argv) > 1:
    UNE = sys.argv[1]
    if UNE not in G:
        print(f"grammaire inconnue : {UNE}")
        print("noms disponibles : " + ", ".join(sorted(G)[:12]) + " …")
        sys.exit(2)
    # mode unitaire : zone a part, on n'efface rien et on ne bascule rien
    CAP = os.path.join(OUT, "captures-a-la-demande")
    os.makedirs(CAP, exist_ok=True)

# ── SONDE D ENTREE ───────────────────────────────────────────────────────────
# Avant d'engager une demi-heure de mesure, on verifie en trente secondes que la
# chaine emet encore des jetons minutes. Le garde anti-effondrement en fin de course
# empeche de PUBLIER du vide ; celui-ci empeche de le MESURER pour rien.
# Le 2026-07-19 une recapture entiere a tourne trente minutes pour rendre 0 jeton MIDI
# sur 113 grammaires — l appel au serialiseur avait ete perdu. Trente secondes de sonde
# l auraient dit d emblee.
if not UNE:
    _ref = os.path.join(OUT, "baseline.json")
    if os.path.isfile(_ref):
        _b = {x["grammaire"]: x for x in json.load(open(_ref, encoding="utf-8"))["grammaires"]}
        _sondes = [n for n in ("vina", "dhati", "mohanam", "ruwet", "tunings")
                   if n in _b and _b[n].get("jetons_midi", 0) > 0]
        _muettes = []
        for _n in _sondes:
            _x = _b[_n]
            _g = os.path.join(TMP, f"sonde.{_n}")
            clean(os.path.join(TD, _x["source"]), _g)
            _tk = os.path.join(TMP, f"sonde.{_n}.json")
            if os.path.isfile(_tk):
                os.remove(_tk)
            _se = se_un_item(_x["config"]["-se"], _n) if "-se" in _x.get("config", {}) else None
            run("produce", _g, _x["config"], _x.get("convention"), _se, _tk,
                os.path.join(TMP, f"sonde.{_n}.txt"))
            _nt = len(json.load(open(_tk))) if os.path.isfile(_tk) else 0
            print(f"  sonde {_n:10s} {_nt:5d} jetons (reference {_x['jetons_midi']})")
            if _nt == 0:
                _muettes.append(_n)
        if _muettes and len(_muettes) == len(_sondes):
            print(f"\nCAPTURE ABANDONNEE — la chaine de mesure n'emet plus aucun jeton minute.")
            print(f"  {len(_muettes)} grammaire(s) sondee(s), toutes muettes, alors que la")
            print(f"  baseline publiee leur attribue des jetons.")
            print("\nUn binaire peut construire, tourner et sortir Errors: 0 sans rien emettre :")
            print("verifiez que l'appel au serialiseur est toujours en place")
            print("  python3 scripts/gate-ancrages.py")
            print("\nRien n'a ete mesure, rien n'a ete publie. La baseline est INTACTE.")
            sys.exit(4)

rows = []
names = [UNE] if UNE else sorted(G)
for idx, name in enumerate(names, 1):
    gd = G[name]
    bern = gd.get("bernard", name)
    gsrc = os.path.join(TD, f"-gr.{bern}")
    slug = re.sub(r"[^A-Za-z0-9_.-]", "_", name)
    if not os.path.isfile(gsrc):
        rows.append(dict(grammaire=name, source=f"-gr.{bern}", action=None, modalite=None,
                         produit=False, raison="source -gr absente du corpus"))
        continue
    raw = open(gsrc, encoding="utf-8", errors="replace").read()
    cfg, conv, cfgsrc = config(gd, raw)
    cfg = add_so(cfg, bern)
    g = os.path.join(TMP, f"g.{slug}")
    clean(gsrc, g)
    # Convention de notes non declaree : on la DERIVE, mais seulement si elle est
    # DETERMINEE — c'est-a-dire si une seule des quatre conventions compile sans
    # erreur. Si plusieurs compilent, c'est ambigu : on ne devine pas, on laisse
    # non declaree. Le champ convention_source dit toujours d'ou vient la valeur.
    convsrc = "php_ref" if conv else None
    if conv is None:
        ok_conv = []
        for c in ("english", "french", "indian", "keys"):
            lg, tt = run("produce", g, cfg, c, None,
                         os.path.join(TMP, f"c.{slug}.tok"), os.path.join(TMP, f"c.{slug}.txt"))
            m = re.search(r"Errors:\s*(\d+)", lg)
            if (not tt) and m and int(m.group(1)) == 0:
                ok_conv.append(c)
        if len(ok_conv) == 1:
            conv, convsrc = ok_conv[0], "derivee : seule convention qui compile"
        elif len(ok_conv) > 1:
            # Plusieurs conventions compilent : ce n'est ambigu QUE si elles donnent des
            # sorties DIFFERENTES. Si elles rendent toutes le meme resultat, la convention
            # ne mord sur rien (grammaire a symboles, sans nom de note) : elle est SANS OBJET.
            # On compare les sorties reelles, pas le nombre de conventions qui compilent —
            # compter les compilations ne peut pas discriminer les deux cas.
            groupes = {}
            for c in ok_conv:
                tk = os.path.join(TMP, f"k.{slug}.tok"); tx = os.path.join(TMP, f"k.{slug}.txt")
                for f in (tk, tx):
                    if os.path.isfile(f):
                        os.remove(f)
                run("produce", g, cfg, c, None, tk, tx)
                # une sortie VIDE n'est pas une sortie : deux vides ne prouvent pas l'egalite
                blob = b"".join(open(f, "rb").read() for f in (tk, tx) if os.path.isfile(f))
                cle = hashlib.sha256(blob).hexdigest()[:10] if blob.strip() else f"vide-{c}"
                groupes.setdefault(cle, []).append(c)
            if len(groupes) == 1:
                conv = ok_conv[0]
                convsrc = ("sans objet : les %d conventions qui compilent rendent la meme sortie"
                           % len(ok_conv))
            else:
                convsrc = ("ambigue : %d sorties differentes selon la convention (%s)"
                           % (len(groupes), " | ".join("+".join(v) for v in groupes.values())))
    toks = os.path.join(CAP, f"{slug}.tokens.json")
    text = os.path.join(CAP, f"{slug}.text.txt")

    # --- 1. LE JEU d'abord : une realisation, un seul item, graine fixe.
    #     C'est la seule action qui emette des jetons minutes (produce-all n'en emet
    #     jamais : il enumere des chaines symboliques, il ne joue pas).
    se_over = se_un_item(cfg["-se"], slug) if "-se" in cfg else None
    log, to = run("produce", g, cfg, conv, se_over, toks, text)
    ntok, nw, items = mesure(toks, text)
    joue = (not to) and ntok > 0

    n_enum, refus = None, False
    if joue:
        # elle joue un morceau -> c'est le jeu qu'on capture (iso-mesure-le-play)
        action = "single"
        # on note quand meme si le moteur SAIT enumerer, pour information
        t2 = os.path.join(TMP, f"e.{slug}.tok")
        x2 = os.path.join(TMP, f"e.{slug}.txt")
        log2, to2 = run("produce-all", g, cfg, conv, None, t2, x2)
        _, _, it2 = mesure(t2, x2)
        refus = any(m in log2 for m in REFUS_MSGS)
        n_enum = len(it2) if (not to2 and not refus and it2) else None
    else:
        # pas de jeu : production symbolique. On demande au moteur d'enumerer.
        log2, to2 = run("produce-all", g, cfg, conv, None, toks, text)
        ntok2, nw2, items2 = mesure(toks, text)
        refus = any(m in log2 for m in REFUS_MSGS)
        if (not to2) and (not refus) and len(items2) > 0:
            action = "produce-all"
            n_enum = len(items2)
            log, to, ntok, nw, items = log2, to2, ntok2, nw2, items2
        else:
            # le moteur refuse d'enumerer -> on retombe sur l'item unique
            action = "single"
            log, to = run("produce", g, cfg, conv, se_over, toks, text)
            ntok, nw, items = mesure(toks, text)
    n_rep = None

    if to:
        modal, ok, why = None, False, "blocage (> 90 s sans rendre la main)"
    elif ntok > 0:
        modal, ok, why = "MIDI", True, None
    elif nw > 0:
        modal, ok, why = "TEXTE", True, None
    else:
        modal, ok = None, False
        m = re.search(r"Errors:\s*(\d+)", log)
        msgs = [l.strip() for l in log.split("\n")
                if re.search(r"Error code|Can't make sense|Cannot|Could not|=> ", l)
                and "_stop" not in l][:1]
        why = (f"{m.group(1)} erreur(s) de compilation : {msgs[0][:70]}"
               if m and int(m.group(1)) > 0 and msgs
               else (msgs[0][:80] if msgs else "aucune sortie, aucun message"))
        action = None

    if os.path.exists(g):
        os.remove(g)
    if not ok:
        for p in (toks, text):
            if os.path.exists(p):
                os.remove(p)
    if ok and os.path.exists(text) and os.path.getsize(text) > TRUNC:
        real = os.path.getsize(text)
        import hashlib
        h = hashlib.sha256(open(text, "rb").read()).hexdigest()
        buf = open(text, "rb").read(TRUNC)
        open(text, "wb").write(buf)
        open(text + ".TRONQUEE.txt", "w").write(
            f"capture tronquee a {TRUNC} octets\ntaille reelle : {real} octets\nsha256 complet : {h}\n")

    rows.append(dict(grammaire=name, source=f"-gr.{bern}", action=action, modalite=modal,
                     produit=ok, raison=why, jetons_midi=ntok, mots_texte=nw,
                     items=len(items), items_enumeres=n_enum,
                     enumeration_refusee_par_le_moteur=bool(refus),
                     joue=bool(joue),
                     config={k: v for k, v in cfg.items()}, convention=conv,
                     config_source=cfgsrc, convention_source=convsrc, declare=gd.get("production_mode"),
                     capture=(f"captures/{slug}." + ("tokens.json" if modal == "MIDI" else "text.txt")) if ok else None))
    print(f"[{idx}/{len(names)}] {name:26} {str(action):11} {str(modal):6} "
          f"{'OK' if ok else 'non':3} items={len(items)}", flush=True)

n_ok = [r for r in rows if r["produit"]]
meta = dict(version="v5", figee_le=datetime.date.today().isoformat(),
            date=datetime.date.today().isoformat(),
            binaire="bp3 v3.4.4 (graphics-for-BP3)", seed=SEED, n=len(rows),
            binaire_md5=hashlib.md5(open(BP3, "rb").read()).hexdigest(),
            script_commit=subprocess.run(
                ["git", "-C", ROOT, "rev-parse", "--short", "HEAD"],
                capture_output=True, text=True).stdout.strip(),
            commande="bp3 <action> -e -gr <gr-nettoyee> --seed " + SEED
                     + " [conv] [cfg...] -o <texte> --tokensout <jetons> ;"
                     + " cwd=capture-run ; clean capture.py:52-61 ; un-item capture.py:96-110",
            capture="par ACTION : single (le jeu, 1 item, graine fixe) des que la grammaire joue ; produce-all (l ensemble) pour les grammaires purement symboliques quand le moteur accepte d enumerer",
            productibles=len(n_ok),
            produce_all=len([r for r in n_ok if r["action"] == "produce-all"]),
            single=len([r for r in n_ok if r["action"] == "single"]),
            grammaires=rows)
if UNE:
    # On n'ecrit PAS baseline.json : la reference publiee ne bouge que sur republication.
    x = rows[0]
    print(f"\noracle frais pour « {UNE} » — baseline PUBLIEE INCHANGEE")
    print(f"  action={x.get('action')}  mode={x.get('modalite')}  "
          f"jetons={x.get('jetons_midi')}  mots={x.get('mots_texte')}  items={x.get('items')}")
    print(f"  convention={x.get('convention')} ({x.get('convention_source')})")
    print(f"  capture ecrite dans {CAP}/")
    if x.get('capture_comparable') is False or UNE in ("trySrand", "trySerial"):
        print("  ⚠ CETTE GRAMMAIRE N'EST PAS REPRODUCTIBLE a graine fixe : le nombre de jetons "
              "est stable mais leur ORDRE change d'une execution a l'autre. Comparez les "
              "compteurs, JAMAIS la sequence.")
    sys.exit(0)

# ── GARDE ANTI-EFFONDREMENT ──────────────────────────────────────────────────
# On REFUSE de publier une capture dont la modalite MIDI s'est effondree par rapport
# a la baseline publiee. Le 2026-07-19, une recapture a rendu 98 TEXTE et ZERO MIDI
# parce que l'appel au serialiseur avait ete perdu : le binaire construisait, tournait,
# sortait Errors: 0, et n'emettait plus rien. Sans ce garde, cette capture serait
# devenue la reference de trois consommateurs.
# Le garde BLOQUE la bascule, il n'avertit pas : une etape manuelle de verification
# s'oublie, un refus de publier ne s'oublie pas.
_ancien = os.path.join(OUT, "baseline.json")
if os.path.isfile(_ancien):
    _av = json.load(open(_ancien, encoding="utf-8"))
    _midi_av = sum(1 for x in _av["grammaires"] if x.get("modalite") == "MIDI")
    _midi_ap = sum(1 for x in rows if x.get("modalite") == "MIDI")
    if _midi_av > 0 and _midi_ap < _midi_av * 0.5:
        print(f"\nPUBLICATION REFUSEE — EFFONDREMENT DE LA MODALITE MIDI")
        print(f"  baseline publiee ({_av.get('version')}) : {_midi_av} grammaires en MIDI")
        print(f"  cette capture                        : {_midi_ap}")
        print(f"  soit {100 * _midi_ap // max(_midi_av, 1)} % — sous le seuil de 50 %.")
        print("\nUne chute de cette ampleur ne vient pas des grammaires : elle vient du moteur")
        print("ou de la chaine de mesure. Verifiez que --tokensout emet encore (un binaire")
        print("peut construire, tourner et sortir Errors: 0 sans rien emettre), puis relancez.")
        print(f"\nLa baseline publiee est INTACTE. Les mesures de cette tentative sont dans")
        print(f"{CAP}/ si vous voulez les examiner.")
        sys.exit(3)

# BASCULE ATOMIQUE : jusqu'ici le repertoire publie n'a pas ete touche.
if os.path.isdir(CAP_PUBLIE):
    _vieux = CAP_PUBLIE + ".remplace"
    if os.path.isdir(_vieux):
        shutil.rmtree(_vieux)
    os.rename(CAP_PUBLIE, _vieux)
os.rename(CAP, CAP_PUBLIE)
if os.path.isdir(CAP_PUBLIE + ".remplace"):
    shutil.rmtree(CAP_PUBLIE + ".remplace")

json.dump(meta, open(os.path.join(OUT, "baseline.json"), "w"), indent=1, ensure_ascii=False)
c = collections.Counter((r["modalite"] or "NE PRODUIT PAS") for r in rows)
a = collections.Counter((r["action"] or "-") for r in rows)
print("\n=== BILAN ===")
for k, v in c.most_common():
    print(f"  {v:>4}  {k}")
print("  --- action:")
for k, v in a.most_common():
    print(f"  {v:>4}  {k}")
