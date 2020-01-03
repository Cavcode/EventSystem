/*
    ScriptName: es_inc_core.nss
    Created by: Daz

    Description:
*/

//void main(){}

#include "es_inc_util"
#include "nwnx_events"

const string ES_CORE_SYSTEM_TAG                     = "Core";
const string ES_CORE_SCRIPT_NAME                    = "es_inc_core";

const int ES_CORE_EVENT_FLAG_BEFORE                 = 1;
const int ES_CORE_EVENT_FLAG_DEFAULT                = 2;
const int ES_CORE_EVENT_FLAG_AFTER                  = 4;

const int EVENT_SCRIPT_MODULE_ON_MODULE_SHUTDOWN    = 3018;

/* Internal Functions */
int ES_Core_GetCoreHashChanged();
string ES_Core_GetDependencies(string sSubsystem, string sScriptContents);
int ES_Core_GetEventFlags(int nEvent);
void ES_Core_SetEventFlag(int nEvent, int nEventFlag);
/* ****************** */

// Set oObject's nEvent script to the EventSystem's event script
//
// nEvent: An EVENT_SCRIPT_* constant
// bStoreOldEvent: If TRUE, the existing script will be stored and called before the _DEFAULT event.
void ES_Core_SetObjectEventScript(object oObject, int nEvent, int bStoreOldEvent = TRUE);
// Get an ES_CORE_EVENT_FLAG_* from an object event
int ES_Core_GetEventFlagFromEvent(string sEvent);
// Convenience function to construct an object event
//
// If nEvent = EVENT_SCRIPT_MODULE_ON_MODULE_LOAD and nEventFlag = ES_CORE_EVENT_FLAG_AFTER -> Returns: 3002_OBJEVT_4
string ES_Core_GetEventName_Object(int nEvent, int nEventFlag = ES_CORE_EVENT_FLAG_DEFAULT);

// Subscribe to an object event, generally called in a subsystem's init function.
//
// sEventHandlerScript:
// nEvent: An EVENT_SCRIPT_* constant
// nEventFlags: One or more ES_CORE_EVENT_FLAG_* constants
//              For example, to subscribe to both the _BEFORE and _AFTER event you'd do the following:
//              ES_Core_SubscribeEvent_Object(sEventHandlerScript, nEvent, ES_CORE_EVENT_FLAG_BEFORE | ES_CORE_EVENT_FLAG_AFTER);
// bDispatchListMode: Convenience option to toggle DispatchListMode for the event
void ES_Core_SubscribeEvent_Object(string sEventHandlerScript, int nEvent, int nEventFlags = ES_CORE_EVENT_FLAG_DEFAULT, int bDispatchListMode = FALSE);
// Convenience function to subscribe to a NWNX event
void ES_Core_SubscribeEvent_NWNX(string sEventHandlerScript, string sNWNXEvent, int bDispatchListMode = FALSE);

// NWNX_Events_GetEventData() string data wrapper (Not really needed)
string ES_Core_GetEventData_NWNX_String(string sTag);
// NWNX_Events_GetEventData() int data wrapper
int ES_Core_GetEventData_NWNX_Int(string sTag);
// NWNX_Events_GetEventData() float data wrapper
float ES_Core_GetEventData_NWNX_Float(string sTag);
// NWNX_Events_GetEventData() object data wrapper
object ES_Core_GetEventData_NWNX_Object(string sTag);
// NWNX_Events_GetEventData() vector data wrapper
vector ES_Core_GetEventData_NWNX_Vector(string sTagX, string sTagY, string sTagZ);
// NWNX_Events_GetEventData() location data wrapper
location ES_Core_GetEventData_NWNX_Location(string sTagArea, string sTagX, string sTagY, string sTagZ);

