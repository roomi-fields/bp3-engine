/* TokensOut.c — Sérialiseur natif des "timed tokens" (oracle).

   Port fidèle de bp3_get_timed_tokens() (csrc/wasm/bp3_api.c) en verbose=0
   (tokens sonnants seulement — c'est le niveau utilisé pour les snapshots s3_timed).
   Sérialise le buffer p_Instance rempli par TimeSet, AU MÊME POINT que le WASM
   (juste après TimeSet, AVANT MakeSound), au format JSON identique :
       [{"token":"X","start":<ms>,"end":<ms>}, ...]

   Activé par le flag CLI --tokensout <fichier> (TokensOutFile, ConsoleMain.c).
   Fichier NATIF-ONLY (jamais compilé dans le WASM, qui a son propre sérialiseur).
   Appelé par PlayBuffer1 (PlayThings.c), une fois par item ; le process CLI étant
   mono-coup, les items successifs sont concaténés (comme ProduceAll côté WASM) et
   le fichier est réécrit complet à chaque item. */

#ifndef _H_BP3
#include "-BP3.h"
#endif
#include "-BP3decl.h"
#include <stdio.h>
#include <string.h>

extern char TokensOutFile[];

#define TOK_MAX     65536
#define TOK_SSO_MAX 4096

typedef struct { char name[64]; long start; long end; } TokOut;
static TokOut tok_buf[TOK_MAX];
static int    tok_count = 0;
static char   tok_is_sso[TOK_SSO_MAX];  /* 1 = bol j traité en SSO (T47) */

/* Échappe une chaîne pour insertion JSON. */
static void tok_json_escape(char *dst, int maxlen, const char *src) {
    int i = 0, s;
    for(s = 0; src[s] && i < maxlen - 2; s++) {
        if(src[s] == '"' || src[s] == '\\') dst[i++] = '\\';
        dst[i++] = src[s];
    }
    dst[i] = '\0';
}

/* Réécrit le fichier complet (tableau JSON de tous les tokens accumulés). */
static void tok_write_file(void) {
    FILE *f;
    int i;
    char esc[128];
    if(TokensOutFile[0] == '\0') return;
    f = fopen(TokensOutFile, "w");
    if(f == NULL) return;
    fputc('[', f);
    for(i = 0; i < tok_count; i++) {
        if(i > 0) fputc(',', f);
        tok_json_escape(esc, sizeof(esc), tok_buf[i].name);
        fprintf(f, "{\"token\":\"%s\",\"start\":%ld,\"end\":%ld}",
            esc, tok_buf[i].start, tok_buf[i].end);
    }
    fputc(']', f);
    fclose(f);
}

/* Appelé depuis PlayBuffer1 juste après TimeSet, pour chaque item.
   kmax = nombre d'instances calculé par TimeSet (sortie p_kmx). */
void EmitTimedTokensItem(tokenbyte ***pp_buff, long kmax) {
    long k;
    char note_name[64];

    if(TokensOutFile[0] == '\0') return;
    if(p_Instance == NULL || *p_Instance == NULL || kmax < 2) { tok_write_file(); return; }

    /* Scan T47 : identifie les SSO (silent sound objects) depuis pp_buff.
       Port du stub WASM (PlayBuffer1) : paires [tag, param], param = index de bol. */
    memset(tok_is_sso, 0, sizeof(tok_is_sso));
    if(pp_buff != NULL && *pp_buff != NULL && **pp_buff != NULL) {
        size_t buf_size = MyGetHandleSize((Handle)*pp_buff) / sizeof(tokenbyte);
        tokenbyte *buf = **pp_buff;
        size_t bi;
        for(bi = 0; bi + 1 < buf_size; bi += 2) {
            if(buf[bi] == T47) {
                int p = buf[bi + 1];
                if(p > 1 && p < TOK_SSO_MAX) tok_is_sso[p] = 1;
            }
        }
    }


    for(k = 2; k <= kmax; k++) {
        int j = (*p_Instance)[k].object;
        long start_ms, end_ms;
        const char *name;

        if(j == 0) continue;
        if(j == -1) break;

        /* La mesure se prend AVANT toute compensation de gigue (décision Romain du
           2026-08-12) : les instants sortent tels que le moteur les produit. Une
           soustraction de la quantification vivait ici ; elle rendait les captures
           antérieures d'un pas à ce que le fichier MIDI écrit. */
        start_ms = (long)(*p_Instance)[k].starttime;
        end_ms   = (long)(*p_Instance)[k].endtime;

        if(j == 1) continue;  /* silence : non émis en verbose=0 */

        if(j >= 16384) {
            int   midiKey = j - 16384;
            int   trans = (*p_Instance)[k].transposition;
            short xpk   = (*p_Instance)[k].xpandkey;
            short xpv   = (*p_Instance)[k].xpandval;
            char  lit   = (*p_Instance)[k].transposefirst;  /* 3.5.0: lastistranspose renomme transposefirst (amont) */
            int   scale = (*p_Instance)[k].scale;
            if(lit) {
                if(trans != 0) TransposeKey(&midiKey, trans);
                midiKey = ExpandKey(midiKey, xpk, xpv);
            } else {
                midiKey = ExpandKey(midiKey, xpk, xpv);
                if(trans != 0) TransposeKey(&midiKey, trans);
            }
            note_name[0] = '\0';  /* init : si scale invalide PrintThisNote n'écrit pas (cf. WASM) */
            PrintThisNote(scale, midiKey, -1, -1, note_name);
            name = note_name;
        } else if(j > 1 && j < Jbol && p_Bol != NULL && (*p_Bol)[j] != NULL
                  && *((*p_Bol)[j]) != NULL) {
            name = *((*p_Bol)[j]);
        } else {
            name = "?";
        }

        /* En verbose=0, ignorer contrôles/non-sonnants. */
        if(name != NULL && (name[0] == '_' || name[0] == '/' || name[0] == '?')) continue;

        /* Ignorer les bols non-sonnants (pas de prototype MIDI) sauf SSO (T47). */
        if(j > 1 && j < 16384 && j < Jbol && p_Type != NULL && !((*p_Type)[j] & 1)) {
            if(j >= TOK_SSO_MAX || !tok_is_sso[j]) continue;
        }

        if(tok_count < TOK_MAX) {
            strncpy(tok_buf[tok_count].name, name, sizeof(tok_buf[tok_count].name) - 1);
            tok_buf[tok_count].name[sizeof(tok_buf[tok_count].name) - 1] = '\0';
            tok_buf[tok_count].start = start_ms;
            tok_buf[tok_count].end   = end_ms;
            tok_count++;
        }
    }
    tok_write_file();
}
