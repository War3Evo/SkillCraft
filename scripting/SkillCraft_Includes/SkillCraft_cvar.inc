




new Handle:hSkillLimitEnabled;

/*

new Handle:ChanceModifierPlasma;
new Handle:ChanceModifierBurn;
new Handle:ChanceModifierHeavy;


new Handle:ChanceModifierMedic;
new Handle:ChanceModifierSMGSniper;
*/

new Handle:hChangeGameDescCvar;
//new Handle:hUseMetric;

new Handle:botsetraces;
/////END CVARS
///other cvar handle definitions are in war3source.inc ??
SkillCraft_InitCVars()
{
	/*	
	ChanceModifierPlasma=CreateConVar("war3_chancemodifier_directburn","0.0625","From 0.0 to 1.0 chance modifier for direct burns (plasma)");
	ChanceModifierBurn=CreateConVar("war3_chancemodifier_burn","0.10","From 0.0 to 1.0 chance modifier for burns");
	ChanceModifierHeavy=CreateConVar("war3_chancemodifier_heavy","0.125","From 0.0 to 1.0 chance modifier for heavy gun");
	ChanceModifierMedic=CreateConVar("war3_chancemodifier_medic","0.125","From 0.0 to 1.0 chance modifier for medic needle gun");
	ChanceModifierSMGSniper=CreateConVar("war3_chancemodifier_smgsniper","0.5","From 0.0 to 1.0 chance modifier for sniper SMG");
	
	*/
	botsetraces=CreateConVar("war3_bot_set_races","1","should bots get races");
	
	hSkillLimitEnabled=CreateConVar("war3_racelimit_enable","1","Should race limit restrictions per team be enabled");
	SC_SetVar(hSkillLimitEnabledCvar,hSkillLimitEnabled);


	hChangeGameDescCvar=CreateConVar("war3_game_desc","1","change game description to war3source? does not affect player connect");
	
	return true;
}

