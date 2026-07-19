/* DOUBLURE de <curl/curl.h> pour la construction WebAssembly UNIQUEMENT.
 *
 * Le moteur amont v3.4.7 inclut libcurl sans condition (-BP3.h:97) pour UNE seule
 * fonction : « enter_notes », qui pousse une capture MIDI vers un projet web
 * (ConsoleMain.c:307, curl_global_init). Emscripten n'a pas libcurl, et cette
 * fonctionnalite n'a de toute facon pas de sens dans le navigateur : la capture MIDI
 * en temps reel et l'envoi vers un fichier de projet sont des chemins natifs.
 *
 * Cette doublure permet de compiler les sources AMONT SANS LES MODIFIER. C'est
 * volontaire : diverger de csrc/bp3/ nous obligerait a re-fusionner a chaque version
 * amont, et c'est exactement la voie parallele que l'interdiction de retrocompatibilite
 * proscrit. Ici rien ne bifurque — le code amont reste intact, seul l'environnement de
 * construction WASM lui fournit un symbole inerte.
 *
 * Si un jour le moteur amont utilise reellement libcurl ailleurs, cette doublure
 * echouera a l'edition de liens sur le symbole manquant — bruyamment, ce qui est le
 * comportement voulu. Elle ne masque rien en silence.
 */
#ifndef BP3_WASM_DOUBLURE_CURL_H
#define BP3_WASM_DOUBLURE_CURL_H

#define CURL_GLOBAL_DEFAULT 0

/* Retourne toujours 0 (CURLE_OK). Aucun reseau n'est initialise. */
int curl_global_init(long flags);

#endif
