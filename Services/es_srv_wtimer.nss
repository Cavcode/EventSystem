/*
    ScriptName: es_srv_wtimer.nss
    Created by: Daz

    Description: An EventSystem Service that exposes various world timer related events.
*/

//void main() {}

#include "es_inc_core"

const string WORLD_TIMER_LOG_TAG                = "WorldTimer";
const string WORLD_TIMER_SCRIPT_NAME            = "es_srv_wtimer";

const string WORLD_TIMER_EVENT_DAWN             = "WORLD_TIMER_EVENT_DAWN";
const string WORLD_TIMER_EVENT_DUSK             = "WORLD_TIMER_EVENT_DUSK";
const string WORLD_TIMER_EVENT_IN_GAME_HOUR     = "WORLD_TIMER_EVENT_IN_GAME_HOUR";

const string WORLD_TIMER_EVENT_1_MINUTE         = "WORLD_TIMER_EVENT_1_MINUTE";
const string WORLD_TIMER_EVENT_5_MINUTES        = "WORLD_TIMER_EVENT_5_MINUTES";
const string WORLD_TIMER_EVENT_10_MINUTES       = "WORLD_TIMER_EVENT_10_MINUTES";
const string WORLD_TIMER_EVENT_15_MINUTES       = "WORLD_TIMER_EVENT_15_MINUTES";
const string WORLD_TIMER_EVENT_30_MINUTES       = "WORLD_TIMER_EVENT_30_MINUTES";
const string WORLD_TIMER_EVENT_60_MINUTES       = "WORLD_TIMER_EVENT_60_MINUTES";

// Subscribe sEventHandlerScript to a WORLD_TIMER_EVENT_*
void WorldTimer_SubscribeEvent(string sSubsystemScript, string sWorldTimerEvent, int bDispatchListMode = FALSE);
// Get the current heartbeat count tick
int WorldTimer_GetHeartbeatCount();

// @Init
void WorldTimer_Init(string sServiceScript)
{
    object oDataObject = ES_Util_GetDataObject(WORLD_TIMER_SCRIPT_NAME);
    ES_Util_SetInt(oDataObject, "WORLD_TIMER_MINUTES_PER_HOUR", NWNX_Util_GetMinutesPerHour());
    ES_Core_SubscribeEvent_Object(sServiceScript, EVENT_SCRIPT_MODULE_ON_HEARTBEAT);
}

// @EventHandler
void WorldTimer_EventHandler(string sServiceScript, string sEvent)
{
    object oDataObject = ES_Util_GetDataObject(WORLD_TIMER_SCRIPT_NAME);
    int nModuleMinutesPerHour = ES_Util_GetInt(oDataObject, "WORLD_TIMER_MINUTES_PER_HOUR");
    int nHeartbeatCount = ES_Util_GetInt(oDataObject, "WORLD_TIMER_HEARTBEAT_COUNT");

    // Every 1 minute
    if (!(nHeartbeatCount % 10) && ES_Util_GetInt(oDataObject, WORLD_TIMER_EVENT_1_MINUTE))
        NWNX_Events_SignalEvent(WORLD_TIMER_EVENT_1_MINUTE, OBJECT_SELF);
    // Every 5 minutes
    if (!(nHeartbeatCount % (10 * 5)) && ES_Util_GetInt(oDataObject, WORLD_TIMER_EVENT_5_MINUTES))
        NWNX_Events_SignalEvent(WORLD_TIMER_EVENT_5_MINUTES, OBJECT_SELF);
    // Every 10 minutes
    if (!(nHeartbeatCount % (10 * 10)) && ES_Util_GetInt(oDataObject, WORLD_TIMER_EVENT_10_MINUTES))
        NWNX_Events_SignalEvent(WORLD_TIMER_EVENT_10_MINUTES, OBJECT_SELF);
    // Every 15 minutes
    if (!(nHeartbeatCount % (10 * 15)) && ES_Util_GetInt(oDataObject, WORLD_TIMER_EVENT_15_MINUTES))
        NWNX_Events_SignalEvent(WORLD_TIMER_EVENT_15_MINUTES, OBJECT_SELF);
    // Every 30 minutes
    if (!(nHeartbeatCount % (10 * 30)) && ES_Util_GetInt(oDataObject, WORLD_TIMER_EVENT_30_MINUTES))
        NWNX_Events_SignalEvent(WORLD_TIMER_EVENT_30_MINUTES, OBJECT_SELF);
    // Every 60 minutes
    if (!(nHeartbeatCount % (10 * 60)) && ES_Util_GetInt(oDataObject, WORLD_TIMER_EVENT_60_MINUTES))
        NWNX_Events_SignalEvent(WORLD_TIMER_EVENT_60_MINUTES, OBJECT_SELF);

    // Every ingame hour
    if (!(nHeartbeatCount % (10 * nModuleMinutesPerHour)))
    {
        if (ES_Util_GetInt(oDataObject, WORLD_TIMER_EVENT_IN_GAME_HOUR))
            NWNX_Events_SignalEvent(WORLD_TIMER_EVENT_IN_GAME_HOUR, OBJECT_SELF);

        if (GetIsDawn())
        {
            if (ES_Util_GetInt(oDataObject, WORLD_TIMER_EVENT_DAWN))
                NWNX_Events_SignalEvent(WORLD_TIMER_EVENT_DAWN, OBJECT_SELF);
        }

        if (GetIsDusk())
        {
            if (ES_Util_GetInt(oDataObject, WORLD_TIMER_EVENT_DUSK))
                NWNX_Events_SignalEvent(WORLD_TIMER_EVENT_DUSK, OBJECT_SELF);
        }
    }

    ES_Util_SetInt(oDataObject, "WORLD_TIMER_HEARTBEAT_COUNT", ++nHeartbeatCount);
}

void WorldTimer_SubscribeEvent(string sSubsystemScript, string sWorldTimerEvent, int bDispatchListMode = FALSE)
{
    ES_Util_SetInt(ES_Util_GetDataObject(WORLD_TIMER_SCRIPT_NAME), sWorldTimerEvent, TRUE);

    NWNX_Events_SubscribeEvent(sWorldTimerEvent, sSubsystemScript);

    if (bDispatchListMode)
        NWNX_Events_ToggleDispatchListMode(sWorldTimerEvent, sSubsystemScript, bDispatchListMode);
}

int WorldTimer_GetHeartbeatCount()
{
    return ES_Util_GetInt(ES_Util_GetDataObject(WORLD_TIMER_SCRIPT_NAME), "WORLD_TIMER_HEARTBEAT_COUNT");
}
