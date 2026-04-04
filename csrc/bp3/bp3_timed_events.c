/* bp3_timed_events.c (BP3)
   Timed event buffer filled by MakeSound, read by consumers (WASM, native).

   EmitTimedEvent() is called at NoteOn/NoteOff points in MakeSound,
   AFTER temporal calculations (beta, scheduling) but BEFORE MIDI-specific
   processing (p_keyon, velocity, CC, channels).

   This captures the engine's temporal corrections without content transforms
   (transposition, key expansion, key mapping) which belong to the consumer. */

#ifndef _H_BP3
#include "-BP3.h"
#endif

#include "-BP3decl.h"

TimedEvent g_timed_events[MAX_TIMED_EVENTS];
long g_timed_event_count = 0;

void ResetTimedEvents(void) {
    g_timed_event_count = 0;
}

void EmitTimedEvent(long instance, Milliseconds time, int type) {
    if(g_timed_event_count >= MAX_TIMED_EVENTS) return;
    g_timed_events[g_timed_event_count].instance = instance;
    g_timed_events[g_timed_event_count].time_ms = (long)time;
    g_timed_events[g_timed_event_count].type = type;
    g_timed_event_count++;
}
