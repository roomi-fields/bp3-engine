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

- **BPE-14** `CAUSE ETABLIE 2026-07-19 — DEFAUT DE GRAMMAIRE, PAS DE MOTEUR` [P2] — `cloches1` : Le tampon croit
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

- **BPE-16** `RESOLU 2026-07-19` [P2] — CORPUS-FINS-DE-LIGNE-MAC : 14 fichiers du corpus
  n'avaient que des retours chariot Mac (`0x0D`) et aucun saut de ligne — le moteur y lit une
  seule ligne geante et ne compile rien. `-al.Mozartnotes`, `-al.dhin--`, `-al.engine`,
  `-al.trial.mohanam`, `-da.checktemplates` + 9 fichiers `-tb.*` (ces derniers ignores par le
  moteur, convertis par coherence). REPARATION SURE, non une reecriture : `-al.dhin--`,
  `-al.Mozartnotes` et `-al.engine` sont IDENTIQUES A L'OCTET PRES a leurs jumeaux `-ho.*` une
  fois les fins de ligne converties — ce sont les memes fichiers, abimes au transfert.
  MESURE : `-gr.dhin--` charge avec `-al.dhin--` passe de 22 erreurs a 0.
  NON-REGRESSION : `mohanam`, seule autre entree de la baseline concernee, rend des jetons
  binairement identiques avant/apres (755 jetons). Commit `b4fdf8d`.
  ⚠ PIEGE SYMETRIQUE A NE PAS « REPARER » : 62 fichiers `-se.*` n'ont eux non plus aucun saut
  de ligne (`-se.dhadhatite`, `-se.tryKeyMap`, `-se.gramgene`…) mais les grammaires qui les
  emploient PRODUISENT. C'est leur format normal, pas un degat. Ne pas y toucher.

- **BPE-17** `RESOLU 2026-07-19` [P2] — CHECKRESTS-SILENCE-INDETERMINE : les 12 erreurs de
  compilation de `-gr.checkrests` venaient d'UN SEUL caractere. Le silence indetermine, ecrit
  `…` a l'origine, avait ete converti a tort en `É` (octet `0xC9` du jeu Mac lu comme du
  latin-1 puis re-encode ; octets constates `C3 89`). Retabli en `_rest`, la notation que
  `BP3_help.txt:127` recommande explicitement PARCE QUE l'ancienne souffre des conversions de
  caracteres — la doc decrivait d'avance le bug. 12 erreurs -> 0. Commit `2df5fa1`.
  Meme famille que BPE-5/BPE-9 (mojibake), mais cause et correctif distincts.

- **BPE-18** `en-attente-arbitrage` [P3] — CHECKVOLCHAN-HERITAGE-BP2 : `-gr.checkVolChan` est un
  fichier BP2 de 1994 (`V.2.4`, `Date: Mar 6 Sep 1994`). 12 erreurs -> 5, trois causes empilees
  mesurees une par une : en-tete BP2 + ligne `INIT:` vide (6 erreurs, retires) ; `_vol(` renomme
  `_volume(` en BP3 (`BP3_help.txt:800`, corrige). NON CORRIGE VOLONTAIREMENT : `_cresc` /
  `_decresc` n'existent plus en BP3 (ni moteur ni doc) — leur equivalent plausible est
  `_volumecont` (`BP3_help.txt:817`) mais c'est un choix de SENS, pas une transcription
  (verifie : avec `_volumecont` on tombe a 3) ; et 2 `_script(…)` emploient la syntaxe BP2.
  Arbitrage porte a Romain par l'architecte. Commit `2df5fa1`.

