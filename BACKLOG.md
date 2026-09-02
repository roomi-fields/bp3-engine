# BACKLOG — bp3-engine (moteur)

Dette technique **interne** au moteur. Un id court + statut par item.
Statuts : `ouvert` · `en-cours` · `bloqué` · `fait`. Vue globale : `tour backlog` (hub).
Items qui touchent le **langage** (syntaxe/sémantique) → backlog central
`hub/projets/2026-06-15-backlog-langage-bps/README.md` via `tour` (pas ici).

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

- **D1** `ouvert` —
  **POINT DE REPRISE (2026-08-14)** : rien n'est engagé de mon côté et rien ne l'a jamais été — l'item
  est délégué, l'owner est **bpscript**. Prochaine action : leur demander l'état de l'utilitaire
  partagé avant toute écriture ici. Ce qu'elle attend : leur réponse. Aucune dépendance avec le
  chantier des entrées.
  Libellé d'origine : Tokeniseur « ordre texte » qui REFLÈTE BP3 (markers `=`/`:`, virgule `{N,…}`) — owner **bpscript** (utilitaire partagé). Si l'alignement exact demande du dev → leur backlog. Réf. CDC `hub/contrats/2026-06-16-sortie-production-texte-kanopi.md` §9.
- **BP3E-ISO-EKDOTIN** `fait` [P4] — ISO-EKDOTIN-TEMPLATES [P4] : ek-do-tin + templates ont un oracle natif présent MAIS leur source -gr est absente de test-data (branche wasm, library/ non checkout) → non mesurables par le frontal .gr, donc non publiables tant que la source n'est pas dispo. Fournir les sources -gr si on veut les exposer. Signalé par bp3-frontend [105]  _(fait: Confirme par bp3-engine sur sa propre mesure (contre-mesure du 2026-08-14))_
- **BP3E-ISO-REGRESSION** `bloqué` [P3] — ISO-100 RÉGRESSION-NATIF [P3] : dhadhatite1 + dhin1 — le moteur natif ne sort RIEN alors qu'un oracle WASM existait (16/24 jetons). Régression moteur OU dépendance manquante (aux). À discriminer — potentiellement au-delà de ces 2. Signalé campagne bpscript A.2b [71bda33]  _(bloqué: élargi : 4 grammaires — dhadhatite1, dhin1, tryhomomorphism (PHP 6/natif 0), tryRagas (PHP 42/natif 0). Le natif produit RIEN où la référence produisait = régression moteur OU aux manquant. Débloque potentiellement plusieurs si corrigé. bp3-engine dormant → à relancer quand on attaque Phase D moteur)_
- **BP3E-BUCKET-CONSOLE** `ouvert` [P3] — ISO-100 BUCKET-CONSOLE-BUGS [bonne nouvelle] : le plan bp3-frontend a trouvé que le bucket moteur (55 'natif ne produit pas') est SURTOUT des BUGS DE CONSOLE (ConsoleStubs.c LoadAlphabet) + câblage harnais, PAS des features moteur manquantes → plusieurs adressables SANS toucher le cœur moteur. Conséquence : le dénominateur productible (53) va grossir. Chantier à cadrer : réparer les bugs console → re-mesurer combien de grammaires sortent du bucket vers le productible
- **BPE-1** `sans-objet` [P1] — S0-HARNAIS-DEPS
  ⛔ **SANS OBJET (2026-08-14)** : l'outil visé n'existe plus. `s0_snapshot.cjs` et le pipeline S0-S5
  qui le portait ont été supprimés — mesuré des deux côtés le 2026-08-14 en instruisant BPE-7, zéro
  occurrence chez BPScript comme ici. L'item décrit un correctif à apporter à un harnais disparu, et
  sa part qui m'incombait — livrer les six spécifications — est faite depuis le message #56.
  Aucune dépendance avec le chantier des entrées. Libellé d'origine : : s0_snapshot.cjs (BPscript/test) doit passer les DEPENDANCES declarees en tete de grammaire (-al alphabet, -gl, -cs csound, -to tonality) — actuellement il lance -gr seul -> echec spurieux (62/63 erreurs dhati = alphabet non charge). Fix = lire les deps par grammaire (logique dans scratchpad/reharness.py) et les passer. Recupere dhati + 5 grammaires (12345678, 765432, Nadaka, trial.mohanam, tryRagas) SANS toucher le moteur.  _(bloqué: CORRIGE : pas un fix code s0_snapshot.cjs — s0 passe DEJA -al si php_ref.alphabet present (l.202-210). Le vrai fix = entrees grammars.json manquantes (config), TERRITOIRE bpscript. bp3-engine fournit les specs, bpscript applique. Reassigne -> BPScript.)_  _(en-cours: DEBLOQUE+RESOLU cote specs : bp3-engine a livre les 6 specs grammars.json (message #56), corpus BPE-2 nettoye (fc2b364). bpscript applique (BPS-16).)_
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
- **BPE-6/BPE-7** `fait` [P1] — REGLAGES-ANCIEN-FORMAT-NON-LUS.
  **CLOS LE 2026-08-14 sur instruction de l'architecte**, après l'arbitrage de Romain « ce qui est
  conforme reste ». Les 22 fichiers sont convertis, **zéro reste au format BP2**, la conformité est
  établie clé par clé (`scripts/conformite-reglages-convertis.py`, 22/22, zéro clé manquante) et les
  cinq grammaires concernées sont revenues dans l'assiette scellée — 91 → 96.
  **REQUALIFIE LE 2026-08-14 SUR LA MESURE DU JOUR, decision de Romain « on convertit »** (relayee
  par l'architecte [329]). Le libelle ci-dessous decrit 84 fichiers et une attente du correctif
  `convertOldSettings` de BPS-24 : les deux sont faux. L'outil attendu n'existe plus, ni chez
  BPScript ni ici, et le pipeline S0-S5 qui le portait a ete supprime.
  **PERIMETRE REEL, mesure par `scripts/inventaire-reglages-anciens.py`** : **22 fichiers** `-se.*`
  au format BP2 positionnel sur 143, portant **11 versions distinctes** — de `V.2.4` a `BP2.7.3`.
  **5 grammaires** les designent : `check&`, `koto1`, `koto2`, `transposition1`, `tryMIDIfile`.
  **Aucune dans l'assiette scellee v15**, sorties par l'arbitrage de Romain du 2026-08-12.
  18 des 22 ne sont designes par aucune grammaire du registre.
  **CE QUI REND LA CONVERSION SURE CETTE FOIS** : `scripts/convertir-reglages-bp2.py` porte le
  lecteur d'origine du moteur (`docs-developer/format-se-bp2/LoadSettings.reference.c`) avec ses
  branchements `iv` et `jmax`, et n'ecrit que les variables ayant une cle dans le lecteur JSON
  actuel. Les deux demi-cartes viennent du code. La conversion de 2026-07-18 corrompait 40 % parce
  qu'elle supposait un agencement unique.
  ⚠ **Le piege trouve en chemin** : `BP2.7` est un prefixe de `BP2.7.1`, et prendre le prefixe donne
  `iv=12` au lieu de 13 — donc un autre agencement. La correspondance se fait sur la version la plus
  longue presente.

  Libelle d'origine, conserve : le moteur ne lit QUE des reglages JSON.
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
- **BPE-3** `fini-a-clore` [P1] — PORTAGE-HO-CLI
  ✔ **FINI SUR SON OBJET (2026-08-14)** : les 13 grammaires visées sont récupérées en data et en
  configuration, zéro ligne de C, commit `2f01fbb`. Le mécanisme supposé était faux et l'item porte
  son autocorrection.
  ⛔ **CE QUI RESTE N'EST PAS UN RELIQUAT À FAIRE** : accepter `-ho` au CLI est du confort que personne
  n'a demandé, ET il touche `ConsoleMain.c`, un fichier de Bernard — donc il exigerait l'accord de
  Romain pour le geste précis. Il ne se rouvre pas de lui-même : si le besoin apparaît, il fera un
  item neuf avec sa demande d'accord.
  Aucune dépendance avec le chantier des entrées. Libellé d'origine : — ⚠ **RECADRE 2026-07-18, l'intitule etait trompeur** :  _(en-cours: RESOLU EN DATA/CONFIG — zero C, zero decision Romain. bp3-engine (commit 2f01fbb) : les 11->13 grammaires recuperees par alphabet fourni (config php_ref.alphabet) + 5 fichiers -al derives des -ho (en-tete BP2 retire, corpus). Auto-correction : le mecanisme (C) 'en-tete -ho lu comme regle' etait FAUX (CompileGrammar.c:258 consulte FileOldPrefix, le -ho est deja saute) ; le gain venait de l alphabet. Le C n est necessaire pour AUCUNE. BPE-4 reste valide (-or. dans aucune table). Reliquat (A) accepter -ho au CLI = pur confort, non demande.)_
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
- **BPE-7** `fait` [P1] — BPE-6 (BLOCAGE DOMINANT) : 84 fichiers -se.* en ANCIEN format BP2 positionnel (vs 59 JSON, 143 total). Le moteur ne lit QUE du JSON -> 'Could not parse JSON settings' (SaveLoads1.c:607) puis exit 0 SILENCIEUX, 0 octet = cargaison de faux 'natif produit rien'. Aucun convertisseur C ; seul le harnais JS convertit (convertOldSettings, s0_snapshot.cjs:44-110). OPTIONS : (a) porter convertOldSettings en C ; (b) convertir le corpus une fois ; (c) harnais convertit partout (mirror du PHP de Bernard). RECO archi = (c) : ni moteur ni corpus touches, on reflète les conditions standard Bernard. DECISION ROMAIN.  _(fait: fait le 2026-08-14, f936475 : 143 fichiers -se sur 143 en JSON, zero ancien format, mesure par l architecte le 2026-09-02. Ce qui reste est un AUDIT, item separe : 15 fichiers portent la signature du bogue de conversion (DeftVelocity, DeftVolume, Quantize a 10 ; un Seed=0l))_
- **BPE-8** `fait` [P2] — BPE-4 (-or. prefixe) : 7 grammaires bloquees par un prefixe -or. non reconnu ; retrait = 3 recuperees seches (Djinns 3671o, checkVolMasterSlave 91o, tryKeyXpand 581o). Une ligne. Faible risque.  _(fait: Confirme par bp3-engine sur sa propre mesure (contre-mesure du 2026-08-14))_
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

- **BPE-15** `CAUSE ETABLIE 2026-08-09 — DATA/CORPUS (BP2), PAS DEFAUT MOTEUR` [P2] — l'intitule
  d'origine (« regles de drapeaux seuls refusees ») est FAUX, confronte au binaire sur les deux cas :
  une RHS de drapeaux SEULS compile (`S --> /x = 3/` → Errors:0), et `Dummy --> /K2 = 11/` (cite
  pour `-gr.a`) aussi. Ce n'est donc pas une regle de drapeaux qui casse.
  VRAIE CAUSE, bisectee au binaire (bp3 3.5.1) :
  (a) BP3 exige une regle COMPLETE par ligne. Une ligne NUE sans `-->` est refusee « Error code 8 »,
      que ce soit des drapeaux (`/Atimes = 20/ …`) OU des notes (`D4 E4`) — meme erreur, rien de
      specifique aux drapeaux. Le corpus (tryTranspose l.9, Rajeev) porte la RHS MULTI-LIGNES de BP2,
      que le parseur ligne-a-ligne de BP3 n'accepte pas. → correctif DATA : rejoindre chaque regle
      sur une seule ligne.
  (b) `¬` (U+00AC, octets c2 ac) en entree de RHS → « Error code 15 ». C'est un marqueur de
      saut-de-ligne d'AFFICHAGE (BP3_help.txt:538-541 le montre en sortie `abba.bcca.¬`), pas un
      jeton d'entree ; il a fuite dans la grammaire (tryTranspose l.8). Le vrai marqueur de battement
      `.` fonctionne. → correctif DATA : retirer `¬`.
  (c) `-gr.a` : son echec vient de `--.` au lieu de `-->` (l.16) et du mojibake `≥` (famille BPE-5/9),
      pas des drapeaux.
  CONCLUSION : rien a remonter a Bernard — le compilateur est coherent (une regle par ligne, `-->`
  obligatoire). Meme famille que BPE-2/5/16 (conventions BP2 dans le corpus).
  DIAGNOSTIC COMPLET de tryTranspose (bisecte au binaire, 4 erreurs) : 2 sont BPE-15 (ligne de
  drapeaux nue + `¬`), 2 sont BPE-3 (« Error code 15 » sur `{a N}`/`{a P}` = terminal MINUSCULE non
  defini car l'alphabet `-ho.tryKeyMap` n'etait pas charge ; `a` est defini l.5 de ce fichier).
  ZERO bug moteur. PREUVE de correctif : joindre l.8-9 en une ligne + retirer `¬`, ET charger
  l'alphabet en `-al` → `Errors: 0` ET la DERIVATION fonctionne (work-string expanse sous `-D` :
  20× `_transpose(0.20){A4…}` etc.).
  ⚠️ MAIS `-o` rend 0 octet la ou `-D` affiche l'item — canal de sortie a instruire (sous-question
  SEPAREE, non liee aux drapeaux ; possiblement -se/limite/taille). RESTE, donc, avant de declarer
  un gain : (1) elucider `-o` vide (compile+derive ≠ item ecrit) ; (2) reecriture data de
  tryTranspose/Rajeev ; (3) config alphabet cote bpscript (php_ref.alphabet, famille BPE-3). Je
  n'ai PAS mute le corpus : pas de gain declare non verifie end-to-end.

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


