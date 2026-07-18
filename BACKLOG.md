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

- **M1** `ouvert` — `one-scale`/`tryShruti` : nom de terminal VIDE sur gamme invalide (natif) vs `<60>` WASM.
  **Motif corrigé 2026-07-18** — ce n'est PAS « la gamme est incomplète » : les 23 degrés de grama sont bien
  présents. Cause établie en partie : `-to.tryShruti` et `-cs.tryShruti` sont des ébauches écrites à la main,
  sans en-tête BP3 ni ligne de numéros de touches → défaut de CORPUS, réparable en données. Mais même réparés,
  la compilation refuse encore les degrés : cause NON isolée (suspect principal = 23 degrés par octave contre
  12 touches). Détail et preuves : `docs-developer/tryShruti-gammes-microtonales.md`. Rien à remonter à
  Bernard Bel tant que ce reste n'est pas isolé. Avis Romain toujours demandé (verrou §3.2 résorption).
- **M2** `ouvert` — Couches de correction WASM NON portées en natif : `#33` dédup keep-longest, `#35` offset Kpress, `#32` drift MIDI. Le natif émet le TimeSet brut (fait foi) ; documenter l'écart par cas.
- **M3** `fait` — `PrintArg→FILE*` ne sort pas les NOMS de jetons (Bernard a commenté le `fprintf` de `Display()`, « Fixed by BB 2022-02-20 »). Conséquence : pas de flag `--textout` dédié possible proprement. Contourné : ordre des jetons texte = `produce -o` (sortie brute lossless). Voir memory `oracle-texte-option-o`.

