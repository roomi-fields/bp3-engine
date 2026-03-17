/*  bp3_api.c — Minimal C API for BP3 WASM build
 *
 *  Exposes functions callable from JavaScript via Emscripten's ccall/cwrap.
 *  Captures BP3 output via the BPSetMessageCallback mechanism.
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <emscripten.h>

#include "-BP3.h"
#include "-BP3decl.h"

/* Forward declarations for ConsoleMain.c functions */
extern void ConsoleInit(BPConsoleOpts* opts);
extern void ConsoleMessagesInit(void);
extern int LoadSettings(const char *filename, int startup);
extern int LoadTonality(void);
extern int LoadCsoundInstruments(int checkversion, int tryname);

/* ---- Output capture buffers ---- */

#define OUTPUT_BUF_SIZE  (1024 * 1024)   /* 1 MB */
#define MSG_BUF_SIZE     (256 * 1024)    /* 256 KB */

static char  output_buffer[OUTPUT_BUF_SIZE];
static int   output_pos = 0;

static char  message_buffer[MSG_BUF_SIZE];
static int   message_pos = 0;

/* ---- Message callback ---- */

static int wasm_message_callback(void* bp, int dest, const char* format, va_list args) {
    (void)bp;
    char temp[4096];
    int len = vsnprintf(temp, sizeof(temp), format, args);
    if(len < 0) return OK;
    if((size_t)len >= sizeof(temp)) len = sizeof(temp) - 1;

    if(dest & (odDisplay | odCsScore)) {
        /* Production output */
        int remaining = OUTPUT_BUF_SIZE - output_pos - 1;
        if(remaining > 0) {
            int to_copy = len < remaining ? len : remaining;
            memcpy(output_buffer + output_pos, temp, to_copy);
            output_pos += to_copy;
            output_buffer[output_pos] = '\0';
        }
    }

    /* All messages (info, errors, warnings, trace) go to message buffer */
    {
        int remaining = MSG_BUF_SIZE - message_pos - 1;
        if(remaining > 0) {
            int to_copy = len < remaining ? len : remaining;
            memcpy(message_buffer + message_pos, temp, to_copy);
            message_pos += to_copy;
            message_buffer[message_pos] = '\0';
        }
    }

    return OK;
}

/* ---- Exported API ---- */

static int bp3_initialized = 0;