- **BPE-23** `fait` [P1] — PASSAGE-MOTEUR-v3.4.7 : l'amont a publie v3.4.5, v3.4.6 et v3.4.7
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
  **CLOS le jour meme (2026-07-19, 16:22) : l'accord a ete obtenu, `libcurl4-openssl-dev` installe
  et cable via pkg-config (non en dur). Patch reapplique, double passage effectue.
  `./bp3 --short-version` = **3.4.7** (commit `38a8f32`). Bug #55 CORRIGE, verdict empirique via
  `verif-bug55.sh` (seul juge). Build WASM casse par la mise a jour puis repare (commit `d93048a`),
  changelog documente (commit `1c984d3`), appel `--tokensout` restaure apres regression
  (commit `49c0b12`). La baseline v13 (`baseline-native/baseline.json`, `"binaire": "bp3 v3.4.7"`)
  tourne sur ce binaire.**
- **BPE-24** `fait` [P2] — Tracabilite du binaire natif (constat #65) : aucune empreinte fiable — deux md5 distincts impriment la meme version et le meme horodatage, la provenance de la baseline est tapee a la main et FAUSSE pour 14 entrees, le md5 n est consigne nulle part. Reponse retenue : que la capture enregistre le md5 du binaire + l IDSTRING complet. Re-capture des 14 = arbitrage Romain, INTERDITE sans son mot.  _(fait: Confirme par bp3-engine sur sa propre mesure (contre-mesure du 2026-08-14))_
- **BPE-25** `abandonné` [P3] — checktemplates : fausse alerte. Deja ancre nativement, sous le nom de corpus « templates » (entree #25 des 113, `baseline-native/baseline.json:1743-1764` et `hub/projets/2026-07-16-iso-100-grammaires/BASELINE-CENTRALE.md:89`), avec `produit:true`, `capture_comparable:true` et une capture deja presente (`baseline-native/captures/templates.text.txt`, 5 lignes). L'absence du literal « checktemplates » comme nom de grammaire avait ete confondue avec l'absence d'ancre — la source `-gr.checktemplates` / `-se.checktemplates` est bien celle du corpus « templates ».
- **BPE-26** `ouvert` [P2] — ISO-100 -- _stepOn et _stepOff sont INECRIVABLES : le controle de perf _step les masque par match de prefixe glouton SANS garde de frontiere (CompileProcs.c:722-732), erreur code 15 a toute position. Declarees en GramProcedure et inatteignables. Constat #69. A REMONTER A BERNARD (decision Romain 2026-08-09 : backlog).
- **BPE-27** `ouvert` [P3] — ISO-100 -- CINQ directives sans comportement observable en lot, preuve source : _stop (InterruptCompute est un stub console, ConsoleStubs.c:142) ; _capture et _part (sautees en production, ProduceItems.c:1239 et Compute.c:1664, MIDI temps-reel seulement) ; _printOn et _printOff (basculent DisplayProduce, Compute.c:243, aucun differentiel en produce console). Fait mesure, pas echec. Decision Romain 2026-08-09 : backlog.
- **BPE-30** `ouvert` [P2] — `test-data/` EST CONSOMMÉ PAR COPIE, SANS CHEMIN DÉRIVÉ. Kanopi en porte
  une copie complète — 143 fichiers dans `packages/library/test-assets/bp3/commun/`, chargés en glob
  eager — et **rien ne la dérive de la source**. Mesuré le 2026-08-14 : sa copie était en retard
  exactement des 22 réglages convertis le matin même, et aucun autre fichier ne différait.
  **Ce que la porte change** : les consommateurs qui lisent le disque reçoivent une correction sans
  geste ; celui qui en tient une copie diverge en silence, et son garde de correspondance vérifie que
  chaque chemin **existe** sans rien dire de sa **fraîcheur** — une copie périmée y passe au vert.
  **La moitié qui m'appartient** : reporter des fichiers à la main reproduirait la divergence au coup
  suivant. Le geste juste est un chemin dérivé, et il se décide avec kanopi — sa resynchronisation
  est inscrite chez lui en KAN-51.
  ⛔ En attente : le chantier ouvert est celui des entrées, et rien ne se pose ici avant.

- **BPE-36** `ouvert` [P2] — UN CLONE FRAIS NE LANCE AUCUN PORTILLON. Priorité posée par
  l'architecte le 2026-08-17 sur la mesure ci-dessous : le défaut est réel et dormant.
  `core.hooksPath` est une configuration locale, jamais versionnée : un clone frais ne porte pas
  ce qui désigne `scripts/githooks`, donc git ne lance rien. Le crochet a été rendu exécutable
  dans l'index (`da81eae`) puis les treize scripts avec lui (`1a6349f`) — nécessaire et
  insuffisant : le crochet est lançable et personne ne l'appelle. Un mécanisme d'installation
  reste à poser.
  **Qui est atteint** : personne aujourd'hui. La vérification qui refuse une construction de
  production est `kanopi/scripts/lib/voisins-lies.mjs`, et elle porte sur les dépôts consommés
  **par lien symbolique** ; kanopi consomme ce dépôt par copie — 417 fichiers sous
  `packages/library/test-assets/bp3/commun/`. Le seul clone du dépôt est
  `~/dev/bp/BPweb/bp3-engine`, sur `06a0de5`, propre. Le défaut mordrait le jour où un
  consommateur lirait par lien, ce qui est l'objet de [[BPE-30]].
  **L'arbre sale au checkout est résolu** (`59aebd2`) : 39 grammaires normalisées en LF, 43
  sorties identiques au sha256 près sur du contenu non vide, 0 écart, 4 nommées hors preuve. Un
  clone frais rend 0 ligne de `git status`.

- **BPE-37** `fait` [P3] — QUARANTE-QUATRE FICHIERS DU CORPUS PORTENT ENCORE DES CR, ET RIEN NE  _(fait: Traite par bp3-engine, rendu le 2026-08-18. Clos par l architecte.)_
  LE DIT. `test-data/.gitattributes` ne couvre que `-gr.*` : les autres types passent au vert dans
  un clone frais tout en portant des retours chariot. Mesure du 2026-08-17 sur les blobs : 83
  fichiers de `test-data` en portent, 39 traités, 44 restants — 22 en `-da.`, 8 en `-al.`, 2 en
  `-sc.`, un chacun en `-so.` `-md.` `-kb.` `-in.` `-gl.`, et sept sans préfixe de type.
  **L'un est en CR seul** : `test-data/annotated.bpse`, 337 CR, aucun CRLF — exactement la
  corruption qui a motivé le garde en juillet, sur un autre fichier que celui alors corrigé.
  Le geste est de même forme que celui des grammaires : témoin, normalisation, contre-témoin.
  Élargir la règle sans normaliser rendrait ces 44 sales d'un coup.

- **BPE-39** `ouvert` [P2] — RÉCLAMER LA LISTE D'ÉVÉNEMENTS FAIT ÉCRIRE LE MOTEUR DANS
  `test-data/`. Mesuré le 2026-08-17 par épreuve contrôlée : avec `-so.abc` et `-al.abc`, la même
  commande ne crée rien sans `--eventlistout` et crée `test-data/abc.json` avec. Le moteur dépose
  un dump JSON des prototypes **à côté du fichier `-so.` qu'on lui donne**, donc dans le corpus.
  **Trois résidus sont déjà committés** : `dhati.json`, `tryCsoundObjects.json`, `tryKeyMap.json`
  — un par `-so.` correspondant, suivis par git, jamais identifiés comme dérivés.
  **Ce que ça a coûté aujourd'hui** : mes mesures de la journée ont modifié `dhati.json` et créé
  `abc.json` sans que je m'en aperçoive ; trouvé par un `git status` de contrôle après avoir écrit
  dans un rapport que le corpus était intact. Restauré, corpus propre.
  **Qui déclenche** : `scripts/confronter-jetons-liste.py` et `scripts/confronter-amont.py`
  réclament `--eventlistout`. `baseline-native/capture.py` ne le réclame pas — la référence est
  indemne, vérifié.
  Le geste tient en deux parties : faire écrire ces outils dans une copie hors corpus, et décider
  du sort des trois résidus committés. La seconde touche le corpus et attend Romain.

- **BPE-49** `fait-a-clore` [P3] — LE MAILLON `oracle-fige-intact` N'AVAIT PAS D'INJECTION DÉDIÉE.
  Posé le 2026-08-21 avec la bascule des injections en copie, complété le même jour.
  `scripts/gate-oracle-injection.sh` monte un dépôt jetable dont le rôle d'oracle est tenu par un
  fichier quelconque, y copie `copie-injection.sh` — qui déduit sa racine de son emplacement — et
  **écrit réellement** dans ce fichier. Le code éprouvé est le même, l'écriture est réelle, et le
  binaire de référence n'est pas touché : l'injection vérifie son empreinte en dernière étape.
  Quatre volets : vert au départ, rouge nommant le fichier et les deux empreintes après écriture,
  vert après restauration, oracle réel intact. Branché au portillon sous `oracle-fige-morsure`,
  19 maillons.

- **BPE-48** `fait-a-clore` [P1] — LE PORTILLON ÉCRIT DANS L'ARBRE DE TRAVAIL, DONT LE CODE AMONT ET
  L'ORACLE. Mesuré le 2026-08-21, sur demande de l'architecte. **Corrigé le même jour.**
  **Après bascule** : zéro écriture de contenu, zéro horodatage touché, portillon de 2,3 s à 2,6 s.
  Les huit injections s'éprouvent dans une copie posée par `scripts/copie-injection.sh`, hors de
  l'arbre — clone partagé de 17 Mo en 600 ms, portant les références distantes, la configuration
  locale, le travail non enregistré et ce que le dépôt ignore. Les 730 Mo d'oracles figés sont
  atteints par lien symbolique, et le maillon `oracle-fige-intact` vérifie que rien ne les a écrits.
  Sans copie, pas d'injection : le portillon échoue plutôt que de se replier sur l'arbre réel.
  ⛔ **Ce que la bascule a révélé, et qui la bloquait** : `baseline-native/capture.py` portait sa
  racine en dur. Lancée depuis la copie, elle lisait et écrivait l'arbre **original** en se croyant
  isolée — l'injection de la sonde y mesurait donc l'original, preuve nulle et pollution sous
  couvert d'isolement. La racine se déduit désormais du fichier, et la zone de travail aussi : elle
  suivait le chemin de bac à sable d'une seule session. Mesure inchangée depuis l'original.
  Portillon complet, 2,3 s, arbre propre avant et après. **Sept écritures de contenu**, toutes
  restaurées, chacune visible de 0,00 à 0,05 s : `source/BP3/PlayThings.c`, le binaire `bp3`,
  `baseline-native/baseline.json`, `baseline-native/capture.py`, deux captures, et la création de
  `scripts/bp3_leurre_legacy.c` — un nom fabriqué pour ressembler à ce qu'un garde chasse, non ignoré
  par git. Sept autres fichiers ne reçoivent qu'un horodatage, dont `source/BP3/Misc.c`.
  **Ce qu'un voisin peut y lire** : une modification non déclarée du moteur d'origine, et une mesure
  prise sur un oracle muté.
  **L'obstacle à la bascule vers une copie** : `bp3` fait 2 536 512 octets et **n'est suivi par aucun
  commit** — `.gitignore:7`. Un clone ne le porte pas, et les deux maillons qui le mesurent
  rougiraient sur un dépôt sain. Une copie doit donc porter aussi ce que le dépôt ignore
  délibérément, population distincte des modifications en cours et invisible à `git status`.
  **Le geste** : huit injections à basculer, chacune reprouvée mordante une par une sur le nouveau
  support. Le portillon reste en l'état d'ici là — le désarmer serait un repli.

- **BPE-47** `fait-a-clore` [P1] — UNE POUSSÉE NUE VISAIT LE DÉPÔT DE BERNARD BEL. Mesuré et corrigé
  le 2026-08-19, en confrontant une clame de l'architecte sur le régime de ce dépôt.
  `branch.wasm.remote` valait `upstream` et `branch.wasm.merge` valait `refs/heads/graphics-for-BP3` :
  un `git push` sans argument visait `bolprocessor/bolprocessor`, le dépôt du mainteneur externe.
  Seul un garde-fou de nommage l'arrêtait, et son message parlait de configuration, jamais de
  destination.
  **Ce que ça a déjà coûté** : une poussée nue de ce jour a échoué en silence, et le code de sortie lu
  était celui du filtre — la synchronisation a été annoncée avant d'être vraie, puis corrigée.
  `wasm` suit désormais `origin/wasm`. L'écart avec l'amont reste lisible par
  `git rev-list --left-right --count upstream/graphics-for-BP3...wasm`, qui rend 42 et 221.

- **BPE-46** `bloqué` [P1] — LA BRANCHE PAR DÉFAUT PUBLIÉE EST LE MIROIR DE L'AMONT, PAS LA BRANCHE
  VIVANTE. Mesuré le 2026-08-19, sur un signalement d'atlas confronté à mon état réel.
  `gh repo view --json defaultBranchRef` rend `master`, et `origin/master` vaut `e31c3a7` — le
  dernier commit de Bernard Bel, daté du 2025-01-28, identique à `upstream/master`. **Un clone de ce
  dépôt rend donc un arbre de janvier 2025, sans aucun des 696 commits de `wasm`.**
  **Ce qui n'est pas en cause** : `wasm` est publiée et à jour, zéro commit local en attente, et les
  fichiers que la carte d'autorités désigne y sont tous présents. La pureté de `master` est la règle
  — c'est contre lui que se confronte chaque montée de version amont.
  **Ce qui l'est** : tout voisin qui résout `origin/HEAD` lit le miroir et conclut que ce dépôt n'a
  pas son travail. Le défaut est dans ce que le dépôt annonce, non dans leur lecture.
  **Bloqué** : basculer la branche par défaut change ce que le dépôt présente comme lui-même, et
  l'articulation entre le miroir amont et la branche vivante appartient à Romain.
  **La portée est locale à ce dépôt** : atlas mesure le 2026-08-19 que quatre dépôts de la tour ne
  posent aucune branche par défaut. Une résolution par ce moyen reste donc muette chez un quart de la
  tour même après cette correction, et la branche de référence se déclare au contrat partagé. Aucun
  voisin n'attend cet item : atlas déclare `origin/wasm` pour ce dépôt, avec sa cause.

- **BPE-45** `ouvert` [P3] — TROIS FICHIERS DE CORPUS GISENT HORS DU DÉPÔT, SORTIS DE LA RACINE.
  Constaté le 2026-08-19 à 11h15, à l'arrêt général demandé par l'architecte.
  `-ho.transposition` (une table d'homomorphisme), `-se.transposition` (des réglages BP2 datés de
  1997) et `console_strings.json` (les chaînes de console du moteur) traînaient à la racine, jamais
  suivis. Ils sont déposés dans
  `/tmp/claude-1000/-home-romi-dev-bp-bp3-engine/2886bb74-5c18-4f37-8f64-8d3075d1375c/scratchpad/residus-racine/`,
  intacts.
  **Ce qui reste à faire** : établir qui les a écrits, et si les deux premiers rejoignent `test-data/`
  avec leur entrée au `REGISTRE.json` ou se jettent. Même famille que [[BPE-39]] — un outil qui écrit
  hors du corpus.

- **BPE-44** `ouvert` [P3] — LE GARDE ANTI-RÉTROCOMPATIBILITÉ ROUGIT SUR UNE MENTION DESCRIPTIVE.
  Mesuré par injection le 2026-08-19, après une décision de méthode de l'architecte sur le périmètre
  des gardes de forme.
  `scripts/gate-legacy.py:32` cherche les mots `deprecated|legacy|obsolete|voué au retrait` sur une
  ligne quelconque, et marque tout symbole déclaré dans les deux lignes suivantes. Un commentaire qui
  dit qu'une fonction **n'est pas** vouée au retrait suffit donc à la marquer.
  **La morsure, prouvée** : une sonde portant `# Cette fonction n'est pas deprecated` deux lignes
  au-dessus d'une déclaration et un appelant vivant fait sortir le garde en code 1, sur 32 fichiers
  examinés. Sonde retirée, garde revenu vert sur 31 fichiers.
  **Le geste** : discriminer sur la graphie qui porte la décision plutôt que sur le mot en prose —
  une convention de marquage reste à choisir, et ce choix est un arbitrage.
  **Ce que la borne du motif coûte, mesuré le 2026-08-19 sur les primitives natives** : `_map` sort
  à 12 fichiers sans borne, 0 avec une borne exigeant la parenthèse, 2 avec une borne de mot ; `_sub`
  sort à 19 puis 0, ses occurrences étant toutes `_subgram` et `_subtable`. Une borne trop lâche
  compte des sous-chaînes, une borne trop stricte efface les primitives sans argument. Le compte juste
  se prend sur une borne de mot, et se vérifie en ouvrant les occurrences.
  Ce que le garde tient déjà : le périmètre exclut `source/BP3/`, nommément et pour une cause écrite,
  et il compte ce qu'il a examiné plutôt que d'accepter zéro.

- **BPE-43** `ouvert` [P2] — L'INDEX SERT DEUX CAPTURES DE RÉFÉRENCE QUI N'EXISTENT PLUS, ET LE
  RETRAIT EST EN FILE SANS SERVEUR. Mesuré le 2026-08-18, sur demande de recensement de l'architecte.
  535 documents indexés, **159 n'existent plus sur le disque — 29,7 %**. Deux instruments
  concordants : l'énumération `rtfm files` confrontée au disque, et `git ls-files`.
  **Répartition** : 156 sont des résidus dans trois répertoires de capture que git n'a jamais suivis,
  dont deux ont disparu et un est vide. Les 2 derniers vivent dans `baseline-native/captures`, le
  répertoire de référence, mêlés à 158 vivants : `check_.text.txt` et `tryMIDIfile.text.txt`, dont
  les jumeaux `.tokens.json` existent.
  **Le coût, constaté** : sur la requête « tryMIDIfile capture texte », le fantôme sort premier,
  score 17,90, devant six vivants. L'axe texte de l'oracle est celui qui ment.
  **La cause** : `rtfm queue stats` rend `remove done=939 pending=114`. Le retrait existe et a tourné
  939 fois ; 114 attendent. L'ouvrier mutualisé sert 20 dépôts sur 12 places et ne sert pas celui-ci ;
  deux relevés espacés ne montrent aucun drainage. La reprise de cet ouvrier sort de ce dépôt.
  **Une ligne d'énumération porte `(? bytes)`** — l'index ne parvient plus à mesurer ce fichier. Un
  premier motif de lecture l'a écartée en silence, l'écart n'apparaissant qu'en comparant à l'en-tête.
  **L'autre moitié, mesurée le même soir** : 385 fichiers vivants, versionnés et indexables, dont
  **14 absents de l'index — 3,6 %**. Onze attendent en file, aucun n'a échoué, et trois n'ont jamais
  été réclamés : `source/BP3/.vscode/{tasks,settings,c_cpp_properties}.json`, suivis par git et
  qu'aucun filtre d'exclusion ne réclame — le parcours ne descend pas dans les répertoires cachés.
  ⛔ **Les deux comptes se croisent sur deux noms** : `check_` et `tryMIDIfile` ont leur capture
  texte indexée et morte, et leur capture jetons vivante et absente. Pour ces deux-là l'index porte
  exactement la moitié fausse. Ni le compte des morts ni celui des absents ne le montrait seul.
  Sont également en file les deux documents écrits le 2026-08-18 pour rendre les mesures trouvables,
  `comment-un-nom-se-lit.md` et `etat-du-portillon.md`.
  ⛔ **45 des 159 morts ne sont inscrits nulle part** — ni en file, ni tombés, au 2026-08-18 à 23h.
  Un bloc contigu de `baseline-native/captures.en-cours`, de `765432` à `cloches1`. L'inscription des
  retraits s'arrête en cours de route ; `pending=114` porte 71 % du travail et tait le reste.
  Contrôle inverse : aucun retrait en file ne porte sur un vivant.
  **Cet état ne dure pas** : au 2026-08-19 à 10h50, le compteur de retraits passe de 939 à 1098, soit
  159 exactement, et la file en porte zéro. Les 45 ont donc été inscrits et servis. La mesure de la
  veille vaut pour son heure ; l'arrêt qu'elle décrit n'est pas permanent.
  **La réconciliation est sûre ici** : 376 vivants indexés, zéro illisible, zéro résolu hors de la
  racine, zéro lien symbolique suivi. Mesuré après avoir lancé le `gc`, non avant.
  **Nature des morts** : 159 captures, artefacts régénérables ; zéro document rédigé. Ce qui rend
  `check_` et `tryMIDIfile` nuisibles est leur emplacement — le répertoire de référence scellé, au
  milieu de 163 captures versionnées qui font autorité — et non leur nature ni leur versionnage.
  **Nature des absents**, le chiffre à citer plutôt que le brut : 5 captures régénérables se refont
  par une commande, **9 sont réels** — trois skills dont `bpscript-oracle`, l'autorité sur la forme
  du langage, absente de l'instrument censé la trouver ; deux documents de `docs-developer/` ; un
  script ; trois configurations d'éditeur.
  **La réparation n'est pas un geste de ce dépôt** : l'ordonnanceur mutualisé place le balayage
  au-dessus du retrait, chaque créneau part au balayage, et le balayage réinscrit. La priorité de la
  tour dans cet ordonnanceur appartient à Romain.
  **Une déclaration d'index propre au dépôt, jamais enregistrée, doublait le module global.** Elle
  est retirée le 2026-08-19 par `claude mcp remove rtfm -s project`, et le module sert l'index,
  vérifié sur trois requêtes.
  ⛔ **Les deux instances rendent la même chose.** Contrôle du 2026-08-19 à 10h55, requête
  `tryMIDIfile capture texte` lancée sur l'une puis l'autre à la suite : jeux de résultats
  identiques, aucun mort de part et d'autre. Une comparaison antérieure les opposait — elle portait
  deux relevés séparés de onze heures, entre lesquels les 159 morts avaient quitté la base, et
  attribuait à l'instance un écart qui venait du temps. Les deux relevés différaient aussi de version,
  `0.25.0` en ligne de commande contre `0.24.1` pour le module : deux confusions possibles pour un
  seul écart observé.
  ⛔ **Les chiffres ci-dessus décrivent l'état du 2026-08-18 au soir.** Relevé du 2026-08-19 à 10h45 :
  l'index porte 376 documents contre 535, et **aucun mort — les 159 sont sortis**.
  Les 14 absents sont inchangés, les 9 réels compris — le skill
  `bpscript-oracle` en tête. Le retrait a donc porté, la première ingestion non.
  **Ce qui distingue les deux** : `BACKLOG.md`, déjà indexé, a été repris quelques minutes après un
  enregistrement. Une mise à jour de document connu passe ; une première entrée de document jamais
  indexé n'est pas passée ici.
  Versions **déclarées par les gestionnaires d'installation** au 2026-08-19 : `rtfm-ai 0.25.0` en
  ligne de commande, `0.24.1` pour le module intégré, une seule déclaration. L'outil ne porte pas de
  commande de version — `--version` rend son aide — et le numéro vient donc de l'installateur.

- **BPE-42** `ouvert` [P2] — UN BINAIRE QUI N'EST PAS L'ORACLE PORTE LE NOM DE L'ORACLE, DANS UN
  ARBRE DE TRAVAIL DÉTACHÉ. Trouvé le 2026-08-18, en répondant à un recensement d'arbres de travail
  demandé par l'architecte.
  `git worktree list` en rend deux : l'arbre principal, et un arbre détaché sur le tag amont
  `v3.5.1`, hors de la racine du dépôt. Ce second arbre n'est pas propre — `Makefile` modifié de
  100 insertions et 73 suppressions, et un binaire `bp3` construit sur place.
  **L'écart** : ce binaire porte l'empreinte `06244c55d11bd9496c6e7187afea2787`, quand l'oracle figé
  `builds/v3.5.1-iso.2/bp3` porte `372dd047bc52fd152ff51ec6715fae74`. Toute mesure de référence se
  prend sur le binaire figé ; celui-ci est le binaire reconstruit que la règle écarte, sous le même
  nom et dans un dossier appelé « amont ».
  **Portée mesurée** : aucune mesure publiée n'est touchée — `baseline-native/capture.py` désigne le
  chemin figé, vérifié. Le piège est armé, jamais mordu.
  **Ce qui protège l'index** : les deux requêtes de contrôle rendent 30 sources, toutes sous la
  racine du dépôt, zéro ailleurs — l'arbre détaché vit dans un répertoire temporaire que l'indexeur
  ne parcourt pas. Cette immunité tient à l'emplacement, pas à une garde : un arbre de travail posé
  dans le dépôt serait indexé.
  Le détachement attend la méthode d'identification des commits déjà repris, que l'architecte
  annonce. Le commit est retenu par `refs/tags/v3.5.1` et `refs/remotes/upstream/graphics-for-BP3`.

- **BPE-41** `en-attente` [P2] — CE QUE J'ATTENDS, ET DE QUI. État au 2026-08-18, avant compaction.
  **De Romain** : le sort des 22 grammaires dont l'en-tête diverge du registre ([[BPE-35]] — le
  principe est tranché, la mesure le contredit, la frappe attend son mot) · l'ancre de hauteur
  ([[BPE-29]]) · l'envoi à Bernard Bel de trois défauts moteur mesurés — la valeur non initialisée
  que rend un `#` après une minuscule, le compilateur d'alphabet qui avale ses marqueurs de
  section, et le brouillon de `courrier-bernard-brouillon.md` qui attend sa relecture.
  **De l'architecte** : la fermeture de la fenêtre BPScript, qu'il annonce · le routage de ce que
  je lui ai rendu les 16, 17 et 18 et qu'il n'avait pas encore porté.
  **De kanopi** : rien — sa resynchronisation est chez lui en KAN-51, et [[BPE-30]] en dépend.
  **De bpscript** : un signal si `dist/bp3.js` ou `test/FEEDBACK_BERNARD.md` apparaissent, changent
  de nom ou de chemin ([[BPE-40]]).
  Rien de ma part n'est en cours : aucun chantier ouvert, aucun geste suspendu à mi-course.

- **BPE-40** `ouvert` [P3] — `build.sh` LIT DEUX CHEMINS QUI N'EXISTENT PLUS, ET L'UN ÉCRIT ZÉRO
  SANS LE DIRE. Mesuré le 2026-08-18, après un signalement de bpscript confronté à ma propre mesure.
  `build.sh:24` définit `BPSCRIPT_DIST="$BPSCRIPT_DIR/dist"` et `:99` vérifie l'existence de
  `dist/bp3.js`. **Le répertoire `dist/` n'existe pas chez bpscript** : `--status` affiche donc
  « missing » en permanence, et non quand un paquet n'est pas construit. Aucun `cp` ne déploie vers
  ce chemin — la vérification survit à un déploiement retiré lors de la migration du 2026-06-14,
  dont le commentaire de `:22` porte encore la trace.
  `build.sh:265` lit `test/FEEDBACK_BERNARD.md` pour compter ses points et les inscrire à la fiche
  d'un binaire archivé (`:291`). **Le fichier n'existe pas non plus** ; le `|| echo 0` fait que
  `feedback_count` vaut zéro en silence. Une fiche d'archive porterait donc « 0 points » sans
  qu'aucun message ne dise que la source est absente. Aucune fiche existante ne porte la mention.
  **Ce que ça vaut** : deux lectures vers un voisin qui ne désignent rien. La première est
  cosmétique, la seconde écrit une donnée fausse dans une fiche d'archive.

- **BPE-38** `ouvert` [P3] — DEUX QUESTIONS NON MESURÉES, LAISSÉES OUVERTES SANS ÊTRE TRAITÉES.
  Pourquoi 39 blobs sont restés en CRLF pendant un mois alors que `test-data/.gitattributes` le
  refusait : le garde agit au commit et au checkout des fichiers **touchés**, et ceux-là ne
  l'ont pas été ; le fil n'est pas remonté commit par commit. Et les liens symboliques des cinq
  autres dépôts de la tour vers celui-ci : le périmètre examiné est `~/dev/bp/*/` hors
  `node_modules`, plus les `node_modules` de kanopi. Le test tient en une ligne — cloner, puis
  `git status` — et se prend chez chacun.

- **BPE-35** `en-attente-arbitrage` [P2] — EN-TÊTE DE GRAMMAIRE CONTRE REGISTRE. ⚠ Même sujet que
  [[BPE-33]], inscrit par l'architecte : celui-ci porte la directive, celui-là la mesure qui la
  corrige. Leur fusion est le geste de l'architecte, pas le mien. La divergence est
  de **22** grammaires, pas de 39, et elle va dans le sens inverse de celui qu'on lui prête.
  Le chiffre 39 vient d'un commentaire de `baseline-native/capture.py`. Remesuré le 2026-08-17 :
  13 en-têtes concordent avec le registre, 22 nomment le **même alphabet sous son autre préfixe**
  (`-ho.Ruwet` contre `-al.Ruwet` — le corpus passe les deux sous le drapeau `-al` et les deux se
  chargent), et 22 divergent réellement.
  **Le sens de la divergence** : sur les 18 écarts d'alphabet parmi ces 22, aucun n'est « le
  registre retient un autre alphabet ». L'en-tête n'en cite **aucun**, et c'est le registre qui en
  retient un — couples établis par mesure là où l'en-tête est muette, arbitrés par Romain le
  2026-08-11. Une seule va dans l'autre sens, `-gr.checkrests`, dont l'en-tête cite `-ho.notes`,
  fichier **absent du disque** ; trois autres auxiliaires cités en en-tête sont absents de même
  (`-md.VisserShapes.bpmd`, `-se.checkVolChan`, `-se.tryConsoleMaxTime`).
  **Ce que le retrait coûterait** : les 22 sont toutes inscrites à la baseline, dont 19
  productibles ; aucune ne figure dans `test-data/iso100`. De 113 entrées et 98 productibles, on
  passerait à 91 et 79.
  ⛔ La baseline est scellée. Romain a tranché le **principe** d'un retrait sur la prémisse
  « couples douteux » ; la mesure dit que ce sont les couples arbitrés. Rien ne se pose, rien ne
  se mesure, en attente de son mot sur pièce.

- **BPE-29** `en-attente-arbitrage` [P2] — ANCRE DE HAUTEUR : le natif ENCODE la note décalée, la
  tour la recompense à la main. `C4key` s'applique à l'**encodage** (`Encode.c:674` et `:865`), donc
  avant que la moindre sortie ne voie la note : les quatre axes du moteur — jetons, liste
  d'événements, score Csound, fichier MIDI — nomment la note décalée, unanimement, et la colonne
  `transpos` vaut **0**. Le moteur ne tient jamais le nom écrit.
  Les chaînes d'aval tiennent le nom écrit et déplacent la fréquence : les deux modèles concordent
  sur les hertz et divergent sur le **nom**, d'une octave, indépendamment de la paire d'ancres
  (mesuré sur 48/220 et sur 48/440).
  **Mesure figée** : les quatre combinaisons `C4key` × `A4freq` sur `tryMIDIfile`, deux axes, dans
  l'historique de ce dépôt ; l'écart et sa cause sont inscrits à `baseline-native/SCELLE.json`.
  **Coût des deux branches, chiffré par kanopi** : 7 scènes déjà compensées d'un côté, 19 grammaires
  déclarant les deux ancres de l'autre.
  ⛔ **Arbitrage de Romain — le nom écrit ou le nom natif.** Aucune mesure de plus ne le tranche :
  ce sont deux modèles cohérents chacun de son côté. Rien ne se pose, rien ne se mesure, en attente.

- **BPE-28** `ouvert` [P2] — SEGFAULT NATIF sur l'ecriture `-o` d'un item profondement imbrique
  (chemin de serialisation fichier). Trouve 2026-08-09 en instruisant BPE-15. REPRO FIABLE (100 %),
  bp3 natif 3.5.1 : prendre `-gr.tryTranspose`, joindre ses lignes 8-9 en une seule regle + retirer
  le `¬` (correctif BPE-15), puis
  `./bp3 produce -gr <tryTranspose-corrige> -al test-data/-ho.tryKeyMap -o <fichier> --seed 1`
  -> **Erreur de segmentation (code 139)**. DISCRIMINANT NET, meme item : `-D` (affichage terminal)
  reussit et montre l'expansion (20x `_transpose(0.20){A4 ...}` imbriques + parties N/P) ; `-o`
  (ecriture fichier) CRASHE. Le « 0 octet » initialement observe etait le crash AVANT ecriture, pas
  un item vide. Axe : chemin d'ECRITURE FICHIER de l'item produit (PrintArg->FILE / serialisation),
  distinct de la derivation (qui, elle, fonctionne). Suspect : debordement de pile d'un imprimeur
  recursif sur l'imbrication polymetrique profonde forcee par les gardes de drapeaux (Atimes=20...).
  MINIMISE 2026-08-09 — REPRO MINIMAL TROUVE, remonte a Bernard (constat #70) :
  `gram#1[1] S --> {A4 {A4 … A4}}` avec **17 niveaux** de groupes polymetriques imbriques →
  `./bp3 produce -gr <g> -o <f>` SEGFAULTE. Seuil EXACT : 16 niveaux OK, 17 crash ; tout au-dela
  crashe. DISCRIMINANT : a profondeur 50, `-D` (terminal) et `compile` REUSSISSENT, seul `-o`
  (ecriture fichier) crashe → debordement de pile d'un imprimeur RECURSIF sur le chemin de
  serialisation FICHIER (PrintArg->FILE, cf. memoire oracle-texte-option-o). Aucune dependance
  (ni drapeaux, ni alphabet, ni motif de temps) : c'est la PROFONDEUR d'imbrication seule.
  Lien BPE-15 : tryTranspose ne l'exposait qu'une fois rendue compilable (sa recursion garde-forcee
  atteint ~40 niveaux). `_stepOn`/... sans rapport. Statut : `remonte a Bernard`.
- **BPE-31** `ouvert` [P3] — COURRIER A BERNARD, en francais — reecrit, attend la relecture de Romain avant envoi. Son point 2b n a plus d objet : la liste d evenements vide est notre defaut, pas le sien.
- **BPE-32** `ouvert` [P4] — DEUX DEMANDES DE L ARCHITECTE DU 2026-08-14, non faites et hors chantier : la section de contrat sur test-data/ (mesure faite — qui lit quoi et par quelle porte — mais la section n est pas ecrite) et la lecture des trente-et-une directives de mesure avec avis sur celles tirees de ses propres mesures.
- **BPE-33** `ouvert` — EXCLURE DE LA BASELINE ISO-100 LES 39 GRAMMAIRES DONT L EN-TETE DIVERGE DU REGISTRE. Principe tranche par Romain le 2026-08-16 ; la frappe attend son mot pour le geste precis, la baseline etant scellee. MESURE ETABLIE le 2026-08-16 : l en-tete d une grammaire N EST PAS l autorite sur son alphabet — le moteur saute cette ligne, et elle designe un AUTRE auxiliaire que celui retenu pour 39 des 113 grammaires du registre. Ce n est pas marginal, c est un tiers. Et ce n est pas theorique : -ho.Ruwet est REFUSE au chargement (« Can t compile alphabet ») la ou -al.Ruwet charge — suivre l en-tete de ruwet casserait la scene. L AUTORITE EST test-data/REGISTRE.json, arbitre par Romain le 2026-08-11. AVANT TOUTE FRAPPE, trois chiffres a rendre : lesquelles sont les 39 nommees, combien d entre elles sont AUJOURD HUI dans la baseline, et ce que leur retrait change — le compte avant et apres, et si des mesures publiees s appuient dessus. ⛔ LA BASELINE NE BOUGE QU AVEC L ACCORD DE ROMAIN POUR LE GESTE PRECIS. HORS DU CHANTIER LIBRAIRIES/LANGAGE — sorti du scope le 2026-08-17.
- **BP3E-51** `ouvert` [P3] — ⛔ **`SUB` fait STRICTEMENT MOINS que `SUB1`, et l'aide du moteur dit l'inverse.** Mesuré par bp3-engine le 2026-08-24, en fermant une tâche aveugle de son banc : en sous-grammaire **unique**, même grammaire, seul le type change — **`SUB` rend « a X a »**, la seconde règle **ne s'applique pas** ; **`SUB1` et `ORD` rendent « a b a »**. ⇒ `BP3_help.txt:389-394` écrit que `SUB` s'applique **jusqu'à ce qu'aucune règle ne soit candidate** et que `SUB1` fait **comme SUB mais une seule fois** — la mesure dit l'opposé. ⚠️ **Bornes serrées, posées par lui** : la cause **n'est pas localisée dans le C** · **aucune grammaire du corpus** n'écrit une sous-grammaire `SUB` unique · la forme est peut-être dégénérée · **rien de vivant n'en dépend** — sous la forme du corpus l'équivalence tient. ⇒ **Cinquième candidat du lot Bernard**, si Romain ouvre l'envoi, et **après localisation de la cause**.
- **BPE-50** `ouvert` [P2] — AUDIT DE PLAUSIBILITÉ DES 143 RÉGLAGES `-se` CONVERTIS — 15 fichiers portent la signature du bogue de conversion (BPS-24). Mesuré par l'architecte le 2026-09-02 sur `test-data/` : la conversion du 2026-08-14 (`f936475`) a laissé la valeur dégénérée `10` là où la norme du corpus est 64 (`DeftVelocity`, 107 fichiers), 90 (`DeftVolume`, 78), 1 (`Quantize`, 127) ou 50 (`SamplingRate`, 106) ; et un `Seed=0l` non converti dans `-se.blurb` que le correctif `7aafd19` disait avoir réglé. Les 15 : 765432 · Ruwet · blurb · checkNegativeContext · dhati2 · gramgene · kss.old · polyphony1 · simpletemplates · tryGOTO · tryLIN · tryflags2 · tryflags3 · trytemplates · trytemplates2 — dix portent le triplet complet DeftVelocity+DeftVolume+Quantize à 10. ⚠️ « 10 » peut être une valeur voulue par l'auteur : l'audit tranche fichier par fichier contre l'original BP2 (l'historique git le porte, avant `0446f54`), jamais par la norme. Ce qui remplace BPE-7, clos le 2026-09-02. Indépendant du langage et de BPscript : corpus et moteur seuls.