- **BPE-11** `RESOLU 2026-07-19` [P2] — **Root-cause trouve.** Le lecteur de ressources Csound
  boucle sans fin quand la section `_begin tables` n'est pas fermee (`SaveLoads1.c:434-448` :
  les seules sorties sont `_end tables` ou une ligne VIDE ; a la vraie fin de fichier, rien).
  Cause de corpus : l'habillage HTML de l'epoque BP2 avait mange le `_end tables` de
  `-cs.Vina`, `-cs.tryCsound` et `-cs.tryCsoundObjects`. **Corriges** (des-habillage + marqueur) :
  `blurb`, `csound`, `vina`, `vina2`, `vina3` passent de > 90 s de blocage a une production en 1 s.
  Le defaut MOTEUR subsiste et est remonte a Bernard Bel : **bug #55**. Constat d'origine :
  CHARGEMENT `-cs` : BLOCAGE > 240 s. Sur `tryCsound` et `vina3`,
  passer le fichier Csound declare en tete fait BOUCLER le moteur : aucune sortie, aucun message,
  code 124 apres 240 s (mesure `/usr/bin/time` : 241,2 s). SANS `-cs`, les memes grammaires
  echouent VITE et proprement : « Error code 15: argument syntax » sur `_ins(3)` / `_ins(Vina)`
  (2 erreurs pour tryCsound, 1 pour vina3) — la fonction `_ins()` ne resout pas son instrument
  sans les ressources Csound, ce qui est coherent.
  REPRO : `./bp3 produce -e -gr <tryCsound sans INIT> --seed 1 -se test-data/-se.tryCsound
  -cs test-data/-cs.tryCsound -o <sortie>` -> ne rend jamais la main.
  NB : ces 2 grammaires etaient classees « TIMEOUT > 90 s » avant BPE-7 ; la conversion des
  reglages a change leur comportement (echec rapide sans `-cs`), mais le blocage avec `-cs`
  demeure. PAS root-cause : je ne sais pas encore si c'est une boucle infinie ou une lenteur
  pathologique (cf. #50 `watch` ~257 s, possible meme famille). A instruire avant toute
  remontee a Bernard.

## Délégué (action ailleurs, suivi)

- **D1** `en-cours` — Tokeniseur « ordre texte » qui REFLÈTE BP3 (markers `=`/`:`, virgule `{N,…}`) — owner **bpscript** (utilitaire partagé). Si l'alignement exact demande du dev → leur backlog. Réf. CDC `hub/contrats/2026-06-16-sortie-production-texte-kanopi.md` §9.
- **BP3E-ISO-EKDOTIN** `ouvert` [P4] — ISO-EKDOTIN-TEMPLATES [P4] : ek-do-tin + templates ont un oracle natif présent MAIS leur source -gr est absente de test-data (branche wasm, library/ non checkout) → non mesurables par le frontal .gr, donc non publiables tant que la source n'est pas dispo. Fournir les sources -gr si on veut les exposer. Signalé par bp3-frontend [105]
- **BP3E-ISO-REGRESSION** `bloqué` [P3] — ISO-100 RÉGRESSION-NATIF [P3] : dhadhatite1 + dhin1 — le moteur natif ne sort RIEN alors qu'un oracle WASM existait (16/24 jetons). Régression moteur OU dépendance manquante (aux). À discriminer — potentiellement au-delà de ces 2. Signalé campagne bpscript A.2b [71bda33]  _(bloqué: élargi : 4 grammaires — dhadhatite1, dhin1, tryhomomorphism (PHP 6/natif 0), tryRagas (PHP 42/natif 0). Le natif produit RIEN où la référence produisait = régression moteur OU aux manquant. Débloque potentiellement plusieurs si corrigé. bp3-engine dormant → à relancer quand on attaque Phase D moteur)_
- **BP3E-BUCKET-CONSOLE** `ouvert` [P3] — ISO-100 BUCKET-CONSOLE-BUGS [bonne nouvelle] : le plan bp3-frontend a trouvé que le bucket moteur (55 'natif ne produit pas') est SURTOUT des BUGS DE CONSOLE (ConsoleStubs.c LoadAlphabet) + câblage harnais, PAS des features moteur manquantes → plusieurs adressables SANS toucher le cœur moteur. Conséquence : le dénominateur productible (53) va grossir. Chantier à cadrer : réparer les bugs console → re-mesurer combien de grammaires sortent du bucket vers le productible
- **BPE-1** `en-cours` [P1] — S0-HARNAIS-DEPS : s0_snapshot.cjs (BPscript/test) doit passer les DEPENDANCES declarees en tete de grammaire (-al alphabet, -gl, -cs csound, -to tonality) — actuellement il lance -gr seul -> echec spurieux (62/63 erreurs dhati = alphabet non charge). Fix = lire les deps par grammaire (logique dans scratchpad/reharness.py) et les passer. Recupere dhati + 5 grammaires (12345678, 765432, Nadaka, trial.mohanam, tryRagas) SANS toucher le moteur.  _(bloqué: CORRIGE : pas un fix code s0_snapshot.cjs — s0 passe DEJA -al si php_ref.alphabet present (l.202-210). Le vrai fix = entrees grammars.json manquantes (config), TERRITOIRE bpscript. bp3-engine fournit les specs, bpscript applique. Reassigne -> BPScript.)_  _(en-cours: DEBLOQUE+RESOLU cote specs : bp3-engine a livre les 6 specs grammars.json (message #56), corpus BPE-2 nettoye (fc2b364). bpscript applique (BPS-16).)_
- **BPE-2** `fait` [P2] — CORPUS-HTML-STARTSTRING : 28 fichiers -se.* portaient une chaine de depart corrompue `<HTML>S</HTML>` au lieu de `S` (artefact export web) -> moteur ne derivait rien. **25 nettoyes** (forme simple, identique a la forme saine de reference `-se.Alarm`/`-se.blurb` : `STARTSTRING:` puis le symbole nu). Verifie : le moteur lit desormais `STARTSTRING: S`. Aucune des 7 grammaires recuperees n'utilise un fichier touche (non-regression). NB : sur -se.a, corriger la chaine seule ne suffit pas (format ancien non-JSON, impasse distincte).
  - **BPE-2b** `bloqué` [P3] — 3 fichiers NON touches car forme multi-lignes `<HTML>S<BR>Part1<BR>Part2</HTML>` : `-se.checkArticulation`, `-se.checkControls`, `-se.lahras`. AUCUN fichier sain du corpus n'a de chaine de depart multi-lignes -> pas de reference pour trancher entre « 3 lignes S/Part1/Part2 » et « S seul ». Test empirique non concluant (le moteur ne lit que la 1re ligne ; -gr.checkControls ne se charge meme pas). Refus de deviner la semantique : demande d'arbitrage envoyee a l'architecte.
- **BPE-4** `fait` [P1] — PREFIXE-OR-ORPHELIN : 7 grammaires declarent `-or.<nom>` en tete
  (Djinns, checkVolMasterSlave, cloches1, Mozartexpression, Nadaka1, tryKeyMap, tryKeyXpand) et
  les fichiers `-or.*` EXISTENT dans test-data. Mais `-or.` n'a AUCUNE entree dans la table des
  prefixes connus : `csrc/bp3/-BP3.h:631` porte `// #define wMIDIorchestra 38` **commente**, et
  le slot 38 de `FilePrefix` (`csrc/bp3/-BP3main.h:389-391`) vaut `"-to."`. Consequence :
  `GetRelease.c:1263` ne reconnait pas la ligne d'en-tete, ne la saute pas, et le compilateur la
  lit comme une REGLE -> « Error code 8 ... ??? -or.Djinns » -> 0 sortie.
  PREUVE : en retirant la seule ligne `-or.`, 3 grammaires produisent immediatement —
  Djinns 3671 o, tryKeyXpand 581 o, checkVolMasterSlave 91 o (les 4 autres ont un blocage en plus).
  APPLIQUE 2026-07-18 (arbitrage architecte [61] : correctif DONNEES, pas moteur) : les 7 lignes
  `-or.` sont COMMENTEES (`// -or.<nom>  (BPE-4 : ...)`), PAS supprimees — l'information de
  dependance est preservee pour le jour ou `wMIDIorchestra` sera reactive. Verifie : Djinns
  produit 3671 o a l'identique avec la ligne commentee. 7 fichiers, 1 ligne chacun.
  RESTE OUVERT COTE MOTEUR (hors ce correctif) : (a) re-activer le type MIDI-orchestra, ou
  (b) faire sauter au moteur toute ligne d'en-tete `-xx.` inconnue. Non tranche, non urgent.
- **BPE-5** `fait` [P3] — CORPUS-MOJIBAKE : caracteres corrompus (MacRoman mal decode) dans les
  grammaires, meme famille que BPE-2. `³` la ou il faut `≥` : `-gr.a`, `-gr.tryflags3` (2 fichiers ;
  un seul fichier du corpus a le `≥` correct) -> « Error code 52: Missing slash after /flag/ » sur
  `/K1³200/`. `Ê` (espace insecable corrompu) : `-gr.Mozartexpression` -> « Can't make sense of
  "Êt13Ê=Ê104/100" », Error code 46. NB : S0 patche deja 2 mojibakes (`¥`->`.`, `ž`->`u`,
  s0_snapshot.cjs) mais pas ceux-ci.
  APPLIQUE 2026-07-18 — cibles etablies par ANALYSE D'OCTETS (table MacRoman), pas par supposition :
  `C2 B3` -> `≥` (MacRoman B3 = superieur-ou-egal ; usage `/K1≥100//K1<200/` s'apparie avec `<`) ;
  `C3 8A` -> espace (MacRoman CA = espace insecable ; le voisinage utilise des espaces ordinaires) ;
  `C3 82` -> `¬` (MacRoman C2 = signe NOT ; caractere DOCUMENTE `BP3_help.txt:541` : « periods
  indicate beat delimitations and line breaks '¬' sections »).
  5 fichiers corriges : -gr.a, -gr.tryflags3 (`≥`), -gr.Mozartexpression (espace), -gr.Rajeev,
  -gr.tryTranspose (`¬`). RESULTAT : Mozartexpression RECUPEREE (0 erreur, 1255 o). Les 4 autres
  progressent sans passer (a: 4 err, tryflags3: 5, tryTranspose: 4, Rajeev: 27) — causes restantes
  distinctes, a trier.
- **BPE-6/BPE-7** `en-cours` [P1] — REGLAGES-ANCIEN-FORMAT-NON-LUS : le moteur ne lit QUE des reglages JSON.
  Sur un `-se.*` au format BP2 positionnel il affiche « Could not parse JSON settings »
  (`csrc/bp3/SaveLoads1.c:607`) puis s'arrete SILENCIEUSEMENT (exit 0, aucune phase « Compiling
  grammar », 0 octet) — d'ou des faux « natif ne produit rien ». AUCUN convertisseur cote C
  (grep : rien dans csrc/bp3). Seul le harnais JS convertit (`convertOldSettings`,
  BPscript/test/s0_snapshot.cjs:44-110). AMPLEUR : **84 fichiers -se.* en ancien format contre
  59 en JSON** (143 au total). C'est le blocage DOMINANT du bucket, devant -ho et -or.
  DECISION ROMAIN 2026-07-18 = option (b), convertir le corpus une fois pour toutes
  (`hub/decisions/2026-07-18-convertir-corpus-reglages-vieux-format-json.md`).
  APPLIQUE : les **84** fichiers reecrits en JSON avec le convertOldSettings EXISTANT
  (BPscript/test/s0_snapshot.cjs:44-110, extrait et execute tel quel via scratchpad/conv.cjs —
  aucune reecriture ad-hoc). 84 convertis, 0 echec. Corpus : 143 JSON, 0 ancien.
  Les 59 deja-JSON sont INTACTS (perimetre respecte). Originaux conserves dans l'historique git.
  MESURE AVANT/APRES sur les 38 grammaires concernees : **0 produisaient -> 8 produisent**
  (Djinns 3671 o, Mozartexpression 1255 o, tryKeyXpand 581 o, transposition1 629 o, tryRotate 229 o,
  MyMelody 180 o, check& 41 o, tryMIDIfile 37 o). Les 3 premieres marchaient deja via config
  manuelle ; elles marchent desormais DEPUIS LE CORPUS, sans traitement special.
  IDEMPOTENCE VERIFIEE : `loadSettings` (s0_snapshot.cjs:115) teste `seContent.startsWith('{')`
  et n'appelle le convertisseur que sur l'ancien format -> S0 continue de fonctionner sans
  modification, l'appel n'est pas devenu incorrect (juste inerte). Rien a retirer.
  ⚠ EFFET DE BORD ASSUME ET TRACE : le format JSON n'a AUCUN champ de chaine de depart. La
  section `STARTSTRING:` disparait donc a la conversion. Verifie sur les 84 originaux : 81
  portaient `S` (valeur par defaut du moteur, aucune perte) et 3 portaient la forme non tranchee
  de BPE-2b (`<HTML>S<BR>Part1<BR>Part2</HTML>` : -se.checkArticulation, -se.checkControls,
  -se.lahras). Ces 3 valeurs ne sont plus dans les fichiers de travail mais restent dans git.
  ⛔⛔ REVERTE 2026-07-18 — LA CONVERSION ETAIT DEFECTUEUSE, alerte bpscript [67] CONFIRMEE.
  `convertOldSettings` suppose UN SEUL layout positionnel, or le corpus en contient PLUSIEURS
  (fichiers de 112, 128, 145, 167-199, 238-306, ~357 lignes). Sur les layouts non prevus, les
  positions fixes tombent a cote et produisent des valeurs DEGENEREES.
  AUDIT DE PLAUSIBILITE que j'ai fait apres coup : **34 des 84 fichiers convertis etaient
  suspects** (A4freq hors [200,900], VolumeController != 7/11, C4key hors [36,84],
  SamplingRate < 20, MaxConsoleTime < 10). Signature typique : une serie de champs qui
  s'effondrent tous sur la meme petite valeur (10, 10, 10) ou MaxConsoleTime=1 (qui COUPE la
  production). Exemple verifie : `-se.Alarm` = 112 lignes de valeurs contre 357 pour un fichier
  sain ; ses positions 62/63/65/67 valent toutes '10'.
  DECISION : j'ai RESTAURE les 84 fichiers a leur etat d'avant BPE-7 (`git checkout 0446f54^`).
  Je n'ai pas garde les 50 « plausibles » : ma verification est une HEURISTIQUE, pas une preuve,
  et je refuse de laisser un corpus partage a 40 % corrompu en attendant. BPE-2 (chaine de
  depart) est preserve, il est anterieur. BPE-10 (conventions hors-plage) est annule avec, il
  ne corrigeait qu'un symptome de cette meme conversion.
  RECONVERSION PARTIELLE FAITE 2026-07-18 (garde de plausibilite bpscript 3476a55) : sur les 84
  anciens, **28 eligibles reconvertis**, 56 laisses EN L'ETAT (23 a 128 lignes = anomalie de
  layout non elucidee + 34 suspects de l'audit de plausibilite ; union = 56).
  Audit apres reconversion : **0 valeur implausible** sur les 28.
  GAIN MESURE, avant/apres ne differant QUE par ces 28 fichiers : **0 -> 8 grammaires
  produisent** (Djinns 3671 o, tryKeyMap 1791 o, Mozartexpression 1255 o, tryKeyXpand 581 o,
  tryRotate 229 o, dhadhatite 220 o, MyMelody 180 o, tryhomomorphism 42 o). **0 regression.**
  RESTE : les 56 en attente — 23 sur l'anomalie 128 lignes, 34 sur la plausibilite.
  Reliquat historique (P1, leur territoire) : reconvertir
  les 84, puis re-mesurer le gain (le « 0 -> 8 » annonce est CADUC tant que la conversion est fausse).
  ⚠ A SIGNALER A BPSCRIPT : 8 fichiers ont une convention de note propre qui DIFFERE du
  `php_ref.note_convention` que S0 leur forcait (-se.Djinns 1 vs 0, -se.Mozartexpression 1 vs 0,
  -se.Rajeev 2 vs 0, -se.cloches 1 vs 0, -se.dhadhatite 1 vs 0, -se.simpletemplates 1 vs 0,
  -se.tryGOTO 1 vs 0, -se.trytemplates2 1 vs 0). SANS EFFET AUJOURD'HUI : les 10 grammaires qui
  les utilisent sont toutes `php_ref.blocked` -> ecartees par s0_snapshot.cjs:174. Mais a leur
  deblocage il faudra aligner php_ref sur la valeur du fichier (pour Djinns et Mozartexpression
  j'ai verifie que la valeur du FICHIER est la bonne : production en do/mi/la = french).
- **BPE-3** `en-cours` [P1] — PORTAGE-HO-CLI — ⚠ **RECADRE 2026-07-18, l'intitule etait trompeur** :  _(en-cours: RESOLU EN DATA/CONFIG — zero C, zero decision Romain. bp3-engine (commit 2f01fbb) : les 11->13 grammaires recuperees par alphabet fourni (config php_ref.alphabet) + 5 fichiers -al derives des -ho (en-tete BP2 retire, corpus). Auto-correction : le mecanisme (C) 'en-tete -ho lu comme regle' etait FAUX (CompileGrammar.c:258 consulte FileOldPrefix, le -ho est deja saute) ; le gain venait de l alphabet. Le C n est necessaire pour AUCUNE. BPE-4 reste valide (-or. dans aucune table). Reliquat (A) accepter -ho au CLI = pur confort, non demande.)_
  `-ho` n'est PAS une feature d'homomorphisme a porter, c'est **l'ancien nom du fichier
  d'ALPHABET**. Preuve : `csrc/bp3/-BP3main.h:392` `FileOldPrefix[1] = "-ho."` vs
  `csrc/bp3/-BP3main.h:389` `FilePrefix[1] = "-al."`, meme index `wAlphabet` (`csrc/bp3/-BP3.h:591`) ;
  les fichiers eux-memes se declarent « Alphabet file saved as '-ho.abc' ».
  POURQUOI LE CLI REFUSE : `csrc/bp3/ConsoleMain.c:925` teste `strncmp(args[argn],FilePrefix[w],3)`
  et JAMAIS `FileOldPrefix` -> « Unknown option '-ho' ».
  EFFORT : (A) accepter les anciens prefixes au CLI = etendre cette boucle a `FileOldPrefix`,
  ordre de 5-10 lignes, risque FAIBLE, couvre aussi `-mi.`->`-so.` ; (B) faire tolerer au
  compilateur d'alphabet l'en-tete BP2 des `-ho.*` (`V.2.5` / `Date: ...` — le `:` declenche
  « Can't accept character ':' in alphabet »), risque MOYEN car c'est la zone du bug #48.
  ⚠⚠ RENDEMENT RE-MESURE 2026-07-18 APRES BPE-7 — MA PREMIERE ESTIMATION (1/10) ETAIT FAUSSE.
  Elle etait biaisee deux fois : (i) je testais AVANT la conversion des reglages (BPE-7), donc
  la plupart s'arretaient avant meme de compiler ; (ii) je ne COMMENTAIS PAS la ligne d'en-tete
  `-ho.` de la grammaire — or cette ligne casse la compilation exactement comme `-or.` :
  `-ho.` est dans FileOldPrefix, pas dans FilePrefix, donc GetRelease.c:1263 ne la saute pas et
  le compilateur la lit comme une REGLE (« Error code 8 ... in gram#1 rule 1 »).
  MESURE CORRECTE (ligne d'en-tete neutralisee + alphabet fourni) : **11 grammaires produisent**
    via `-al.<X>` existant : checkSUB1 (4 o), dhati2 (248 o), dhati3 (254 o), koto2 (18 o),
      tryflags3 (9 o), trytemplates (2724 o)
    via le fichier `-ho.<X>` LUI-MEME comme alphabet, en-tete BP2 retire : dhadhatite (220 o),
      koto1 (14 o), tryKeyMap (1791 o), trySrand (158 o), tryhomomorphism (42 o)
  ⚠⚠⚠ CORRECTION 2026-07-18 (2e passe) — MON MECANISME (C) ETAIT FAUX AUSSI.
  J'avais affirme que la ligne d'en-tete `-ho.` etait lue comme une REGLE. C'EST INEXACT :
  `csrc/bp3/CompileGrammar.c:258` consulte explicitement `FileOldPrefix[wAlphabet]` (= `-ho.`),
  donc l'en-tete `-ho.` EST reconnu et saute. PREUVE ISOLEE (meme grammaire, meme alphabet,
  seul l'en-tete change) : trytemplates 2724 o / dhati2 248 o / checkSUB1 4 o — resultats
  STRICTEMENT IDENTIQUES avec `-ho.` et avec `-al.`, 0 « Error code 8 » dans les deux cas.
  Le gain que j'attribuais a (C) venait EN ENTIER de l'alphabet fourni, rien d'autre.
  (BPE-4 en revanche est CONFIRME par test isole : Djinns avec `-or.` = 3 erreurs / 0 octet,
  avec la ligne commentee = 0 erreur / 3671 octets. `-or.` n'est ni dans FilePrefix ni dans
  FileOldPrefix, d'ou la difference de traitement avec `-ho.`.)
  CONSEQUENCE : **BPE-3 ne necessite AUCUN C.** Les 13 grammaires se recuperent en DATA+CONFIG :
    DATA (fait, mon corpus) : 5 fichiers `-al.<X>` derives des `-ho.<X>` (en-tete BP2 retire) —
      -al.dhadhatite, -al.gramgene, -al.tryKeyMap, -al.tryKeyXpand, -al.tryhomomorphism.
    CONFIG (a faire par bpscript) : `php_ref.alphabet` pointant le bon `-al.<X>`.
  RECUPEREES (13, verifiees) : checkSUB1 4 o · dhati2 248 o · dhati3 254 o · koto1 14 o ·
    koto2 18 o · tryflags3 9 o · trytemplates 2724 o · dhadhatite 220 o · tryKeyMap 1791 o ·
    trySrand 158 o · tryhomomorphism 42 o · gramgene1 44 o · gramgene2 507 o.
  Reste eventuellement (A) accepter `-ho` en option CLI (ConsoleMain.c:925 ne consulte que
  FilePrefix) : PUR CONFORT, non necessaire — le harnais passe deja `-al <chemin>`.
  SEQUENCE : BPE-6 (fait) > BPE-4 (fait) > BPE-3 = data/config, PAS de C, PAS d'arbitrage. : le CLI bp3 repond 'Unknown option -ho' -> 27 grammaires native-broken sont en fait BLOQUEES par l homomorphisme non porte au CLI (-ho.abc/abc1/checkhomo/cloches1/dhadhatite/dhin--/Frenchnotes/gramgene/keys/notes/tryKeyMap/tryKeyXpand/tryhomomorphism). Statut reel INDETERMINE tant que -ho pas porte. LIE a la decision design homomorphisme cyclique (chaines cyclic:true + depth%period, en attente arbitrage Romain).
- **BPE-7** `bloqué` [P1] — BPE-6 (BLOCAGE DOMINANT) : 84 fichiers -se.* en ANCIEN format BP2 positionnel (vs 59 JSON, 143 total). Le moteur ne lit QUE du JSON -> 'Could not parse JSON settings' (SaveLoads1.c:607) puis exit 0 SILENCIEUX, 0 octet = cargaison de faux 'natif produit rien'. Aucun convertisseur C ; seul le harnais JS convertit (convertOldSettings, s0_snapshot.cjs:44-110). OPTIONS : (a) porter convertOldSettings en C ; (b) convertir le corpus une fois ; (c) harnais convertit partout (mirror du PHP de Bernard). RECO archi = (c) : ni moteur ni corpus touches, on reflète les conditions standard Bernard. DECISION ROMAIN.  _(bloqué: REVERTE (commit cf53c6e) — convertOldSettings a un bug de LAYOUT (suppose 1 layout, corpus en a plusieurs) -> 34/84 fichiers (40%) corrompus (valeurs degenerees). bp3-engine a restaure le corpus pre-conversion, refuse de garder les 50 'plausibles' (heuristique != preuve). En attente du fix converter de bpscript (BPS-24) -> puis reconversion + re-audit plausibilite + re-mesure honnete. Le '+8' est CADUC.)_
- **BPE-8** `ouvert` [P2] — BPE-4 (-or. prefixe) : 7 grammaires bloquees par un prefixe -or. non reconnu ; retrait = 3 recuperees seches (Djinns 3671o, checkVolMasterSlave 91o, tryKeyXpand 581o). Une ligne. Faible risque.
- **BPE-9** `ouvert` [P3] — BPE-5 (mojibake) : 3 fichiers -gr cassent la compilation car un mojibake (³ pour >=, Ê, Â) tombe DANS une regle (a, Mozartexpression, Rajeev ; + tryflags3). 20 -gr portent la signature mais seuls ceux ou elle est dans une regle cassent. Nettoyer l encodage.
- **BPE-10** (ANNULE avec BPE-7) `ouvert` [P2] — BPE-7-RESIDU-NOTECONV : 3 fichiers -se.* (dhati2, koto1, tryWait) ont une convention de note HORS plage 0/1/2 (=5,5,3) apres conversion (position 47 lue ne contenait pas la convention). Post-JSON, la valeur du FICHIER gagne sur php_ref -> le fix doit etre DANS le fichier. FIX = determiner la BONNE convention par RECOUPEMENT de production (comme Djinns/Mozartexpression) et l ecrire dans le fichier ; si la grammaire est sans note (symboles seuls), retirer la cle (defaut). Affecte dhati2/dhati3/koto1/koto2 (produisent mais spelling possiblement faux).
- **BPE-12** `ouvert` [P3] — PORTAGE-FEATURES-BP2 : 5 grammaires du lot 48 bloquees par des FEATURES non portees (pas un trou de harnais) : _cont/_value/_ins/_step/_fixed, liaison '&' (testTie7), terminaux de gamme (tryScales fap3), blurb. Vrai portage moteur BP2->BP3, a instruire quand priorise. Distinct des trous de mesure (deja resolus).
- **BPE-13** `RESOLU 2026-07-19` [P3] — meme cause que BPE-11 (bug moteur #55, section de tables
  non fermee dans le `-cs`). Corpus corrige, les deux grammaires produisent. Constat d'origine :
  BPE-11-CS-LOOP : tryCsound + vina3 BOUCLENT avec -cs (config correcte) : 0 sortie, code 124, ~241s puis tue ; SANS -cs elles echouent vite (Error 15 _ins). Possible meme famille que bug #50 (watch ~257s). Pas root-cause (boucle infinie vs lenteur patho indistingues). A instruire, non bloquant.

- **BPE-14** `ouvert` [P2] — `cloches1` : production GALOPANTE, pas un blocage. Le tampon croit
  geometriquement (6876 -> 10300 -> 15452 -> 23180 jetons...). Deux causes distinctes a ne pas
  confondre : (a) CORPUS — son `MaxConsoleTime` converti vaut 59944 s (16 h 39), valeur jamais
  plausible, la garde de plausibilite de la conversion l'a laissee passer ; (b) MOTEUR — meme
  ramene a 30 s avec un seul item, le moteur ne s'arrete pas dans les 60 s : la limite de temps
  de calcul ne coupe pas pendant l'expansion du tampon. Remonte a Bernard Bel : **bug #56**.

- **BPE-15** `ouvert` [P2] — REGLES DE DRAPEAUX SEULS refusees (« Error code 8: incorrect
  expression or bad derivation »). Signature partagee par plusieurs muettes : une regle qui ne
  contient QUE des drapeaux, sans membre gauche ni fleche — ex. `-gr.tryTranspose` rule 2
  (`/Atimes = 20/ /Btimes = 19/ /Ctimes = 5/ /Dtimes = 5/`), et 20 occurrences dans `-gr.Rajeev`.
  `-gr.a` presente une variante proche (« Error code 52: Missing slash after /flag/ » sur
  `Dummy --> /K2 = 11/`). A instruire : notation BP2 d'initialisation de drapeaux abandonnee,
  ou defaut du compilateur ? Non tranche, aucun correctif applique.
