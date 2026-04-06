/*  bp3_wasm_stubs.c — Stub implementations for BP3 WASM build
 *
 *  These replace functions from excluded source files:
 *  MIDIdriver.c, MIDIstuff.c, MIDIfiles.c, PlayThings.c,
 *  MakeSound.c, Graphic.c, Csound.c, CsoundMaths.c,
 *  CsoundScoreMake.c, Script.c, ScriptUtils.c, HTML.c
 */

#include <math.h>
#include <emscripten.h>
#include "-BP3.h"
#include "-BP3decl.h"

/* Global: kmax from last TimeSet call, used by bp3_get_timed_tokens() */
long wasm_last_kmax = 0;

/* MPE channel tracking — matches native MIDIstuff.c:AssignUniqueChannel().
   Each MPE note gets a unique channel (1-15). Channel 0 is master. */
static short wasm_MPEnote[17];      /* Current note on each channel */
static short wasm_MPEold_note[17];  /* Original note before semitone shift */
static short wasm_MPEscale[17];     /* Scale index active on each channel */
static int   wasm_MPEpitch[17];     /* Pitch bend value on each channel */

static void wasm_MPE_reset(void) {
    int ch;
    for(ch = 0; ch < 17; ch++) {
        wasm_MPEnote[ch] = 0;
        wasm_MPEold_note[ch] = 0;
        wasm_MPEscale[ch] = -1;
        wasm_MPEpitch[ch] = -1;
    }
}

/* Assign a unique MPE channel for a note.
   Returns channel 1-15, or -1 if all channels are in use.
   For NoteOff, finds the channel that has this note+scale. */
static int wasm_MPE_assign(int isNoteOn, int note, int i_scale, int pitch) {
    int ch;
    if(!isNoteOn) {
        /* NoteOff: find matching channel */
        for(ch = 1; ch < 16; ch++) {
            if(wasm_MPEold_note[ch] == note && wasm_MPEscale[ch] == i_scale) {
                wasm_MPEnote[ch] = 0;
                wasm_MPEscale[ch] = -1;
                wasm_MPEpitch[ch] = -1;
                return ch;
            }
        }
        return 1; /* fallback */
    }
    /* NoteOn: find free channel */
    for(ch = 1; ch < 16; ch++) {
        if(wasm_MPEnote[ch] == 0 && wasm_MPEscale[ch] == -1) {
            wasm_MPEnote[ch] = note;
            wasm_MPEold_note[ch] = note;
            wasm_MPEscale[ch] = i_scale;
            wasm_MPEpitch[ch] = pitch;
            return ch;
        }
    }
    return 1; /* fallback: reuse channel 1 */
}

/* Accumulated instances across Improvize items for timed tokens.
   p_Instance is overwritten by each TimeSet call, so we copy relevant
   fields after each PlayBuffer1 into this accumulator. */
typedef struct {
    short object;
    Milliseconds starttime, endtime;
    char velocity, channel;
    int scale;
    short transposition;
    short xpandkey, xpandval;
    char lastistranspose;
} WasmInstanceAccum;

WasmInstanceAccum *wasm_accum = NULL;
long wasm_accum_count = 0;
long wasm_accum_capacity = 0;
/* Time offset for multi-item production (Improvize/AllItems): each item's
   timestamps are relative, we shift them by the cumulative max(endtime) of
   prior items.  This gives exact ms timestamps from TimeSet.
   Note: the native MIDI file introduces ±1ms rounding per event due to
   tick→ms conversion (ms_per_tick != 1.0 exactly), but the WASM timestamps
   are the correct values. */
Milliseconds wasm_accum_time_offset = 0;
/* Same offset applied to MIDI events in eventStack.
   Separate from wasm_accum_time_offset because the accum is Improvize-only
   while MIDI events are always extracted. */
Milliseconds wasm_midi_time_offset = 0;

/* Kpress quantization offset: when Kpress >= 2, TimeSet's rounding
   compensation shifts all T[] values by one quantum (T[0] gets overwritten
   with T[1]). Native corrects via FormatMIDIstream(zerostart). We subtract
   this offset when reading p_Instance timestamps. */
Milliseconds wasm_kpress_offset = 0;

/* T47 / SSO detection: after PolyMake resolves pp_buff, we scan the
   tokenbyte stream for T47 tags and mark the corresponding bol indices.
   bp3_get_timed_tokens uses this to distinguish SSO (emit) from
   non-terminal residuals (skip). Reset at each PlayBuffer1 call. */
#define WASM_SSO_MAX 4096
char wasm_is_sso[WASM_SSO_MAX];  /* 1 = bol j is SSO (T47), 0 = not */
int wasm_sso_scanned = 0;  /* set after scan */

/* ============================================================
 * RNG: now using bp3_random.c (MSVC-compatible LCG) included via -BP3.h.
 * The glibc TYPE_3 implementation that was here has been removed.
 * All engine code now calls bp3_rand()/bp3_srand()/BP3_RAND_MAX
 * instead of rand()/srand()/RAND_MAX.
 * ============================================================ */

/* ============================================================
 * MIDIdriver.c stubs
 * ============================================================ */

int initializeMIDISystem(void) {
    return OK;
}

void closeMIDISystem(void) {
    return;
}

int MIDIflush(int force, int panic) {
    BP_NOT_USED(force);
    BP_NOT_USED(panic);
    return OK;
}

unsigned long getClockTime(void) {
    /* Return time in microseconds using clock() */
    return (unsigned long)((double)clock() / CLOCKS_PER_SEC * 1000000.0);
}

int ListenToEvents(void) {
    return OK;
}

void sendMIDIEvent(int type, int status, int data1, int data2,
                   unsigned char* sysex, int sysex_len, long time) {
    BP_NOT_USED(type); BP_NOT_USED(status);
    BP_NOT_USED(data1); BP_NOT_USED(data2);
    BP_NOT_USED(sysex); BP_NOT_USED(sysex_len);
    BP_NOT_USED(time);
}

int MaybeWait(unsigned long time) {
    BP_NOT_USED(time);
    return OK;
}

/* ============================================================
 * MIDIstuff.c stubs
 * ============================================================ */

int FormatMIDIstream(MIDIcode **p_b, long imax, MIDIcode **p_c, int zerostart,
    long im2, long *p_nbytes, int filter) {
    BP_NOT_USED(p_b); BP_NOT_USED(imax); BP_NOT_USED(p_c); BP_NOT_USED(zerostart);
    BP_NOT_USED(im2); BP_NOT_USED(p_nbytes); BP_NOT_USED(filter);
    return OK;
}

int MIDItoPrototype(int zerostart, int filter, int j, MIDIcode **p_b, long imax) {
    BP_NOT_USED(zerostart); BP_NOT_USED(filter); BP_NOT_USED(j);
    BP_NOT_USED(p_b); BP_NOT_USED(imax);
    return OK;
}

int SendToDriver(int a, int b, int c, Milliseconds d, int e,
                 int* f, MIDI_Event* g) {
    BP_NOT_USED(a); BP_NOT_USED(b); BP_NOT_USED(c);
    BP_NOT_USED(d); BP_NOT_USED(e); BP_NOT_USED(f); BP_NOT_USED(g);
    return OK;
}

int CaptureMidiEvent(Milliseconds time, int nseq, MIDI_Event *p_e) {
    BP_NOT_USED(time); BP_NOT_USED(nseq); BP_NOT_USED(p_e);
    return OK;
}

int CleanUpBuffer(void) {
    return OK;
}

/* ============================================================
 * MIDIfiles.c stubs
 * ============================================================ */

int ResetMIDIfile(void) {
    return OK;
}

int CloseMIDIFile(void) {
    return OK;
}

/* ChannelConvert — now in real MakeSound.c */

