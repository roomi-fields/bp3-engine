# Le tiret `-` dans un nom de terminal — silence, jamais lettre

Établi le 2026-07-27 par `bp3-engine`, oracle du moteur natif v3.4.7, sur `csrc/bp3/` +
le binaire, en réponse à [176] (migration de `dhin--`/`dha--` vers `dhinOO`/`dhaOO`).

**Axe : sortie texte de `produce -o` (ces grammaires sont en mode texte, 0 jeton MIDI) + code.**

## 1. `dhin--` = le bol `dhin` SUIVI de deux silences — pas un terminal `dhin--`

`-` (comme `_`) est un **silence / prolongation** en BP3, pas une lettre. Un nom de terminal
**ne peut pas** contenir `-` : le lexeur `GetBol()` le rejette explicitement
(`CompileGrammar.c:1194-1200`) —

```c
for(j=(*p_i)+1; OkBolChar2(c=(*p_line)[j]); j++) {
    if(c == '-') { Print(wTrace,"Found '-' in terminal symbol\n"); goto ERR; }
}
```

⚠️ Le commentaire `case '-': /* Discarded in GetBol() */` de `OkBolChar2`
(`CompileGrammar.c:1264`) est **périmé** : le code actuel n'« élimine » pas le `-`, il **coupe
le terminal avant** lui. Le `-` qui suit devient un silence.

**MESURE (dhin1, config d'origine `-se.dhin-- -al -ho.dhin--`), `Errors: 0`** — aucun message
« Found '-' » : la sortie émet

```
4+4/6 dhin - - dha ge na . dha - - dha ge na . ...
```

`dhin--` ressort **`dhin` + `-` + `-`** (trois jetons : un bol, deux silences). L'engin
re-sérialise lui-même la règle : `gram#6[2] Q24 <-> dhin - - dha ge na dha - - dha ge na ...`.
La baseline figée le confirme (`dhin - - dhin - - tin - - ...`). Le natif ne fabrique **jamais**
un jeton unique `dhin--`.

## 2. `-` est toujours un séparateur — mais la segmentation exige un bol déclaré

`-` n'est jamais admis dans un nom de terminal (§1). Nuance de contexte, mesurée :

- **Avec un alphabet qui déclare `dhin`** (`-ho.dhin--` déclare `dha`, `ta`, `dhin`… via
  `dhin --> tin`), le lexeur reconnaît le bol `dhin`, s'arrête, et lit `--` comme deux silences.
- **Sans alphabet déclarant** (grammaire nue `S --> dhin--`), le compilateur ne sait pas où finit
  le bol et **échoue** : `Error code 15` — *« Can't make sense of "dhin--". May be unknown
  terminal symbol… »*. Il ne le coupe pas tout seul, il refuse.

Dans les deux cas, `dhin--` n'est **jamais** un terminal unique nommé `dhin--`.

## 3. Conséquence de la mesure — la migration a fabriqué de faux terminaux

Le natif sort `dhin` **puis deux silences**. Donc, selon le critère posé dans la demande :
**la migration `dhin-- → dhinOO` a cassé les quatorze règles.** `dhinOO` est **un seul**
terminal valide (`O` est une lettre, accepté par `OkBolChar2`) qui ne correspond à **aucune**
entrée de la table de transcription — là où l'original était `dhin` + deux silences. La scène
sœur `dhin.bps`, qui écrit `dhin - -` (avec espaces), est **fidèle** au natif ; c'est l'autre
migration qui a dévié. *(Périmètre : je ne propose pas la correction BPScript, hors de mon
domaine — je donne le fait qui tranche.)*

## 4. Les tirets du NOM DE FICHIER `-ho.dhin--` sont d'un autre ordre

Rien à voir avec le lexeur de terminaux. `-ho.dhin--`, `-gr.dhin--`, `-se.dhin--`… sont des
**noms de fichiers** : la scène/ressource s'appelle `dhin--`, et le moteur ouvre ces chemins
tels quels (jamais lexés comme des terminaux). Le `--` y est une chaîne de nom de fichier, pas
un silence. `-gr.dhin1` porte d'ailleurs le commentaire *« An initial version of '-gr.dhin--' »*
— c'est un identifiant de scène, sans rapport avec le sens grammatical de `-`.

## 5. Le natif SEGMENTE un long nom — au plus long bol DÉCLARÉ, pas au tiret

Un terminal d'un seul tenant est **découpé** en plusieurs bols. `gram#6[2]` écrit un nom de
~50 caractères d'affilée :

```
Q24 <-> dhin--dhagenadha--dhagenadhatigegenakadheenedheenagena
```

Le natif (config d'origine, `Errors:0`) le rend en **24 jetons** :

```
dhin - - dha ge na dha - - dha ge na dha ti ge ge na ka dhee ne dhee na ge na
```

Un seul nom écrit → 24 jetons. **Le compte prouve le découpage.** Et la coupe n'est **pas**
faite par les tirets : `dhagena` (sans aucun tiret) devient `dha ge na`, `dhatigegenaka` devient
`dha ti ge ge na ka`. La segmentation est **pilotée par l'alphabet déclaré**.

**Le code qui segmente** : à l'encodage (`Encode.c:888-918`, `SEARCHTERMINAL`), le moteur balaie
**tous** les bols déclarés et retient à chaque position le **plus long** qui apparie —
`for(j=0; j<Jbol; j++) { if(Match(...,(*p_Bol)[j],l) && l > lmax) { lmax=l; jj=j; } }` — émet ce
bol (`T3` + indice), avance le pointeur derrière lui (`*pp = qmax`), et **recommence** sur le
reste. Les `-` sont pris comme silences en parallèle. La segmentation dépend donc entièrement de
**quels bols sont déclarés** (`Jbol`/`p_Bol`, ici le fichier `-ho.dhin--`), pas de la table de
transcription ni d'une règle de lexeur fixe : un run dont aucun préfixe n'est un bol déclaré
échoue (§2).

**Conséquence** (fait, sans remède, hors de mon périmètre) : un nom laissé **entier**
n'intersecte pas la table car le natif ne le compare jamais entier — il le compare **segment par
segment**. Une écriture bols **séparés** est ce que le natif produit ; une écriture d'un seul
tenant décrit la même chose *à condition que le lecteur segmente comme le fait le moteur*.