void ES_Core_Init()
{
    ES_Util_Log(ES_CORE_SYSTEM_TAG, "* Initializing Core System");

    object oModule = GetModule();

    ES_Util_Log(ES_CORE_SYSTEM_TAG, "  > Checking Core Hash");
    ES_Util_ExecuteScriptChunk(ES_CORE_SCRIPT_NAME, nssFunction("ES_Core_CheckCoreHash"), oModule);

    ES_Util_Log(ES_CORE_SYSTEM_TAG, "  > Checking Object Event Scripts");
    string sCreateObjectEventScripts =
        nssFunction("ES_Core_CreateObjectEventScripts", "EVENT_SCRIPT_MODULE_ON_HEARTBEAT, EVENT_SCRIPT_MODULE_ON_MODULE_SHUTDOWN") +
        nssFunction("ES_Core_CreateObjectEventScripts", "EVENT_SCRIPT_AREA_ON_HEARTBEAT, EVENT_SCRIPT_AREA_ON_EXIT") +
        nssFunction("ES_Core_CreateObjectEventScripts", "EVENT_SCRIPT_AREAOFEFFECT_ON_HEARTBEAT, EVENT_SCRIPT_AREAOFEFFECT_ON_OBJECT_EXIT") +
        nssFunction("ES_Core_CreateObjectEventScripts", "EVENT_SCRIPT_CREATURE_ON_HEARTBEAT, EVENT_SCRIPT_CREATURE_ON_BLOCKED_BY_DOOR") +
        nssFunction("ES_Core_CreateObjectEventScripts", "EVENT_SCRIPT_TRIGGER_ON_HEARTBEAT, EVENT_SCRIPT_TRIGGER_ON_CLICKED") +
        nssFunction("ES_Core_CreateObjectEventScripts", "EVENT_SCRIPT_PLACEABLE_ON_CLOSED, EVENT_SCRIPT_PLACEABLE_ON_LEFT_CLICK") +
        nssFunction("ES_Core_CreateObjectEventScripts", "EVENT_SCRIPT_DOOR_ON_OPEN, EVENT_SCRIPT_DOOR_ON_FAIL_TO_OPEN") +
        nssFunction("ES_Core_CreateObjectEventScripts", "EVENT_SCRIPT_ENCOUNTER_ON_OBJECT_ENTER, EVENT_SCRIPT_ENCOUNTER_ON_USER_DEFINED_EVENT") +
        nssFunction("ES_Core_CreateObjectEventScripts", "EVENT_SCRIPT_STORE_ON_OPEN, EVENT_SCRIPT_STORE_ON_CLOSE");
    ES_Util_ExecuteScriptChunk(ES_CORE_SCRIPT_NAME, sCreateObjectEventScripts, oModule);

    int nEvent;
    ES_Util_Log(ES_CORE_SYSTEM_TAG, "  > Hooking Module Event Scripts");
    for(nEvent = EVENT_SCRIPT_MODULE_ON_HEARTBEAT; nEvent <= EVENT_SCRIPT_MODULE_ON_PLAYER_CHAT; nEvent++)
    {
        ES_Core_SetObjectEventScript(oModule, nEvent);
    }

    ES_Util_Log(ES_CORE_SYSTEM_TAG, "  > Hooking Area Event Scripts");
    string sSetAreaEventScripts = nssObject("oArea", nssFunction("GetFirstArea")) + nssWhile(nssFunction("GetIsObjectValid", "oArea", FALSE)) +
        nssBrackets(
            nssFunction("ES_Core_SetObjectEventScript", "oArea, EVENT_SCRIPT_AREA_ON_HEARTBEAT") +
            nssFunction("ES_Core_SetObjectEventScript", "oArea, EVENT_SCRIPT_AREA_ON_USER_DEFINED_EVENT") +
            nssFunction("ES_Core_SetObjectEventScript", "oArea, EVENT_SCRIPT_AREA_ON_ENTER") +
            nssFunction("ES_Core_SetObjectEventScript", "oArea, EVENT_SCRIPT_AREA_ON_EXIT") +
            nssObject("oArea", nssFunction("GetNextArea"), FALSE));
    ES_Util_ExecuteScriptChunk(ES_CORE_SCRIPT_NAME, sSetAreaEventScripts, oModule);

    string sDisabledSubsystems = NWNX_Util_GetEnvironmentVariable("ES_DISABLE_SUBSYSTEMS");
    ES_Util_Log(ES_CORE_SYSTEM_TAG, "* Disabled Subsystems: " + (sDisabledSubsystems == "" ? "N/A" : sDisabledSubsystems));
    ES_Util_SetString(ES_Util_GetDataObject(ES_CORE_SYSTEM_TAG), "DisabledSubsystems", sDisabledSubsystems);

    string sSubsystemList = ES_Util_GetResRefList(NWNX_UTIL_RESREF_TYPE_NSS, "es_s_.+", FALSE);

    ES_Util_Log(ES_CORE_SYSTEM_TAG, "* Initializing Subsystems");
    ES_Util_ExecuteScriptChunkForListItem(sSubsystemList, ES_CORE_SCRIPT_NAME, nssFunction("ES_Core_InitializeSubsystem", "sListItem"), oModule);

    ES_Util_Log(ES_CORE_SYSTEM_TAG, "* Checking for Subsystem Changes");
    ES_Util_ExecuteScriptChunkForListItem(sSubsystemList, ES_CORE_SCRIPT_NAME, nssFunction("ES_Core_CheckSubsystemChanges", "sListItem"), oModule);

    ES_Util_Log(ES_CORE_SYSTEM_TAG, "* Checking for Dependency Changes");
    ES_Util_ExecuteScriptChunkForListItem(sSubsystemList, ES_CORE_SCRIPT_NAME, nssFunction("ES_Core_CheckDependencyChanges", "sListItem"), oModule);

    ES_Util_Log(ES_CORE_SYSTEM_TAG, "* Checking Subsystem Status");
    ES_Util_ExecuteScriptChunkForListItem(sSubsystemList, ES_CORE_SCRIPT_NAME, nssFunction("ES_Core_CheckSubsystemStatus", "sListItem"), oModule);

    ES_Util_Log(ES_CORE_SYSTEM_TAG, "* Executing Init Functions");
    ES_Util_ExecuteScriptChunkForListItem(sSubsystemList, ES_CORE_SCRIPT_NAME, nssFunction("ES_Core_ExecuteInitFunctions", "sListItem"), oModule);

    ES_Util_Log(ES_CORE_SYSTEM_TAG, "* Cleanup");
    ES_Util_ExecuteScriptChunkForListItem(sSubsystemList, ES_CORE_SCRIPT_NAME, nssFunction("ES_Core_Cleanup", "sListItem"), oModule);

    ES_Util_Log(ES_CORE_SYSTEM_TAG, "* Done!");
}