int AllNotesOffAllChannels(int force) {
    BP_NOT_USED(force);
    return OK;
}

int AllControlsOffAllChannels(int force) {
    BP_NOT_USED(force);
    return OK;
}

int ReadMIDIfile(int* p_result) {
    BP_NOT_USED(p_result);
    return MISSED;
}

int PrepareMIDIFile(void) {
    return OK;
}

int FadeOut(void) {
    return OK;
}

int ImportMIDIfile(int w) {
    BP_NOT_USED(w);
    return MISSED;
}

int NewTrack(void) {
    return OK;
}

/* ClipVelocity, WaitForLastSounds — now in real MakeSound.c */

int MakeMIDIFile(OutFileInfo* finfo) {
    BP_NOT_USED(finfo);
    return OK;
}

/* ============================================================
 * PlayThings.c stubs
 * ============================================================ */

int PlaySelection(int w, int all) {
    BP_NOT_USED(w); BP_NOT_USED(all);
    BPPrintMessage(0, odWarning, "PlaySelection() not available in WASM build\n");
    return OK;
}

int ExpandSelection(int w) {
    BP_NOT_USED(w);
    BPPrintMessage(0, odWarning, "ExpandSelection() not available in WASM build\n");
    return OK;
}

int ChangedProtoType(int j) {
    /* Stub: in native, updates UI when a prototype changes.
       In WASM, nothing to do — no UI to update. */
    BP_NOT_USED(j);
    return OK;
}

int PlayBuffer(tokenbyte ***pp_buff, int onlypianoroll) {
    int r;
    int savedPanic;

    if(Panic || CheckEmergency() != OK) return(ABORT);
    if(Jbol < 3) NoAlphabet = TRUE;
    else NoAlphabet = FALSE;

    /* Save Panic state — WASM PlayBuffer must not propagate ABORT
       from MIDI extraction failures to the text production pipeline */
    savedPanic = Panic;

    if(FirstTime && !onlypianoroll) {
        if(p_Initbuff == NULL) {
            return(OK); /* Graceful: no init buffer, skip MIDI */
        }
        r = PlayBuffer1(&p_Initbuff, NO);
        if(r != OK) {
            Panic = savedPanic; /* Restore */
            return(OK); /* Don't abort production */
        }
        FirstTime = FALSE;
    }
    r = PlayBuffer1(pp_buff, onlypianoroll);
    if(!PlaySelectionOn && ItemNumber > INT_MAX) ItemNumber = 1L;

    /* In WASM non-Improvize mode, don't let MIDI extraction failure abort
       text production. But in Improvize mode, ABORT from PlayBuffer is the
       normal signal to stop the loop — propagate it. */
    if(!Improvize && (r == ABORT || r == EXIT)) {
        Panic = savedPanic;
        r = OK;
    }
    return(r);
}

