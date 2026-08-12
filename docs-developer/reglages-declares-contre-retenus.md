# Le réglage déclaré par la grammaire, et celui que la capture retient

Mesuré le 2026-08-12 sur le binaire gelé `bp3 3.5.1`, empreinte `fb6df5ad5ee18a0398ae3cdb1817287d`.
Chaque tirage : même action, même graine (`--seed 1`), même convention de notes ; seuls les
auxiliaires changent. Le tirage de référence reproduit la capture scellée sur les 7 grammaires.

**Axes observés** : jetons (`--tokensout` : nom du terminal, instant, durée) pour les grammaires
sonnantes, sortie texte (`-o`) pour les grammaires symboliques. La fréquence de référence
n'apparaît sur aucun des deux.

## Ce que le moteur fait de l'en-tête

`CompileGrammar.c:250` porte `/* Skip headers */` : la ligne `-se.` de la grammaire est reconnue
puis sautée (`goto NEXTLINE`). Le moteur charge le réglage passé en ligne de commande, et lui seul.
Le nom déclaré est un enregistrement de l'interface BP2, sans effet sur la production.

## Le format BP2 arrête le moteur

Un fichier de réglages au format texte BP2 produit `=> Could not parse JSON settings:` suivi du
contenu brut, puis la console s'arrête : ni compilation, ni production, aucun fichier de sortie.

Sur les 143 fichiers de réglages du corpus, 22 sont au format texte BP2.

Sur les 110 grammaires du corpus :

- 84 déclarent un réglage lisible ;
- 5 déclarent un réglage BP2 — `check&`, `koto1`, `koto2`, `transposition1`, `tryMIDIfile` ;
- 3 déclarent un réglage absent du corpus — `checkVolChan`, `tryConsoleMaxTime`, et le fichier
  HTML `tryflags3.html` ;
- 18 n'en déclarent aucun.

## Les sept cas, un par un

### transposition1 — le remplacement est fidèle et sans effet

Déclaré `-se.transposition` (BP2, référence 440 Hz). Retenu `-se.transposition3` (JSON,
`A4freq=440`, `C4key=60`), qui porte la même référence.

Jetons : 3047 octets, identiques à un tirage sans aucun réglage. Témoin à valeur non nulle :
`-se.koto3` donne 2910 octets et `-se.765432` en donne 2 — la grammaire répond bien aux réglages,
l'égalité tient donc au fichier.

### koto1, koto2 — le remplacement est nécessaire, sa valeur reste invérifiée

Déclaré `-se.koto1` (BP2, sans référence de fréquence). Retenu `-se.koto3` (JSON).

Le texte produit change : `koto1` rend `a a a a a a a` avec `-se.koto3` et `a d` sans réglage ;
`koto2` rend `b a a a b b a` contre `c a c b c b c b d`. La correspondance entre le vidage
positionnel du fichier BP2 et les clés du fichier JSON n'est pas établie.

### tryMIDIfile — sans effet sur les axes observés, en contradiction sur un axe non observé

Déclaré `-se.tryMIDIfile` (BP2, référence **220 Hz**). Retenu `-se.asymmetric1` (JSON,
`A4freq=440`) — une octave d'écart.

Jetons : 310 octets, identiques à un tirage sans réglage. Témoin à valeur non nulle : `-se.koto3`
donne 298 octets, `-se.765432` en donne 306. La fréquence de référence n'apparaît pas dans les
jetons : l'écart de 220 à 440 est hors de portée de cette mesure.

### check& — le remplacement contredit la déclaration, et cela se voit

Déclaré `-se.check&` (BP2, référence **440 Hz**). Retenu `-se.765432` (JSON, `A4freq=220`,
`C4key=48`) — une octave en dessous.

Jetons retenus : `do2` 0→666, `sol3` 0→1333, `mi4` 0→333, `fa2` 1000→1666.
Jetons sans réglage : `do3` 0→2000, `sol4` 0→4000, `mi5` 0→1000, `fa3` 3000→5000.

Les noms de terminaux et les durées se déplacent ensemble.

### checkBT — la grammaire est sourde aux réglages

Déclaré `-ho.abc1`, sans réglage. Retenu `-se.koto3` + `-al.abc1`.

Texte : 11 octets dans tous les cas. Témoins `-se.koto3`, `-se.765432`, `-se.tryTempo` : la sortie
ne bouge pas. La résolution par le nom déclaré reproduit la capture scellée octet pour octet.

### PP — le réglage ajouté déplace les instants

Déclaré `-ho.abc`, sans réglage. Retenu `-se.koto3` + `-al.abc`.

Terminaux identiques dans les deux cas (`b a b a X1 b a b YA`). Jetons retenus :
`X1` 600→750, `YA` 1200→1350. Jetons sans réglage : `X1` 4000→5000, `YA` 8000→9000.

## L'alphabet — `-ho.` contre `-al.`

Les deux fichiers diffèrent : `abc` fait 390 octets en `-ho.` et 425 en `-al.` ; `abc1` fait
91 octets contre 204.

À réglages inchangés, une seule variable déplacée, la production est identique octet pour octet sur
`koto1`, `koto2`, `PP` et `checkBT`.

## Synthèse

| grammaire | réglage déclaré | réglage retenu | effet mesuré du retenu |
| --- | --- | --- | --- |
| transposition1 | BP2, 440 Hz | `transposition3`, 440 Hz | aucun sur les jetons |
| koto1 | BP2, sans fréquence | `koto3` | texte différent |
| koto2 | BP2, sans fréquence | `koto3` | texte différent |
| tryMIDIfile | BP2, 220 Hz | `asymmetric1`, 440 Hz | aucun sur les jetons |
| check& | BP2, 440 Hz | `765432`, 220 Hz | jetons transposés, durées ×1/3 |
| checkBT | aucun | `koto3` | aucun sur le texte |
| PP | aucun | `koto3` | instants et durées ×1/6,67 |
