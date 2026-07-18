# BACKLOG — bp3-engine (moteur)

Dette technique **interne** au moteur. Un id court + statut par item.
Statuts : `ouvert` · `en-cours` · `bloqué` · `fait`. Vue globale : `tour backlog` (hub).
Items qui touchent le **langage** (syntaxe/sémantique) → backlog central
`hub/projets/backlog-langage-bps.md` via `tour` (pas ici).

## Bugs moteur — bloquants pour l'oracle natif (amont Bernard)

- **48** `bloqué` — `#48` `do4-` (alphabet) : crash à la compilation. Quarantaine.
- **49** `bloqué` — `#49` Préfixe `Su`/`Suresh` (765432) : production native fausse. Hors-oracle.
- **50** `bloqué` — `#50` `watch` : perf de production ~257 s (à profiler). Hors-oracle.
- **51** `bloqué` — `#51` Gardes mono-item : production native incorrecte sur grammaires à 1 item.
- **52** `bloqué` — `#52` `look-and-say` : production vide côté natif. Hors-oracle.

→ Re-capture des oracles natifs INTERDITE tant que #48-#52 ouverts (765432/watch/look-and-say gelées sur WASM).

## Limites / dette interne

- **M1** `ouvert` — `one-scale`/`tryShruti` : nom de terminal VIDE sur gamme invalide (natif) vs `<60>` WASM. À trancher : gamme réellement invalide (acter natif + retirer) ou bug de résolution de gamme. Avis Romain demandé (verrou §3.2 résorption).
- **M2** `ouvert` — Couches de correction WASM NON portées en natif : `#33` dédup keep-longest, `#35` offset Kpress, `#32` drift MIDI. Le natif émet le TimeSet brut (fait foi) ; documenter l'écart par cas.
- **M3** `fait` — `PrintArg→FILE*` ne sort pas les NOMS de jetons (Bernard a commenté le `fprintf` de `Display()`, « Fixed by BB 2022-02-20 »). Conséquence : pas de flag `--textout` dédié possible proprement. Contourné : ordre des jetons texte = `produce -o` (sortie brute lossless). Voir memory `oracle-texte-option-o`.

## Délégué (action ailleurs, suivi)

- **D1** `en-cours` — Tokeniseur « ordre texte » qui REFLÈTE BP3 (markers `=`/`:`, virgule `{N,…}`) — owner **bpscript** (utilitaire partagé). Si l'alignement exact demande du dev → leur backlog. Réf. CDC `hub/contrats/2026-06-16-sortie-production-texte-kanopi.md` §9.
- **BP3E-ISO-EKDOTIN** `ouvert` [P4] — ISO-EKDOTIN-TEMPLATES [P4] : ek-do-tin + templates ont un oracle natif présent MAIS leur source -gr est absente de test-data (branche wasm, library/ non checkout) → non mesurables par le frontal .gr, donc non publiables tant que la source n'est pas dispo. Fournir les sources -gr si on veut les exposer. Signalé par bp3-frontend [105]
- **BP3E-ISO-REGRESSION** `bloqué` [P3] — ISO-100 RÉGRESSION-NATIF [P3] : dhadhatite1 + dhin1 — le moteur natif ne sort RIEN alors qu'un oracle WASM existait (16/24 jetons). Régression moteur OU dépendance manquante (aux). À discriminer — potentiellement au-delà de ces 2. Signalé campagne bpscript A.2b [71bda33]  _(bloqué: élargi : 4 grammaires — dhadhatite1, dhin1, tryhomomorphism (PHP 6/natif 0), tryRagas (PHP 42/natif 0). Le natif produit RIEN où la référence produisait = régression moteur OU aux manquant. Débloque potentiellement plusieurs si corrigé. bp3-engine dormant → à relancer quand on attaque Phase D moteur)_
- **BP3E-BUCKET-CONSOLE** `ouvert` [P3] — ISO-100 BUCKET-CONSOLE-BUGS [bonne nouvelle] : le plan bp3-frontend a trouvé que le bucket moteur (55 'natif ne produit pas') est SURTOUT des BUGS DE CONSOLE (ConsoleStubs.c LoadAlphabet) + câblage harnais, PAS des features moteur manquantes → plusieurs adressables SANS toucher le cœur moteur. Conséquence : le dénominateur productible (53) va grossir. Chantier à cadrer : réparer les bugs console → re-mesurer combien de grammaires sortent du bucket vers le productible
- **BPE-1** `bloqué` [P1] — S0-HARNAIS-DEPS : s0_snapshot.cjs (BPscript/test) doit passer les DEPENDANCES declarees en tete de grammaire (-al alphabet, -gl, -cs csound, -to tonality) — actuellement il lance -gr seul -> echec spurieux (62/63 erreurs dhati = alphabet non charge). Fix = lire les deps par grammaire (logique dans scratchpad/reharness.py) et les passer. Recupere dhati + 5 grammaires (12345678, 765432, Nadaka, trial.mohanam, tryRagas) SANS toucher le moteur.  _(bloqué: CORRIGE : pas un fix code s0_snapshot.cjs — s0 passe DEJA -al si php_ref.alphabet present (l.202-210). Le vrai fix = entrees grammars.json manquantes (config), TERRITOIRE bpscript. bp3-engine fournit les specs, bpscript applique. Reassigne -> BPScript.)_
- **BPE-2** `fait` [P2] — CORPUS-HTML-STARTSTRING : 28 fichiers -se.* portaient une chaine de depart corrompue `<HTML>S</HTML>` au lieu de `S` (artefact export web) -> moteur ne derivait rien. **25 nettoyes** (forme simple, identique a la forme saine de reference `-se.Alarm`/`-se.blurb` : `STARTSTRING:` puis le symbole nu). Verifie : le moteur lit desormais `STARTSTRING: S`. Aucune des 7 grammaires recuperees n'utilise un fichier touche (non-regression). NB : sur -se.a, corriger la chaine seule ne suffit pas (format ancien non-JSON, impasse distincte).
  - **BPE-2b** `bloqué` [P3] — 3 fichiers NON touches car forme multi-lignes `<HTML>S<BR>Part1<BR>Part2</HTML>` : `-se.checkArticulation`, `-se.checkControls`, `-se.lahras`. AUCUN fichier sain du corpus n'a de chaine de depart multi-lignes -> pas de reference pour trancher entre « 3 lignes S/Part1/Part2 » et « S seul ». Test empirique non concluant (le moteur ne lit que la 1re ligne ; -gr.checkControls ne se charge meme pas). Refus de deviner la semantique : demande d'arbitrage envoyee a l'architecte.
- **BPE-3** `ouvert` [P1] — PORTAGE-HO-CLI : le CLI bp3 repond 'Unknown option -ho' -> 27 grammaires native-broken sont en fait BLOQUEES par l homomorphisme non porte au CLI (-ho.abc/abc1/checkhomo/cloches1/dhadhatite/dhin--/Frenchnotes/gramgene/keys/notes/tryKeyMap/tryKeyXpand/tryhomomorphism). Statut reel INDETERMINE tant que -ho pas porte. LIE a la decision design homomorphisme cyclique (chaines cyclic:true + depth%period, en attente arbitrage Romain).