int PlayBuffer1(tokenbyte ***pp_buff, int onlypianoroll) {
    int result, nmax, k, j;
    long tmin, tmax, kmax, length;
    unsigned long maxseq;
    double maxseqapprox;
    unsigned long **p_imaxseq;
    tokenbyte **p_b;

    length = LengthOf(pp_buff);
    emscripten_log(EM_LOG_CONSOLE, "PlayBuffer1: length=%ld midi_offset=%ld", length, (long)wasm_midi_time_offset);
    if(length < 1) return(OK);
    CurrentChannel = 1;

    /* Reset MPE channel tracking for this item */
    if(MIDImicrotonality) wasm_MPE_reset();

    /* Store item for later restoration */
    p_b = NULL;
    int store = FALSE;
    if(!Improvize && !PlaySelectionOn && !onlypianoroll) store = TRUE;
    if(store) {
        if((p_b = (tokenbyte**)GiveSpace((Size)MyGetHandleSize((Handle)*pp_buff))) == NULL)
            return(ABORT);
        if(CopyBuf(pp_buff, &p_b) == ABORT) return(ABORT);
    }

    result = OK;
    ShowMessages = TRUE;

    /* PolyMake: resolve polymetric expressions */
    emscripten_log(EM_LOG_CONSOLE, "PlayBuffer1: calling PolyMake...");
    while((result = PolyMake(pp_buff, &maxseqapprox, YES)) == AGAIN) {};
    emscripten_log(EM_LOG_CONSOLE, "PlayBuffer1: PolyMake result=%d", result);
    if(result == EMPTY) { result = OK; goto SORTIR; }
    if(result != OK) {
        result = OK; goto SORTIR;
    }

    /* Scan pp_buff for T47 tags to identify SSO (silent sound objects).
       T47 = remaining variable processed as SSO (Bernard 2026-04-06).
       Format: tokenbyte pairs [tag, param] — T47 with param = bol index. */
    {
        size_t buf_size = MyGetHandleSize((Handle)*pp_buff) / sizeof(tokenbyte);
        tokenbyte *buf = **pp_buff;
        memset(wasm_is_sso, 0, sizeof(wasm_is_sso));
        wasm_sso_scanned = 1;
        int sso_count = 0;
        size_t bi;
        for(bi = 0; bi + 1 < buf_size; bi += 2) {
            if(buf[bi] == T47) {
                int p = buf[bi + 1];
                if(p > 1 && p < WASM_SSO_MAX) {
                    if(!wasm_is_sso[p]) { wasm_is_sso[p] = 1; sso_count++; }
                }
            }
        }
        if(sso_count > 0)
            emscripten_log(EM_LOG_CONSOLE, "PlayBuffer1: T47 scan found %d SSO bols", sso_count);
    }

    /* Allocate event space */
    emscripten_log(EM_LOG_CONSOLE, "PlayBuffer1: calling MakeEventSpace... Maxevent=%ld Maxconc=%ld Jbol=%ld",
        (long)Maxevent, (long)Maxconc, (long)Jbol);
    if((result = MakeEventSpace(&p_imaxseq)) != OK) {
        emscripten_log(EM_LOG_CONSOLE, "PlayBuffer1: MakeEventSpace FAILED");
        result = OK; goto SORTIR;
    }

    /* Check prototypes */
    if((result = CheckLoadedPrototypes()) != OK) {
        goto RELEASE;
    }

    /* Debug: verify p_MIDIsize before TimeSet */
    {
        int dbg;
        for(dbg = 2; dbg < Jbol && dbg < 20; dbg++) {
            if((*p_MIDIsize)[dbg] > 0)
                emscripten_log(EM_LOG_CONSOLE, "pre-TimeSet: p_Bol[%d] MIDIsize=%ld Dur=%ld",
                    dbg, (long)(*p_MIDIsize)[dbg], (long)(*p_Dur)[dbg]);
        }
    }

    /* Match native MakeSound.c:124 — increment ItemNumber when writing MIDI.
       New ProduceItems.c delegates ItemNumber management to MakeSound/PlayBuffer1
       when WriteMIDIfile is TRUE (no more unconditional increment in Improvize loop).
       ProduceItems.c has a fallback increment only if PlayBuffer1 didn't do it. */
    if(WriteMIDIfile || OutCsound) {
        ItemNumber++;
        /* Native MakeSound.c:126-128: early return if max items reached.
           Without this, WASM processes one extra item beyond MaxItemsProduce. */
        if((MaxItemsProduce > 0) && ItemNumber > MaxItemsProduce) {
            result = OK;
            goto SORTIR;
        }
    }

    /* TimeSet: compute start/end times for all sound objects.
       Matches native PlayThings.c:PlayBuffer1 behavior — no token-type guard.
       Native calls TimeSet unconditionally; we do the same.
       WriteMIDIfile check: text-only grammars should call bp3_set_write_midi(0)
       before produce, which makes PlayBuffer a no-op in native. In WASM we still
       reach here, so skip TimeSet when there's nothing to time-set. */
    if(!WriteMIDIfile && !OutCsound) {
        /* Text-only mode: no MIDI output needed, skip TimeSet entirely
           (matches native where PlayBuffer is not called without WriteMIDIfile) */
        result = OK;
        goto SORTIR;
    }
    SetTimeOn = TRUE; nmax = 0; kmax = 0;
    result = TimeSet(pp_buff, &kmax, &tmin, &tmax, &maxseq, &nmax, p_imaxseq, maxseqapprox);
    SetTimeOn = FALSE;
    /* Match native: MISSED → ShowError(37), ABORT/EXIT → goto RELEASE */
    if(result == MISSED || result == ABORT || result == EXIT) {
        emscripten_log(EM_LOG_CONSOLE, "PlayBuffer1: TimeSet result=%d — skipping MIDI extraction", result);
        if(Panic) return(ABORT);
        kmax = 0;
        goto RELEASE;
    }
    if(result == AGAIN) result = OK;
    wasm_last_kmax = kmax;

    /* MakeSound call DISABLED — modifies global state (t0, t1, Tcurr, p_keyon, etc.)
       which corrupts subsequent PlayBuffer1 extraction and multi-item processing.
       EmitTimedEvent infrastructure remains for future S3 use when Bernard fixes #32/#33.
    if(WriteMIDIfile || OutCsound) {
        int ms_result = MakeSound(&kmax, maxseq, nmax+1, pp_buff, tmin, tmax, NO, NULL);
        if(ms_result == ABORT) { result = ABORT; goto RELEASE; }
        emscripten_log(EM_LOG_CONSOLE, "PlayBuffer1: MakeSound result=%d timed_events=%ld",
            ms_result, g_timed_event_count);
    } */

    emscripten_log(EM_LOG_CONSOLE, "PlayBuffer1: TimeSet result=%d kmax=%ld nmax=%d", result, kmax, nmax);
    {   long dbg_max = (kmax < 50) ? kmax : 50;
        for(k = 2; k <= dbg_max; k++) {
            emscripten_log(EM_LOG_CONSOLE, "  p_Instance[%ld] obj=%d start=%ld end=%ld",
                k, (*p_Instance)[k].object, (long)(*p_Instance)[k].starttime, (long)(*p_Instance)[k].endtime);
        }
        if(kmax > 50) emscripten_log(EM_LOG_CONSOLE, "  ... (%ld more instances)", kmax - 50);
    }
    result = OK;

    /* Compute Kpress quantization offset (#35) for this item.
       When Kpress >= 2, TimeSet's rounding compensation shifts T[0] by one
       quantum. Find min starttime and store as wasm_kpress_offset. */
    if(Kpress >= 2.0 && wasm_kpress_offset == 0) {
        Milliseconds min_start = -1;
        long ks;
        for(ks = 2; ks <= kmax; ks++) {
            int obj = (*p_Instance)[ks].object;
            if(obj == -1) break;
            if(obj < 2) continue;
            Milliseconds st = (*p_Instance)[ks].starttime;
            if(min_start < 0 || st < min_start) min_start = st;
        }
        if(min_start > 0) {
            wasm_kpress_offset = min_start;
            emscripten_log(EM_LOG_CONSOLE, "PlayBuffer1: Kpress=%.0f, kpress_offset=%ldms", Kpress, (long)min_start);
        }
    }

    /* === WASM: Extract MIDI events from p_Instance into eventStack ===
       Apply wasm_midi_time_offset for inter-item time accumulation.
       Apply MPE microtonal remapping when MIDImicrotonality is active.
       Post-extraction: zerostart normalization (subtract min time from all
       events in this item), matching native FormatMIDIstream behavior. */
    Milliseconds midi_item_max_end = 0;
    long eventStart = eventCount;  /* Remember start index for zerostart normalization */
    if(p_Instance != NULL && eventStack != NULL) {
        /* Pre-MPE dedup tracking: record (key, time) pairs before MPE remapping.
           MPE assigns unique channels per note, so post-MPE dedup would fail.
           Allocate based on kmax to handle large grammars (visser5: 1100+ notes). */
        #define DEDUP_STATIC_MAX 256
        int dedupKeysStatic[DEDUP_STATIC_MAX];
        Milliseconds dedupTimesStatic[DEDUP_STATIC_MAX];
        long dedupNoteOffStatic[DEDUP_STATIC_MAX];  /* eventStack index of NoteOff */
        int *dedupKeys = dedupKeysStatic;
        Milliseconds *dedupTimes = dedupTimesStatic;
        long *dedupNoteOff = dedupNoteOffStatic;
        long dedupCount = 0;
        long dedupMax = DEDUP_STATIC_MAX;
        if(kmax > DEDUP_STATIC_MAX) {
            dedupKeys = (int *)malloc(kmax * sizeof(int));
            dedupTimes = (Milliseconds *)malloc(kmax * sizeof(Milliseconds));
            dedupNoteOff = (long *)malloc(kmax * sizeof(long));
            if(dedupKeys && dedupTimes && dedupNoteOff) {
                dedupMax = kmax;
            } else {
                /* Fallback to static if malloc fails */
                if(dedupKeys && dedupKeys != dedupKeysStatic) free(dedupKeys);
                if(dedupTimes && dedupTimes != dedupTimesStatic) free(dedupTimes);
                if(dedupNoteOff && dedupNoteOff != dedupNoteOffStatic) free(dedupNoteOff);
                dedupKeys = dedupKeysStatic;
                dedupTimes = dedupTimesStatic;
                dedupNoteOff = dedupNoteOffStatic;
                dedupMax = DEDUP_STATIC_MAX;
            }
        }

        for(k = 2; k <= kmax; k++) {
            j = (*p_Instance)[k].object;
            if(j < 2) continue;  /* Skip silences/markers */

            int midiKey;
            if(j >= 16384) {
                /* Simple note (T25): MIDI key encoded as object - 16384 */
                midiKey = j - 16384;
            } else {
                /* Complex sound object — skip for now */
                continue;
            }

            /* Apply _transpose and _keyxpand — match native MakeSound.c:421-423. */
            int trans = (*p_Instance)[k].transposition;
            short xpk = (*p_Instance)[k].xpandkey;
            short xpv = (*p_Instance)[k].xpandval;
            if((*p_Instance)[k].lastistranspose) {
                if(trans != 0) TransposeKey(&midiKey, trans);
                midiKey = ExpandKey(midiKey, xpk, xpv);
            } else {
                midiKey = ExpandKey(midiKey, xpk, xpv);
                if(trans != 0) TransposeKey(&midiKey, trans);
            }

            if(midiKey < 0 || midiKey > 127) continue;

            Milliseconds startMs = (*p_Instance)[k].starttime - wasm_kpress_offset + wasm_midi_time_offset;
            Milliseconds endMs = (*p_Instance)[k].endtime - wasm_kpress_offset + wasm_midi_time_offset;


            int vel = (unsigned char)(*p_Instance)[k].velocity;
            int chan = (*p_Instance)[k].channel;
            int scale = (*p_Instance)[k].scale;
            int blockkey = (*p_Instance)[k].blockkey;

            if((*p_Instance)[k].endtime > midi_item_max_end)
                midi_item_max_end = (*p_Instance)[k].endtime;

            if(vel == 0) continue;
            if(vel > 127) vel = 127;
            if(chan < 1) chan = 1;
            if(chan > 16) chan = 16;

            /* Deduplicate BEFORE MPE remapping: when same note+time appears
               on multiple polymetric lines, keep the longest duration.
               Matches native MakeSound p_keyon behavior (NoteOff at last release).
               Must happen before MPE because MPE assigns unique channels per note. */
            {
                int dup = FALSE;
                long dd;
                for(dd = 0; dd < dedupCount; dd++) {
                    if(dedupKeys[dd] == midiKey && dedupTimes[dd] == startMs) {
                        dup = TRUE; break;
                    }
                }
                if(dup) {
                    /* Keep longest: update NoteOff time if this instance ends later */
                    if(dedupNoteOff[dd] >= 0 && dedupNoteOff[dd] < eventCount
                       && endMs > eventStack[dedupNoteOff[dd]].time) {
                        eventStack[dedupNoteOff[dd]].time = endMs;
                    }
                    continue;
                }
                if(dedupCount < dedupMax) {
                    dedupKeys[dedupCount] = midiKey;
                    dedupTimes[dedupCount] = startMs;
                    dedupNoteOff[dedupCount] = -1;  /* Updated after NoteOff is emitted */
                    dedupCount++;
                }
            }

            /* === MPE microtonal remapping ===
               Match native MIDIstuff.c:SendToDriver() algorithm:
               1. Look up scale deviation + blockkey_shift (cents)
               2. If |correction| >= 100: shift note by semitones
               3. Assign unique MPE channel
               4. Emit PitchBend event for remaining cents */
            int mpe_chan = -1;
            int correction = 0;
            int i_scale = 0;
            if(MIDImicrotonality && scale != 0) {
                i_scale = FindScale(scale);
                if(i_scale > 0 && i_scale <= NumberScales) {
                    correction = (*(*Scale)[i_scale].deviation)[midiKey]
                               + (*(*Scale)[i_scale].blockkey_shift)[blockkey];

                    /* Semitone shift if |correction| >= 100 cents */
                    if(correction < -100 || correction >= 100) {
                        int shift = (int)floor((double)correction / 100.0);
                        int new_key = midiKey + shift;
                        if(new_key >= 0 && new_key < 128) {
                            correction -= 100 * shift;
                            midiKey = new_key;
                        } else {
                            /* Native warns "pitchbender out of range" and
                               plays the note without MPE correction.
                               Match that: emit the note as-is, no MPE. */
                            correction = 0;
                            i_scale = 0; /* disable MPE for this note */
                        }
                    }

                    /* Assign MPE channel */
                    mpe_chan = wasm_MPE_assign(1, midiKey, i_scale,
                        8192 + (int)(correction * 0.01 * 8192.0 / 2.0));
                    if(mpe_chan > 0) chan = mpe_chan;
                }
            }

            /* PitchBend event (before NoteOn, as native does) */
            if(MIDImicrotonality && i_scale > 0 && correction != 0
               && eventCount < eventCountMax) {
                unsigned int pbVal = 8192 + (int)(correction * 0.01 * 8192.0 / 2.0);
                if(pbVal > 16383) pbVal = 16383;
                eventStack[eventCount].time = startMs;
                eventStack[eventCount].type = RAW_EVENT;
                eventStack[eventCount].status = PitchBend | ((chan - 1) & 0x0F);
                eventStack[eventCount].data1 = pbVal & 0x7F;
                eventStack[eventCount].data2 = (pbVal >> 7) & 0x7F;
                eventStack[eventCount].instance = k;
                eventStack[eventCount].scale = scale;
                eventCount++;
            }

            /* NoteOn event */
            if(eventCount < eventCountMax) {
                eventStack[eventCount].time = startMs;
                eventStack[eventCount].type = RAW_EVENT;
                eventStack[eventCount].status = NoteOn | ((chan - 1) & 0x0F);
                eventStack[eventCount].data1 = (unsigned char)midiKey;
                eventStack[eventCount].data2 = (unsigned char)vel;
                eventStack[eventCount].instance = k;
                eventStack[eventCount].scale = scale;
                eventCount++;
            }

            /* NoteOff event — same channel and remapped note as NoteOn */
            if(eventCount < eventCountMax) {
                /* Record NoteOff index for dedup longest-duration update */
                if(dedupCount > 0) dedupNoteOff[dedupCount - 1] = eventCount;
                eventStack[eventCount].time = endMs;
                eventStack[eventCount].type = RAW_EVENT;
                eventStack[eventCount].status = NoteOff | ((chan - 1) & 0x0F);
                eventStack[eventCount].data1 = (unsigned char)midiKey;
                eventStack[eventCount].data2 = 0;
                eventStack[eventCount].instance = k;
                eventStack[eventCount].scale = scale;
                eventCount++;
            }
        }
        /* Free dynamic dedup arrays if allocated */
        if(dedupKeys != dedupKeysStatic) free(dedupKeys);
        if(dedupTimes != dedupTimesStatic) free(dedupTimes);
        if(dedupNoteOff != dedupNoteOffStatic) free(dedupNoteOff);
    }

    /* Zerostart normalization REMOVED (wasm.15).
       The native MIDI pipeline includes MIDIsetUpTime + grammatical silence
       in absolute event times.  The WASM reads p_Instance starttimes which
       already contain those offsets.  Subtracting the min time here destroyed
       legitimate initial silences (ames: 666ms, watch: 1590ms → 0ms).
       The native FormatMIDIstream(zerostart=TRUE) subtracts the first byte
       time from the raw MIDI stream, but that stream includes non-note setup
       events (ControlChange, Volume) written at MIDIsetUpTime — this is NOT
       equivalent to subtracting the first NoteOn time from p_Instance. */

    /* === NoteOff-before-re-trigger (p_keyon) ===
       Match native SendToDriver behavior: when the same key is re-triggered
       on the same channel, the previous note's NoteOff is truncated to the
       new NoteOn time.
       Algorithm: events are emitted in groups per instance (PitchBend?,
       NoteOn, NoteOff).  NoteOn at index ei has its NoteOff at ei+1 or ei+2.
       For each NoteOn, find its paired NoteOff, then check if any OTHER
       NoteOn on the same key+chan starts strictly between this NoteOn and
       this NoteOff — if so, truncate this NoteOff to the earliest such
       re-trigger time. */
    if(eventCount > eventStart) {
        long ei, ej;
        for(ei = eventStart; ei < eventCount; ei++) {
            if((eventStack[ei].status & 0xF0) != NoteOn) continue;
            int onKey  = eventStack[ei].data1;
            int onChan = eventStack[ei].status & 0x0F;
            Milliseconds onTime = eventStack[ei].time;
            /* Find paired NoteOff: same key+chan, next NoteOff after this NoteOn
               in the event list (they are emitted consecutively per instance). */
            long offIdx = -1;
            for(ej = ei + 1; ej < eventCount && ej <= ei + 2; ej++) {
                if((eventStack[ej].status & 0xF0) == NoteOff
                   && eventStack[ej].data1 == onKey
                   && (eventStack[ej].status & 0x0F) == onChan) {
                    offIdx = ej;
                    break;
                }
            }
            if(offIdx < 0) continue;
            Milliseconds offTime = eventStack[offIdx].time;
            /* Find earliest re-trigger: another NoteOn on same key+chan
               with time in (onTime, offTime) — strictly between. */
            Milliseconds earliestRetrigger = offTime;
            for(ej = eventStart; ej < eventCount; ej++) {
                if(ej == ei) continue;
                if((eventStack[ej].status & 0xF0) != NoteOn) continue;
                if(eventStack[ej].data1 != onKey) continue;
                if((eventStack[ej].status & 0x0F) != onChan) continue;
                if(eventStack[ej].time > onTime && eventStack[ej].time < earliestRetrigger) {
                    earliestRetrigger = eventStack[ej].time;
                }
            }
            if(earliestRetrigger < offTime) {
                eventStack[offIdx].time = earliestRetrigger;
            }
        }
    }

    /* Accumulate item duration for next item's offset. */
    wasm_midi_time_offset += midi_item_max_end;

    /* Accumulate instances for timed tokens (multi-item: Improvize or AllItems).
       p_Instance is overwritten by each TimeSet call, so we must copy here.
       Single-item grammars: bp3_get_timed_tokens reads p_Instance directly
       (wasm_accum_count stays 0).
       Dedup polymetric duplicates: when nmax > 1, p_Instance contains entries
       for ALL concurrent sequences — the same note appears once per sequence.
       Native MakeSound processes each unique note once; we replicate that here. */
    if(p_Instance != NULL && kmax > 1) {
        long accum_item_start = wasm_accum_count;  /* dedup within this item */
        Milliseconds item_max_end = 0;
        Milliseconds accum_q = wasm_accum_time_offset;
        for(k = 2; k <= kmax; k++) {
            j = (*p_Instance)[k].object;
            if(j <= 0) continue;
            if(j == -1) break;
            /* Skip vel=0 instances (silent notes, e.g. _vel(0) do#4) */
            if((*p_Instance)[k].velocity == 0) continue;
            /* Dedup: skip if same object+starttime+channel+transposition already in this item.
               Must include transposition: same object (e.g. C3) at same time but different
               transpositions produces different notes (e.g. Visser3 style). */
            {
                int dup = 0;
                long di;
                Milliseconds st = (*p_Instance)[k].starttime + accum_q;
                char ch = (*p_Instance)[k].channel;
                short tr = (*p_Instance)[k].transposition;
                for(di = accum_item_start; di < wasm_accum_count; di++) {
                    if(wasm_accum[di].object == j
                       && wasm_accum[di].starttime == st
                       && wasm_accum[di].channel == ch
                       && wasm_accum[di].transposition == tr) {
                        dup = 1; break;
                    }
                }
                if(dup) continue;
            }
            /* Grow accumulator if needed */
            if(wasm_accum_count >= wasm_accum_capacity) {
                long newcap = wasm_accum_capacity ? wasm_accum_capacity * 2 : 512;
                WasmInstanceAccum *newbuf = (WasmInstanceAccum*)realloc(wasm_accum, newcap * sizeof(WasmInstanceAccum));
                if(!newbuf) break;
                wasm_accum = newbuf;
                wasm_accum_capacity = newcap;
            }
            wasm_accum[wasm_accum_count].object = j;
            wasm_accum[wasm_accum_count].starttime = (*p_Instance)[k].starttime + accum_q;
            wasm_accum[wasm_accum_count].endtime = (*p_Instance)[k].endtime + accum_q;
            wasm_accum[wasm_accum_count].velocity = (*p_Instance)[k].velocity;
            wasm_accum[wasm_accum_count].channel = (*p_Instance)[k].channel;
            wasm_accum[wasm_accum_count].scale = (*p_Instance)[k].scale;
            wasm_accum[wasm_accum_count].transposition = (*p_Instance)[k].transposition;
            wasm_accum[wasm_accum_count].xpandkey = (*p_Instance)[k].xpandkey;
            wasm_accum[wasm_accum_count].xpandval = (*p_Instance)[k].xpandval;
            wasm_accum[wasm_accum_count].lastistranspose = (*p_Instance)[k].lastistranspose;
            if((*p_Instance)[k].endtime > item_max_end)
                item_max_end = (*p_Instance)[k].endtime;
            wasm_accum_count++;
        }
        wasm_accum_time_offset += item_max_end;
    }

RELEASE:
    ReleasePhaseDiagram(nmax, &p_imaxseq);

SORTIR:
    if(store) {
        if(CopyBuf(&p_b, pp_buff) == ABORT) return(ABORT);
        MyDisposeHandle((Handle*)&p_b);
    }
    return(result);
}

