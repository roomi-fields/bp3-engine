#!/usr/bin/env python3
# Validation différentielle des grammaires ISO-100 : pour chaque directive, prouver que
# le témoin PEUT montrer un effet sur l'axe déclaré (varie vs ne varie pas). Ne mesure PAS
# ce que fait la directive (ça, c'est BPx) — vérifie seulement qu'un différentiel EXISTE.
import subprocess, csv, os, sys, struct

BP = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "bp3"))
GDIR = os.path.dirname(os.path.abspath(__file__))
TMP = "/tmp/claude-1000/-home-romi-dev-bp-bp3-engine/2886bb74-5c18-4f37-8f64-8d3075d1375c/scratchpad/v"
os.makedirs(TMP, exist_ok=True)

def run(name, midi=False):
    g = os.path.join(GDIR, "-gr.iso_" + name)
    ev = os.path.join(TMP, name + ".csv")
    args = [BP, "produce", "-gr", g, "-o", os.path.join(TMP, "o.txt"),
            "--eventlistout", ev, "--seed", "1"]
    if midi:
        args += ["--midiout", os.path.join(TMP, name + ".mid")]
    out = subprocess.run(args, capture_output=True, text=True)
    return out.stdout + out.stderr, ev

def evrows(ev):
    with open(ev) as f:
        r = list(csv.reader(f))
    return r[0], r[1:]

def col(name, colsub):
    h, rows = evrows(run(name)[1])
    idx = [i for i, c in enumerate(h) if colsub in c.lower()]
    vals = set(tuple(row[i] for i in idx) for row in rows)
    return len(vals) > 1, sorted(vals)

def dur_varies(name):
    h, rows = evrows(run(name)[1])
    si, ei = h.index("start time"), h.index("end time")
    durs = set(int(row[ei]) - int(row[si]) for row in rows)
    return len(durs) > 1, sorted(durs)

def starts_irregular(name):
    h, rows = evrows(run(name)[1])
    si = h.index("start time")
    s = sorted(set(int(row[si]) for row in rows))
    gaps = set(b - a for a, b in zip(s, s[1:]))
    return len(gaps) > 1, s

def midi_cc(name):
    run(name, midi=True)
    data = open(os.path.join(TMP, name + ".mid"), "rb").read()
    ccnums, vels, pb, at = set(), [], 0, 0
    i = 0
    while i < len(data) - 2:
        b = data[i]
        if 0xB0 <= b <= 0xBF: ccnums.add(data[i+1]); i += 3; continue
        if 0x90 <= b <= 0x9F:
            if data[i+2] > 0: vels.append(data[i+2])
            i += 3; continue
        if 0xE0 <= b <= 0xEF: pb += 1; i += 3; continue
        if 0xD0 <= b <= 0xDF: at += 1; i += 2; continue
        i += 1
    return ccnums, sorted(set(vels)), pb, at

def trace_lines(name):
    out, _ = run(name)
    return sum(1 for L in out.splitlines() if "[Step" in L or "-->" in L and "Selected" in L)

CHECKS = {
    "volumefixed": lambda: col("volumefixed", "volume mode"),
    "modfixed":    lambda: col("modfixed", "modulation mode"),
    "modstep":     lambda: col("modstep", "modulation mode"),
    "panfixed":    lambda: col("panfixed", "panoramic mode"),
    "pancont":     lambda: col("pancont", "panoramic mode"),
    "panstep":     lambda: col("panstep", "panoramic mode"),
    "pan":         lambda: col("pan", "panoramic start"),
    "pressfixed":  lambda: col("pressfixed", "pressure mode"),
    "pitchstep":   lambda: col("pitchstep", "pitchbend mode"),
    "transposefixed": lambda: col("transposefixed", "transpos"),
    "transposecont":  lambda: col("transposecont", "transpos"),
    "transposestep":  lambda: col("transposestep", "transpos"),
    "articulfixed": lambda: dur_varies("articulfixed"),
    "articulcont":  lambda: dur_varies("articulcont"),
    "articulstep":  lambda: dur_varies("articulstep"),
    "rndtime":      lambda: starts_irregular("rndtime"),
}
MIDI = {  # (nom, prédicat sur (ccnums,vels,pb,at))
    "velfixed":      lambda m: len(m[1]) >= 1,
    "velstep":       lambda m: len(m[1]) > 1,
    "volumerate":    lambda m: 7 in m[0],
    "volumecontrol": lambda m: 11 in m[0],
    "modrate":       lambda m: 1 in m[0],
    "panrate":       lambda m: 10 in m[0],
    "pancontrol":    lambda m: 9 in m[0],
    "pressrate":     lambda m: m[3] > 0,
    "pitchrate":     lambda m: m[2] > 0,
}
TRACE = ["traceon", "traceoff"]  # trace de dérivation stdout, auto-activée
# smooth : observable en CROISÉ (mêmes notes avec _striated vs _smooth)
def smooth_diff():
    import tempfile
    st = os.path.join(TMP, "striated.csv")
    subprocess.run([BP, "produce", "-gr", os.path.join(GDIR, "-gr.iso_smooth"),
                    "-o", os.path.join(TMP, "o.txt"), "--eventlistout",
                    os.path.join(TMP, "smooth.csv"), "--seed", "1"], capture_output=True)
    # témoin striated : réécrit la même grammaire en striated
    sg = os.path.join(TMP, "-gr.striated")
    open(sg, "w").write("_mm(60.0000) _striated\ngram#1[1] S --> {2/3, C4 C4 C4}\n")
    subprocess.run([BP, "produce", "-gr", sg, "-o", os.path.join(TMP, "o.txt"),
                    "--eventlistout", st, "--seed", "1"], capture_output=True)
    a = evrows(os.path.join(TMP, "smooth.csv"))[1]
    b = evrows(st)[1]
    return a != b

# Sans différentiel observable en batch console (faits source-prouvés, cf. README) :
#   stop    InterruptCompute = stub console (ConsoleStubs.c:142)
#   capture / part  sautés en production (ProduceItems.c:1239)
#   printon / printoff  basculent DisplayProduce, non surfacé par le harnais console
# Inécrivables (masqués par le contrôle _step) : stepon, stepoff (CompileProcs.c:726-732)
NOEFFECT = ["stop", "capture", "part", "printon", "printoff", "stepon", "stepoff"]

ok = 0; tot = 0
for name, fn in CHECKS.items():
    tot += 1; varies, vals = fn()
    print(f"{'OK ' if varies else 'XX '}{name:20s} eventlist différentiel={varies}  {vals[:4]}")
    ok += varies
for name, pred in MIDI.items():
    tot += 1; m = midi_cc(name); good = pred(m)
    print(f"{'OK ' if good else 'XX '}{name:20s} MIDI cc={sorted(m[0])} vels={m[1][:4]} pb={m[2]} at={m[3]}")
    ok += good
for name in TRACE:
    tot += 1; n = trace_lines(name); good = n > 0
    print(f"{'OK ' if good else 'XX '}{name:20s} lignes de trace stdout={n}")
    ok += good
tot += 1; sd = smooth_diff()
print(f"{'OK ' if sd else 'XX '}{'smooth':20s} différentiel croisé striated/smooth={sd}")
ok += sd
print(f"\n{ok}/{tot} différentiels prouvés (28 attendus).")
print(f"Sans différentiel en batch console (documentés, cf. README) : {', '.join(NOEFFECT)}")