- **BPE-19** `RESOLU 2026-07-19` [P3] — CHECKALLCSOUND-RESSOURCE-ABSENTE : `-gr.checkAllCsound`
  declare `-cs.checkAllCsound`, ABSENT du depot ; les 30 erreurs sont toutes des recherches
  d'instruments dans un fichier inexistant. Avec `-cs.tryCsound` a la place : 3 erreurs. Tous
  les instruments demandes (Flute, Harpsichord, Splashmachine) y sont, sauf `The_default`,
  introuvable dans les 14 fichiers `-cs.*` du corpus. DECISION CORPUS : soit un fichier a ete
  perdu, soit l'en-tete pointe un nom qui n'a jamais existe et il faut le rediriger.
  ARBITRAGE RENDU (critere Romain via architecte [118]) : SUBSTITUER, le sens est preserve.
  (1) C'est bien une grammaire de TEST — son propre en-tete le dit : « This grammar is used to
  play items in -da.checkAllCsound until "Play selection" has been implemented », un banc pour
  auditionner le fichier de donnees regle par regle en basculant un poids.
  (2) Le sens survit a la substitution : `-cs.tryCsound` couvre 28 des 31 references
  d'instruments (Harpsichord 12, numerique 1 -> 9, Splashmachine 3, Flute 2, numerique 3 -> 2).
  `The_default` (3 references) ne teste AUCUN mecanisme distinct : c'est un nom de plus par le
  meme chemin `_ins(<nom>)` que les trois autres noms exercent deja. Verifie qu'il n'est pas un
  mot reserve : absent du moteur et de `BP3_help.txt`, present nulle part ailleurs que dans cette
  paire de fichiers.
  CORRECTIF APPLIQUE : en-tete redirige vers `-cs.tryCsound` ; les 3 regles appelant
  `The_default` COMMENTEES et non supprimees (meme motif que BPE-4, l'information est preservee)
  car elles empechent la compilation quel que soit le poids actif ; poids actif deplace de la
  regle 16 sur la regle 14, qui exerce les memes controles continus (`_pitchrange`,
  `_pitchcont`, `_pitchbend`) — deplacement legitime, l'en-tete du fichier invite explicitement
  a regler le poids soi-meme. MESURE : 30 erreurs -> 0, et la grammaire PRODUIT 8 jetons.

- **BPE-20** `RESOLU 2026-07-19` [P3] — DHIN-TROU-DE-CONFIG : les 22 erreurs de `-gr.dhin--`
  n'etaient pas un defaut du corpus mais de MA capture : l'alphabet n'etait pas charge.
  Charge correctement, `Errors: 0` sans rien modifier. Cause reelle du fichier lui-meme = BPE-16.

- **BPE-21** `RESOLU 2026-07-19 — CE N'ETAIT PAS UN DEFAUT MOTEUR` [P1] — WASM-REGLAGES-TUENT-LE-MIDI : `scripts/test-settings-params.js`
  echoue sur 2 de ses 5 cas, et c'est un DEFAUT REEL, pas un garde perime. Quand on charge les
  reglages par `bp3_load_settings_params`, la production rend **0 evenement MIDI** la ou elle en
  rend 6 sans (cas 2 : « settings must not kill MIDI » ; cas 4 : idem). Les cas 1, 3 et 5 passent,
  donc le moteur produit bien par ailleurs — c'est le passage des reglages qui tue le MIDI.
  ⚠ NE PAS REECRIRE LE TEST POUR LE FAIRE VERDIR (regle explicite de la decision Romain du
  2026-07-19) : l'echec vient du CODE, c'est le CODE qui doit bouger. Le garde reste BRANCHE au
  portillon dans une voie `rouge` dediee, visible, tant que le defaut n'est pas corrige.
  ⚠ **JE ME SUIS TROMPE, ET J'AVAIS FAIT ENDOSSER MON ERREUR.** Ce n'etait PAS un defaut moteur.
  BISSECTION parametre par parametre : sur les six arguments, un seul tue le MIDI — `noteConvention=1`.
  Or **1 = FRANCAIS**, pas anglais : `ConventionString[] = {ENGLISH, FRENCH, INDIAN, KEYS}`
  (`csrc/bp3/-BP3main.h:134`). Le test passait 1 en commentant « English convention=1 », avec une
  grammaire en notes ANGLAISES (`C4 D4 E4`). Sous convention francaise, `C4` n'est pas une note :
  zero evenement est la BONNE reponse.
  PREUVE DE SYMETRIE, qui etablit que le moteur est juste : anglais+notes anglaises = 6 evenements ;
  francais+notes francaises = 6 ; anglais+notes francaises = 0 ; francais+notes anglaises = 0.
  Chaque convention lit les siennes et refuse les autres. Rien a corriger dans le moteur.
  CORRECTIF : le test est aligne sur la verite du moteur (convention 0 pour des notes anglaises) —
  c'est le cas « aligner un garde perime sur la verite ratifiee », PAS « reecrire pour verdir » :
  l'echec ne venait pas du code. Et il est **RENFORCE** : deux cas ajoutes exigent desormais la
  SYMETRIE (francais lit les notes francaises, ET refuse les anglaises). Sans eux, un vert ne
  prouverait pas que la convention est prise en compte, seulement qu'elle ne gene pas.
  7 cas sur 7 passent. Le garde vit en voie rapide ; la voie `rouge` est desormais vide.

- **BPE-22** `TRANCHE 2026-07-19` [P3] — TEST-ALL-TROP-LONG : `scripts/test-all.js` (toutes les grammaires
  confrontees au moteur WASM) depasse 90 s et ne peut pas vivre dans la voie rapide. Range en voie
  `lente` avec un delai de 600 s (`./scripts/gate.sh lente`). A instruire : est-il lent par nature
  TRANCHE (demande architecte [122]) : il est **BLOQUE sur une grammaire**, il n'est PAS lent par
  volume. Mesure : **25 grammaires traitees a 60 s, toujours 25 a 200 s** — zero progression en
  140 s de plus. La derniere traitee est `checktemplates` ; la bloquante est la suivante dans
  l'ordre de tri : **`cloches1`**.
  Ce n'est donc pas un defaut de `test-all` : c'est **BPE-14** (production galopante de `cloches1`)
  qui le bloque. Les deux entrees se referment ensemble — corriger BPE-14 debloque BPE-22.
  COUVERTURE REELLE, chiffree : **25 grammaires sur 110, soit 23 %**. Tant que BPE-14 n'est pas
  corrige, `test-all` ne couvre pas ce qu'il pretend couvrir, et il ne faut PAS s'appuyer dessus.
  Il reste en voie lente, avec ce chiffre ecrit noir sur blanc plutot qu'une couverture supposee.


- **BPE-23** `ouvert` [P1] — PASSAGE-MOTEUR-v3.4.7 : l'amont a publie v3.4.5, v3.4.6 et v3.4.7
  (etiquette `v3.4.7`, commit amont `39512c9`, 2026-07-19). Nous sommes en **v3.4.4** (`b094e18`).
  ECART MESURE sur les sources partagees `csrc/bp3/` : **19 fichiers**, dont `ProduceItems.c`
  (614 lignes), `Zouleb.c` (559), `Arithmetic.c` (139), `Compute.c` (123), `ConsoleMain.c` (117).
  ⚠ **CE N'EST PAS UNE COPIE, C'EST UNE FUSION.** Ces memes fichiers portent nos ajouts locaux —
  le serialiseur `--tokensout`, le portage de deduplication de BPx dans `ProduceItems.c`, et
  `bp3_timed_events.h` qui n'existe pas en amont. Ecraser detruirait ce travail.
  A FAIRE, dans cet ordre : (1) inventorier nos modifications locales fichier par fichier ;
  (2) fusionner en conservant les deux apports ; (3) reconstruire ; (4) verifier #55 sur pieces
  (le correctif annonce n'est PAS visible dans le diff de `SaveLoads1.c`) ; (5) re-mesurer
  `cloches1` avec la limite de temps corrigee ; (6) re-capturer la baseline SI un comportement
  change, et comparer champ par champ ET empreinte par empreinte comme pour la v12.
  **ETAPE 1 FAITE — INVENTAIRE, et il CORRIGE mon estimation a la baisse.** L'ecart brut etait
  du BRUIT DE MISE EN FORME (espaces, fins de ligne). Ecart REEL, a `diff -w -B --strip-trailing-cr` :
  | fichier | brut | reel |
  |---|---:|---:|
  | `ProduceItems.c` | 614 | **38** |
  | `Zouleb.c` | 559 | **7** |
  | `Compute.c` | 123 | 117 |
  | `ConsoleMain.c` | 117 | 95 |
  | `SaveLoads3.c` | 93 | 93 |
  | `Arithmetic.c` | 139 | 31 |
  | les 6 autres | — | 116 |
  **497 lignes reelles au total**, pas ~1800. Le chantier est bien plus petit que je ne l'ai
  annonce — je le corrige ici plutot que de laisser une estimation gonflee justifier un retard.
  NOS AJOUTS sont concentres dans `ConsoleMain.c` (`--tokensout`, `TokensOut`) et dans des
  fichiers que l'amont N'A PAS (`bp3_timed_events.h`) : le risque de les ecraser est donc
  circonscrit, pas diffus.
  ET L'INVENTAIRE CONFIRME #56 : le correctif de la limite de temps est bien visible dans
  `ProduceItems.c` amont (`MaxConsoleTime` / `time_end_compute`). C'est le contraste exact avec
  #55, invisible lui dans `SaveLoads1.c` — deux annonces, une confirmee par la source, une non.
  **ETAPE 2 FAITE — LA FUSION EST REUSSIE, MAIS LA CONSTRUCTION EST BLOQUEE PAR UNE NOUVELLE
  DEPENDANCE SYSTEME.**
  Fusion a TROIS versions (base de fork `b094e18` / notre arbre / amont `39512c9`), via
  `git merge-file` et non a la main : **39 fichiers repris de l'amont tels quels, 1 fusionne,
  ZERO conflit**. Le patch complet est garde dans `BPE-23-fusion-v3.4.7.patch` (5444 lignes).
  DECOUVERTE QUI SIMPLIFIE TOUT : nos modifications locales aux sources partagees du moteur
  totalisent **14 lignes dans UN SEUL fichier**, `ConsoleMain.c` (le drapeau `--tokensout`).
  Plus deux fichiers qui nous sont propres et que l'amont n'a pas (`bp3_timed_events.c/.h`).
  Tout le reste de `csrc/bp3/` etait du code amont intact. Le risque que j'avais decrit comme
  diffus sur 19 fichiers etait en realite de 14 lignes.
  BLOCAGE, precis : l'amont v3.4.7 introduit une dependance **libcurl** INCONDITIONNELLE
  (`csrc/bp3/-BP3.h:97`, `#include <curl/curl.h>`), pour une seule fonction nouvelle qu'on
  n'utilise pas — `enter_notes` (`csrc/bp3/ConsoleMain.c:307`, `curl_global_init`), qui pousse
  une capture MIDI vers un projet web via `UrlToPush`. Les en-tetes de developpement ne sont pas
  installes sur la machine. `apt-get install -s libcurl4-openssl-dev` confirme que le paquet est
  disponible ; l'installer est une modification de la machine de Romain, je ne la fais pas seul.
  ETAT RETABLI, volontairement : arbre revenu en 3.4.4, binaire reconstruit et coherent
  (`./bp3 --short-version` = 3.4.4, les deux arbres identiques, portillon vert). Je REFUSE de
  laisser des sources en 3.4.7 avec un binaire en 3.4.4 — c'est exactement la bifurcation
  silencieuse que le garde anti-retrocompat existe pour empecher, et elle s'est presentee des
  la premiere manoeuvre.
  ⚠ PIEGE OBSERVE SUR PIECES, a retenir : au PREMIER passage `./build.sh` a annonce
  « linux built in 0s » et a **deploye l'ancien binaire** ; c'est le SECOND passage, apres que
  `sync` ait copie les nouvelles sources, qui a revele l'echec de compilation. Sans le double
  passage documente, j'aurais cru avoir construit la 3.4.7 en livrant la 3.4.4.
  **PREPARATION FAITE PENDANT LE BLOCAGE — la verification de #55 est ecrite et mesuree.**
  `scripts/verif-bug55.sh` reproduit le bug de facon DETERMINISTE : un fichier `-cs` authentique
  (`-cs.tryCsound`) prive de sa SEULE ligne `_end tables` fait boucler le moteur — aucun retour
  apres 45 s, mesure sur v3.4.4. C'est l'etat AVANT, etabli noir sur blanc.
  Ce script est le SEUL juge de #55 : la comparaison des sources ne confirme pas le correctif
  annonce par Bernard (`SaveLoads1.c` est identique dans toute la boucle de lecture, lignes
  437-439). Apres le passage en v3.4.7, une seule commande tranchera. Il est branche dans la voie
  `rouge` du portillon (`./scripts/gate.sh rouge`), qui retrouve ainsi un occupant legitime.
  RESTE : accord pour installer `libcurl4-openssl-dev`, puis reappliquer le patch, reconstruire
  en DOUBLE passage, lancer `./scripts/gate.sh rouge` pour trancher #55, re-mesurer `cloches1`,
  recapturer seulement si un comportement change.