int PlayHandle(char** h, int w) {
    BP_NOT_USED(h); BP_NOT_USED(w);
    return OK;
}

int ShowPeriods(int w) {
    BP_NOT_USED(w);
    return OK;
}

/* AnalyzeSelection is defined in ProduceItems.c */

/* ============================================================
 * MakeSound.c stubs
 * ============================================================ */

/* MakeSound stub REMOVED — real MakeSound.c is now compiled for WASM.
   This enables EmitTimedEvent for timed tokens with temporal corrections
   (beta, scheduling, cyclic objects). */

/* MIDI utility functions needed by MakeSound — extracted from MIDIstuff.c
   (MIDIstuff.c itself has too many hardware MIDI dependencies for WASM) */
int TwoByteEvent(int c) {
    int c0;
    if(c < NoteOff) return(NO);
    if(c == SongSelect) return(YES);
    c0 = c - c % 16;
    if(c0 == ProgramChange || c0 == ChannelPressure) return(YES);
    return(NO);
}

int ThreeByteChannelEvent(int c) {
    if(c < NoteOff) return(NO);
    if(c == ProgramChange || c == ChannelPressure) return(NO);
    if(c > PitchBend) return(NO);
    return(YES);
}

int ThreeByteEvent(int c) {
    int c0;
    if(c < NoteOff) return(NO);
    if(c == SongPosition) return(YES);
    c0 = c - c % 16;
    if(ThreeByteChannelEvent(c0)) return(YES);
    return(NO);
}

