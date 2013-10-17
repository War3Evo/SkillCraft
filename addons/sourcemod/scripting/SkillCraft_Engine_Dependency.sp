#include <sourcemod>
#include "SkillCraft_Includes/SkillCraft_Interface"

public Plugin:myinfo= 
{
	name="SkillCraft Engine Skill Dependency",
	author="SkillCraft Team",
	description="SkillCraft Core Plugins",
	version="1.0",
};

// holds informations about the skill dependency id(0) and required level(1)
new sc_skillDependency[MAXSKILLS];

public bool:Init_SC_NativesForwards()
{
	// Adds an dependency on the given skill
	CreateNative("SC_SetDependency",Native_SC_SetDependency);
	// Removes all dependencys from a skill
	CreateNative("SC_RemoveDependency",Native_SC_RemDependency);
	// Returns various informations about the dependency
	CreateNative("SC_GetDependency",Native_SC_GetDependency);
	return true;
}

public Native_SC_SetDependency(Handle:plugin,numParams)
{
	if(numParams != 2) {
		return ThrowNativeError(SP_ERROR_NATIVE,"numParams is invalid!");
	}
	new iSkillID = GetNativeCell(1);
	if(iSkillID>0) {
		new iOtherSkillId = GetNativeCell(2);
		if(iOtherSkillId>0) {
			sc_skillDependency[iSkillID] = iOtherSkillId;
			return 1;
		}
		return 0;
	}
	else return ThrowNativeError(SP_ERROR_NATIVE,"skill is invalid!");
	//else return -1;
}

public Native_SC_RemDependency(Handle:plugin,numParams)
{
	if(numParams != 1) {
		return ThrowNativeError(SP_ERROR_NATIVE,"numParams is invalid!");
	}
	new iSkillID = GetNativeCell(1);
	if(iSkillID>0) {
		sc_skillDependency[iSkillID] = 0;
		return 1;
	}
	else return ThrowNativeError(SP_ERROR_NATIVE,"skill is invalid!");
	//else return -1;
}

public Native_SC_GetDependency(Handle:plugin,numParams)
{
	if(numParams != 1) {
		return ThrowNativeError(SP_ERROR_NATIVE,"numParams is invalid!");
	}
	new iSkillID = GetNativeCell(1);
	if(iSkillID>0) {
		return sc_skillDependency[iSkillID];
	}
	else return ThrowNativeError(SP_ERROR_NATIVE,"skill is invalid!");
	//else return -1;
}
