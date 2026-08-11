# Deux comportements du moteur BP3 en ligne de commande

Bonjour Bernard,

Deux observations faites sur le moteur en ligne de commande, avec leurs cas reproductibles. Aucune
des deux n'est une régression : les trois versions que nous avons sous la main se comportent
identiquement.

**Versions vérifiées** — 3.4.7, 3.5.0 et 3.5.1, compilées depuis `graphics-for-BP3`. Le binaire
3.5.1 utilisé pour les mesures ci-dessous porte l'empreinte md5 `fb6df5ad5ee18a0398ae3cdb1817287d`,
version affichée `Version 3.5.1 (Aug 11 2026 - 13:16:56)`.

---

## 1. Une expression polymétrique déséquilibrée produite par `_rotate(0)`

Le moteur produit une accolade fermante en trop, puis refuse sa propre production.

**Grammaire complète, deux lignes, aucune dépendance :**

```
gram#1[1] S --> _rotate(0) {a b c d}
```

**Commande :**

```
./bp3 produce -e -gr <cette grammaire> -al -al.abc --seed 1 -o out.txt
```

**Ce qui sort :**

```
Errors: 0
Applying serial tools to modify order of sequence(s) in Compute()
Interpreting structure...
=> Incorrect polymetric expression(s): '{' and '}' are not balanced. Can't proceed further...
```

Et `out.txt` contient :

```
{a b c d}}
```

La grammaire ne porte qu'une paire d'accolades. Aucun événement n'est produit.

**Seul l'argument nul est concerné.** Les autres valeurs se comportent normalement :

| règle | texte produit | interprétation |
| --- | --- | --- |
| `_rotate(0) {a b c d}` | `{a b c d}}` | refusée |
| `_rotate(1) {a b c d}` | `{b c d a}` | passe |
| `_rotate(2) {a b c d}` | `{c d a b}` | passe |
| `_rotate(-1) {a b c d}` | `{d a b c}` | passe |
| `{a b c d}` sans rotation | `{a b c d}` | passe |

**Notre question** : `_rotate(0)` est-il censé être accepté — auquel cas la rotation nulle devrait
rendre la séquence inchangée — ou bien un argument nul devrait-il être refusé à la compilation
plutôt qu'à l'interprétation ?

---

## 2. Demander une seconde sortie change ce qui est écrit

Sur une grammaire en mode improvisation (`Improvize = 1`), ajouter `--midiout` ou `--eventlistout`
à une commande qui écrit déjà `-o` change le contenu produit.

**Cas, avec les fichiers du corpus de test :**

```
./bp3 produce -e -gr -gr.koto3 -se -se.koto3 -al -al.abc1 --seed 1 \
      -o out.txt [--midiout out.mid] [--eventlistout out.csv]
```

**Ce que contient `out.txt` :**

| options | lignes dans `out.txt` | items annoncés produits |
| --- | --- | --- |
| `-o` seul | **20** | 20 |
| `-o --midiout` | **14** | 20 |
| `-o --eventlistout` | **14** | 20 |
| les trois | **14** | 20 |

Les 14 lignes écrites sont exactement les **14 premières** des 20 : le contenu conservé est identique
octet à octet, les 6 dernières manquent.

**La perte croît avec la borne d'items**, ce qui exclut un simple bord de tampon :

| `MaxItemsProduce` | `-o` seul | `-o --midiout` | perte |
| --- | --- | --- | --- |
| 5 | 5 | 4 | 1 |
| 10 | 10 | 8 | 2 |
| 20 | 20 | 14 | 6 |
| 40 | 40 | 26 | 14 |

`-o` seul écrit toujours exactement `MaxItemsProduce` lignes.

**Ce n'est pas seulement l'écriture du fichier texte.** Sur les 24 grammaires de notre corpus qui sont
en mode improvisation et qui produisent, nous avons comparé la sortie MIDI et la liste d'événements
**avec et sans `-o`**, toutes autres options égales : 16 rendent des sorties identiques, 8 rendent une
liste d'événements différente, 3 rendent aussi un MIDI différent.

Trois d'entre elles — `koto1`, `koto2`, `tryGOTO` — rendent une **liste d'événements différente selon
qu'on demande `-o` ou non**, et elles sont parfaitement stables d'un passage à l'autre. L'écart est
donc bien imputable à la présence de l'option.

**Notre question** : la présence d'une option d'écriture est-elle censée influer sur ce qui est
produit, ou seulement sur ce qui est écrit ?

**Condition d'apparition** : le mode improvisation. Avec `Improvize = 0`, les mêmes commandes rendent
le même nombre de lignes et les mêmes sorties — aucun écart.

---

## 3. Un point connexe, sur lequel nous ne demandons rien

En cherchant le point 2, nous avons constaté que quatre grammaires de notre corpus rendent une sortie
MIDI ou une liste d'événements **différente d'un passage à l'autre, à options strictement identiques
et graine fixée à 1** : `PP`, `koto3`, `simpletemplates`, `tryMIDIfile`. Trois passages consécutifs
suffisent à le voir.

Sur les axes texte et jetons, ces quatre-là sont stables. Nous le signalons parce que cela peut
concerner l'usage de `--seed` : si ce non-déterminisme est délibéré — objets sonores tirés au moment
du rendu, par exemple — nous adapterons nos comparaisons. Si vous ne l'attendiez pas, nous pouvons
préparer un cas minimal.

---

Nous restons à disposition pour tout complément, et pouvons fournir les fichiers de test et les
sorties complètes.

Bien à vous,