int ChannelEvent(int c) {
    int c0;
    if(c < NoteOff) return(NO);
    c0 = c - c % 16;
    if(c0 < SystemExclusive) return(YES);
    return(NO);
}

int InterruptSound(void) {
    return OK;
}

/* ============================================================
 * Graphic.c stubs
 * ============================================================ */

int HasGWorlds(void) {
    return 0;
}

int DrawNoteScale(Rect* r, int a, int b, int c, int d, int e, int f) {
    BP_NOT_USED(r); BP_NOT_USED(a); BP_NOT_USED(b); BP_NOT_USED(c);
    BP_NOT_USED(d); BP_NOT_USED(e); BP_NOT_USED(f);
    return OK;
}

int DrawPianoNote(char* s, int a, int b, Milliseconds c, Milliseconds d,
                  int e, int f, int g, int h, int i, Rect* r) {
    BP_NOT_USED(s); BP_NOT_USED(a); BP_NOT_USED(b); BP_NOT_USED(c);
    BP_NOT_USED(d); BP_NOT_USED(e); BP_NOT_USED(f); BP_NOT_USED(g);
    BP_NOT_USED(h); BP_NOT_USED(i); BP_NOT_USED(r);
    return OK;
}

/* Findibm — now in real MakeSound.c */

int DrawItemBackground(Rect* r, unsigned long a, int b, int c, int d, int e,
                        Milliseconds** f, long* g, int h, int* i, char* j) {
    BP_NOT_USED(r); BP_NOT_USED(a); BP_NOT_USED(b); BP_NOT_USED(c);
    BP_NOT_USED(d); BP_NOT_USED(e); BP_NOT_USED(f); BP_NOT_USED(g);
    BP_NOT_USED(h); BP_NOT_USED(i); BP_NOT_USED(j);
    return OK;
}

/* GetTableValue, ContinuousParameter — now in real MakeSound.c */

int GetPartOfTable(XYgraph* a, double b, double c, long d, Coordinates** e) {
    BP_NOT_USED(a); BP_NOT_USED(b); BP_NOT_USED(c);
    BP_NOT_USED(d); BP_NOT_USED(e);
    return OK;
}

int MakeCsoundFunctionTable(int a, double** b, double c, double d,
                             long e, Coordinates** f, int g, int h,
                             int i, int j, int k) {
    BP_NOT_USED(a); BP_NOT_USED(b); BP_NOT_USED(c); BP_NOT_USED(d);
    BP_NOT_USED(e); BP_NOT_USED(f); BP_NOT_USED(g); BP_NOT_USED(h);
    BP_NOT_USED(i); BP_NOT_USED(j); BP_NOT_USED(k);
    return OK;
}

