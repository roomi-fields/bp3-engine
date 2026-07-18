/* EXTRAIT TEL QUEL de source/BP3/SaveLoads1.c au commit e9249594 (2024-11-27),
   dernier etat AVANT le passage des reglages au JSON (v3.0.16, 2024-12-15).
   C'est le lecteur POSITIONNEL d'origine : l'ordre des appels Read* EST la carte
   champ -> position de ligne, et les `if(iv > N)` sont les differences de layout
   entre versions. AUCUNE retranscription : lisez ce code, pas un resume. */

int LoadSettings(const char *filename, int startup) {
	int i,j,jmax,rep,result,iv,w,wmax,oldoutmidi,oldoutcsound,oldwritemidifile;
	FILE* sefile;
	long pos,k;
	unsigned long kk;
	double x;
	char **p_line,**p_completeline;

	if(check_memory_use) BPPrintMessage(0,odInfo,"MemoryUsed start LoadSettings = %ld i_ptr = %d\n",(long)MemoryUsed,i_ptr);

	result = OK;
	oldoutmidi = rtMIDI;
	p_line = p_completeline = NULL;
	if(startup) {
		// FIXME: set filename = location of a startup settings file and continue? We'll see later (BB)
		return OK;
		}
	else {
		// filename cannot be NULL or empty
		if (filename == NULL || filename[0] == '\0') {
			BPPrintMessage(0,odError, "=> Err. LoadSettings(): filename was NULL or empty\n");
			return MISSED;
			}
		}

	// open the file for reading
	sefile = my_fopen(1,filename, "rb");
	if(sefile == NULL) {
		BPPrintMessage(0,odError, "=> Could not open settings file %s\n", filename);
		return MISSED;
	    }

	pos = ZERO; Dirty[iSettings] = Created[iSettings] = FALSE;

	LoadOn++;

	if(ReadOne(FALSE,FALSE,FALSE,sefile,TRUE,&p_line,&p_completeline,&pos) != OK) {
    //   BPPrintMessage(0,odError,"=> Error reading settings file\n");
        goto ERR;
        }
	if(trace_load_settings) 
		BPPrintMessage(0,odInfo, "Version line = %s\n",*p_completeline);
	if(CheckVersion(&iv,p_line,filename) != OK) {
		result = MISSED;
		goto QUIT;
		}
	if(trace_load_settings) BPPrintMessage(0,odError, "Settings file version %d\n",iv);
	if(ReadOne(FALSE,FALSE,FALSE,sefile,TRUE,&p_line,&p_completeline,&pos) == MISSED) goto ERR;
    if(trace_load_settings) BPPrintMessage(0,odError, "%s\n",*p_completeline);

	if(ReadInteger(sefile,&j,&pos) == MISSED) {
        BPPrintMessage(0,odError,"=> Error ReadInteger() in LoadSettings()\n");
        goto ERR;	// serial port used by old built-in Midi driver
        }
	// if(startup) Port = j;

	if(ReadOne(FALSE,FALSE,TRUE,sefile,TRUE,&p_line,&p_completeline,&pos) == MISSED) goto ERR;	// Not used but should be kept for consistency
	if(ReadLong(sefile,&k,&pos) == MISSED) goto ERR; Quantization = k;
    if(trace_load_settings) BPPrintMessage(0,odError, "Quantization = %ld\n",k);
	if(ReadLong(sefile,&k,&pos) == MISSED) goto ERR; Time_res = k;
	if(ReadInteger(sefile,&j,&pos) == MISSED) goto ERR; MIDIsetUpTime = j;
	if(trace_load_settings) BPPrintMessage(0,odError, "MIDIsyncDelay = %d\n",MIDIsyncDelay);
	if(ReadInteger(sefile,&j,&pos) == MISSED) goto ERR; QuantizeOK = j;
	if(trace_load_settings) BPPrintMessage(0,odError, "QuantizeOK = %d\n",QuantizeOK);
	#if BP_CARBON_GUI_FORGET_THIS
	SetTimeAccuracy(); // We'll see later what to do with Time_res
	Dirty[wTimeAccuracy] = FALSE;
	#endif /* BP_CARBON_GUI_FORGET_THIS */
	NotSaidKpress = TRUE;

	if(ReadInteger(sefile,&j,&pos) == MISSED) goto ERR; Nature_of_time = j;
	if(ReadUnsignedLong(sefile,&kk,&pos) == MISSED) goto ERR; Pclock = (double)kk;
	if(ReadUnsignedLong(sefile,&kk,&pos) == MISSED) goto ERR; Qclock = (double)kk;
	SetTempo(); SetTimeBase(); Dirty[wMetronom] = Dirty[wTimeBase] = FALSE;

	if(ReadInteger(sefile,&jmax,&pos) == MISSED) goto ERR;
	if(jmax != Jbutt) {
		my_sprintf(Message,"\nError in settings file:  jmax = %d instead of %d\n",jmax,Jbutt);
		if(Beta) Alert1(Message);
		goto ERR;
		}
		
	oldwritemidifile = WriteMIDIfile;
	oldoutcsound = OutCsound;

	if(ReadInteger(sefile,&Improvize,&pos) == MISSED) goto ERR;
	if(trace_load_settings) BPPrintMessage(0,odError, "Improvize = %d\n",Improvize);
	if(PlaySelectionOn) Improvize = FALSE;
	if(ReadInteger(sefile,&MaxItemsDisplay,&pos) == MISSED) goto ERR;
	if(MaxItemsDisplay < 2) MaxItemsDisplay = 20;
	if(ReadInteger(sefile,&UseEachSub,&pos) == MISSED) goto ERR;
	if(ReadInteger(sefile,&AllItems,&pos) == MISSED) goto ERR;
	if(AllItems) Improvize = FALSE;
	if(ReadInteger(sefile,&DisplayProduce,&pos) == MISSED) goto ERR;
	if(ReadInteger(sefile,&StepProduce,&pos) == MISSED) goto ERR;
	if(ReadInteger(sefile,&TraceMicrotonality,&pos) == MISSED) goto ERR;
	if(ReadInteger(sefile,&TraceProduce,&pos) == MISSED) goto ERR;
	if(ReadInteger(sefile,&PlanProduce,&pos) == MISSED) goto ERR;
	if(ReadInteger(sefile,&DisplayItems,&pos) == MISSED) goto ERR; 
	if(ReadInteger(sefile,&ShowGraphic,&pos) == MISSED) goto ERR;
	// if(ShowGraphic) BPPrintMessage(0,odInfo,"Graphics activated\n");
	if(ReadInteger(sefile,&AllowRandomize,&pos) == MISSED) goto ERR;
	if(ReadInteger(sefile,&DisplayTimeSet,&pos) == MISSED) goto ERR; 
	if(ReadInteger(sefile,&StepTimeSet,&pos) == MISSED) goto ERR; 
	if(ReadInteger(sefile,&TraceTimeSet,&pos) == MISSED) goto ERR; 
	if(jmax > 27) ReadInteger(sefile,&CsoundTrace,&pos);
	else CsoundTrace = FALSE;
	if(ReadInteger(sefile,&j,&pos) == MISSED) goto ERR;
	// rtMIDI  = j;
	if(ReadInteger(sefile,&ResetNotes,&pos) == MISSED) goto ERR; 
	if(ReadInteger(sefile,&ComputeWhilePlay,&pos) == MISSED) goto ERR; 
	if(ReadInteger(sefile,&TraceMIDIinteraction,&pos) == MISSED) goto ERR; // Previously it was 'Interactive'
	if(jmax > 19) ReadInteger(sefile,&ResetWeights,&pos);
	else ResetWeights = FALSE;
	NeverResetWeights = FALSE;
	if(jmax > 20) ReadInteger(sefile,&ResetFlags,&pos);
	else ResetFlags = FALSE;
	if(jmax > 21) ReadInteger(sefile,&ResetControllers,&pos);
	else ResetControllers = FALSE; 
	if(jmax > 22) ReadInteger(sefile,&NoConstraint,&pos);
	else NoConstraint = FALSE;
	if(jmax > 23) ReadInteger(sefile,&WriteMIDIfile,&pos);
	else WriteMIDIfile = FALSE;
	WriteMIDIfile = FALSE; // This must be set by the command line
	if(jmax > 24) ReadInteger(sefile,&ShowMessages,&pos); 
	if(jmax > 25) ReadInteger(sefile,&OutCsound,&pos);
	else OutCsound = FALSE;
	if(jmax > 26) ReadInteger(sefile,&j,&pos); // used to read p_oms
	Oms = FALSE;	// OMS is no more
	if(ReadInteger(sefile,&SplitTimeObjects,&pos) == MISSED) goto ERR;
	if(ReadInteger(sefile,&SplitVariables,&pos) == MISSED) goto ERR;
	if(ReadInteger(sefile,&j,&pos) == MISSED) goto ERR;
	// UseTextColor = (j > 0);
	if(ReadLong(sefile,&k,&pos) == MISSED) goto ERR;
	if(k < 100) k = 1000;
	DeftBufferSize = BufferSize = k;
	// BPPrintMessage(0,odInfo, "Default buffer size = %ld symbols\n", DeftBufferSize);
	if(ReadInteger(sefile,&j,&pos) == MISSED) goto ERR;
	/* UseGraphicsColor = (j > 0);
	if(ForceTextColor == 1) UseTextColor = TRUE;
	if(ForceTextColor == -1) UseTextColor = FALSE;
	if(ForceGraphicColor == 1) UseGraphicsColor = TRUE;
	if(ForceGraphicColor == -1) UseGraphicsColor = FALSE; */
	if(ReadInteger(sefile,&UseBufferLimit,&pos) == MISSED) goto ERR;
	UseBufferLimit = FALSE;
	if(ReadLong(sefile,&MaxConsoleTime,&pos) == MISSED) goto ERR;
	if(MaxConsoleTime > 3600) MaxConsoleTime = 3600;
//   if(trace_load_settings && MaxConsoleTime > 0L) BPPrintMessage(0,odInfo, "MaxConsoleTime = %ld\n",(long)MaxConsoleTime);
    
	if(ReadLong(sefile,&k,&pos) == MISSED) goto ERR;
	Seed = (unsigned) (k % 32768L);
	if(Seed > 0) {
		if(!PlaySelectionOn) BPPrintMessage(0,odInfo, "Random seed = %u as per settings\n", Seed);
		ResetRandom();
		}
	else {
		if(!PlaySelectionOn) BPPrintMessage(0,odInfo, "Not using a random seed: shuffling the cards\n");
		Randomize();
		}

	if(ReadInteger(sefile,&Token,&pos) == MISSED) goto ERR;
	if(Token > 0) Token = TRUE;
	else Token = FALSE;
	if(ReadInteger(sefile,&NoteConvention,&pos) == MISSED) goto ERR;
	if(NoteConvention > (KEYS + 1)) {
		BPPrintMessage(0,odInfo, "\n=> ERROR NoteConvention = %d\n",NoteConvention);
		goto ERR;
		}
	if(ReadInteger(sefile,&StartFromOne,&pos) == MISSED) goto ERR;
	if(ReadInteger(sefile,&j,&pos) == MISSED) goto ERR;
	// SmartCursor = (j == 1);
	if(ReadInteger(sefile,&GraphicScaleP,&pos) == MISSED) goto ERR;
	if(ReadInteger(sefile,&GraphicScaleQ,&pos) == MISSED) goto ERR;

	#if BP_CARBON_GUI_FORGET_THIS
	SetGraphicSettings();
	#endif /* BP_CARBON_GUI_FORGET_THIS */

	/* Read OMS default input device, and ignore it */
	if(ReadOne(FALSE,FALSE,TRUE,sefile,TRUE,&p_line,&p_completeline,&pos) == MISSED) goto ERR;
	/* Read OMS default output device, and ignore it */
	if(iv > 5) {
		if(ReadOne(FALSE,FALSE,TRUE,sefile,TRUE,&p_line,&p_completeline,&pos) == MISSED) goto ERR;
		}

	if(iv > 11) {
		if(ReadInteger(sefile,&j,&pos) == MISSED) goto ERR;
		if(iv > 15) UseBullet = j;
		else UseBullet = TRUE;
		UseBullet = FALSE; // FIXED by BB 2020-10-22
	//	if(UseBullet) Code[7] = '�'; Requires UTF8 format BB 2022-02-17
	//	else
		Code[7] = '.';
		}

	PlayTicks = FALSE;
	ResetTickFlag = TRUE;

	if(iv > 7) {
		if(ReadInteger(sefile,&j,&pos) == MISSED) goto ERR;
		PlayTicks = j;
	/*	if(PlayTicks && !InitOn && !startup) {
			ResetMIDI(FALSE); 
			} */
		}
	if(iv > 10) {
		if(ReadInteger(sefile,&j,&pos) == MISSED) goto ERR;
		FileSaveMode = ALLSAME;  // was = j;
		if(ReadInteger(sefile,&j,&pos) == MISSED) goto ERR;
		FileWriteMode = NOW;     // was = j;
		}
	else {
		FileSaveMode = ALLSAME;  // was = ALLSAMEPROMPT;
		FileWriteMode = NOW;     // was = LATER;
		}
	if(iv > 11) {
		if(ReadInteger(sefile,&j,&pos) == MISSED) goto ERR;
		MIDIfileType = j;
		if(ReadInteger(sefile,&j,&pos) == MISSED) goto ERR;
		CsoundFileFormat = j;
		if(ReadInteger(sefile,&j,&pos) == MISSED) goto ERR;
		ProgNrFrom = j;
		if(ProgNrFrom == 0) {
	/*		if(Beta) Alert1("Old program numbers"); */
			ProgNrFrom = 1;
			}
		if(ReadFloat(sefile,&x,&pos) == MISSED) goto ERR;
		if(iv > 19) EndFadeOut = x;
		else EndFadeOut = 2.;
		my_sprintf(Message,"EndFadeOut = %.2f sec\n",EndFadeOut);
	//	BPPrintMessage(0,odInfo,Message);
		
		if(ReadInteger(sefile,&j,&pos) == MISSED) goto ERR;
		if(j > 1 && j < 128) C4key = j;
		else C4key = 60;
		ReadFloat(sefile,&x,&pos);
		if(x > 1.) A4freq = x;
		else A4freq = 440.;
		if(ReadInteger(sefile,&j,&pos) == MISSED) goto ERR;
		StrikeAgainDefault = j;
		}
	else {
		MIDIfileType = 1;
		CsoundFileFormat = UNIX;
		StrikeAgainDefault = TRUE;
		// C4key = 48;	/* Here we compensate wrong conventions on old projects */
		// A4freq = 220.;	/* ditto */
		C4key = 60;
		A4freq = 440.0;
		}
	if(iv > 15) {
		if(ReadInteger(sefile,&j,&pos) == MISSED) goto ERR;
		DeftVolume = j;
	//	BPPrintMessage(0,odInfo,"Default volume = %d\n",j);
		if(ReadInteger(sefile,&j,&pos) == MISSED) goto ERR;
		VolumeController = j;
		if(ReadInteger(sefile,&j,&pos) == MISSED) goto ERR;
		DeftVelocity = j;
		if(ReadInteger(sefile,&j,&pos) == MISSED) goto ERR;
		DeftPanoramic = j;
		if(ReadInteger(sefile,&j,&pos) == MISSED) goto ERR;
		PanoramicController = j;
		if(ReadInteger(sefile,&j,&pos) == MISSED) goto ERR;
		SamplingRate = j;
	//	BPPrintMessage(0,odInfo,"Sampling rate = %d\n",j);
		}
	else {
		DeftVolume = DEFTVOLUME;
		VolumeController = VOLUMECONTROL;
		DeftVelocity = DEFTVELOCITY;
		DeftPanoramic = DEFTPANORAMIC;
		PanoramicController = PANORAMICCONTROL;
		SamplingRate = SAMPLINGRATE;
		}
	#if BP_CARBON_GUI_FORGET_THIS
	SetFileSavePreferences();
	SetDefaultPerformanceValues();
	SetTuning();
	SetDefaultStrikeMode();
	#endif /* BP_CARBON_GUI_FORGET_THIS */

	// This block reads in font sizes for Carbon GUI text windows
	if(ReadInteger(sefile,&j,&pos) == MISSED) goto ERR;
	wmax = j;
	// BPPrintMessage(0,odInfo,"Number of windows = %d\n",j);
	if(wmax > 0) {
		for(w=0; w < (wmax - 1); w++) {
			if(ReadInteger(sefile,&j,&pos) == MISSED) goto ERR;
			}
		}
	if(ReadInteger(sefile,&j,&pos) == MISSED) goto ERR;
	if(j <= 10 || j > 127) DefaultBlockKey = 60;
	else DefaultBlockKey = j;

	// ResetMIDIFilter();

	if(iv > 4) {
		if(ReadLong(sefile,&k,&pos) == MISSED) goto ERR;
		for(i=0; i < 12; i++) {
			if(ReadInteger(sefile,&j,&pos) == MISSED) goto ERR;
			NameChoice[i] = j;
		//	BPPrintMessage(0,odInfo,"NameChoice[%d] = %d\n",i,j);
			}
		}
	if(ReadLong(sefile,&k,&pos) == MISSED) goto ERR;

	if(iv > 19) {
		if(ReadInteger(sefile,&j,&pos) == MISSED) goto ERR;
		ShowObjectGraph = j;
		if(ReadInteger(sefile,&j,&pos) == MISSED) goto ERR;
		ShowPianoRoll = j;
		/**** THIS IS WHERE THE SETTINGS FILE ENDS NOW IN BP3 ****/
		/* Removed code for reading piano roll colors */
		}
	else {
		ShowObjectGraph = TRUE;
		ShowPianoRoll = FALSE;
		}

	if(ShowObjectGraph || ShowPianoRoll) ShowGraphic = TRUE;
	if(!ShowGraphic) ShowObjectGraph = ShowPianoRoll = FALSE;
	if(ShowPianoRoll) BPPrintMessage(0,odInfo,"Pianoroll graphics will be displayed\n");
	if(ShowObjectGraph) BPPrintMessage(0,odInfo,"Object graphics will be displayed\n");
	BPPrintMessage(0,odInfo,"Metronome will be %.3f beats/mn by default (as per settings)\n",(Qclock * 60.)/Pclock); 
	if(Nature_of_time == STRIATED) BPPrintMessage(0,odInfo,"Time is STRIATED\n");
	else BPPrintMessage(0,odInfo,"Time is SMOOTH (no metronome)\n");

	if(PlaySelectionOn) Improvize = 0;			
	/* Removed code for reading "NewEnvironment", window coordinates & text colors */

	goto QUIT;

	ERR:
	result = MISSED;
	BPPrintMessage(0,odError,"=> Error reading '%s' settings file\n",filename);

	QUIT:
	MyDisposeHandle((Handle*)&p_line); MyDisposeHandle((Handle*)&p_completeline);
	my_fclose(sefile);

	LoadOn--;

	if(check_memory_use) BPPrintMessage(0,odInfo,"MemoryUsed end LoadSettings = %ld i_ptr = %d\n",(long)MemoryUsed,i_ptr);
	return(result);
	}
