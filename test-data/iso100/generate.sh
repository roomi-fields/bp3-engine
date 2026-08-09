#!/usr/bin/env bash
# Génère les 35 grammaires de référence ISO-100 pour les directives que le corpus
# n'écrit jamais (lot [200], 2026-08-09). Chaque grammaire oppose un témoin qui NE
# VARIE PAS à un témoin qui VARIE, la comparaison étant ce qui rend l'effet mesurable.
# Produit par l'agent bp3-engine (oracle moteur). BPx mesure au binaire.
set -u
cd "$(dirname "$0")"
DIR="$(pwd)"

emit() { # emit <nom-directive> <corps-grammaire>
  printf '// -gr.iso_%s — grammaire de référence ISO-100 (directive _%s)\n// Générée par bp3-engine, lot [200]. Témoin/test : la comparaison prouve.\n%s\n' \
    "$1" "$1" "$2" > "$DIR/-gr.iso_$1"
}

# ===== VOLUME (eventlist: volume mode/start/end ; MIDI: densité/n° CC) =====
emit volumefixed   'gram#1[1] S --> {_volumecont _volume(10) C4 C4 C4 _volume(120) , _volumefixed _volume(10) C4 C4 C4 _volume(120)}'
emit volumerate    'gram#1[1] S --> {_volumecont _volume(10) C4 C4 C4 _volume(120) , _volumerate(4) _volumecont _volume(10) C4 C4 C4 _volume(120)}'
emit volumecontrol 'gram#1[1] S --> {_volumecont _volume(10) C4 C4 C4 _volume(120) , _volumecontrol(11) _volumecont _volume(10) C4 C4 C4 _volume(120)}'

# ===== MODULATION (eventlist: modulation mode/start/end ; MIDI CC#1) =====
emit modfixed 'gram#1[1] S --> {_modcont _mod(10) C4 C4 C4 _mod(120) , _modfixed _mod(10) C4 C4 C4 _mod(120)}'
emit modstep  'gram#1[1] S --> {_modcont _mod(10) C4 C4 C4 _mod(120) , _modstep _mod(10) C4 C4 C4 _mod(120)}'
emit modrate  'gram#1[1] S --> {_modcont _mod(10) C4 C4 C4 _mod(120) , _modrate(4) _modcont _mod(10) C4 C4 C4 _mod(120)}'

# ===== PANORAMIQUE (eventlist: panoramic mode/start/end ; MIDI CC#10) =====
emit pan        'gram#1[1] S --> {C4 C4 C4 , _pan(20) C4 C4 C4}'
emit panfixed   'gram#1[1] S --> {_pancont _pan(10) C4 C4 C4 _pan(120) , _panfixed _pan(10) C4 C4 C4 _pan(120)}'
emit pancont    'gram#1[1] S --> {_pan(64) C4 C4 C4 C4 , _pancont _pan(10) C4 C4 C4 _pan(120)}'
emit panstep    'gram#1[1] S --> {_pancont _pan(10) C4 C4 C4 _pan(120) , _panstep _pan(10) C4 C4 C4 _pan(120)}'
emit panrate    'gram#1[1] S --> {_pancont _pan(10) C4 C4 C4 _pan(120) , _panrate(4) _pancont _pan(10) C4 C4 C4 _pan(120)}'
emit pancontrol 'gram#1[1] S --> {_pancont _pan(10) C4 C4 C4 _pan(120) , _pancontrol(9) _pancont _pan(10) C4 C4 C4 _pan(120)}'

# ===== PRESSION (eventlist: pressure mode/start/end ; MIDI aftertouch d0) =====
emit pressfixed 'gram#1[1] S --> {_presscont _press(10) C4 C4 C4 _press(120) , _pressfixed _press(10) C4 C4 C4 _press(120)}'
emit pressrate  'gram#1[1] S --> {_presscont _press(10) C4 C4 C4 _press(120) , _pressrate(4) _presscont _press(10) C4 C4 C4 _press(120)}'

# ===== HAUTEUR (eventlist: pitchbend mode/start/end ; MIDI pitchbend e0) =====
emit pitchstep 'gram#1[1] S --> {_pitchcont _pitchbend(0) C4 C4 C4 _pitchbend(16000) , _pitchstep _pitchbend(0) C4 C4 C4 _pitchbend(16000)}'
emit pitchrate 'gram#1[1] S --> {_pitchcont _pitchbend(0) C4 C4 C4 _pitchbend(16000) , _pitchrate(4) _pitchcont _pitchbend(0) C4 C4 C4 _pitchbend(16000)}'

