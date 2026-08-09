# bp3-reference.md — bon de travail : chaque contrôle → sa scène démonstrative

Produit par bp3-engine (oracle natif), chantier [204]/[207], 2026-08-09. Mesure, pas décision.
Corrige l'estimation [204] : la plupart des contrôles ont DÉJÀ une scène ; il ne reste qu'une
poignée à écrire et 4 à marquer. La page cite aujourd'hui le guide en cellules de table ; le
chantier veut que chaque exemple POINTE vers une scène réelle testée au NATIF (compile ET dérive).

- **Écriture des scènes = bpscript** (canonique, sens/matière/produit) ; **atlas** lie ; **kanopi** héberge (samples).
- Les scènes ISO-100 (`test-data/iso100/`) sont MES témoins déjà écrits (lot [200]).

Bilan : 44 déjà dans le corpus · 26 scènes ISO-100 · **0 à écrire** · 4 à marquer.

⚠️ **Le seul « à écrire » du balayage — `_trace` — est en fait une INEXACTITUDE de la page.** `_trace`
nu n'existe pas dans le moteur : la table `GramProcedure` porte `_traceOn` (15) et `_traceOff` (16),
tous deux déjà couverts par des scènes ISO-100 (`-gr.iso_traceon`, `-gr.iso_traceoff`). Correctif de
page : remplacer la ligne `_trace` par `_traceOn`/`_traceOff`. Donc **aucune scène à écrire**.

⚠️ **Les 4 « à marquer » ne sont PAS des exemples manquants mais des formes que le natif ne peut pas
démontrer** (BPE-26/27, prouvé) : `_stop`, `_capture`, `_part` (inertes en batch), et `_step` (la
famille `_stepOn`/`_stepOff` est INÉCRIVABLE, masquée par `_step`). Elles reçoivent une bannière
datée + renvoi, pas une scène — quel que soit l'arbitrage sur la nature de la page.

| Contrôle | Statut | Scène / motif |
|---|---|---|
| `_retro` | corpus | -gr.tryTranspose |
| `_rndseq` | corpus | -gr.trySrand |
| `_value` | corpus | -gr.vina3 |
| `_keyxpand` | corpus | -gr.tryTranspose |
| `_srand` | corpus | -gr.trySrand |
| `_transpose` | corpus | -gr.transposition3 |
| `_randomize` | corpus | -gr.trySrand |
| `_step` | MARQUER | famille _stepOn/_stepOff INÉCRIVABLE, masquée par _step (CompileProcs.c:722-732), BPE-26 |
| `_cont` | corpus | -gr.vina3 |
| `_pitchrange` | corpus | -gr.tryRagas |
| `_rotate` | corpus | -gr.Visser.Waves |
| `_rest` | corpus | -gr.Ames |
| `_fixed` | corpus | -gr.vina3 |
| `_transposecont` | ISO-100 | test-data/iso100/-gr.iso_transposecont |
| `_tempo` | corpus | -gr.Mozart |
| `_goto` | corpus | -gr.tryGOTO |
| `_pitchbend` | corpus | -gr.ShapesInRhythm |
| `_keymap` | corpus | -gr.tryKeyMap |
| `_failed` | corpus | -gr.tryGOTO |
| `_print` | corpus | -gr.tryGOTO |
| `_scale` | corpus | -gr.Mozart |
| `_chan` | corpus | -gr.Watch_What_Happens |
| `_modstep` | ISO-100 | test-data/iso100/-gr.iso_modstep |
| `_volume` | corpus | -gr.tryShruti |
| `_ordseq` | corpus | -gr.trySerial |
| `_rndtime` | ISO-100 | test-data/iso100/-gr.iso_rndtime |
| `_repeat` | corpus | -gr.tryGOTO |
| `_trace` | CORRIGER LA PAGE | n'existe pas ; remplacer par `_traceOn`/`_traceOff` → -gr.iso_traceon, -gr.iso_traceoff |
| `_capture` | MARQUER | sautée en production (ProduceItems.c:1239), MIDI temps-réel, BPE-27 |
| `_velstep` | ISO-100 | test-data/iso100/-gr.iso_velstep |
| `_mod` | corpus | -gr.ShapesInRhythm |
| `_modcont` | corpus | -gr.ShapesInRhythm |
| `_pitchcont` | corpus | -gr.ShapesInRhythm |
| `_legato` | corpus | -gr.Visser.Waves |
| `_volumecont` | corpus | -gr.tryRagas |
| `_transposestep` | ISO-100 | test-data/iso100/-gr.iso_transposestep |
| `_mm` | corpus | -gr.tryTranspose |
| `_script` | corpus | -gr.Mozart |
| `_part` | MARQUER | sautée/portée (ProduceItems.c:1239, Compute.c:1664), BPE-27 |
| `_rndvel` | corpus | -gr.trySrand |
| `_velcont` | corpus | -gr.Visser.Waves |
| `_pitchstep` | ISO-100 | test-data/iso100/-gr.iso_pitchstep |
| `_presstep` | corpus | -gr.checkVolChan |
| `_presscont` | corpus | -gr.ShapesInRhythm |
| `_switchon` | corpus | -gr.ShapesInRhythm |
| `_volumestep` | corpus | -gr.checkAllCsound |
| `_staccato` | corpus | -gr.testNC1 |
| `_articulstep` | ISO-100 | test-data/iso100/-gr.iso_articulstep |
| `_articulcont` | ISO-100 | test-data/iso100/-gr.iso_articulcont |
| `_pancont` | ISO-100 | test-data/iso100/-gr.iso_pancont |
| `_panstep` | ISO-100 | test-data/iso100/-gr.iso_panstep |
| `_transposefixed` | ISO-100 | test-data/iso100/-gr.iso_transposefixed |
| `_pitchrate` | ISO-100 | test-data/iso100/-gr.iso_pitchrate |
| `_volumecontrol` | ISO-100 | test-data/iso100/-gr.iso_volumecontrol |
| `_pan` | ISO-100 | test-data/iso100/-gr.iso_pan |
| `_pancontrol` | ISO-100 | test-data/iso100/-gr.iso_pancontrol |
| `_stop` | MARQUER | stub console (ConsoleStubs.c:142), BPE-27 |
| `_destru` | corpus | -gr.tryAllItems0 |
| `_smooth` | ISO-100 | test-data/iso100/-gr.iso_smooth |
| `_striated` | corpus | -gr.tryTranspose |
| `_ins` | corpus | -gr.tryCsound |
| `_vel` | corpus | -gr.tryTranspose |
| `_press` | corpus | -gr.ShapesInRhythm |
| `_switchoff` | corpus | -gr.ShapesInRhythm |
| `_velfixed` | ISO-100 | test-data/iso100/-gr.iso_velfixed |
| `_modfixed` | ISO-100 | test-data/iso100/-gr.iso_modfixed |
| `_pitchfixed` | corpus | -gr.vina3 |
| `_pressfixed` | ISO-100 | test-data/iso100/-gr.iso_pressfixed |
| `_volumefixed` | ISO-100 | test-data/iso100/-gr.iso_volumefixed |
| `_articulfixed` | ISO-100 | test-data/iso100/-gr.iso_articulfixed |
| `_panfixed` | ISO-100 | test-data/iso100/-gr.iso_panfixed |
| `_modrate` | ISO-100 | test-data/iso100/-gr.iso_modrate |
| `_pressrate` | ISO-100 | test-data/iso100/-gr.iso_pressrate |
| `_volumerate` | ISO-100 | test-data/iso100/-gr.iso_volumerate |
| `_panrate` | ISO-100 | test-data/iso100/-gr.iso_panrate |