EMSCRIPTEN_KEEPALIVE
int bp3_init(void) {
    output_buffer[0] = '\0';
    output_pos = 0;
    message_buffer[0] = '\0';
    message_pos = 0;

    /* Set up the message callback to capture output */
    BPSetMessageCallback(wasm_message_callback);

    /* Free previous allocations if re-initializing */
    if(bp3_initialized) {
        if(eventStack != NULL) {
            free(eventStack);
            eventStack = NULL;
        }
        /* Reset compilation state so Inits() re-allocates cleanly */
        CompiledGr = FALSE;
        CompiledAl = FALSE;
        CompiledPt = FALSE;
        CompiledIn = FALSE;
        CompiledCsObjects = FALSE;

        /* Reset alphabet counters — prevents contamination from prior grammar */
        Jbol = 0;
        Jfunc = 0;
        iProto = 0;
        Jpatt = 0;
        Jvar = 0;
        Jflag = 0;
        Jhomo = 0;
        N_err = 0;
        BolsInGrammar = 0;
        NoAlphabet = TRUE;

        /* Reset grammar structure */
        MaxGram = 0;
        MaxRul = 0;
        Gram.trueBP = Gram.hasTEMP = Gram.hasproc = FALSE;

        /* Reset scale state */
        NumberScales = 0;
        DefaultScaleParam = -1;

        /* Clear text handles content */
        if(TEH[wGrammar])   CopyStringToTextHandle(TEH[wGrammar], "");
        if(TEH[wAlphabet])  CopyStringToTextHandle(TEH[wAlphabet], "");
        if(TEH[wData])      CopyStringToTextHandle(TEH[wData], "");
        if(TEH[wTrace])     CopyStringToTextHandle(TEH[wTrace], "");

        emscripten_log(EM_LOG_CONSOLE, "bp3_init: re-init (cleaned previous state)");
    }

    /* Replicate essential init from ConsoleMain.c main() */
    MaxHandles = ZERO;
    MemoryUsed = 0;
    MemoryUsedInit = MemoryUsed;
    SkipFlag = FALSE;
    Interactive = FALSE;
    StopPlay = FALSE;
    PausePlay = FALSE;
    TraceMIDIinteraction = FALSE;
    TimeStopped = Oldtimestopped = 0L;
    MIDIsyncDelay = 380;
    DisplayItems = FALSE;  /* Must be FALSE in WASM — TRUE causes stack overflow
                               on complex grammars (Visser3: 7593 tokens).
                               Output is retrieved via bp3_get_result() from TEH[OutputWindow]. */

    NoteOffInputFilter = NoteOnInputFilter = KeyPressureInputFilter =
    ControlTypeInputFilter = ProgramTypeInputFilter =
    ChannelPressureInputFilter = PitchBendInputFilter =
    SysExInputFilter = TimeCodeInputFilter = SongPosInputFilter =
    SongSelInputFilter = TuneTypeInputFilter = EndSysExInputFilter =
    ClockTypeInputFilter = StartTypeInputFilter = ContTypeInputFilter =
    ActiveSenseInputFilter = ResetInputFilter = 3;

    LiveGrammar = LiveSettings = TraceLive = ChangedGrammar =
    NewGrammarWaiting = ChangedSettings = SyncChange = FALSE;
    strcpy(LiveFolder, "");

    emscripten_log(EM_LOG_CONSOLE, "bp3_init: ConsoleInit...");
    ConsoleInit(&gOptions);
    ConsoleMessagesInit();

    emscripten_log(EM_LOG_CONSOLE, "bp3_init: Inits()...");
    if(Inits() != OK) {
        emscripten_log(EM_LOG_CONSOLE, "bp3_init: Inits() FAILED");
        return -1;
    }
    emscripten_log(EM_LOG_CONSOLE, "bp3_init: Inits() OK");

    TraceMemory = FALSE;
    MaxMIDIMessages = 1000L;
    eventStack = (MIDI_Event*)malloc(MaxMIDIMessages * sizeof(MIDI_Event));
    if(eventStack == NULL) {
        return -2;
    }

    eventCount = 0L;
    eventCountMax = MaxMIDIMessages - 50L;
    initTime = FirstEventTime = 0L;
    FirstGrammar = TRUE;
    InitOn = FALSE;
    time(&SessionStartTime);
    ProductionTime = ProductionStartTime = PhaseDiagramTime =
    TimeSettingTime = (time_t)0L;
    time(&ProductionStartTime);

    /* Enable MIDI event generation path so PlayBuffer gets called */
    WriteMIDIfile = TRUE;

    /* Reset production state */
    Panic = FALSE;
    EmergencyExit = FALSE;
    NumberMessages = 0;
    Improvize = FALSE;

    ReseedOrShuffle(NEWSEED);
    CopyStringToTextHandle(TEH[wStartString], "S\n");

    /* Call LoadSettings with minimal defaults to initialize internal state.
       Without this, complex grammars (Visser3) crash — LoadSettings performs
       essential setup beyond just assigning variables (memory layout, defaults). */
    {
        FILE* f = fopen("/tmp_init_settings.json", "w");
        if(f) {
            fputs("{\"DisplayItems\":{\"name\":\"Display items\",\"value\":\"0\",\"boolean\":\"1\"}}", f);
            fclose(f);
            LoadSettings("/tmp_init_settings.json", FALSE);
            remove("/tmp_init_settings.json");
        }
    }

    bp3_initialized = 1;
    emscripten_log(EM_LOG_CONSOLE, "bp3_init: complete");
    return 0;
}

EMSCRIPTEN_KEEPALIVE
int bp3_load_grammar(const char* text) {
    if(!text) return -1;
    /* Copy grammar text into TEH[wGrammar] */
    CopyStringToTextHandle(TEH[wGrammar], (char*)text);
    /* Force recompilation on next produce */
    CompiledGr = FALSE;
    CompiledAl = FALSE;
    CompiledPt = FALSE;
    return 0;
}

EMSCRIPTEN_KEEPALIVE
int bp3_load_alphabet(const char* text) {
    if(!text) return -1;
    CopyStringToTextHandle(TEH[wAlphabet], (char*)text);
    /* Force recompilation */
    CompiledAl = FALSE;
    return 0;
}

/* bp3_load_settings: kept for backward compatibility but should not be used.
   LoadSettings() expects Bernard's -se format, not arbitrary JSON.
   Use bp3_load_settings_params() instead. */
EMSCRIPTEN_KEEPALIVE
int bp3_load_settings(const char* json_content) {
    if(!json_content || json_content[0] == '\0') return -1;
    FILE* f = fopen("/tmp_settings.json", "w");
    if(!f) return -2;
    fputs(json_content, f);
    fclose(f);
    int r = LoadSettings("/tmp_settings.json", FALSE);
    remove("/tmp_settings.json");
    return (r == OK) ? 0 : -3;
}

/* bp3_load_settings_params: set engine parameters directly without file I/O.
   noteConvention: 0=English, 1=French, 2=Indian, 3=Keys
   quantize: quantization in ms (0 = off)
   timeRes: time resolution in ms
   natureOfTime: 0=smooth, 1=striated
   seed: random seed (0 = don't change)
   maxTime: max computation time in seconds (0 = no limit)
*/
EMSCRIPTEN_KEEPALIVE
int bp3_load_settings_params(int noteConvention, int quantize, int timeRes,
                              int natureOfTime, int seed, int maxTime) {
    NoteConvention = noteConvention;
    Quantize = quantize;
    Time_res = (long)timeRes;
    Nature_of_time = natureOfTime;

    if(seed > 0) {
        Seed = (unsigned)(((long)seed) % 32768L);
        ReseedOrShuffle(seed);
    }

    if(maxTime > 0) MaxConsoleTime = (long)maxTime;
    else MaxConsoleTime = 0;  /* No limit */

    /* Force recompilation since note convention may have changed */
    CompiledGr = FALSE;
    CompiledAl = FALSE;

    return 0;
}

