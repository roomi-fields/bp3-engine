/* bp3_timed_events.c — Timed event capture buffer
   Filled by MakeSound at NoteOn/NoteOff points, read by consumers. */

#include "bp3_timed_events.h"

TimedEvent g_timed_events[MAX_TIMED_EVENTS];
long g_timed_event_count = 0;

void ResetTimedEvents(void) {
    g_timed_event_count = 0;
}

void EmitTimedEvent(long instance, long time_ms, int type) {
    if(g_timed_event_count >= MAX_TIMED_EVENTS) return;
    g_timed_events[g_timed_event_count].instance = instance;
    g_timed_events[g_timed_event_count].time_ms = time_ms;
    g_timed_events[g_timed_event_count].type = type;
    g_timed_event_count++;
}