void ES_Core_CheckCoreHash()
{
    string sCoreScriptContents = NWNX_Util_GetNSSContents(ES_CORE_SCRIPT_NAME);
    int nOldCoreHash = GetCampaignInt(GetModuleName() + "_EventSystemCore", ES_CORE_SCRIPT_NAME);
    int nNewCoreHash = NWNX_Util_Hash(sCoreScriptContents);

    if (nOldCoreHash != nNewCoreHash)
    {
        ES_Util_Log(ES_CORE_SYSTEM_TAG, "    > Core Hash Changed -> Old: " + IntToString(nOldCoreHash) + ", New: " + IntToString(nNewCoreHash));

        SetCampaignInt(GetModuleName() + "_EventSystemCore", ES_CORE_SCRIPT_NAME, nNewCoreHash);
        ES_Util_SetInt(ES_Util_GetDataObject(ES_CORE_SYSTEM_TAG), "CoreHashChanged", TRUE);
    }
}

int ES_Core_GetCoreHashChanged()
{
    return ES_Util_GetInt(ES_Util_GetDataObject(ES_CORE_SYSTEM_TAG), "CoreHashChanged");
}

int ES_Core_GetSubsystemDisabled(string sSubsystem)
{
    return FindSubString(ES_Util_GetString(ES_Util_GetDataObject(ES_CORE_SYSTEM_TAG), "DisabledSubsystems"), sSubsystem) != -1;
}

