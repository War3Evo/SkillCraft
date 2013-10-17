
// outdated or not needed:
/*
stock GlobalOptionalSkillNatives() {
	MarkNativeAsOptional("SC_CreateNewSkill");
	MarkNativeAsOptional("SC_AddSkillSkill");
	MarkNativeAsOptional("SC_CreateNewSkillT");
	MarkNativeAsOptional("SC_AddSkillSkillT");
	MarkNativeAsOptional("SC_CreateSkillEnd");
	MarkNativeAsOptional("SC_GetSkillName");
	MarkNativeAsOptional("SC_GetSkillShortname");
	//MarkNativeAsOptional("SC_GetSkillString"); // not implemented
	MarkNativeAsOptional("SC_GetSkillSkillString");
	MarkNativeAsOptional("SC_GetSkillsLoaded");
	MarkNativeAsOptional("SC_GetSkillMaxLevel");
	MarkNativeAsOptional("SC_IsSkillUltimate");
	MarkNativeAsOptional("SC_GetSkillSkillCount");
	MarkNativeAsOptional("SC_GetSkillSkillName");
	MarkNativeAsOptional("SC_GetSkillSkillDesc");
	MarkNativeAsOptional("SC_GetSkillSkillMaxLevel");
	MarkNativeAsOptional("SC_GetSkillOrder");
	MarkNativeAsOptional("SC_SkillHasFlag");
	MarkNativeAsOptional("SC_GetSkillList");
	MarkNativeAsOptional("SC_GetSkillIDByShortname");
	MarkNativeAsOptional("SC_GetSkillAccessFlagStr");
	MarkNativeAsOptional("SC_GetSkillItemRestrictionsStr");
	MarkNativeAsOptional("SC_GetSkillMaxLimitTeam");
	MarkNativeAsOptional("SC_GetSkillMaxLimitTeamCvar");
	MarkNativeAsOptional("SC_GetSkillMinLevelRequired");
	MarkNativeAsOptional("SC_IsSkillTranslated");	
}
*/

// in constants.inc:
/*
enum SKILLTYPE
{
	mastery=0,
	talent,
	ability,
	ultimate
}
*/

/* BEGIN Race Class */

//creates a new race, returns the race id
//a valid skill id is >0

//creates a new race, returns the race id
// typeofskill = SKILLTYPE
native SC_CreateNewSkill(String:skill_longname[],String:skill_shortname[],String:skill_description[],SKILLTYPE:typeofskill);


native SC_GetSkillName(skillid,String:retstr[],maxlen);
native SC_GetSkillShortname(skillid,String:retstr[],maxlen);
native SC_GetSkillDesc(skillid,String:retstr[],maxlen);

native SC_GetSkillsLoaded();

native SC_GetSkillCount(skillid);
native SC_GetSkillOrder(skillid);

//Flag is a generic string. We compare the race_flags cvar to the string you passed
native bool:SC_SkillHasFlag(skillid,String:flag[]);

//returns a simple array of skill IDs, sorted properly.
//Does not include "hidden" skills
//pass array of MAXSKILLS, returns number of skills in the array. starts at 0
//ordered properly
//returns the size of the array
native SC_GetSkillList(skilllist[]);

native SC_GetSkillAccessFlagStr(skillid,String:ret[],maxlen);
native SC_GetSkillItemRestrictionsStr(skillid,String:ret[],maxlen);
native SC_GetSkillMaxLimitTeam(skillid, team);
native SC_GetSkillMaxLimitTeamCvar(skillid, team); //returns the internal cvar id (int not handle)

//a valid race is >0
native SC_GetSkillIDByShortname(String:raceshortname[]);

native SC_GetSkillCell(skillid,ENUM_SkillObject:property);
native SC_SetSkillCell(skillid,ENUM_SkillObject:property,any:somevalue);



native SC_IsSkillMastery(skillid);
native SC_IsSkillTalent(skillid);
native SC_IsSkillAbility(skillid);
native SC_IsSkillUltimate(skillid);

native SC_GetSkill(client, SKILLTYPE:typeofskill);
native SC_SetSkill(client, skillid);

native bool:SC_HasSkill(client, skillid);

native SKILLTYPE:SC_GetSkillType(skillid);

stock SC_GetPendingSkill(client, SKILLTYPE:typeofskill) {
	switch(typeofskill)
	{
		case mastery:
		{
			return SC_GetPlayerProp(client, Pending_Mastery_Skill);
		}
		case talent:
		{
			return SC_GetPlayerProp(client, Pending_Talent_Skill);
		}
		case ability:
		{
			return SC_GetPlayerProp(client, Pending_Ability_Skill);
		}
		case ultimate:
		{
			return SC_GetPlayerProp(client, Pending_Ultimate_Skill);
		}
	}
	return 0;
}

stock SC_SetPendingSkill(client, SKILLTYPE:typeofskill, pendskill) {
	switch(typeofskill)
	{
		case mastery:
		{
			return SC_SetPlayerProp(client, Pending_Mastery_Skill, pendskill);
		}
		case talent:
		{
			return SC_SetPlayerProp(client, Pending_Talent_Skill, pendskill);
		}
		case ability:
		{
			return SC_SetPlayerProp(client, Pending_Ability_Skill, pendskill);
		}
		case ultimate:
		{
			return SC_SetPlayerProp(client, Pending_Ultimate_Skill, pendskill);
		}
	}
	return 0;
}
