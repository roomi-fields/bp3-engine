/*  bp3_api.c — Minimal C API for BP3 WASM build
 *
 *  Exposes functions callable from JavaScript via Emscripten's ccall/cwrap.
 *  Captures BP3 output via the BPSetMessageCallback mechanism.
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <limits.h>
#include <emscripten.h>

#include "-BP3.h"
#include "-BP3decl.h"
#include "bp3_random.h"
#include "bp3_timed_events.h"

/* Accumulated instance type — defined in bp3_wasm_stubs.c */
typedef struct {
    short object;
    Milliseconds starttime, endtime;
    char velocity, channel;
    int scale;
    short transposition;
    short xpandkey, xpandval;
    char lastistranspose;
} WasmInstanceAccum;

/* Debug: expose trace_compute toggle for SUB loop investigation */
extern int trace_compute;
extern int trace_weights;

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
    DisplayItems = TRUE;

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
    MaxMIDIMessages = 50000L;  /* 1000 was too small for complex grammars (765432=1646 events, NotReich=1160) */
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

    /* Always TRUE in WASM: enables PlayBuffer path which handles both
       MIDI extraction (musical grammars) and TimeSet (timed tokens).
       For text-only grammars, PlayBuffer runs but produces 0 MIDI events
       naturally (no T25 objects). bp3_set_write_midi() can override. */
    WriteMIDIfile = TRUE;

    /* Reset production state */
    Panic = FALSE;
    EmergencyExit = FALSE;
    NumberMessages = 0;
    Improvize = FALSE;

    ReseedOrShuffle(NEWSEED);
    CopyStringToTextHandle(TEH[wStartString], "S\n");

    /* Call LoadSettings to initialize internal state (memory layout, defaults).
       Without this call, complex grammars (Visser3) crash with SIGSEGV.
       Only on first init — re-init already has the state from previous cycle. */
    if(!bp3_initialized) {
        FILE* f = fopen("/tmp_init_settings.json", "w");
        if(f) {
            fputs("{\"DisplayItems\":{\"name\":\"Display items\",\"value\":\"1\",\"boolean\":\"1\"}}", f);
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

/* bp3_load_settings: load settings from Bernard's JSON format.
   Parses the full -se.xxx JSON (84+ parameters) via cJSON in LoadSettings().
   Works with JSON files from Bernard's PHP interface (starting with '{').
   Does NOT work with old text-format -se files (BP2 legacy starting with '//').
   For minimal settings (6 params), use bp3_load_settings_params() instead. */
/* LoadSettingsFromString: parse JSON settings directly from a string buffer.
   Identical logic to LoadSettings() in SaveLoads1.c but skips file I/O.
   This avoids the fseek/ftell/fread round-trip through Emscripten MEMFS
   which causes memory corruption in WASM for large JSON payloads. */
static int LoadSettingsFromString(const char* json_data) {
    int ch, intvalue;
    float floatvalue;

    /* Reset defaults — same as LoadSettings lines 553-587 */
    EndFadeOut = 2.; C4key = 60; A4freq = 440.;
    Quantize = TRUE;
    Quantization = 10L;
    UseBullet = FALSE;
    Code[7] = '.';
    MIDIfileType = 1;
    CsoundFileFormat = UNIX;
    StrikeAgainDefault = PedalReleaseDefault = TRUE;
    DeftVolume = DEFTVOLUME;
    VolumeController = VOLUMECONTROL;
    DeftVelocity = DEFTVELOCITY;
    DeftPanoramic = DEFTPANORAMIC;
    PanoramicController = PANORAMICCONTROL;
    SamplingRate = SAMPLINGRATE;
    DefaultBlockKey = 60;
    ShowObjectGraph = TRUE;
    ShowAllObjects = FALSE;
    ShowPianoRoll = FALSE;
    Token = Oms = FALSE;
    UseBufferLimit = FALSE;
    CsoundTrace = FALSE;
    NoConstraint = FALSE;
    ResetControllers = FALSE;
    FileSaveMode = ALLSAME;
    FileWriteMode = NOW;
    ProgNrFrom = 1;
    NotSaidKpress = TRUE;
    NeverResetWeights = FALSE;
    ResetFlags = FALSE;
    ResetWeights = FALSE;
    NeverResetWeights = FALSE;
    MinPeriod = 0;
    MaxConsoleTime = 0;

    int old_livegrammar = LiveGrammar;
    int old_livesettings = LiveSettings;

    cJSON *json = cJSON_Parse(json_data);
    if(!json) {
        BPPrintMessage(0,odError,"=> Could not parse JSON settings: %s\n",cJSON_GetErrorPtr());
        return MISSED;
    }

    cJSON *current_element = NULL;
    cJSON_ArrayForEach(current_element,json) {
        if(!cJSON_IsObject(current_element)) continue;
        const char *key = current_element->string;
        if(key == NULL) continue;
        cJSON *value_field = cJSON_GetObjectItem(current_element,"value");
        if(value_field == NULL) continue;
        if(cJSON_IsString(value_field)) {
            const char *string_value = cJSON_GetStringValue(value_field);
            intvalue = atoi(string_value);
            floatvalue = strtof(string_value, NULL);
        }
        else if(cJSON_IsNumber(value_field)) {
            intvalue = cJSON_GetNumberValue(value_field);
            floatvalue = cJSON_GetNumberValue(value_field);
        }
        else continue;

        /* Setting assignments — same as LoadSettings lines 629-702 */
        if(strcmp(key,"Quantization") == 0) Quantization = (long) intvalue;
        else if(strcmp(key,"Quantize") == 0) Quantize = intvalue;
        else if(strcmp(key,"Time_res") == 0) Time_res = (long) intvalue;
        else if(strcmp(key,"MIDIsyncDelay") == 0) MIDIsyncDelay = intvalue;
        else if(strcmp(key,"Nature_of_time") == 0) Nature_of_time = intvalue;
        else if(strcmp(key,"Pclock") == 0) Pclock = (double) intvalue;
        else if(strcmp(key,"Qclock") == 0) Qclock = (double) intvalue;
        else if(strcmp(key,"Improvize") == 0) Improvize = intvalue;
        else if(strcmp(key,"MaxItemsProduce") == 0) MaxItemsProduce = intvalue;
        else if(strcmp(key,"UseEachSub") == 0) UseEachSub = intvalue;
        else if(strcmp(key,"AllItems") == 0) AllItems = intvalue;
        else if(strcmp(key,"DisplayProduce") == 0) DisplayProduce = intvalue;
        else if(strcmp(key,"StepProduce") == 0) StepProduce = intvalue;
        else if(strcmp(key,"TraceMicrotonality") == 0) TraceMicrotonality = intvalue;
        else if(strcmp(key,"TraceProduce") == 0) TraceProduce = intvalue;
        else if(strcmp(key,"PlanProduce") == 0) PlanProduce = intvalue;
        else if(strcmp(key,"DisplayItems") == 0) DisplayItems = intvalue;
        else if(strcmp(key,"ShowGraphic") == 0) ShowGraphic = intvalue;
        else if(strcmp(key,"ShowAllObjects") == 0) ShowAllObjects = intvalue;
        else if(strcmp(key,"AllowRandomize") == 0) AllowRandomize = intvalue;
        else if(strcmp(key,"DisplayTimeSet") == 0) DisplayTimeSet = intvalue;
        else if(strcmp(key,"StepTimeSet") == 0) StepTimeSet = intvalue;
        else if(strcmp(key,"TraceTimeSet") == 0) TraceTimeSet = intvalue;
        else if(strcmp(key,"TraceNoteOn") == 0) TraceNoteOn = intvalue;
        else if(strcmp(key,"CsoundTrace") == 0) CsoundTrace = intvalue;
        else if(strcmp(key,"ResetNotes") == 0) ResetNotes = intvalue;
        else if(strcmp(key,"ComputeWhilePlay") == 0) ComputeWhilePlay = intvalue;
        else if(strcmp(key,"AdvanceTime") == 0) AdvanceTime = 1000. * floatvalue;
        else if(strcmp(key,"TraceMIDIinteraction") == 0) TraceMIDIinteraction = intvalue;
        else if(strcmp(key,"ResetWeights") == 0) ResetWeights = intvalue;
        else if(strcmp(key,"ResetFlags") == 0) ResetFlags = intvalue;
        else if(strcmp(key,"ResetControllers") == 0) ResetControllers = intvalue;
        else if(strcmp(key,"NoConstraint") == 0) NoConstraint = intvalue;
        else if(strcmp(key,"SplitTimeObjects") == 0) SplitTimeObjects = intvalue;
        else if(strcmp(key,"Split_|SplitVariables|") == 0) SplitVariables = intvalue;
        else if(strcmp(key,"SplitVariables") == 0) SplitVariables = intvalue;
        else if(strcmp(key,"DeftBufferSize") == 0) DeftBufferSize = (long) intvalue;
        else if(strcmp(key,"MaxConsoleTime") == 0) MaxConsoleTime = (long) intvalue;
        else if(strcmp(key,"Seed") == 0) {
            unsigned newseed = (unsigned) (((long) intvalue) % 32768L);
            if(Seed > 0L)
                BPPrintMessage(1,odInfo,"Seed forced to command line value = %u\n",Seed);
            else Seed = newseed;
        }
        else if(strcmp(key,"NoteConvention") == 0) NoteConvention = intvalue;
        else if(strcmp(key,"GraphicScaleP") == 0) GraphicScaleP = intvalue;
        else if(strcmp(key,"GraphicScaleQ") == 0) GraphicScaleQ = intvalue;
        else if(strcmp(key,"EndFadeOut") == 0) EndFadeOut = floatvalue;
        else if(strcmp(key,"C4key") == 0) C4key = intvalue;
        else if(strcmp(key,"A4freq") == 0) A4freq = floatvalue;
        else if(strcmp(key,"StrikeAgainDefault") == 0) StrikeAgainDefault = intvalue;
        else if(strcmp(key,"PedalReleaseDefault") == 0) PedalReleaseDefault = intvalue;
        else if(strcmp(key,"DeftVolume") == 0) DeftVolume = intvalue;
        else if(strcmp(key,"VolumeController") == 0) VolumeController = intvalue;
        else if(strcmp(key,"DeftVelocity") == 0) DeftVelocity = intvalue;
        else if(strcmp(key,"DeftPanoramic") == 0) DeftPanoramic = intvalue;
        else if(strcmp(key,"PanoramicController") == 0) PanoramicController = intvalue;
        else if(strcmp(key,"SamplingRate") == 0) SamplingRate = intvalue;
        else if(strcmp(key,"StopPauseContinue") == 0) StopPauseContinue = intvalue;
        else if(strcmp(key,"DefaultBlockKey") == 0) DefaultBlockKey = intvalue;
        else if(strcmp(key,"B#_instead_of_C") == 0) NameChoice[0] = intvalue;
        else if(strcmp(key,"Db_instead_of_C#") == 0) NameChoice[1] = intvalue;
        else if(strcmp(key,"Eb_instead_of_D#") == 0) NameChoice[3] = intvalue;
        else if(strcmp(key,"Fb_instead_of_E") == 0) NameChoice[4] = intvalue;
        else if(strcmp(key,"E#_instead_of_F") == 0) NameChoice[5] = intvalue;
        else if(strcmp(key,"Gb_instead_of_F#") == 0) NameChoice[6] = intvalue;
        else if(strcmp(key,"Ab_instead_of_G#") == 0) NameChoice[8] = intvalue;
        else if(strcmp(key,"Bb_instead_of_A#") == 0) NameChoice[10] = intvalue;
        else if(strcmp(key,"Cb_instead_of_B") == 0) NameChoice[11] = intvalue;
        else if(strcmp(key,"ShowObjectGraph") == 0) ShowObjectGraph = intvalue;
        else if(strcmp(key,"ShowPianoRoll") == 0) ShowPianoRoll = intvalue;
        else if(strcmp(key,"MinPeriod") == 0) MinPeriod = intvalue;
        else if(strcmp(key,"LiveGrammar") == 0) LiveGrammar = intvalue;
        else if(strcmp(key,"LiveSettings") == 0) LiveSettings = intvalue;
        else if(strcmp(key,"TraceLive") == 0) TraceLive = intvalue;
    }
    cJSON_Delete(json);

    /* Post-processing — same as LoadSettings lines 704-767 */
    if(NoTracePath) {
        ShowObjectGraph = ShowPianoRoll = ShowGraphic = FALSE;
    }
    if(DeftBufferSize < 100) DeftBufferSize = 1000;
    BufferSize = DeftBufferSize;
    SetTempo();
    if(Seed > 0) {
        ResetRandom();
    }
    else {
        Randomize();
    }
    for(ch=0; ch < MAXCHAN; ch++) {
        (*p_Oldvalue)[ch].volume = 90;
        (*p_Oldvalue)[ch].panoramic = 64;
        (*p_Oldvalue)[ch].pressure = 0;
        (*p_Oldvalue)[ch].pitchbend = DEFTPITCHBEND;
        (*p_Oldvalue)[ch].modulation = 0;
    }
    if(!Quantize) MaxDeltaTime = 20L;
    else MaxDeltaTime = 2 * Quantization;
    if(MaxItemsProduce < 2) MaxItemsProduce = 20;
    if(PlaySelectionOn) Improvize = FALSE;
    if(AllItems) Improvize = FALSE;
    if(ShowObjectGraph || ShowPianoRoll) ShowGraphic = TRUE;
    if(OutBPdata) ShowGraphic = FALSE;
    if(!ShowGraphic) ShowObjectGraph = ShowPianoRoll = FALSE;

    return OK;
}

EMSCRIPTEN_KEEPALIVE
int bp3_load_settings(const char* json_content) {
    if(!json_content || json_content[0] == '\0') return -1;
    int r = LoadSettingsFromString(json_content);
    emscripten_log(EM_LOG_CONSOLE, "bp3_load_settings: result=%d EmergencyExit=%d", r, EmergencyExit);
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
/* bp3_set_write_midi: enable/disable MIDI output (PlayBuffer path).
   Must be called AFTER bp3_load_alphabet() for musical grammars.
   Only enable for grammars with musical notes (English/French/Indian).
   Text-only grammars (look-and-say, gramgene) must NOT enable this. */
EMSCRIPTEN_KEEPALIVE
void bp3_set_write_midi(int enable) {
    WriteMIDIfile = enable ? TRUE : FALSE;
}

/* bp3_set_seed: set random seed without touching any other settings.
   Use after bp3_load_settings() to override the seed for reproducibility. */
EMSCRIPTEN_KEEPALIVE
void bp3_set_seed(int seed) {
    if(seed > 0) {
        Seed = (unsigned)(((long)seed) % 32768L);
        bp3_srand(Seed);
        UsedRandom = FALSE;
    }
}

EMSCRIPTEN_KEEPALIVE
int bp3_load_settings_params(int noteConvention, int quantize, int timeRes,
                              int natureOfTime, int seed, int maxTime) {
    NoteConvention = noteConvention;
    Quantize = quantize;
    Time_res = (long)timeRes;
    Nature_of_time = natureOfTime;

    if(seed > 0) {
        Seed = (unsigned)(((long)seed) % 32768L);
        /* Use bp3_srand(Seed) directly, matching native's ResetRandom().
           ReseedOrShuffle(seed) computes (Seed+seed)%32768 which gives
           a different effective seed (e.g. seed=1 → bp3_srand(2) instead of bp3_srand(1)). */
        bp3_srand(Seed);
        UsedRandom = FALSE;
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

/* bp3_provision_file: write any file content to the Emscripten virtual filesystem.
   This is the generic mechanism for providing auxiliary files that the engine
   resolves internally during compilation and production:
   - "-mi.xxx" (MIDI prototypes, referenced from -ho. files)
   - "-or.xxx" (orchestra definitions)
   - "-tb.xxx" (time base patterns)
   - "-in.xxx" (interactive MIDI)
   - "-gl.xxx" (glossary)
   - Any other file the engine might try to fopen()

   The filename should match exactly what the grammar/alphabet references
   (e.g. "-mi.dhati" for a grammar referencing -ho.dhati which contains "-mi.dhati").
   Files are written to the root of the Emscripten filesystem "/".

   Call this BEFORE bp3_load_grammar() so files are available during compilation.
   Returns 0 on success, -1 if empty, -2 if write fails. */
EMSCRIPTEN_KEEPALIVE
int bp3_provision_file(const char* filename, const char* content) {
    if(!filename || !content) return -1;
    char path[512];
    /* Write to root "/" so fopen("filename") or fopen("/filename") both find it */
    snprintf(path, sizeof(path), "/%s", filename);
    FILE* f = fopen(path, "w");
    if(!f) return -2;
    fputs(content, f);
    fclose(f);
    emscripten_log(EM_LOG_CONSOLE, "bp3_provision_file: wrote %d bytes to %s",
                   (int)strlen(content), path);
    return 0;
}

EMSCRIPTEN_KEEPALIVE
int bp3_load_object_prototypes(const char* content) {
    if(!content || content[0] == '\0') return -1;
    /* Write -mi. content to virtual filesystem, then call LoadObjectPrototypes.
       This loads MIDI prototypes for sound objects (durations, channels, velocities)
       which are referenced by -ho. alphabet files. Without this, sound objects
       get default 1-beat duration and timings are uniform/wrong. */
    FILE* f = fopen("/tmp_prototypes.txt", "w");
    if(!f) return -2;
    fputs(content, f);
    fclose(f);
    strcpy(FileName[iObjects], "/tmp_prototypes.txt");
    int r = LoadObjectPrototypes(0, 1);
    remove("/tmp_prototypes.txt");
    return (r == OK) ? 0 : (r == MISSED) ? -4 : -3;
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

    /* Clear timed token accumulator and MIDI time offset */
    extern long wasm_accum_count;
    extern Milliseconds wasm_accum_time_offset;
    extern Milliseconds wasm_midi_time_offset;
    extern Milliseconds wasm_kpress_offset;
    wasm_accum_count = 0;
    wasm_accum_time_offset = 0;
    wasm_midi_time_offset = 0;
    wasm_kpress_offset = 0;

    /* Improvize mode: let the engine loop up to MaxItemsProduce items.
       In non-rtMIDI mode (WASM), ProduceItems loops and returns ABORT
       when MaxItemsProduce is reached — this is normal, not an error. */

    /* Redirect stdout to /dev/null during production to avoid JS stack overflow.
       Every printf/fprintf(stdout) in BP3's C code triggers a WASM→JS syscall (fd_write).
       Deep recursion (Compute.c has 542 printf calls) exhausts the JS call stack.
       Output is captured via the BPPrintMessage callback instead. */
    freopen("/dev/null", "w", stdout);

    emscripten_log(EM_LOG_CONSOLE, "bp3_produce: calling ProduceItems...");
    result = ProduceItems(wStartString, FALSE, FALSE, NULL);
    emscripten_log(EM_LOG_CONSOLE, "bp3_produce: done, result=%d", result);

    freopen("/dev/stdout", "w", stdout);
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

#define MIDI_JSON_BUF_SIZE (4 * 1024 * 1024)  /* 4MB for up to 50K events */
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

/* ---- Timed tokens extraction ---- */
/* Correlates text output with p_Instance[] timing (filled by TimeSet).
   When verbose=0 (default): only sounding tokens (notes, named terminals).
   When verbose=1: also includes control tokens (_vel, _chan...) and silence gaps (-). */

static int wasm_timed_tokens_verbose = 0;

EMSCRIPTEN_KEEPALIVE
void bp3_set_timed_tokens_verbose(int v) { wasm_timed_tokens_verbose = v; }



#define TOKEN_JSON_BUF_SIZE (512 * 1024)
static char token_json_buffer[TOKEN_JSON_BUF_SIZE];

/* Escape a string for JSON output */
static int json_escape(char *dst, int maxlen, const char *src, int srclen) {
    int i = 0;
    for(int s = 0; s < srclen && i < maxlen - 2; s++) {
        if(src[s] == '"' || src[s] == '\\') dst[i++] = '\\';
        dst[i++] = src[s];
    }
    dst[i] = '\0';
    return i;
}

extern long wasm_last_kmax;

/* Control token storage for timed_tokens */
typedef struct { const char *start; int len; int after_n; } ControlEntry;
#define MAX_CONTROLS 256
static ControlEntry ctrl_buf[MAX_CONTROLS];

/* Helper: parse text tokens, skip delimiters, handle parentheses */
static const char* next_token(const char *p, const char **tok_start, int *tok_len) {
    while(*p && (*p == ' ' || *p == '\t' || *p == '\n' || *p == '\r')) p++;
    if(!*p) return NULL;
    if(*p == '{' || *p == '}' || *p == ',') { *tok_start = NULL; *tok_len = 0; return p + 1; }
    *tok_start = p;
    int pd = 0;
    while(*p) {
        if(*p == '(') pd++;
        else if(*p == ')') { pd--; if(pd <= 0) { p++; break; } }
        else if(pd == 0 && (*p == ' ' || *p == '\t' || *p == '\n' ||
                *p == '\r' || *p == '{' || *p == '}' || *p == ',')) break;
        p++;
    }
    *tok_len = (int)(p - *tok_start);
    return p;
}

EMSCRIPTEN_KEEPALIVE
const char* bp3_get_timed_tokens(void) {
    int pos = 0, remaining, written, count = 0;
    int has_inst, n_controls, sounding_seen, sounding_emitted, ctrl_idx;
    long kmax, k, start_ms, end_ms;
    int j, tl;
    char escaped[512], note_name[64];
    note_name[0] = '\0';
    const char *text, *p, *ts, *name;
    int include_controls = wasm_timed_tokens_verbose;

    pos += snprintf(token_json_buffer + pos, TOKEN_JSON_BUF_SIZE - pos, "[");

    /* Use accumulated instances if available (Improvize mode) */
    extern WasmInstanceAccum *wasm_accum;
    extern long wasm_accum_count;
    int use_accum = (wasm_accum != NULL && wasm_accum_count > 0);

    has_inst = use_accum || (p_Instance != NULL && *p_Instance != NULL && wasm_last_kmax > 1);
    kmax = use_accum ? wasm_accum_count : wasm_last_kmax;
    text = bp3_get_result();

    if(!has_inst) {
        /* No timing data — text-only tokens */
        if(text == NULL || text[0] == '\0') goto FINISH_TOKENS;
        p = text;
        while((p = next_token(p, &ts, &tl)) != NULL) {
            if(ts == NULL || tl <= 0 || tl >= 500) continue;
            /* In non-verbose mode, skip control tokens (_xxx, /xxx, ?) */
            if(!include_controls && tl > 0 &&
               (ts[0] == '_' || ts[0] == '/' || ts[0] == '?')) continue;
            remaining = TOKEN_JSON_BUF_SIZE - pos - 2;
            if(remaining < 300) break;
            if(count > 0) token_json_buffer[pos++] = ',';
            json_escape(escaped, sizeof(escaped), ts, tl);
            written = snprintf(token_json_buffer + pos, remaining,
                "{\"token\":\"%s\",\"start\":0,\"end\":0}", escaped);
            if(written > 0 && written < remaining) { pos += written; count++; }
        }
        goto FINISH_TOKENS;
    }

    /* First pass: collect controls from text with their position */
    n_controls = 0;
    sounding_seen = 0;
    if(include_controls && text != NULL && text[0] != '\0') {
        p = text;
        while((p = next_token(p, &ts, &tl)) != NULL) {
            if(ts == NULL || tl <= 0) continue;
            if(ts[0] == '_' && n_controls < MAX_CONTROLS) {
                ctrl_buf[n_controls].start = ts;
                ctrl_buf[n_controls].len = tl;
                ctrl_buf[n_controls].after_n = sounding_seen;
                n_controls++;
            } else {
                sounding_seen++;
            }
        }
    }

    /* Second pass: iterate instances and emit tokens with timing.
       When use_accum is set, read from the accumulated buffer (all Improvize items).
       Otherwise, read from p_Instance[2..kmax] (single item).
       object encoding: 0=empty, 1=silence, 2..Jbol=terminal, >=16384=note, -1=end */
    sounding_emitted = 0;
    ctrl_idx = 0;
    long prev_end_ms = 0;
    long k_start = use_accum ? 0 : 2;
    long k_end = use_accum ? wasm_accum_count : kmax;

    /* Kpress quantization offset (#35): subtract the one-quantum shift caused
       by TimeSet's rounding compensation when Kpress >= 2. Unlike the old
       blanket zerostart (removed in wasm.15), this only corrects the Kpress
       artifact — grammatical silences are preserved. */
    extern Milliseconds wasm_kpress_offset;
    long time_offset = (long)wasm_kpress_offset;


    for(k = k_start; k <= k_end; k++) {
        int inst_scale;
        if(use_accum) {
            if(k >= wasm_accum_count) break;
            j = wasm_accum[k].object;
            start_ms = (long)wasm_accum[k].starttime;
            end_ms = (long)wasm_accum[k].endtime;
            inst_scale = wasm_accum[k].scale;
        } else {
            j = (*p_Instance)[k].object;
            start_ms = (long)(*p_Instance)[k].starttime;
            end_ms = (long)(*p_Instance)[k].endtime;
            inst_scale = (*p_Instance)[k].scale;
        }
        if(j == 0) continue;
        if(j == -1) break;

        /* Override timing from MakeSound's timed event buffer if available.
           This provides temporally corrected data (beta, scheduling) that
           p_Instance starttime/endtime from TimeSet alone don't include. */
        if(g_timed_event_count > 0 && !use_accum) {
            long te;
            int found_on = 0;
            for(te = 0; te < g_timed_event_count; te++) {
                if(g_timed_events[te].instance == k) {
                    if(g_timed_events[te].type == 1 && !found_on) {
                        start_ms = g_timed_events[te].time_ms;
                        found_on = 1;
                    } else if(g_timed_events[te].type == 0) {
                        end_ms = g_timed_events[te].time_ms;
                    }
                }
            }
        }

        /* Apply time normalization */
        start_ms -= time_offset;
        end_ms -= time_offset;

        /* Detect silence gaps (verbose mode only) */
        if(include_controls && start_ms > prev_end_ms && prev_end_ms > 0) {
            remaining = TOKEN_JSON_BUF_SIZE - pos - 2;
            if(remaining < 300) goto FINISH_TOKENS;
            if(count > 0) token_json_buffer[pos++] = ',';
            written = snprintf(token_json_buffer + pos, remaining,
                "{\"token\":\"-\",\"start\":%ld,\"end\":%ld}", prev_end_ms, start_ms);
            if(written > 0 && written < remaining) { pos += written; count++; }
            sounding_emitted++;
        }

        /* Emit controls that come before this sounding token (verbose mode only) */
        if(include_controls) {
            while(ctrl_idx < n_controls && ctrl_buf[ctrl_idx].after_n <= sounding_emitted) {
                remaining = TOKEN_JSON_BUF_SIZE - pos - 2;
                if(remaining < 300) goto FINISH_TOKENS;
                if(count > 0) token_json_buffer[pos++] = ',';
                json_escape(escaped, sizeof(escaped), ctrl_buf[ctrl_idx].start, ctrl_buf[ctrl_idx].len);
                written = snprintf(token_json_buffer + pos, remaining,
                    "{\"token\":\"%s\",\"start\":%ld,\"end\":%ld}", escaped, start_ms, start_ms);
                if(written > 0 && written < remaining) { pos += written; count++; }
                ctrl_idx++;
            }
        }

        /* Skip silence objects in non-verbose mode */
        if(j == 1 && !include_controls) continue;

        /* Get token name */
        if(j == 1) {
            name = "-";
        } else if(j >= 16384) {
            int midiKey = j - 16384;
            int trans = use_accum ? wasm_accum[k].transposition : (*p_Instance)[k].transposition;
            short xpk = use_accum ? wasm_accum[k].xpandkey : (*p_Instance)[k].xpandkey;
            short xpv = use_accum ? wasm_accum[k].xpandval : (*p_Instance)[k].xpandval;
            char lit = use_accum ? wasm_accum[k].lastistranspose : (*p_Instance)[k].lastistranspose;
            if(lit) {
                if(trans != 0) TransposeKey(&midiKey, trans);
                midiKey = ExpandKey(midiKey, xpk, xpv);
            } else {
                midiKey = ExpandKey(midiKey, xpk, xpv);
                if(trans != 0) TransposeKey(&midiKey, trans);
            }
            PrintThisNote(inst_scale, midiKey, -1, -1, note_name);
            name = note_name;
        } else if(j > 1 && j < Jbol && p_Bol != NULL && (*p_Bol)[j] != NULL
                  && *((*p_Bol)[j]) != NULL) {
            name = *((*p_Bol)[j]);
        } else {
            name = "?";
        }

        /* In non-verbose mode, skip control/performance tokens that exist as
           alphabet bols (e.g. _vel(64), _chan(1), _legato(20), _transpose(-7),
           /5, _tempo(...)).  These are not sounding tokens — native MakeSound
           ignores them during MIDI generation. */
        if(!include_controls && name != NULL &&
           (name[0] == '_' || name[0] == '/' || name[0] == '?')) continue;

        /* Skip non-sounding bols: named bols without MIDI content are non-terminals
           that survived derivation (e.g. X, Y in kss2). They are in p_Instance but
           not in the alphabet as sound objects. MakeSound.c:850 uses the same check:
           if(!((*p_Type)[j] & 1)) im = ZERO — i.e. no MIDI events to play.
           NOTE: this filter also blocks silent sound objects (SSO) which have no
           MIDI prototypes. See FEEDBACK_BERNARD #38 for the terminal distinction problem. */
        if(!include_controls && j > 1 && j < 16384 && j < Jbol
           && p_Type != NULL && !((*p_Type)[j] & 1)) continue;

        remaining = TOKEN_JSON_BUF_SIZE - pos - 2;
        if(remaining < 300) goto FINISH_TOKENS;
        if(count > 0) token_json_buffer[pos++] = ',';
        json_escape(escaped, sizeof(escaped), name, strlen(name));
        written = snprintf(token_json_buffer + pos, remaining,
            "{\"token\":\"%s\",\"start\":%ld,\"end\":%ld}", escaped, start_ms, end_ms);
        if(written > 0 && written < remaining) { pos += written; count++; }
        sounding_emitted++;
        if(end_ms > prev_end_ms) prev_end_ms = end_ms;
    }

    /* Emit remaining controls (verbose mode only) */
    while(include_controls && ctrl_idx < n_controls) {
        remaining = TOKEN_JSON_BUF_SIZE - pos - 2;
        if(remaining < 300) break;
        if(count > 0) token_json_buffer[pos++] = ',';
        json_escape(escaped, sizeof(escaped), ctrl_buf[ctrl_idx].start, ctrl_buf[ctrl_idx].len);
        written = snprintf(token_json_buffer + pos, remaining,
            "{\"token\":\"%s\",\"start\":0,\"end\":0}", escaped);
        if(written > 0 && written < remaining) { pos += written; count++; }
        ctrl_idx++;
    }

FINISH_TOKENS:
    token_json_buffer[pos++] = ']';
    token_json_buffer[pos] = '\0';
    return token_json_buffer;
}

EMSCRIPTEN_KEEPALIVE
int bp3_get_timed_token_count(void) {
    const char *text = bp3_get_result();
    if(text == NULL) return 0;
    int count = 0;
    const char *p = text;
    while(*p) {
        while(*p && (*p == ' ' || *p == '\t' || *p == '\n' || *p == '\r')) p++;
        if(!*p) break;
        if(*p == '{' || *p == '}' || *p == ',') { p++; continue; }
        int pd = 0;
        while(*p) {
            if(*p == '(') pd++;
            else if(*p == ')') { pd--; if(pd <= 0) { p++; break; } }
            else if(pd == 0 && (*p == ' ' || *p == '\t' || *p == '\n' ||
                    *p == '\r' || *p == '{' || *p == '}' || *p == ',')) break;
            p++;
        }
        count++;
    }
    return count;
}

/* ---- Debug API for SUB loop investigation ---- */

EMSCRIPTEN_KEEPALIVE
void bp3_set_trace(int compute, int weights) {
    trace_compute = compute;
    trace_weights = weights;
}

EMSCRIPTEN_KEEPALIVE
const char* bp3_get_flag_state(void) {
    /* Dump current flag values for debugging K-param issues */
    static char flagbuf[4096];
    int pos = 0;
    pos += snprintf(flagbuf + pos, sizeof(flagbuf) - pos, "{\"Jflag\":%d,\"Flagthere\":%d,\"Varweight\":%d",
                    Jflag, Flagthere, Varweight);
    if(Jflag > 0 && p_Flag != NULL) {
        pos += snprintf(flagbuf + pos, sizeof(flagbuf) - pos, ",\"flags\":[");
        for(int i = 1; i <= Jflag && i < 20; i++) {
            if(i > 1) flagbuf[pos++] = ',';
            pos += snprintf(flagbuf + pos, sizeof(flagbuf) - pos, "%ld", (long)(*p_Flag)[i]);
        }
        pos += snprintf(flagbuf + pos, sizeof(flagbuf) - pos, "]");
    }
    if(Jflag > 0 && p_Flagname != NULL) {
        pos += snprintf(flagbuf + pos, sizeof(flagbuf) - pos, ",\"names\":[");
        for(int i = 1; i <= Jflag && i < 20; i++) {
            if(i > 1) flagbuf[pos++] = ',';
            const char *name = ((*p_Flagname)[i] != NULL && *((*p_Flagname)[i]) != NULL)
                               ? *((*p_Flagname)[i]) : "?";
            pos += snprintf(flagbuf + pos, sizeof(flagbuf) - pos, "\"%s\"", name);
        }
        pos += snprintf(flagbuf + pos, sizeof(flagbuf) - pos, "]");
    }
    pos += snprintf(flagbuf + pos, sizeof(flagbuf) - pos, "}");
    return flagbuf;
}
