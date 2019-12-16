/*
    ScriptName: es_s_spellhook.nss
    Created by: Daz

    Description: A subsystem that allows subscribing to module override spell script events
*/

//void main() {}

#include "es_inc_core"
#include "x2_inc_switches"

const string SPELL_HOOK_SYSTEM_TAG          = "Spellhook";
const string SPELL_HOOK_EVENT_PREFIX        = "SPELL_";

// @EventSystem_Init
void Spellhook_Init(string sEventHandlerScript);

// Subscribe sEventHandlerScript to a SPELL_* cast event
void Spellhook_SubscribeEvent(string sEventHandlerScript, int nSpell);
// Skip a spellhook event
void Spellhook_SkipEvent();

void Spellhook_Init(string sEventHandlerScript)
{
    ES_Util_AddScript("es_spellhook", "es_s_spellhook", "Spellhook_SignalEvent();");
}

void Spellhook_SignalEvent()
{
    string sSpellEvent = SPELL_HOOK_EVENT_PREFIX + IntToString(GetSpellId());

    if (GetLocalInt(ES_Util_GetDataObject(SPELL_HOOK_SYSTEM_TAG), sSpellEvent))
        NWNX_Events_SignalEvent(sSpellEvent, OBJECT_SELF);
}

void Spellhook_SubscribeEvent(string sEventHandlerScript, int nSpell)
{
    SetModuleOverrideSpellscript("es_spellhook");

    SetLocalInt(ES_Util_GetDataObject(SPELL_HOOK_SYSTEM_TAG), SPELL_HOOK_EVENT_PREFIX + IntToString(nSpell), TRUE);

    NWNX_Events_SubscribeEvent(SPELL_HOOK_EVENT_PREFIX + IntToString(nSpell), sEventHandlerScript);
}

void Spellhook_SkipEvent()
{
    SetModuleOverrideSpellScriptFinished();
}