double CombineScoreValues(double a, double b, double c, double d,
                           double e, int f, int g, int h) {
    BP_NOT_USED(a); BP_NOT_USED(b); BP_NOT_USED(c); BP_NOT_USED(d);
    BP_NOT_USED(e); BP_NOT_USED(f); BP_NOT_USED(g); BP_NOT_USED(h);
    return 0.0;
}

int GetGENtype(int a, int b, int c) {
    BP_NOT_USED(a); BP_NOT_USED(b); BP_NOT_USED(c);
    return 0;
}

double Remap(double val, int a, int b, int* c) {
    BP_NOT_USED(a); BP_NOT_USED(b); BP_NOT_USED(c);
    return val;
}

/* WaitForEmptyBuffer — now in real MakeSound.c */

/* ============================================================
 * Csound.c / CsoundMaths.c / CsoundScoreMake.c stubs
 * ============================================================ */

int CompileCsoundObjects(void) {
    return OK;
}

int FindCsoundInstrument(char* name) {
    BP_NOT_USED(name);
    return MISSED;
}

int ResetMIDIFilter(void) {
    return OK;
}

int ResetCsoundInstrument(int a, int b, int c) {
    BP_NOT_USED(a); BP_NOT_USED(b); BP_NOT_USED(c);
    return OK;
}

int ResetMoreParameter(int j, int ip) {
    BP_NOT_USED(j); BP_NOT_USED(ip);
    return OK;
}

/* FindScale() — Real implementation from MIDIstuff.c (Bernard Bel)
   Searches Scale[] array for a scale whose label matches the string constant. */
int FindScale(int scale) {
    int i_scale, result;
    if(scale < 0) return(-1);
    if(scale == 0) { i_scale = 0; return i_scale; } /* Equal-tempered */
    /* 'scale' is the index of its name in StringConstant */
    for(i_scale = 1; i_scale <= NumberScales; i_scale++) {
        result = MyHandlecmp((*p_StringConstant)[scale], (*Scale)[i_scale].label);
        if(result == 0) break;
    }
    return i_scale;
}

/* FixStringConstant and FixNumberConstant are defined in Misc.c */

int CompileRegressions(void) {
    return OK;
}

int CompileObjectScore(int a, int* b) {
    BP_NOT_USED(a); BP_NOT_USED(b);
    return OK;
}

int SetInputFilterWord(int a) {
    BP_NOT_USED(a);
    return OK;
}

int SetOutputFilterWord(int a) {
    BP_NOT_USED(a);
    return OK;
}

int GetInputFilterWord(int a) {
    BP_NOT_USED(a);
    return 0;
}

int GetOutputFilterWord(int a) {
    BP_NOT_USED(a);
    return 0;
}

/* LoadCsoundInstruments is defined in SaveLoads1.c */

int CscoreWrite(Rect* r, int a, int b, int c, int d, int e, int f,
                int g, double h, Milliseconds i, int j, int k, int l,
                int m, int n, int o, int p, int q, PerfParameters**** pp,
                int s, int t) {
    BP_NOT_USED(r); BP_NOT_USED(a); BP_NOT_USED(b); BP_NOT_USED(c);
    BP_NOT_USED(d); BP_NOT_USED(e); BP_NOT_USED(f); BP_NOT_USED(g);
    BP_NOT_USED(h); BP_NOT_USED(i); BP_NOT_USED(j); BP_NOT_USED(k);
    BP_NOT_USED(l); BP_NOT_USED(m); BP_NOT_USED(n); BP_NOT_USED(o);
    BP_NOT_USED(p); BP_NOT_USED(q); BP_NOT_USED(pp); BP_NOT_USED(s);
    BP_NOT_USED(t);
    return OK;
}

int FixCsoundScoreName(char* s) {
    BP_NOT_USED(s);
    return OK;
}

int Findabc(double*** a, int b, regression* c) {
    BP_NOT_USED(a); BP_NOT_USED(b); BP_NOT_USED(c);
    return OK;
}

int GetRegressions(int a) {
    BP_NOT_USED(a);
    return OK;
}

double XtoY(double x, regression* r, int* err, int mode) {
    BP_NOT_USED(r); BP_NOT_USED(err); BP_NOT_USED(mode);
    return x;
}

double YtoX(double y, regression* r, int* err, int mode) {
    BP_NOT_USED(r); BP_NOT_USED(err); BP_NOT_USED(mode);
    return y;
}

/* ============================================================
 * Script.c / ScriptUtils.c stubs
 * ============================================================ */

int ExecScriptLine(char*** h, int a, int b, int c, char** d,
                   long e, long* f, int* g, int* h2) {
    BP_NOT_USED(h); BP_NOT_USED(a); BP_NOT_USED(b); BP_NOT_USED(c);
    BP_NOT_USED(d); BP_NOT_USED(e); BP_NOT_USED(f); BP_NOT_USED(g);
    BP_NOT_USED(h2);
    return OK;
}

int DoScript(int a, char*** b, int c, int d, int e, long* f,
             int* g, char* h, int i) {
    BP_NOT_USED(a); BP_NOT_USED(b); BP_NOT_USED(c); BP_NOT_USED(d);
    BP_NOT_USED(e); BP_NOT_USED(f); BP_NOT_USED(g); BP_NOT_USED(h);
    BP_NOT_USED(i);
    return OK;
}

/* ExecuteScriptList — now in real MakeSound.c */

int InterruptScript(void) {
    return OK;
}

/* ============================================================
 * HTML.c stubs
 * ============================================================ */

int CheckHTML(int a, int b, char** c, long* d, int* e) {
    BP_NOT_USED(a); BP_NOT_USED(b); BP_NOT_USED(c);
    BP_NOT_USED(d); BP_NOT_USED(e);
    return OK;
}

int DOStoMac(char* s) {
    BP_NOT_USED(s);
    return OK;
}

int MacToHTML(int a, char*** b, int c) {
    BP_NOT_USED(a); BP_NOT_USED(b); BP_NOT_USED(c);
    return OK;
}

/* ============================================================
 * Note resolution — Real implementations from MIDIstuff.c (Bernard Bel)
 * ============================================================ */

/* GetThisNote() — Real implementation from MIDIstuff.c (Bernard Bel)
   Resolves note name + octave to MIDI key number using the current NoteConvention. */