# ===== ARTICULATION (eventlist: durée de note end-start) =====
emit articulfixed 'gram#1[1] S --> {_articulcont _legato(10) C4 C4 C4 _legato(100) , _articulfixed _legato(10) C4 C4 C4 _legato(100)}'
emit articulcont  'gram#1[1] S --> {_legato(50) C4 C4 C4 C4 , _articulcont _legato(10) C4 C4 C4 _legato(100)}'
emit articulstep  'gram#1[1] S --> {_legato(50) C4 C4 C4 C4 , _articulstep _legato(10) C4 C4 C4 _legato(100)}'

# ===== TRANSPOSITION (eventlist: transpos) =====
emit transposefixed 'gram#1[1] S --> {_transposecont _transpose(0) C4 C4 C4 _transpose(12) , _transposefixed _transpose(0) C4 C4 C4 _transpose(12)}'
emit transposecont  'gram#1[1] S --> {_transpose(0) C4 C4 C4 C4 , _transposecont _transpose(0) C4 C4 C4 _transpose(12)}'
emit transposestep  'gram#1[1] S --> {_transpose(0) C4 C4 C4 C4 , _transposestep _transpose(0) C4 C4 C4 _transpose(12)}'

# ===== VELOCITE (axe MIDI: octet note-on velocity) =====
emit velfixed 'gram#1[1] S --> {_velcont _vel(20) C4 C4 C4 _vel(120) , _velfixed _vel(20) C4 C4 C4 _vel(120)}'
emit velstep  'gram#1[1] S --> {_velcont _vel(20) C4 C4 C4 _vel(120) , _velstep _vel(20) C4 C4 C4 _vel(120)}'

# ===== TEMPS (eventlist: start times) =====
emit rndtime 'gram#1[1] S --> {C4 C4 C4 C4 , _rndtime(200) C4 C4 C4 C4}'
# _smooth est grammaire-globale (Nature_of_time) : comparaison CROISÉE avec/sans _smooth.
printf '// -gr.iso_smooth — _smooth bascule le temps en continu (défaut moteur = striated).\n// Mesure CROISÉE : comparer les onsets de CETTE grammaire à la même SANS _smooth.\n_mm(60.0000) _smooth\ngram#1[1] S --> {2/3, C4 C4 C4}\n' > "$DIR/-gr.iso_smooth"

# ===== TRACE (axe stdout: trace de dérivation, auto-activée par la directive) =====
tr3() { # tr3 <nom> <preLHS-regle2> [<preLHS-regle3>]
  printf '// -gr.iso_%s — %s (dérivation multi-pas ; la directive active la trace stdout, sans flag CLI).\ngram#1[1] S --> A\ngram#1[2] %sA --> B B\ngram#1[3] %sB --> C4 D4\n' \
    "$1" "$1" "$2" "${3:-}" > "$DIR/-gr.iso_$1"
}
tr3 traceon  '_traceOn '
tr3 printon  '_printOn '
# les *Off : on active à la règle 2, on coupe à la règle 3 → la trace apparaît puis cesse.
tr3 traceoff '_traceOn ' '_traceOff '
tr3 printoff '_printOn ' '_printOff '

# _stepOn / _stepOff : INÉCRIVABLES. Le contrôle de performance '_step' les masque par
# match de préfixe glouton sans garde de frontière (CompileProcs.c:726-732) : à toute
# position d'une règle, '_stepOn' est lu comme '_step' + 'On' → erreur code 15. Déclarés
# en GramProcedure mais inatteignables en texte de grammaire. Fait rapporté, pas un échec.
for d in stepon stepoff; do
  printf '// -gr.iso_%s — INÉCRIVABLE (aucune règle possible).\n// Le contrôle de performance _step masque _%s par match de préfixe glouton\n// (CompileProcs.c:726-732, sans garde de frontière) : _%s est lu comme _step+... → erreur 15.\n// Directive déclarée en GramProcedure mais inatteignable en texte de grammaire.\n// (Grammaire minimale valide, sans la directive, pour que le corpus ait une entrée.)\ngram#1[1] S --> C4 D4 E4\n' "$d" "$d" "$d" > "$DIR/-gr.iso_$d"
done

# ===== CONTROLE (SANS effet observable en batch — compile mais rien à mesurer) =====
emit stop    'gram#1[1] S --> C4 X
gram#1[2] _stop X --> D4 X
gram#1[3] X --> E4'
emit capture 'gram#1[1] S --> _capture(1) C4 D4 E4'
emit part    'gram#1[1] S --> _part(1) C4 D4 _part(2) E4 F4'

echo "35 grammaires écrites dans $DIR"
ls "$DIR"/-gr.iso_* | wc -l
