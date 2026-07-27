# Le point d'attente natif `<<Wx>>` — synchronization tag : sémantique, durée, dessin

Établi le 2026-07-27 par `bp3-engine`, oracle du moteur natif v3.4.7, sur les sources
(`csrc/bp3/` partagé + `source/BP3/Graphic.c` natif-seul) et le binaire, en réponse à la
demande [174] (Romain fait vivre le point d'attente `<!nom` côté BPScript/BPx et veut savoir
ce que fait l'original).

**Axe : sources du moteur + minutage de jetons (`--tokensout`) + sortie texte.** Le comportement
graphique est lu dans le code natif ; le rendu d'image n'a pas pu être exécuté (voir §4).

Ce que BPScript note `<!nom`, BP3 l'appelle un **synchronization tag** et l'écrit `<<Wx>>`, où
`x` est un entier (0 < x ≤ MAXWAIT). Parsé en `Encode.c:572-608` (« Out-time object or
`<<Wx>>` »), tokenisé `T8` + valeur (`Encode.c:601`).

## 1. Bloquant (tout s'arrête), pas une interruption d'un seul flux — et à usage unique

**Bloquant, à l'échelle de l'item.** BP3 aplatit toutes les séquences concurrentes en **une
seule ligne temporelle** (`TimeSet.c` calcule les dates absolues de tous les événements), jouée
par **une seule** boucle d'horloge (`MakeSound.c`). Il n'y a pas d'horloge par flux : un point
d'attente suspend l'item entier — le temps cesse d'avancer, rien d'autre ne joue — jusqu'au
signal. C'est ce que décrit l'aide de Bernard (`BP3_help.txt:593-604`, « Wait for … *waiting
for a NoteOn on the MIDI input* » ; « *Clicking the mouse exits any the wait loop* ») : une
boucle d'attente **globale**, pas une suspension d'un seul flux pendant que les autres
continuent.

**Ce qu'on attend** est défini par la commande de script « Wait for: » qui pose
`WaitKey[x]`/`WaitChan[x]` (`ScriptUtils.c:1455-1456`) : un NoteOn MIDI sur une touche/canal, ou
un message Start/Stop/Continue, ou une frappe clavier (types `KEYBOARDEVENT`…`CONTINUEEVENT`,
`-BP3.h:314-318`). Le tag `<<Wx>>` du texte marque **où** l'item attend le signal `x`.

**Usage unique.** Aucune logique de réarmement trouvée (cherché dans `Encode`, `Compute`,
`FillPhaseDiagram`, `TimeSet`, `MakeSound`, `ScriptUtils`). Le tag est **consommé** puis libéré
après traitement : `GetRelease.c:176-189` parcourt la `WaitList` de l'objet et la remet à `NULL`
(« Already disposed of »). La définition `WaitKey[x]`/`WaitChan[x]` persiste (posée par script),
donc plusieurs tags de même `x` attendent le même type d'événement, mais **chaque occurrence
est un point à un coup**.

**Réserve d'honnêteté.** La boucle d'attente temps-réel elle-même n'est pas exécutable dans les
sources console disponibles : `WaitKey[]` n'y est lu que pour l'affichage (`ScriptUtils.c:1450`)
et **aucun consommateur de `MakeSound` ne bloque** sur la `WaitList`. Le blocage ci-dessus est
donc établi par l'architecture (horloge unique) + l'aide, pas par l'exécution d'une boucle de
blocage dans ce binaire. En mode `produce` hors-ligne (ce que je peux lancer), le tag **ne
bloque pas** : la production s'achève, le tag est une annotation de durée nulle (§2).

## 2. Durée NULLE — c'est un marqueur hors-temps

Le tag n'occupe **aucun** temps dans la ligne temporelle. Deux preuves :

- **Code.** À l'expansion polymétrique, `T8` est rangé avec les objets **hors-temps** (`T7` et
  les contrôleurs `T13`-`T46`, `Polymetric.c:442-491`) : il incrémente le **compte**
  d'événements (`Maxevent++`) mais n'entre **pas** dans la liste qui ajoute de la durée
  (réservée à `T3/T9/T25/T4`, `Polymetric.c:1597`). `TimeSet.c:256-260,322-325` ne fait que
  **lire** la `WaitList` pour l'imprimer, sans allouer de temps.
- **Mesure.** Grammaire `S --> C4 <<W1>> D4 E4`, jetons minutés : `C@0-333, D@333-666,
  E@666-1000`. Le `<<W1>>` entre C et D **n'insère aucun intervalle** — D démarre pile à la fin
  de C. **Zéro durée.**

C'est **fidèle** à la représentation de durée nulle mesurée côté BPx.

## 3. Représentation graphique — un petit chevron VERT sous la règle du temps

BP3 **dessine** le tag, dans le module graphique natif `source/BP3/Graphic.c:179-191`
(« Draw synchronization tag »). Quand l'objet porte une `WaitList` :

- **couleur : vert** (`stroke_style("green")`), trait épais (`pen_size(8,0)`), rétabli en noir
  ensuite ;
- **position** : à l'abscisse du tag sur la ligne temporelle (`tt1 = leftoffset + t1 - trbeg`),
  juste **sous la règle du temps** (`y = yruler + 8`) ;
- **forme** : depuis le point d'ancrage, une boucle `for(edge=3; edge>0; edge--)` trace trois
  traits — un vers le bas-droite, un horizontal vers la **gauche** (la queue), un vers le
  haut-droite — répétés en trois tailles décroissantes, ce qui **remplit** un petit chevron/
  fanion pointant à droite avec une queue à gauche.

Sortie **texte** (autre représentation, celle qu'on obtient hors-ligne) : le tag est réécrit
`<<Wx>>` (`DisplayArg.c:1319`), historiquement colorié `Color[TagC]` dans l'éditeur Mac (`TagC`
= couleur dédiée « tag », `-BP3.h:521` ; `Reformat(...&Color[TagC]...)` `DisplayArg.c:1331`,
aujourd'hui en commentaire). Mesuré : `S --> C4 <<W1>> D4 E4` ressort `C3 <<W1>> D3 E3`.

## 4. Ce que je n'ai pas pu rendre — le gabarit de canevas manque sur ce banc

La console **sait** produire une image (piano-roll HTML, `ConsoleMain.c:559` `CreateImageFile`,
activée par `--traceout` + réglages `ShowPianoRoll`/`ShowGraphic`), et le code de dessin du tag
(§3) est bien compilé dans `./bp3`. Mais le rendu a échoué : `CreateImageFile` lit un gabarit
`php/CANVAS_header.txt` (`ConsoleMain.c:613-620`) **absent de tout l'arbre** — il vit dans le
dépôt externe `bolprocessor/php-frontend`, non installé ici (déjà relevé, constat #62). Sans
gabarit, `imagePtr` reste `NULL` et l'image sort **vide** (fichier HTML de 0 octet, vérifié).
Le dessin est donc décrit **sur le code** (`Graphic.c:179-191`), pas sur une capture rendue.