void ES_Core_InitializeSubsystem(string sSubsystem)
{
    ES_Util_Log(ES_CORE_SYSTEM_TAG, "  > Initializing Subsystem: " + sSubsystem);

    object oDataObject = ES_Util_GetDataObject(ES_CORE_SYSTEM_TAG + "_" + sSubsystem);
    string sSubsystemScriptContents = NWNX_Util_GetNSSContents(sSubsystem);

    int bDisabledSubsystem = ES_Core_GetSubsystemDisabled(sSubsystem);
    ES_Util_Log(ES_CORE_SYSTEM_TAG, "    > Status: " + (bDisabledSubsystem ? "Disabled" : "Enabled"));
    ES_Util_SetInt(oDataObject, "DisabledSubsystem", bDisabledSubsystem);

    int nSubsystemHash = NWNX_Util_Hash(sSubsystemScriptContents);
    ES_Util_Log(ES_CORE_SYSTEM_TAG, "    > Hash: " + IntToString(nSubsystemHash));
    ES_Util_SetInt(oDataObject, "Hash", nSubsystemHash);

    string sSubsystemDependencies = ES_Core_GetDependencies(sSubsystem, sSubsystemScriptContents);
    ES_Util_Log(ES_CORE_SYSTEM_TAG, "    > Dependencies: " + (sSubsystemDependencies == "" ? "N/A" : sSubsystemDependencies));
    ES_Util_SetString(oDataObject, "Dependencies", sSubsystemDependencies);

    int bForceRecompileFlag = ES_Util_GetScriptFlag(sSubsystemScriptContents, "EventSystem_ForceRecompile");
    ES_Util_Log(ES_CORE_SYSTEM_TAG, "    > Flags: " + (bForceRecompileFlag ? "ForceRecompile" : "N/A"));
    ES_Util_SetInt(oDataObject, "ForceRecompile", bForceRecompileFlag);

    string sEventHandlerScript = "es_e_" + GetSubString(sSubsystem, 5, GetStringLength(sSubsystem) - 5);
    ES_Util_SetString(oDataObject, "EventHandlerScript", sEventHandlerScript);

    string sSubsystemInitFunction = ES_Util_GetFunctionName(sSubsystemScriptContents, "EventSystem_Init");
    ES_Util_Log(ES_CORE_SYSTEM_TAG, "    > Init Function: " + (sSubsystemInitFunction == "" ? "N/A" : sSubsystemInitFunction + "()"));
    ES_Util_SetString(oDataObject, "InitFunction", sSubsystemInitFunction);

    string sSubsystemEventHandlerFunction = ES_Util_GetFunctionName(sSubsystemScriptContents, "EventSystem_EventHandler");
    ES_Util_Log(ES_CORE_SYSTEM_TAG, "    > EventHandler Function: " + (sSubsystemEventHandlerFunction == "" ? "N/A" : sSubsystemEventHandlerFunction + "()"));
    ES_Util_SetString(oDataObject, "EventHandlerFunction", sSubsystemEventHandlerFunction);
}

void ES_Core_CreateObjectEventScripts(int nStart, int nEnd)
{
    int nEvent;
    int bCoreHashChanged = ES_Core_GetCoreHashChanged();

    for (nEvent = nStart; nEvent <= nEnd; nEvent++)
    {
        string sScriptName = "es_obj_e_" + IntToString(nEvent);
        int bObjectEventScriptExists = NWNX_Util_IsValidResRef(sScriptName, NWNX_UTIL_RESREF_TYPE_NCS);

        if (bCoreHashChanged || !bObjectEventScriptExists)
        {
            ES_Util_Log(ES_CORE_SYSTEM_TAG, "   > " + (!bObjectEventScriptExists ? "Creating" : "Recompiling") + " Object Event Script: " + sScriptName);

            ES_Util_AddScript(sScriptName, ES_CORE_SCRIPT_NAME, nssFunction("ES_Core_SignalEvent", IntToString(nEvent)));
        }
    }
}

void ES_Core_AddDependent(string sSubsystem, string sDependent)
{
    object oDataObject = ES_Util_GetDataObject(ES_CORE_SYSTEM_TAG + "_" + sSubsystem);
    string sDependents = ES_Util_GetString(oDataObject, "Dependents");

    if (FindSubString(sDependents, sDependent) == -1)
        ES_Util_SetString(oDataObject, "Dependents", sDependents + sDependent + ES_UTIL_DELIMITER);
}