EMSCRIPTEN_KEEPALIVE
int bp3_load_tonality(const char* content) {
    if(!content || content[0] == '\0') return -1;
    /* Write tonality content to virtual filesystem, then call LoadTonality */
    FILE* f = fopen("/tmp_tonality.txt", "w");
    if(!f) return -2;
    fputs(content, f);
    fclose(f);
    strcpy(FileName[wTonality], "/tmp_tonality.txt");
    int r = LoadTonality();
    remove("/tmp_tonality.txt");
    return (r == OK) ? 0 : -3;
}

EMSCRIPTEN_KEEPALIVE
int bp3_load_csound_resources(const char* content) {
    if(!content || content[0] == '\0') return -1;
    /* Write Csound resources to virtual filesystem, then call LoadCsoundInstruments */
    FILE* f = fopen("/tmp_csound.txt", "w");
    if(!f) return -2;
    fputs(content, f);
    fclose(f);
    strcpy(FileName[wCsoundResources], "/tmp_csound.txt");
    int r = LoadCsoundInstruments(0, 1);
    remove("/tmp_csound.txt");
    return (r == OK) ? 0 : -3;
}

EMSCRIPTEN_KEEPALIVE
int bp3_produce(void) {
    int result;

    /* Clear output buffers */
    output_buffer[0] = '\0';
    output_pos = 0;
    message_buffer[0] = '\0';
    message_pos = 0;

    /* Reset state for new production */
    Panic = FALSE;
    EmergencyExit = FALSE;
    NumberMessages = 0;
    eventCount = 0;  /* Clear MIDI events from previous production */

    /* Disable Improvize mode in WASM — no real-time MIDI available.
       Without this, Improvize grammars loop 20+ items then return ABORT. */
    Improvize = FALSE;

    emscripten_log(EM_LOG_CONSOLE, "bp3_produce: calling ProduceItems...");
    result = ProduceItems(wStartString, FALSE, FALSE, NULL);
    emscripten_log(EM_LOG_CONSOLE, "bp3_produce: done, result=%d", result);
    return result;
}

EMSCRIPTEN_KEEPALIVE
const char* bp3_get_result(void) {
    /* The production output is written to TEH[OutputWindow] (= TEH[wData])
       via Print(). Read it from the text handle. */
    if(TEH[OutputWindow] != NULL && (*TEH[OutputWindow]) != NULL
       && (*TEH[OutputWindow])->hText != NULL) {
        long len = (*TEH[OutputWindow])->length;
        if(len > 0 && len < OUTPUT_BUF_SIZE - 1) {
            memcpy(output_buffer, (char*)(*(*TEH[OutputWindow])->hText), len);
            output_buffer[len] = '\0';
            return output_buffer;
        }
    }
    /* Also check TEH[wTrace] for trace output */
    if(TEH[wTrace] != NULL && (*TEH[wTrace]) != NULL
       && (*TEH[wTrace])->hText != NULL) {
        long len = (*TEH[wTrace])->length;
        if(len > 0 && len < OUTPUT_BUF_SIZE - 1) {
            memcpy(output_buffer, (char*)(*(*TEH[wTrace])->hText), len);
            output_buffer[len] = '\0';
            return output_buffer;
        }
    }
    return output_buffer;
}

EMSCRIPTEN_KEEPALIVE
const char* bp3_get_messages(void) {
    return message_buffer;
}

/* ---- MIDI event extraction ---- */

#define MIDI_JSON_BUF_SIZE (512 * 1024)
static char midi_json_buffer[MIDI_JSON_BUF_SIZE];

EMSCRIPTEN_KEEPALIVE
const char* bp3_get_midi_events(void) {
    int pos = 0;
    int remaining;
    int written;

    pos += snprintf(midi_json_buffer + pos, MIDI_JSON_BUF_SIZE - pos, "[");

    for(long i = 0; i < eventCount; i++) {
        MIDI_Event *e = &eventStack[i];
        int statusType = e->status & 0xF0;
        int channel = (e->status & 0x0F) + 1;

        remaining = MIDI_JSON_BUF_SIZE - pos - 2; /* reserve space for "]" */
        if(remaining < 120) break; /* safety margin for one JSON object */

        if(i > 0) midi_json_buffer[pos++] = ',';

        written = snprintf(midi_json_buffer + pos, remaining,
            "{\"time\":%ld,\"type\":%d,\"note\":%d,\"velocity\":%d,\"channel\":%d,\"scale\":%d}",
            (long)e->time, statusType, (int)e->data1, (int)e->data2, channel, e->scale);

        if(written > 0 && written < remaining) pos += written;
        else break;
    }

    midi_json_buffer[pos++] = ']';
    midi_json_buffer[pos] = '\0';
    return midi_json_buffer;
}

EMSCRIPTEN_KEEPALIVE
int bp3_get_midi_event_count(void) {
    return (int)eventCount;
}