int GetThisNote(char* line, int* p_thekey, int* p_channel, int ignorechannel) {
    char *p, *q, line2[MAXLIN];
    int i, j, pitchclass, octave, l;

    i = j = 0;
    while(MySpace(line[i])) i++;
    strcpy(line2, line);

    if(NoteConvention == KEYS) {
        while(line[i] != '\0' && line[i] == KeyString[j]) {
            i++; j++;
        }
        if(KeyString[j] != '\0') return(MISSED);
        *p_thekey = GetInteger(YES, line2, &i);
        if(*p_thekey == INT_MAX) return(MISSED);
    }
    else {
        for(pitchclass = 0; pitchclass < 12; pitchclass++) {
            p = &line2[i];
            switch(NoteConvention) {
                case FRENCH: {
                    q = &Frenchnote[pitchclass][0]; l = strlen(Frenchnote[pitchclass]);
                    if(l > 0 && Match(TRUE, &p, &q, l) && isdigit(p[l])) goto CONT;
                    p = &line2[i];
                    q = &AltFrenchnote[pitchclass][0]; l = strlen(AltFrenchnote[pitchclass]);
                    if(l > 0 && Match(TRUE, &p, &q, l) && isdigit(p[l])) goto CONT;
                    break;
                }
                case ENGLISH: {
                    q = &Englishnote[pitchclass][0]; l = strlen(Englishnote[pitchclass]);
                    if(l > 0 && Match(TRUE, &p, &q, l) && isdigit(p[l])) goto CONT;
                    p = &line2[i];
                    q = &AltEnglishnote[pitchclass][0]; l = strlen(AltEnglishnote[pitchclass]);
                    if(l > 0 && Match(TRUE, &p, &q, l) && isdigit(p[l])) goto CONT;
                    break;
                }
                case INDIAN:
                    q = &Indiannote[pitchclass][0]; l = strlen(Indiannote[pitchclass]);
                    if(l > 0 && Match(TRUE, &p, &q, l) && isdigit(p[l])) goto CONT;
                    p = &line2[i];
                    q = &AltIndiannote[pitchclass][0]; l = strlen(AltIndiannote[pitchclass]);
                    if(l > 0 && Match(TRUE, &p, &q, l) && isdigit(p[l])) goto CONT;
                    break;
            }
        }
        return(MISSED);

    CONT:
        while(!isdigit(line[i]) && line[i] != '\0') i++;
        if(NoteConvention == FRENCH) {
            if(line[i] == '0' && line[i+1] == '0' && line[i+2] == '0') {
                octave = 0; i += 3;
                goto CONT2;
            }
            if(line[i] == '0' && line[i+1] == '0') {
                octave = 1; i += 2;
                goto CONT2;
            }
        }
        if(NoteConvention == ENGLISH || NoteConvention == INDIAN) {
            if(line[i] == '0' && line[i+1] == '0') {
                octave = 0; i += 2;
                goto CONT2;
            }
        }
        if((octave = GetInteger(YES, line2, &i)) == INT_MAX) return(MISSED);
        if(NoteConvention == FRENCH) octave += 2;
        if(NoteConvention == ENGLISH || NoteConvention == INDIAN) octave++;

    CONT2:
        *p_thekey = 12 * octave + pitchclass;
        *p_thekey += (C4key - 60);
    }

    if(ignorechannel) return(OK);
    while(MySpace(line[i])) i++;
    strcpy(Message, "channel");
    p = &line2[i]; q = &(Message[0]);
    if(!Match(FALSE, &p, &q, strlen(Message))) return(MISSED);
    while(!isdigit(line[i]) && line[i] != '\0') i++;
    if((*p_channel = GetInteger(YES, line2, &i)) == INT_MAX) return(MISSED);
    return(OK);
}

/* PrintThisNote() — Real implementation from MIDIstuff.c (Bernard Bel)
   Converts MIDI key number back to note name string. */
int PrintThisNote(int i_scale, int key, int channel, int wind, char* line) {
    int pitchclass, octave;
    char channelstring[20];
    (void)wind;

    if(key < 0) {
        strcpy(line, "<void>");
        return(OK);
    }
    channelstring[0] = '\0';
    if(channel > 0) my_sprintf(channelstring, " channel %ld", (long)channel);

    if(i_scale > NumberScales) {
        BPPrintMessage(0, odError, "=> Error: i_scale (%ld) > NumberScales (%d)\n", (long)i_scale, NumberScales);
        my_sprintf(line, "<%d>", key);  /* Fallback: show MIDI key */
        return(OK);
    }

    if(i_scale > 0) {
        int keyclass;
        int basekey = (*Scale)[i_scale].basekey;
        int numgrades = (*Scale)[i_scale].numgrades;
        int numnotes = (*Scale)[i_scale].numnotes;
        int baseoctave = (*Scale)[i_scale].baseoctave;
        if(numgrades <= 12) {
            keyclass = modulo(key - basekey, numgrades);
            octave = baseoctave + floor(((double)key - basekey) / numgrades);
        }
        else {
            int i_note = modulo(key - basekey, numnotes);
            keyclass = (*((*Scale)[i_scale].keyclass))[i_note];
            octave = baseoctave + floor((((double)key - basekey)) / numnotes);
        }
        my_sprintf(line, "%s%d%s", *((*(*Scale)[i_scale].notenames)[keyclass]), octave, channelstring);
    }
    else {
        pitchclass = modulo((key - C4key), 12);
        octave = (key - pitchclass) / 12;
        if(NameChoice[pitchclass] == 1 && pitchclass == 0) octave--;
        if(NameChoice[pitchclass] == 1 && pitchclass == 11) octave++;
        switch(NoteConvention) {
            case FRENCH:
                octave -= 2;
                switch(octave) {
                    case -2:
                        if(NameChoice[pitchclass] == 0)
                            my_sprintf(line, "%s000%s", Frenchnote[pitchclass], channelstring);
                        else
                            my_sprintf(line, "%s000%s", AltFrenchnote[pitchclass], channelstring);
                        break;
                    case -1:
                        if(NameChoice[pitchclass] == 0)
                            my_sprintf(line, "%s00%s", Frenchnote[pitchclass], channelstring);
                        else
                            my_sprintf(line, "%s00%s", AltFrenchnote[pitchclass], channelstring);
                        break;
                    default:
                        if(NameChoice[pitchclass] == 0)
                            my_sprintf(line, "%s%ld%s", Frenchnote[pitchclass], (long)octave, channelstring);
                        else
                            my_sprintf(line, "%s%ld%s", AltFrenchnote[pitchclass], (long)octave, channelstring);
                        break;
                }
                break;
            case ENGLISH:
                octave--;
                switch(octave) {
                    case -1:
                        if(NameChoice[pitchclass] == 0)
                            my_sprintf(line, "%s00%s", Englishnote[pitchclass], channelstring);
                        else
                            my_sprintf(line, "%s00%s", AltEnglishnote[pitchclass], channelstring);
                        break;
                    default:
                        if(NameChoice[pitchclass] == 0)
                            my_sprintf(line, "%s%ld%s", Englishnote[pitchclass], (long)octave, channelstring);
                        else
                            my_sprintf(line, "%s%ld%s", AltEnglishnote[pitchclass], (long)octave, channelstring);
                        break;
                }
                break;
            case INDIAN:
                octave--;
                switch(octave) {
                    case -1:
                        if(NameChoice[pitchclass] == 0)
                            my_sprintf(line, "%s00%s", Indiannote[pitchclass], channelstring);
                        else
                            my_sprintf(line, "%s00%s", AltIndiannote[pitchclass], channelstring);
                        break;
                    default:
                        if(NameChoice[pitchclass] == 0)
                            my_sprintf(line, "%s%ld%s", Indiannote[pitchclass], (long)octave, channelstring);
                        else
                            my_sprintf(line, "%s%ld%s", AltIndiannote[pitchclass], (long)octave, channelstring);
                        break;
                }
                break;
            default:
                my_sprintf(line, "%s%ld%s", KeyString, (long)key, channelstring);
                break;
        }
    }
    trim_digits_after_key_hash(line);
    return(OK);
}

/* ============================================================
 * SendControl stub (MakeSound.c)
 * ============================================================ */

/* SendControl — now in real MakeSound.c */

/* ============================================================
 * Buffer functions extracted from PlayThings.c (essential for
 * grammar compilation and production)
 * ============================================================ */

long LengthOf(tokenbyte ***pp_X) {
    if(*pp_X == NULL) return -1L;
    size_t imax = MyGetHandleSize((Handle)*pp_X) / sizeof(tokenbyte);
    tokenbyte *tokens = **pp_X;
    long i = 0;
    while (i < (long)imax - 1) {
        if(tokens[i] == TEND && tokens[i + 1] == TEND) return i;
        i++;
    }
    return -1L;
}

