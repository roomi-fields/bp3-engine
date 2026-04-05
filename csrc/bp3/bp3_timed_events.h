/* bp3_timed_events.h — Timed event capture buffer
   Filled by MakeSound at NoteOn/NoteOff points.
   Read by consumers (WASM bp3_api.c, or future native tools). */
#ifndef BP3_TIMED_EVENTS_H
#define BP3_TIMED_EVENTS_H

#ifndef MAX_TIMED_EVENTS
#define MAX_TIMED_EVENTS 100000
#endif

typedef struct {
    long instance;
    long time_ms;
    int type;   /* 0=NoteOn, 1=NoteOff */
} TimedEvent;

extern TimedEvent g_timed_events[];
extern long g_timed_event_count;

void ResetTimedEvents(void);
void EmitTimedEvent(long instance, long time_ms, int type);

#endif
