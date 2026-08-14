# docs-developer — index

Les notes de rétro-ingénierie du moteur natif, et les bons de travail qui en dérivent.

## Comportements mesurés sur le natif

- [contexte-negatif.md](contexte-negatif.md) — le contexte négatif dans le membre gauche
- [instant-negatif.md](instant-negatif.md) — ce que le moteur écrit avant l'origine du temps
- [marqueurs-structurels.md](marqueurs-structurels.md) — les marqueurs de structure
- [operateurs-vitesse.md](operateurs-vitesse.md) — les opérateurs de vitesse
- [point-attente.md](point-attente.md) — le point d'attente et son déclencheur
- [taux-de-compression.md](taux-de-compression.md) — d'où sort `Kpress`, et ce qui allume la
  quantification
- [tiret-dans-terminal.md](tiret-dans-terminal.md) — le tiret à l'intérieur d'un terminal
- [tryShruti-gammes-microtonales.md](tryShruti-gammes-microtonales.md) — les gammes microtonales
- [variation-des-parametres.md](variation-des-parametres.md) — la variation entre deux valeurs
  écrites, et la valeur posée après la dernière note
- [vingt-et-un-mots-et-les-cinq-cadences.md](vingt-et-un-mots-et-les-cinq-cadences.md) — quels mots
  de contrôle ont un corps, et le plafond des cadences du continu
- [volumestep-step-et-plantage-trace.md](volumestep-step-et-plantage-trace.md) — les huit paliers de
  `_volumestep`, `_step` sur un paramètre défini par l'utilisateur, le plantage sur l'option de trace

## Le moteur d'origine et nos écarts

- [inventaire-des-deltas.md](inventaire-des-deltas.md) — chaque écart entre notre arbre et le tag
  amont, ce qu'il change à la production, et sur quel accord il repose
- [reglages-declares-contre-retenus.md](reglages-declares-contre-retenus.md) — les couples grammaire
  et réglages dont la déclaration diverge de ce que la mesure retient

## Propositions en attente de Romain

- [proposition-assiette-96.md](proposition-assiette-96.md) — cinq grammaires peuvent revenir dans
  l'assiette scellée, la cause de leur sortie étant levée. **L'assiette reste à 91.**

## Courriers à Bernard Bel

- [COURRIER-BERNARD-2026-08-11.md](../COURRIER-BERNARD-2026-08-11.md) — deux comportements de la
  ligne de commande, mesurés sur 3.4.7, 3.5.0 et 3.5.1
- [courrier-bernard-brouillon.md](courrier-bernard-brouillon.md) — l'image de zéro octet sur
  l'option de trace. **Brouillon en attente de la relecture de Romain.**

## Témoins conservés

- [essai-decompense/LISEZ-MOI.md](../baseline-native/essai-decompense/LISEZ-MOI.md) — les captures
  prises avant la recapture de l'assiette, quand le sérialiseur a cessé de retrancher la
  quantification

## Bons de travail

- [bp3-reference-scenes-bon-de-travail.md](bp3-reference-scenes-bon-de-travail.md) — les scènes
  d'exemple dont l'aide BP3 a besoin

## Sources d'origine

Les fichiers `.txt` sont les notes de Bernard Bel, reprises telles quelles.
