Cher Bernard,

C'est parfait ! Les silent sound objects fonctionnent exactement comme il faut.

## Résultats des tests

J'ai intégré tes fichiers et tout compile en WASM. Voici les résultats de tes exemples :

| Exemple | Résultat | Tokens |
|---------|----------|--------|
| `z` | ✅ | z:1000 |
| `a z a C4` | ✅ | a:1000, z:1000, a:1000, C4:1000 |
| `a <<z>> a` | ✅ | a:1000, <<z>>:0, a:1000 |
| `a <<a>> _tempo(2) z <<y>> a <<a>> C4` | ✅ | a:1000, _tempo:0, z:500, a:500, C4:500 |
| `a Truc a` | ✅ | a:1000, **Truc:1000**, a:1000 |
| `{a Truc a, z C4}` | ✅ | polymétrie correcte |
| `a <<Truc>> z a` | ✅ | out-time variable |
| `D4 z& a &z` | ⚠️ | durée négative sur D4 (attendu) |

**Les variables préservées marchent !** `Truc` apparaît dans la sortie avec une durée de 1000ms — c'est exactement ce dont j'avais besoin.

## Le nommage fonctionne aussi

J'ai testé les noms qui posaient problème avant (`C4`, `sa4`, `re4`, `do3`) directement dans l'alphabet sans préfixe — **tout fonctionne**. Les terminaux de l'alphabet sont maintenant reconnus avant le match note. C'est une excellente amélioration.

## Multi-cycle OK

5 cycles avec `bp3_init()` entre chaque → tous passent. Plus de bug de re-init.

## Test-sequence

Ames, look-and-say, Visser3 (802 MIDI), 12345678 — tous passent. Ruwet et Mozart ont des erreurs de settings (pas de changement par rapport à avant).

## Ce que ça débloque

Avec les silent sound objects + les variables préservées, je n'ai plus besoin de :
- Fichiers prototypes `-so.` générés
- `bp3_set_object_duration()`
- Préfixes sur les noms de terminaux

Le flux est devenu ultra-simple :
```
init → loadAlphabet("C4\nsa4\nenv1\n") → loadGrammar(...) → produce → getTimedTokens
```

BP3 fait le temps, JavaScript fait le son. C'est exactement la vision qu'on avait.

## Deux fichiers manquants dans ton envoi

Tes fichiers modifiés n'incluaient pas `ConsoleMessages.c` ni `ProduceItems.c` — les deux qui avaient des `#ifdef __BP3_WASM__` dans la v3.3.14. J'ai remis les guards de mon côté, mais il faudrait que tu les intègres aussi dans ta branche `graphics-for-BP3`.

Pour rappel :
- **ConsoleMessages.c** — `gOutDestinations` mis à NULL en WASM (sinon chaque `vfprintf(stdout)` traverse WASM→JS et explose le stack JS en récursion profonde)
- **ProduceItems.c** — `expand = FALSE` dans `PrintResult()` en WASM (le 2e `PolyMake` pour l'expansion textuelle cause un stack overflow sur les grammaires complexes type Visser3)

Je peux te renvoyer ces deux fichiers si tu veux.

## cJSON corrigé

J'ai remplacé les 6 `sprintf` par `snprintf` dans `cJSON.c` — ça supprime les warnings `-fsanitize=address`. Pas besoin de mettre à jour la lib, c'est un changement mécanique :

```c
// Avant
sprintf((char*)number_buffer, "%1.15g", d);
// Après
snprintf((char*)number_buffer, sizeof(number_buffer), "%1.15g", d);
```

Le fichier `cJSON.c` corrigé est dans les PJ. Testé, le parsing JSON fonctionne toujours.

## La liaison & sur les silent objects

Pas bloquant pour nous — on utilise `_` (prolongation) pour étendre un terminal sur plusieurs beats. Le dispatcher JS gère la durée côté playback.

Merci beaucoup pour ce travail !
Romi