string ES_Core_GetDependencies(string sSubsystem, string sScriptContents)
{
    string sDependencies;
    int nIncludeStart = FindSubString(sScriptContents, "#" + "include \"", 0), nIncludeEnd;

    while (nIncludeStart != -1)
    {
        nIncludeEnd = FindSubString(sScriptContents, "\"", nIncludeStart + 10);

        string sDependency = GetSubString(sScriptContents, nIncludeStart + 10, nIncludeEnd - nIncludeStart - 10);

        if (GetStringLeft(sDependency, 5) == "es_s_")
        {
            ES_Core_AddDependent(sDependency, sSubsystem);

            sDependencies += sDependency + ES_UTIL_DELIMITER;
        }

        nIncludeStart = FindSubString(sScriptContents, "#" + "include \"", nIncludeEnd);
    }

    return sDependencies;
}

void ES_Core_CompileEventHandler(string sSubsystem, string sEventHandlerScript, string sEventHandlerFunction)
{
    string sEventHandlerScriptChunk = nssFunction(sEventHandlerFunction, nssEscapeDoubleQuotes(sEventHandlerScript) + ", " + nssFunction("NWNX_Events_GetCurrentEvent", "", FALSE));
    string sResult = ES_Util_AddScript(sEventHandlerScript, sSubsystem, sEventHandlerScriptChunk);

    if (sResult != "")
    {
        ES_Util_Log(ES_CORE_SYSTEM_TAG, "    > ERROR: Failed to compile Event Handler for Subsystem '" + sSubsystem + "' with error: " + sResult);
    }
}

void ES_Core_CheckSubsystemChanges(string sSubsystem)
{
    object oDataObject = ES_Util_GetDataObject(ES_CORE_SYSTEM_TAG + "_" + sSubsystem);
    int bCoreHashChanged = ES_Core_GetCoreHashChanged();

    int nOldHash = GetCampaignInt(GetModuleName() + "_EventSystemCore", sSubsystem);
    int nNewHash = ES_Util_GetInt(oDataObject, "Hash");
    int bHashChanged = nOldHash != nNewHash;

    if (bHashChanged)
    {
        ES_Util_Log(ES_CORE_SYSTEM_TAG, "   > Hash for Subsystem '" + sSubsystem + "' has changed -> Old: " + IntToString(nOldHash) + ", New: " + IntToString(nNewHash));
        SetCampaignInt(GetModuleName() + "_EventSystemCore", sSubsystem, nNewHash);
        ES_Util_SetInt(oDataObject, "HashChanged", bHashChanged);
    }

    string sSubsystemEventHandlerFunction = ES_Util_GetString(oDataObject, "EventHandlerFunction");

    if (sSubsystemEventHandlerFunction != "")
    {
        string sSubsystemEventHandlerScript = ES_Util_GetString(oDataObject, "EventHandlerScript");
        int bEventScriptExists = NWNX_Util_IsValidResRef(sSubsystemEventHandlerScript, NWNX_UTIL_RESREF_TYPE_NCS);
        int bForceRecompileFlag = ES_Util_GetInt(oDataObject, "ForceRecompile");

        if (bCoreHashChanged || !bEventScriptExists || bHashChanged || bForceRecompileFlag)
        {
            ES_Util_Log(ES_CORE_SYSTEM_TAG, "     > " + (!bEventScriptExists ? "Compiling" :
                (bForceRecompileFlag && !bHashChanged) ? "(Forced) Recompiling" : "Recompiling") + " Event Handler for Subsystem: " + sSubsystem);

            ES_Core_CompileEventHandler(sSubsystem, sSubsystemEventHandlerScript, sSubsystemEventHandlerFunction);

            ES_Util_SetInt(oDataObject, "DidNotExist", !bEventScriptExists);
            ES_Util_SetInt(oDataObject, "HasBeenCompiled", TRUE);
        }

        ES_Util_SetInt(oDataObject, "HasEventHandler", TRUE);
    }
}

