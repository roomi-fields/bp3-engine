# Corpus de référence ISO-100 — 35 directives que le corpus n'écrit jamais

Lot [200] (Romain, 2026-08-09), produit par l'agent `bp3-engine` (oracle moteur).

Le moteur déclare 83 contrôles ; 71 apparaissent dans le corpus, **35 jamais**. Ces grammaires
les rendent **mesurables** : chacune oppose un témoin qui NE VARIE PAS à un témoin qui VARIE, la
comparaison étant ce qui prouve. **Je produis les grammaires ; BPx mesure au binaire** — je ne
mesure pas ce que fait chaque directive, je garantis seulement qu'un différentiel EXISTE sur l'axe
déclaré.

- Régénérer : `bash generate.sh`
- Valider (compile + différentiel sur l'axe) : `python3 validate.py` → **28/28 différentiels prouvés**.

## Pièges de mesure (à respecter par le mesureur)
- **`--eventlistout` SEUL rend 0 ligne en 3.5.1** → toujours l'accompagner de `-o` (constat #68).
- **Horloge native en SECONDES** : deux exécutions dans la même seconde rendent l'identique →
  fixer `--seed` (fait ici : graine 1) et ne pas dépendre de l'horloge murale.
- La sortie dépend des sorties demandées : citer version + md5 + **commande complète** (ORACLE-BINAIRE.md).

## Axes observables (où lire l'effet)
| axe | sortie à demander | ce qu'on y lit |
|---|---|---|
| eventlist | `--eventlistout f.csv -o /dev/null` | colonnes mode (1=fixed,2=cont,3=step)/start/end, transpos, durée (end-start), onsets |
| MIDI | `--midiout f.mid` | densité de messages CC, n° de contrôleur, octet de vélocité, pitchbend/aftertouch |
| trace stdout | (aucune ; la directive s'auto-active) | lignes `[Step #n] Selected: gram#…` de la dérivation |

## Les 35, par famille

### Observables directement dans l'eventlist (mode / start / end)
| directive | fichier | signal (test vs témoin) |
|---|---|---|
| `_volumefixed` | -gr.iso_volumefixed | volume mode 1 (tient 10) vs cont (rampe 10→120) |
| `_modfixed` | -gr.iso_modfixed | modulation mode 1 vs 2 |
| `_modstep` | -gr.iso_modstep | modulation mode 3 (paliers) vs 2 |
| `_pan` | -gr.iso_pan | panoramic start 20 vs défaut 64 |
| `_panfixed` | -gr.iso_panfixed | panoramic mode 1 vs 2 |
| `_pancont` | -gr.iso_pancont | panoramic mode 2 vs valeur fixe |
| `_panstep` | -gr.iso_panstep | panoramic mode 3 vs 2 |
| `_pressfixed` | -gr.iso_pressfixed | pressure mode 1 vs 2 |
| `_pitchstep` | -gr.iso_pitchstep | pitchbend mode 3 vs 2 |
| `_transposefixed` | -gr.iso_transposefixed | transpos tient 0 vs cont 0→12 |
| `_transposecont` | -gr.iso_transposecont | transpos rampe vs constant |
| `_transposestep` | -gr.iso_transposestep | transpos paliers vs constant |
| `_articulfixed` | -gr.iso_articulfixed | durée de note tenue vs cont |
| `_articulcont` | -gr.iso_articulcont | durée rampe vs constante |
| `_articulstep` | -gr.iso_articulstep | durée paliers vs constante |
| `_rndtime` | -gr.iso_rndtime | onsets déviés (jitter, reproductible par graine) vs réguliers |

### Observables dans le MIDI (`--midiout`)
| directive | fichier | signal |
|---|---|---|
| `_velfixed` | -gr.iso_velfixed | vélocité note-on tenue vs rampe |
| `_velstep` | -gr.iso_velstep | vélocité par paliers vs rampe |
| `_volumerate` | -gr.iso_volumerate | densité de CC#7 (rampe fine vs grossière) |
| `_volumecontrol` | -gr.iso_volumecontrol | rampe portée par CC#11 au lieu de #7 |
| `_modrate` | -gr.iso_modrate | densité de CC#1 |
| `_panrate` | -gr.iso_panrate | densité de CC#10 |
| `_pancontrol` | -gr.iso_pancontrol | pan porté par CC#9 au lieu de #10 |
| `_pressrate` | -gr.iso_pressrate | densité d'aftertouch (0xD0) |
| `_pitchrate` | -gr.iso_pitchrate | densité de pitchbend (0xE0) |

### Observables dans la trace stdout (dérivation multi-pas ; la directive s'auto-active, sans flag CLI)
| directive | fichier | signal |
|---|---|---|
| `_traceOn` | -gr.iso_traceon | lignes `[Step #n] Selected: …` émises dès la règle marquée |
| `_traceOff` | -gr.iso_traceoff | la trace apparaît puis CESSE à la règle marquée |

### Observable en comparaison CROISÉE (grammaire-globale)
| directive | fichier | signal |
|---|---|---|
| `_smooth` | -gr.iso_smooth | onsets ≠ de la MÊME grammaire en `_striated` (défaut moteur) |

### Déclarées mais SANS différentiel observable en batch console (fait, pas échec — preuve source)
| directive | fichier | pourquoi |
|---|---|---|
| `_stop` | -gr.iso_stop | `InterruptCompute` est un **stub console** (ConsoleStubs.c:142) : ne tronque rien en batch |
| `_capture` | -gr.iso_capture | sautée en production (ProduceItems.c:1239) ; capture MIDI temps-réel seulement |
| `_part` | -gr.iso_part | sautée/portée en appariement (ProduceItems.c:1239, Compute.c:1664) ; aucun événement |
| `_printOn` | -gr.iso_printon | bascule `DisplayProduce` (Compute.c:243) ; non surfacé par `produce`/`produce-all` |
| `_printOff` | -gr.iso_printoff | idem `_printOn` |

### INÉCRIVABLES — masquées par le contrôle de performance `_step`
| directive | fichier | pourquoi |
|---|---|---|
| `_stepOn` | -gr.iso_stepon | `GetPerformanceControl` matche `_step` par préfixe glouton **sans garde de frontière** (CompileProcs.c:726-732) : `_stepOn` est lu comme `_step`+`On` → erreur code 15, à toute position. Bug candidat amont Bernard. |
| `_stepOff` | -gr.iso_stepoff | idem |

Les deux fichiers `stepon`/`stepoff` contiennent une grammaire minimale valide **sans** la directive
(pour que le corpus ait une entrée) + la note explicative.