long CopyBuf(tokenbyte ***pp_X, tokenbyte ***pp_Y) {
    long length;
    Size blocksize, maxsize, oldsize;
    tokenbyte *ptr1, *ptr2;

    length = LengthOf(pp_X);
    blocksize = (length + 2L) * sizeof(tokenbyte);
    if(*pp_X == NULL) {
        BPPrintMessage(0, odError, "=> Err. CopyBuf(). *pp_X = NULL");
        return(ABORT);
    }
    maxsize = oldsize = MyGetHandleSize((Handle)*pp_X);
    if(maxsize <= blocksize) {
        BPPrintMessage(0, odError, "=> Err. CopyBuf(). maxsize (%ld) <= blocksize (%ld)\n",
                       (long)maxsize, (long)blocksize);
        return(ABORT);
    }
    if((*pp_Y) == NULL) {
        BPPrintMessage(0, odError, "=> Err. CopyBuf(). *pp_Y = NULL\n");
        return(ABORT);
    }
    maxsize = oldsize = MyGetHandleSize((Handle)*pp_Y);
    if(maxsize <= blocksize) {
        maxsize = (blocksize * 3L) / 2L;
        MemoryUsed += (maxsize - oldsize);
        if(MemoryUsed > MaxMemoryUsed) {
            MaxMemoryUsed = MemoryUsed;
        }
        if(MySetHandleSize((Handle*)pp_Y, maxsize) != OK) return(ABORT);
    }
    ptr1 = &(**pp_X)[0]; ptr2 = &(**pp_Y)[0];
    memmove(ptr2, ptr1, blocksize);
    return(length);
}

int SelectionToBuffer(int sequence, int noreturn, int w, tokenbyte ***pp_X,
    long *p_end, int mode) {
    char c, *p1, *p2, **ptr, **p_buff, ***pp_buff;
    p_context *p_plx, *p_prx;
    int i, notargument, meta=0, jbolmem, rep, ret;
    long origin, end, length;
    tokenbyte **p_ti;

    BP_NOT_USED(mode);
    if(!CompiledPt) {
        if((rep=CompilePatterns()) != OK) return(rep);
    }
    rep = MISSED;
    MyDisposeHandle((Handle*)pp_X);
    pp_buff = &p_buff; p_buff = NULL;
    if(!Editable[w]) return(MISSED);
    TextGetSelection(&origin, &end, TEH[w]);
    *p_end = end;
    SelectOn = TRUE;

POSITION:
    while(MySpace(c=GetTextChar(w, origin))) {
        origin++;
        if(origin == end) { SelectOn = FALSE; return(MISSED); }
        if(origin > end) {
            SelectOn = FALSE;
            BPPrintMessage(0, odError, "=> SelectionToBuffer error 1, origin = %ld, end = %ld\n", origin, end);
            return(MISSED);
        }
    }
    if(GetTextChar(w, origin) == '[') {
        while((c=GetTextChar(w, origin)) != ']') {
            origin++;
            if(origin >= end) {
                SelectOn = FALSE;
                Panic = TRUE;
                BPPrintMessage(0, odError, "=> SelectionToBuffer error 2, can't find ']'\n");
                return(MISSED);
            }
        }
        origin++; goto POSITION;
    }
    if(origin >= end) {
        SelectOn = FALSE;
        BPPrintMessage(0, odError, "=> SelectionToBuffer error 3, origin = %ld, end = %ld\n", origin, end);
        return(MISSED);
    }
    length = end - origin + 4L;
    if((ptr = (char**) GiveSpace((Size)(length * sizeof(char)))) == NULL) {
        rep = ABORT;
        BPPrintMessage(0, odError, "=> Err. SelectionToBuffer(). ptr == NULL");
        goto SORTIR;
    }
    *pp_buff = ptr;
    if(ReadToBuff(YES, noreturn, w, &origin, end, pp_buff) != OK) goto BAD;

    *p_end = origin;
    p1 = **pp_buff; p2 = p1; i = 0; ret = FALSE;
    while(((*p2) != '\0') && (ret || (*p2) != '\r')) {
        if(!MySpace((*p2))) ret = FALSE;
        p2++;
        if(++i > length) {
            BPPrintMessage(0, odError, "=> Err. SelectionToBuffer(). i > length");
            MyDisposeHandle((Handle*)pp_buff);
            SelectOn = FALSE;
            Panic = TRUE;
            return(MISSED);
        }
    }
    if(p1 == p2) {
        MyUnlock((Handle)*pp_buff);
        goto BAD;
    }
    jbolmem = Jbol;
    notargument = TRUE;
    p_plx = NULL; p_prx = NULL;
    p_ti = Encode(&Gram, sequence, notargument, 0, 0, &p1, &p2, p_plx, p_prx, &meta, 0, NULL, FALSE, &rep);
    MyDisposeHandle((Handle*)pp_buff);
    if(p_ti == NULL) {
        SelectOn = FALSE;
        if(EmergencyExit) return(ABORT);
        else {
            if(rep == OK) return(MISSED);
            else return(rep);
        }
    }
    *pp_X = p_ti;
    SelectOn = FALSE;
    return(OK);

BAD:
    MyDisposeHandle((Handle*)pp_buff);

SORTIR:
    if(!ScriptExecOn) {
        BPPrintMessage(0, odError, "No data selected");
    }
    else {
        PrintBehind(wTrace, "No data selected.\n");
    }
    SelectOn = FALSE;
    return(rep);
}

int ReadToBuff(int nocomment, int noreturn, int w, long *p_i, long im, char ***pp_buff) {
    int first;
    long j, size, k, length;
    char c, oldc, **ptr;

    if(*pp_buff == NULL) {
        BPPrintMessage(0, odError, "=> Err. ReadToBuff(). *pp_buff == NULL");
        return(ABORT);
    }
    size = (long) MyGetHandleSize((Handle)*pp_buff);
    size = (long) (size / sizeof(char)) - 1L;
    if(size < 2L) {
        BPPrintMessage(0, odError, "=> Err. ReadToBuff(). size < 2 ");
        return(ABORT);
    }
    if(*p_i >= im) return(MISSED);
    first = TRUE; oldc = '\0';
    if(stop(0, "ReadToBuff") != OK) return ABORT;

    for(j=*p_i, k=0; j < im; j++) {
        c = GetTextChar(w, j);
        if(nocomment && c == '*' && oldc == '/') {
            oldc = '\0'; j++; k--;
            while(TRUE) {
                c = GetTextChar(w, j);
                if(j >= im) { c = '\r'; break; }
                if(c == '/' && oldc == '*') {
                    j++;
                    c = GetTextChar(w, j);
                    break;
                }
                oldc = c;
                j++;
            }
        }
        if(c == '\r') {
            if(first || noreturn) continue;
            else break;
        }
        oldc = c;
        first = FALSE;
        if(noreturn && nocomment && c == '[') { j--; break; }
        c = Filter(c);
        if(c != '\r' || noreturn) (**pp_buff)[k++] = c;
        if(k >= size) {
            if(ThreeOverTwo(&size) != OK) {
                *p_i = ++j;
                if(!ScriptExecOn) BPPrintMessage(0, odError, "Too long paragraph in selection");
                else PrintBehind(wTrace, "Too long paragraph in selection. Aborted.\n");
                return(MISSED);
            }
            ptr = *pp_buff;
            if((ptr = (char**) IncreaseSpace((Handle)ptr)) == NULL) {
                *p_i = ++j;
                return(ABORT);
            }
            *pp_buff = ptr;
        }
    }
    (**pp_buff)[k] = '\0';
    *p_i = ++j;

    length = MyHandleLen(*pp_buff);
    while(length > 0 && ((c=(**pp_buff)[length-1]) == 10 || MySpace(c))) {
        (**pp_buff)[length-1] = '\0';
        length--;
    }
    return(OK);
}

int StartCount(void) {
    return OK;
}

int StopCount(int i) {
    BP_NOT_USED(i);
    return OK;
}