void ES_Core_CheckDependencyChanges(string sSubsystem)
{
    object oDataObject = ES_Util_GetDataObject(ES_CORE_SYSTEM_TAG + "_" + sSubsystem);
    int bHasEventHandler = ES_Util_GetInt(oDataObject, "HasEventHandler");
    int bDidNotExist = ES_Util_GetInt(oDataObject, "DidNotExist");
    int bHasBeenCompiled = ES_Util_GetInt(oDataObject, "HasBeenCompiled");

    if (bHasEventHandler && !bDidNotExist && !bHasBeenCompiled)
    {
        string sSubsystemDependencies = ES_Util_GetString(oDataObject, "Dependencies");

        if (sSubsystemDependencies != "")
        {
            string sIdentifier = GetRandomUUID();
            string sDepSubsystem = ES_Util_GetFirstListItem(sSubsystemDependencies, sIdentifier);

            while (sDepSubsystem != "")
            {
                object oDepDataObject = ES_Util_GetDataObject(ES_CORE_SYSTEM_TAG + "_" + sDepSubsystem);

                if (ES_Util_GetInt(oDepDataObject, "HashChanged"))
                {
                    ES_Util_Log(ES_CORE_SYSTEM_TAG, "  > Dependencies for Subsystem '" + sSubsystem + "' have changed, recompiling Event Handler");

                    string sSubsystemEventHandlerScript = ES_Util_GetString(oDataObject, "EventHandlerScript");
                    string sSubsystemEventHandlerFunction = ES_Util_GetString(oDataObject, "EventHandlerFunction");

                    ES_Core_CompileEventHandler(sSubsystem, sSubsystemEventHandlerScript, sSubsystemEventHandlerFunction);

                    break;
                }

                sDepSubsystem = ES_Util_GetNextListItem(sSubsystemDependencies, sIdentifier);
            }
        }
    }
}

void ES_Core_CheckSubsystemStatus(string sSubsystem)
{
    object oDataObject = ES_Util_GetDataObject(ES_CORE_SYSTEM_TAG + "_" + sSubsystem);
    int nSubsystemDisabled = ES_Util_GetInt(oDataObject, "DisabledSubsystem");
    string sIdentifier = GetRandomUUID();

    ES_Util_Log(ES_CORE_SYSTEM_TAG, "  * Checking Subsystem: " + sSubsystem + "");

    if (!nSubsystemDisabled)
    {// Check if any of our dependencies are disabled
        string sSubsystemDependencies = ES_Util_GetString(oDataObject, "Dependencies"), sDisabledDependencies;

        if (sSubsystemDependencies != "")
        {
            string sDependencySubsystem = ES_Util_GetFirstListItem(sSubsystemDependencies, sIdentifier);

            while (sDependencySubsystem != "")
            {
                object oDependencyDataObject = ES_Util_GetDataObject(ES_CORE_SYSTEM_TAG + "_" + sDependencySubsystem);

                if (ES_Util_GetInt(oDependencyDataObject, "DisabledSubsystem"))
                {
                    sDisabledDependencies += sDependencySubsystem + ";";
                }

                sDependencySubsystem = ES_Util_GetNextListItem(sSubsystemDependencies, sIdentifier);
            }

            if (sDisabledDependencies != "")
            {// One of our deps is disabled, disable ourselves
                nSubsystemDisabled = TRUE;
                ES_Util_SetInt(oDataObject, "DisabledSubsystem", nSubsystemDisabled);
                ES_Util_Log(ES_CORE_SYSTEM_TAG, "    > Found Disabled Dependencies: " + sDisabledDependencies);
            }
        }
    }

    if (nSubsystemDisabled)
    {// Disable our dependents
        string sSubsystemDependents = ES_Util_GetString(oDataObject, "Dependents"), sDisabledDependents;

        if (sSubsystemDependents != "")
        {
            string sDependentSubsystem = ES_Util_GetFirstListItem(sSubsystemDependents, sIdentifier);

            while (sDependentSubsystem != "")
            {
                object oDependentDataObject = ES_Util_GetDataObject(ES_CORE_SYSTEM_TAG + "_" + sDependentSubsystem);

                if (!ES_Util_GetInt(oDependentDataObject, "DisabledSubsystem"))
                {
                    ES_Util_SetInt(oDependentDataObject, "DisabledSubsystem", TRUE);
                    sDisabledDependents += sDependentSubsystem + ";";
                }

                sDependentSubsystem = ES_Util_GetNextListItem(sSubsystemDependents, sIdentifier);
            }

            if (sDisabledDependents != "")
                ES_Util_Log(ES_CORE_SYSTEM_TAG, "    > Disabling Dependent Subsystems: " + sDisabledDependents);
        }
    }

    ES_Util_Log(ES_CORE_SYSTEM_TAG, "    > Status: " + (nSubsystemDisabled ? "Disabled" : "Enabled"));
}

void ES_Core_ExecuteInitFunctions(string sSubsystem)
{
    object oDataObject = ES_Util_GetDataObject(ES_CORE_SYSTEM_TAG + "_" + sSubsystem);
    string sSubsystemInitFunction = ES_Util_GetString(oDataObject, "InitFunction");

    if (sSubsystemInitFunction != "")
    {
        if (!ES_Util_GetInt(oDataObject, "DisabledSubsystem"))
        {
            ES_Util_Log(ES_CORE_SYSTEM_TAG, "  > Executing Init Function '" + sSubsystemInitFunction + "()' for Subsystem: " + sSubsystem);

            string sEventHandlerScript = ES_Util_GetString(oDataObject, "EventHandlerScript");
            string sResult = ES_Util_ExecuteScriptChunk(sSubsystem, nssFunction(sSubsystemInitFunction, nssEscapeDoubleQuotes(sEventHandlerScript)), GetModule());

            if (sResult != "")
            {
                ES_Util_Log(ES_CORE_SYSTEM_TAG, "    > ERROR: Init Function failed with error: " + sResult);
            }
        }
    }
    else
    {
        ES_Util_Log(ES_CORE_SYSTEM_TAG, "   > WARNING: Subsystem '" + sSubsystem + "' does not have an Init Function set");
    }
}

void ES_Core_Cleanup(string sSubsystem)
{
    ES_Util_DestroyDataObject(ES_CORE_SYSTEM_TAG + "_" + sSubsystem);
}

int ES_Core_GetEventFlags(int nEvent)
{
    return ES_Util_GetInt(ES_Util_GetDataObject(ES_CORE_SYSTEM_TAG), "EventFlags_" + IntToString(nEvent));
}

void ES_Core_SetEventFlag(int nEvent, int nEventFlag)
{
    ES_Util_SetInt(ES_Util_GetDataObject(ES_CORE_SYSTEM_TAG),
                   "EventFlags_" + IntToString(nEvent),
                   ES_Core_GetEventFlags(nEvent) | nEventFlag);
}

void ES_Core_SignalEvent(int nEvent, object oTarget = OBJECT_SELF)
{
    int nEventFlags = ES_Core_GetEventFlags(nEvent);
    string sEvent = IntToString(nEvent) + "_OBJEVT_";

    if (nEventFlags & ES_CORE_EVENT_FLAG_BEFORE)
        NWNX_Events_SignalEvent(sEvent + IntToString(ES_CORE_EVENT_FLAG_BEFORE), oTarget);

    // *** Run any old stored event scripts
    string sScript = ES_Util_GetString(oTarget, "ES_Core_OldEventScript_" + IntToString(nEvent));
    if (sScript != "") ExecuteScript(sScript, oTarget);
    // ***

    if (nEventFlags & ES_CORE_EVENT_FLAG_DEFAULT)
        NWNX_Events_SignalEvent(sEvent + IntToString(ES_CORE_EVENT_FLAG_DEFAULT), oTarget);

    if (nEventFlags & ES_CORE_EVENT_FLAG_AFTER)
        NWNX_Events_SignalEvent(sEvent + IntToString(ES_CORE_EVENT_FLAG_AFTER), oTarget);
}

/* *** */

void ES_Core_SetObjectEventScript(object oObject, int nEvent, int bStoreOldEvent = TRUE)
{
    string sEvent = IntToString(nEvent);
    string sOldScript = GetEventScript(oObject, nEvent);
    string sNewScript = "es_obj_e_" + sEvent;

    SetEventScript(oObject, nEvent, sNewScript);

    if (bStoreOldEvent && sOldScript != "" && sOldScript != sNewScript)
        ES_Util_SetString(oObject, "ES_Core_OldEventScript_" + sEvent, sOldScript);
}

int ES_Core_GetEventFlagFromEvent(string sEvent)
{
    return StringToInt(GetStringRight(sEvent, 1));
}

string ES_Core_GetEventName_Object(int nEvent, int nEventFlag = ES_CORE_EVENT_FLAG_DEFAULT)
{
    return IntToString(nEvent) + "_OBJEVT_" + IntToString(nEventFlag);
}

void ES_Core_SubscribeEvent_Object(string sEventHandlerScript, int nEvent, int nEventFlags = ES_CORE_EVENT_FLAG_DEFAULT, int bDispatchListMode = FALSE)
{
    string sEvent = IntToString(nEvent) + "_OBJEVT_";

    if (nEventFlags & ES_CORE_EVENT_FLAG_BEFORE)
    {
        ES_Core_SetEventFlag(nEvent, ES_CORE_EVENT_FLAG_BEFORE);

        NWNX_Events_SubscribeEvent(sEvent + IntToString(ES_CORE_EVENT_FLAG_BEFORE), sEventHandlerScript);

        if (bDispatchListMode)
            NWNX_Events_ToggleDispatchListMode(sEvent + IntToString(ES_CORE_EVENT_FLAG_BEFORE), sEventHandlerScript, bDispatchListMode);
    }

    if (nEventFlags & ES_CORE_EVENT_FLAG_DEFAULT)
    {
        ES_Core_SetEventFlag(nEvent, ES_CORE_EVENT_FLAG_DEFAULT);

        NWNX_Events_SubscribeEvent(sEvent + IntToString(ES_CORE_EVENT_FLAG_DEFAULT), sEventHandlerScript);

        if (bDispatchListMode)
            NWNX_Events_ToggleDispatchListMode(sEvent + IntToString(ES_CORE_EVENT_FLAG_DEFAULT), sEventHandlerScript, bDispatchListMode);
    }

    if (nEventFlags & ES_CORE_EVENT_FLAG_AFTER)
    {
        ES_Core_SetEventFlag(nEvent, ES_CORE_EVENT_FLAG_AFTER);

        NWNX_Events_SubscribeEvent(sEvent + IntToString(ES_CORE_EVENT_FLAG_AFTER), sEventHandlerScript);

        if (bDispatchListMode)
            NWNX_Events_ToggleDispatchListMode(sEvent + IntToString(ES_CORE_EVENT_FLAG_AFTER), sEventHandlerScript, bDispatchListMode);
    }
}

void ES_Core_SubscribeEvent_NWNX(string sEventHandlerScript, string sNWNXEvent, int bDispatchListMode = FALSE)
{
    NWNX_Events_SubscribeEvent(sNWNXEvent, sEventHandlerScript);

    if (bDispatchListMode)
        NWNX_Events_ToggleDispatchListMode(sNWNXEvent, sEventHandlerScript, bDispatchListMode);
}

/* *** */

string ES_Core_GetEventData_NWNX_String(string sTag)
{
    return NWNX_Events_GetEventData(sTag);
}

int ES_Core_GetEventData_NWNX_Int(string sTag)
{
    return StringToInt(ES_Core_GetEventData_NWNX_String(sTag));
}

float ES_Core_GetEventData_NWNX_Float(string sTag)
{
    return StringToFloat(ES_Core_GetEventData_NWNX_String(sTag));
}

object ES_Core_GetEventData_NWNX_Object(string sTag)
{
    return NWNX_Object_StringToObject(ES_Core_GetEventData_NWNX_String(sTag));
}

vector ES_Core_GetEventData_NWNX_Vector(string sTagX, string sTagY, string sTagZ)
{
    return Vector(ES_Core_GetEventData_NWNX_Float(sTagX),
                  ES_Core_GetEventData_NWNX_Float(sTagY),
                  ES_Core_GetEventData_NWNX_Float(sTagZ));
}

location ES_Core_GetEventData_NWNX_Location(string sTagArea, string sTagX, string sTagY, string sTagZ)
{
    return Location(ES_Core_GetEventData_NWNX_Object(sTagArea),
                    ES_Core_GetEventData_NWNX_Vector(sTagX, sTagY, sTagZ), 0.0f);
}

