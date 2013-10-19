//stock CreateTimer_DEBUG(any:f=0,any:ff=0,any:fff=0,any:ffff=0) {}

/**
 * File: SkillCraft_Interface.inc
 * Description: The file to be included for creating races and whatnot.
 * Author(s): Anthony Iacono  
 * 
 * 
 * LISTS NATIVES AND FORWARDS, BUT NOT ACTUALLY DEFINES THE CODE
 */

#undef REQUIRE_EXTENSIONS
#include <sdktools>
#include <tf2>
#include <tf2_stocks>

#include "SkillCraft_Includes/SkillCraft_constants"
#include "SkillCraft_Includes/SkillCraft_PlayerProp"
#include "SkillCraft_Includes/SkillCraft_Skills"
#include "SkillCraft_Includes/SkillCraft_colors"
#include "SkillCraft_Includes/SkillCraft_aura"
#include "SkillCraft_Includes/SkillCraft_Effects"
#include "SkillCraft_Includes/SkillCraft_stocks_precache"
#include "SkillCraft_Includes/SkillCraft_stocks_misc"
#include "SkillCraft_Includes/SkillCraft_TrieKeyValue"
#include "SkillCraft_Includes/SkillCraft_Events"
#include "SkillCraft_Includes/SkillCraft_buffsystem"
#include "SkillCraft_Includes/SkillCraft_Health"


stock dummy; //variable for dummies! Use this where ever u want for a dummy return
stock String:dummystr[32]; //just a dummy string! 

/**********************
 * CAUTION, THE SC INTERFACE NOW HANDLES AskPluginLoad2Custom BECAUSE IT IS REQUIRED TO HANDLE CERTAIN TASKS
 * It acually simplifies things for you:
 * Determines game mode
 * Mark Natives optional
 * Calls your own functions (hackish way) if you have them:
 * Init_SC_NativesForwards()   
 * AskPluginLoad2Custom(Handle:myself,bool:late,String:error[],err_max);
 * So if you want to do something in AskPluginLoad2, implement public AskPluginLoad2Custom(...) instead. 
 */
public APLRes:AskPluginLoad2(Handle:plugin,bool:late,String:error[],err_max)
{
	GlobalOptionalNatives();
	//GlobalOptionalSkillNatives();
	new Function:func;
	func=GetFunctionByName(plugin, "Init_SC_NativesForwards");
	if(func!=INVALID_FUNCTION) { //non SkillCraft plugins dont have this function
		Call_StartFunction(plugin, func);
		Call_Finish(dummy);
		if(!dummy) {
			LogError("Init_SC_NativesForwards did not return true, possible failure");
		}
	}
	func=GetFunctionByName(plugin, "SC_AskPluginLoad2Custom");
	if(func!=INVALID_FUNCTION) { //non SkillCraft plugins dont have this function
		Call_StartFunction(plugin, func);
		Call_PushCell(plugin);
		Call_PushCell(late);
		Call_PushString(error);
		Call_PushCell(err_max);
		Call_Finish(dummy);
		if(APLRes:dummy==APLRes_SilentFailure) {
			return APLRes_SilentFailure;
		}
		if(APLRes:dummy!=APLRes_Success) {
			LogError("AskPluginLoad2Custom did not return true, possible failure");
		}
	}
	func=GetFunctionByName(plugin, "SC_LoadCheck");
	if(func!=INVALID_FUNCTION) { //non SkillCraft plugins dont have this function
		Call_StartFunction(plugin, func);
		Call_Finish(dummy);
		if(dummy==0) {
			return APLRes_SilentFailure;
		}
	}

	return APLRes_Success;
}
/**********************
 * Implement this if you have natives/forwards
 */
forward bool:Init_SC_NativesForwards();

/**********************
 * Implement this if you need AskPluginLoad2Custom
 */
forward APLRes:AskPluginLoad2Custom(Handle:plugin,bool:late,String:error[],err_max);


//INTERFACE ONLY VARIABLES, use for determining game type
//stock tValveGame;


//Do not manually call this, this determines the game mode and is called internally in the API
/*
stock DetermineGameMode() {

	//DETERMINE GAME TYPE: CS TF ETC       may use this information at a later time = saving it for reference only
	
	new String:gameDir[64];
	GetGameFolderName(gameDir, sizeof(gameDir));
	if(StrContains(gameDir,"tf",false)==0)
	{
#if defined WAR3MAIN
		PrintToServer("[SkillCraft] Game set: Team Fortress 2");
#endif
		tValveGame=_:Game_TF;
	}
	else
	{
		SetFailState("[SkillCraft] Sorry, this game isn't support by SkillCraft. If you think this is a mistake, you probably renamed your game directory. For example, re-naming cstrike to cstrike2 will cause this error. (folder name: %s)", gameDir);
	} */
//bGameModeDetermined=true;
//}

//#pragma deprecated use if(GAMECSANY)

//We mark some natives optional so different plugins can still startup
/**********************
 * CALL THIS IN ASKPLUGINLOAD if you are using any of these or have native errors
 */


stock GlobalOptionalNatives() {
	MarkNativeAsOptional("SC_GetReqXP");

	MarkNativeAsOptional("SC_ShowXP");

	MarkNativeAsOptional("SC_Failed");

	MarkNativeAsOptional("OurTestNative");
	MarkNativeAsOptional("OurTestNative2");
	MarkNativeAsOptional("SC_ExtVersion");
	MarkNativeAsOptional("SC_ExtTestFunc");
	MarkNativeAsOptional("SC_GetSC_Version");
	MarkNativeAsOptional("SC_GetSC_Revision");
	MarkNativeAsOptional("SC_GetStatsVersion");
	MarkNativeAsOptional("SC_Socket");
	MarkNativeAsOptional("SC_Socket2");
	MarkNativeAsOptional("SC_DropWeapon");
	MarkNativeAsOptional("SC_GetVar");
	MarkNativeAsOptional("SC_SetVar");
	MarkNativeAsOptional("SC_HasDiedThisFrame");

	MarkNativeAsOptional("SC_CreateHelpCommand");
	MarkNativeAsOptional("SC_GetLevelsSpent");
	MarkNativeAsOptional("SC_ClearSkillLevels");
	MarkNativeAsOptional("SC_GetKillXP");
	MarkNativeAsOptional("SC_GetReqXP");
	MarkNativeAsOptional("SC_ShowXP");
	MarkNativeAsOptional("SC_GetMaxGold");
	MarkNativeAsOptional("SC_IsInSteamGroup");
	
	MarkNativeAsOptional("SC_GetTargetInViewCone");
	MarkNativeAsOptional("SC_LOS");
	MarkNativeAsOptional("SC_DealDamage");
	MarkNativeAsOptional("SC_GetWar3DamageDealt");
	MarkNativeAsOptional("SC_GetDamageIsBullet");
	MarkNativeAsOptional("SC_ForceDamageIsBullet");
	MarkNativeAsOptional("SC_GetDamageStack");
	MarkNativeAsOptional("SC_FlashScreen");
	MarkNativeAsOptional("SC_ShakeScreen");
	MarkNativeAsOptional("SC_SpawnPlayer");
	MarkNativeAsOptional("SC_CachedAngle");
	MarkNativeAsOptional("SC_CachedPosition");
	MarkNativeAsOptional("SC_CachedDucking");
	MarkNativeAsOptional("SC_CachedWeapon");
	MarkNativeAsOptional("SC_CachedClip1");
	MarkNativeAsOptional("SC_CachedAmmo");
	MarkNativeAsOptional("SC_CachedDeadClip1");
	MarkNativeAsOptional("SC_CachedDeadAmmo");
	MarkNativeAsOptional("SC_CachedDeadWeaponName");
	MarkNativeAsOptional("SC_IsUbered");
	MarkNativeAsOptional("SC_HasFlag");
	MarkNativeAsOptional("SC_IsCloaked");
	MarkNativeAsOptional("SC_DamageModPercent");
	MarkNativeAsOptional("SC_TF_ParticleToClient");
	MarkNativeAsOptional("SC_HealToMaxHP");
	MarkNativeAsOptional("SC_HealToBuffHP");
	MarkNativeAsOptional("SC_DecreaseHP");
	MarkNativeAsOptional("SC_CooldownMGR");
	MarkNativeAsOptional("SC_SkillCooldownOnSpawn");
	MarkNativeAsOptional("SC_CooldownRemaining");
	MarkNativeAsOptional("SC_CooldownReset");
	MarkNativeAsOptional("SC_SkillNotInCooldown");
	MarkNativeAsOptional("SC_PrintSkillIsNotReady");
	
	// Buff system
	MarkNativeAsOptional("SC_SetBuff");
	MarkNativeAsOptional("SC_ApplyBuffSimple");
	MarkNativeAsOptional("SC_ResetBuffRace");
	MarkNativeAsOptional("SC_ResetAllBuffRace");
	MarkNativeAsOptional("SC_GetBuff");
	MarkNativeAsOptional("SC_GetBuffHasTrue");
	MarkNativeAsOptional("SC_GetBuffStackedFloat");
	MarkNativeAsOptional("SC_GetBuffSumFloat");
	MarkNativeAsOptional("SC_GetBuffMinFloat");
	MarkNativeAsOptional("SC_GetBuffMaxFloat");
	MarkNativeAsOptional("SC_GetBuffLastValue");
	MarkNativeAsOptional("SC_GetBuffMinInt");
	MarkNativeAsOptional("SC_GetBuffSumInt");
	MarkNativeAsOptional("SC_ReapplySpeed");
	MarkNativeAsOptional("SC_GetSpeedMulti");
	MarkNativeAsOptional("SC_ShowBuffs");
	MarkNativeAsOptional("SC_GetBuffLoopLimit");
	MarkNativeAsOptional("SC_IsBuffInvised");
	
	MarkNativeAsOptional("SC_RegisterDelayTracker");
	MarkNativeAsOptional("SC_TrackDelay");
	MarkNativeAsOptional("SC_TrackDelayExpired");
	MarkNativeAsOptional("SC_GetAimEndPoint");
	MarkNativeAsOptional("SC_GetAimTraceMaxLen");
	MarkNativeAsOptional("SC_WeaponRestrictTo");
	MarkNativeAsOptional("SC_GetWeaponRestriction");
	MarkNativeAsOptional("SC_GetPhysicalArmorMulti");
	MarkNativeAsOptional("SC_GetMagicArmorMulti");
	MarkNativeAsOptional("SC_GetCurrentWeaponEnt");
	MarkNativeAsOptional("SC_GetMinUltLevel");
	MarkNativeAsOptional("SC_GetDamageType");
	MarkNativeAsOptional("SC_GetDamageInflictor");
	MarkNativeAsOptional("SC_ChanceModifier");
	MarkNativeAsOptional("SC_IsOwnerSentry");
	MarkNativeAsOptional("SC_Hint");
	MarkNativeAsOptional("SC_GetSkill");
	MarkNativeAsOptional("SC_SetSkill");
	MarkNativeAsOptional("SC_SetPlayerProp");
	MarkNativeAsOptional("SC_GetPlayerProp");
	MarkNativeAsOptional("SC_GiveXPGold");
	MarkNativeAsOptional("SC_CreateCvar");
	MarkNativeAsOptional("SC_GetCvar");
	MarkNativeAsOptional("SC_SetCvar");
	MarkNativeAsOptional("SC_FindCvar");
	MarkNativeAsOptional("SC_CvarList");
	MarkNativeAsOptional("SC_GetCvarByString");
	MarkNativeAsOptional("SC_GetCvarActualString");
	MarkNativeAsOptional("SC_IsDeveloper");
	MarkNativeAsOptional("SC_SaveEnabled");
	MarkNativeAsOptional("SC_SaveXP");
	
	// LOG STUFF
	
	MarkNativeAsOptional("SC_Log");
	MarkNativeAsOptional("SC_LogError");
	MarkNativeAsOptional("SC_LogNotError");
	MarkNativeAsOptional("Create_SC_GlobalError");
	
	
	MarkNativeAsOptional("SC_CreateEvent");

	//MarkNativeAsOptional("SC_SetDiamondsEXT");
	//MarkNativeAsOptional("SC_GetDiamondsEXT");
	//MarkNativeAsOptional("SC_GetOwnsItem2EXT");
	//MarkNativeAsOptional("SC_SetOwnsItem2EXT");
	//MarkNativeAsOptional("SC_ExtShowShop2");

	// Skills
	MarkNativeAsOptional("SC_SuicideBomber");
	MarkNativeAsOptional("SC_Teleport");
	// Ward stuff
	MarkNativeAsOptional("SC_CreateWardBehavior");
	MarkNativeAsOptional("SC_GetWardBehaviorsLoaded");
	MarkNativeAsOptional("SC_GetWardBehaviorName");
	MarkNativeAsOptional("SC_GetWardBehaviorShortname");
	MarkNativeAsOptional("SC_GetWardBehaviorDesc");
	MarkNativeAsOptional("SC_GetWardBehaviorByShortname");
	MarkNativeAsOptional("SC_CreateWard");
	MarkNativeAsOptional("SC_GetWardBehavior");
	MarkNativeAsOptional("SC_GetWardLocation");
	MarkNativeAsOptional("SC_GetWardInterval");
	MarkNativeAsOptional("SC_GetWardRadius");
	MarkNativeAsOptional("SC_GetWardOwner");
	MarkNativeAsOptional("SC_GetWardData");
	MarkNativeAsOptional("SC_RemoveWard");

	//String Math
	MarkNativeAsOptional("SC_StringMath");

	// Dependency Engine
	MarkNativeAsOptional("SC_SetDependency");
	MarkNativeAsOptional("SC_RemoveDependency");
	MarkNativeAsOptional("SC_GetDependency");

	//MarkNativeAsOptional("SC_RaceBeforePluginStart");
	//MarkNativeAsOptional("SC_RaceOnPluginEnd");
	//MarkNativeAsOptional("SC_IsRaceReloading");
	
	MarkNativeAsOptional("SC_GetLevelEx");
	
	MarkNativeAsOptional("SC_ToggleCyborgSkin");
	
	//MarkNativeAsOptional("SC_SaveXPsh3");
	
	
	// SKILLS -- SKILLCRAFT
	
	MarkNativeAsOptional("SC_CreateNewSkill");
	MarkNativeAsOptional("SC_GetSkillName");
	MarkNativeAsOptional("SC_GetSkillShortname");
	MarkNativeAsOptional("SC_GetSkillString");
	MarkNativeAsOptional("SC_GetSkillsLoaded");
	MarkNativeAsOptional("SC_IsSkillUltimate");
	MarkNativeAsOptional("SC_GetSkillCount");
	MarkNativeAsOptional("SC_GetSkillName");
	MarkNativeAsOptional("SC_GetSkillDesc");
	MarkNativeAsOptional("SC_GetSkillOrder");
	MarkNativeAsOptional("SC_SkillHasFlag");
	MarkNativeAsOptional("SC_GetSkillList");
	MarkNativeAsOptional("SC_GetSkillIDByShortname");
	MarkNativeAsOptional("SC_GetSkillAccessFlagStr");
	MarkNativeAsOptional("SC_GetSkillMaxLimitTeam");
	MarkNativeAsOptional("SC_GetSkillMaxLimitTeamCvar");
	MarkNativeAsOptional("SC_IsSkillMastery");
	MarkNativeAsOptional("SC_IsSkillTalent");
	MarkNativeAsOptional("SC_IsSkillAbility");
	MarkNativeAsOptional("SC_IsSkillUltimate");
	MarkNativeAsOptional("SC_GetSkill");
	MarkNativeAsOptional("SC_SetSkill");
	MarkNativeAsOptional("SC_GetSkillType");
	MarkNativeAsOptional("SC_SetSkillCell");
	MarkNativeAsOptional("SC_GetSkillCell");
	
	// Deny -- SkillCraft_Engine_Events.sp
	
	MarkNativeAsOptional("SC_Denied");
	MarkNativeAsOptional("SC_Deny");


}

/**
 * Called when the plugin is ready.
 * this is called many times, increasing num each time 0.0-float(MAXSKILLS)*10 in 1 increments
 * USED FOR OFFICIAL PLUGINS ONLY
 */
forward On_SC_LoadSkillOrdered(num);

// For future skill reload:
forward On_SC_LoadSkillOrdered2(num,reloadid);


//Called for each category if the user opens the catted cr menu
forward Action:OnSC_DrawCategory(client,categoryindex,String:categoryname[]);

//Warcraft required executions, does common tasks, such as loading translations.
forward War3InterfaceExec();

// SKILLCRAFT STILL NEEDS TO REVIEW THE TRANSLATION FILES AND CONVERT
public War3InterfaceExec() {
	LoadTranslations("w3s._common.phrases");
}

/*
 * Natives and misc stocks
 * Natives and misc stocks
 * Natives and misc stocks
 * Natives and misc stocks
 * Natives and misc stocks
 * Natives and misc stocks
 * Natives and misc stocks
 * Natives and misc stocks
 * Natives and misc stocks
 * Natives and misc stocks
 * Natives and misc stocks
 */

native bool:SC_IsPlayerBoss(client);

native SC_ShowBuffs(client);
native SC_ShowSpeedBuff(client);

native SC_ToggleCyborgSkin(client,bool:toggle);

native bool:SC_AddCustomModel(client,String:weapon[],modelIndex,mdltype);
native bool:SC_RemoveCustomModel(client,String:weapon[],mdltype);

native SC_GetSC_Version(String:retstr[],maxlen);//str
//native SC_GetSC_Revision();//int
native SC_GetStatsVersion();//int

//Socket functions
native SC_Socket(String:url[],Function:callback);
native SC_Socket2(String:url[],String:postdata[],Function:callback);

//forces weapon drop, given a weapon entity
native SC_DropWeapon(client, weaponent);

/**
 * Checks if we are in the freeze time. Certain games support this, like CS.
 * @return True if so, false if not.
 *  
 */
#pragma deprecated
native bool:SC_InFreezeTime();

/* BEGIN GLOBAL VARS */
//retrieves specified values from the main SkillCraft plugin, see SC_Var enum in constants.inc, only those values are allowed
//this mostly used for accessing a variable without creating a special native just for it
//this returns any:, you should tag it if return value is not suppose to be normal integer. like Float:SC_GetVar( or Handle:SC_GetVar(
//most are temporary variables and this function should be called immidiately in the right functions
//examples SC_GetVar(OldRace)
//See SC_Var enum in constants to get a list
//Do not get/set vars arbitrarily unless you know what you are doing
native any:SC_GetVar(SC_Var:variabletoretrieve);
native any:SC_SetVar(SC_Var:variabletoretrieve,any:value);
/* END GLOBAL VARS */


/**
 * Registers a help command with the War3Source plugin for war3help
 * @param name: The name of the command. (max 64)
 * @param desc: The description of the command. (max 256) 
 * @noreturn
 */
native SC_CreateHelpCommand(String:name[],String:desc[]);


// Checks if a player is in steam group
// returns true if they are in steam group
native SC_IsInSteamGroup(client);

/**
 * Finds the best target within a player's view cone
 * Can be limited by max distance
 * function perfers closer target over a target that has less degrees 
 * @param client: Client index
 * @param max_distance: Optional, set to 0 to allow unlimited distance
 * @param include_friendlys: Optional, should we look for friendlys too?
 * @param cone_angle: Optional, view cone angle, SDK default is 23.0 degrees.
 * @param FilterFunction: Callback filter function, return false in this function to ignore entity.     
 */
native SC_GetTargetInViewCone(client,Float:max_distance=0.0,bool:include_friendlys=false,Float:cone_angle=23.0,Function:FilterFunction=INVALID_FUNCTION);

//generic immunity filter for ultimate
public bool:UltFilter(client)
{
	return (!SC_HasImmunity(client,Immunity_Ultimates));
}
//generic immunity filter for skills
public bool:SkillFilter(client)
{
	return (!SC_HasImmunity(client,Immunity_Skills));
}

///traces from client to target and see if they are in view of each other (Line of Signt - LOS)
native SC_LOS(client, target);

// The following are bit-flags for SC_DealDamage
// Does not appear useful in any way
#define DMG_GENERIC					0
#define DMG_CRUSH					(1 << 0)
#define DMG_BULLET					(1 << 1)
#define DMG_SLASH					(1 << 2)
#define DMG_BURN					(1 << 3)
#define DMG_VEHICLE					(1 << 4)
#define DMG_FALL					(1 << 5)
#define DMG_BLAST					(1 << 6)
#define DMG_CLUB					(1 << 7)
#define DMG_SHOCK					(1 << 8)
#define DMG_SONIC					(1 << 9)
#define DMG_ENERGYBEAM				(1 << 10)
#define DMG_PREVENT_PHYSICS_FORCE	(1 << 11)
#define DMG_NEVERGIB				(1 << 12)
#define DMG_ALWAYSGIB				(1 << 13)
#define DMG_DROWN					(1 << 14)
#define DMG_TIMEBASED				(DMG_PARALYZE | DMG_NERVEGAS | DMG_POISON | DMG_RADIATION | DMG_DROWNRECOVER | DMG_ACID | DMG_SLOWBURN)
#define DMG_PARALYZE				(1 << 15)
#define DMG_NERVEGAS				(1 << 16)
#define DMG_POISON					(1 << 17)
#define DMG_RADIATION				(1 << 18)
#define DMG_DROWNRECOVER			(1 << 19)
#define DMG_ACID					(1 << 20)
#define DMG_SLOWBURN				(1 << 21)
#define DMG_REMOVENORAGDOLL			(1 << 22)
#define DMG_PHYSGUN					(1 << 23)
#define DMG_PLASMA					(1 << 24)
#define DMG_AIRBOAT					(1 << 25)
#define DMG_DISSOLVE				(1 << 26)
#define DMG_BLAST_SURFACE			(1 << 27)
#define DMG_DIRECT					(1 << 28)
#define DMG_BUCKSHOT				(1 << 29)

/**
 * Deal damage.
 * @param victim: Victim's client index.
 * @param damage: Damage to be dealt.
 * @param attacker: Optional, attacker client index. Pass 0 for none.
 * @param damage_type: Optional, damage bit-flags. See above for DMG_* defines.
 * @param weaponstr: Optional, weapon name for simulated damage.
 * @param SC_DMGOrigin: where the damage came from IE SKILL or ULTIMATE or ITEM  
 * @param SC_DMGTYPE: is this damage true (no armor) physical (physical armor/immunity)  or magic (magic armor/immunity)
 * @param respectVictimImmunity: should damage be blocked if victim has that type of immunity, accouts for ORIGIN immunity and DMG type. (SKILL, ULTIMATE, ITEM, |||| MAGIC AND PHYSICAL ) simplifies so that u dont have to check
 * @param countAsFirstDamageRetriggered: should this damage allow to be rehooked (creating a real hurt-event again)? this may cause infinite loops!  Yes to combime with items and other skills only if its not in a damage hook itself. (infinite loop triggering)
 * @param noWarning: Prevent warning print when using DealDamage from a event where it's error prone
 * @return bool: did damage go through, false if player was immune to that damage type or damage was zero or something else failed
 */
native bool:SC_DealDamage(victim,damage,attacker=0,damage_type=DMG_GENERIC,String:weaponNameStr[], SC_DamageOrigin:SC_DMGORIGIN=SC_DMGORIGIN_UNDEFINED , SC_DamageType:SC_DMGTYPE=SC_DMGTYPE_MAGIC , bool:respectVictimImmunity=true , bool:countAsFirstDamageRetriggered=false, bool:noWarning=false);

//get the actual damage dealt from SC_DealDamage, because real damage is different after taking account to magic/physical armor
//u wana call this immediately after SC_DealDamage cuz this is a single global variable. when someone else calls SC_DealDamage it will be changed
native SC_GetWar3DamageDealt();

///is last damage a bullet first triggered damage? works on posthurt and sdkhookdmgall
//is the damange number right now, was it trigered by bullet type attack, or a warcraft type attack
native SC_GetDamageIsBullet();

native SC_ForceDamageIsBullet();
// if u do damage within a takedmg, the original damage may be nullified as non bullet, 
//use this function after you have dealt damage inside a takedmg
//so you can allow other isdmgbullet proc

//get the depth of the damage stack, usually 1 or more
native SC_GetDamageStack();

// MOVED TO SC_PLAYERPROP.INC
/*
stock bool:ValidPlayer(client,bool:check_alive=false,bool:alivecheckbyhealth=false) {
	if(client>0 && client<=MaxClients && IsClientConnected(client) && IsClientInGame(client))
	{
		if(check_alive && !IsPlayerAlive(client))
		{
			return false;
		}
		if(alivecheckbyhealth&&GetClientHealth(client)<1) {
			return false;
		}
		return true;
	}
	return false;
}*/

//is a buff index valid? X > 0 and X <  MaxBuffLoopLimitTemp
stock ValidBuff(SC_Buff:buffindex) {
	if(_:buffindex>=0&&_:buffindex<MaxBuffLoopLimit) {
		return true;

	}
	ThrowError("invalid buff index (%d)",buffindex);
	return false;
}

stock bool:ValidSkill(skillid_) {
	return bool:(skillid_>0&&skillid_<=SC_GetSkillsLoaded());
}

/**
 * Stock, checks if a player is near any entity in a datapack of entities, again by name.
 * @param client: Client's index.
 * @param hEnts: Datapack of entity names.
 * @param pack_size: Size of datapack.
 * @param distance: Optional, how far is "near."
 * @return ADT array of results, otherwise INVALID_HANDLE.
 * DO NOT FORGET TO CloseHandle() the results if they don't equal INVALID_HANDLE!!!  
 */
stock Handle:SC_NearEntsByName(client,Handle:hEnts,pack_size,Float:distance=150.0)
{
	new Handle:hResults=CreateArray();
	ResetPack(hEnts);
	for(new x=0;x<pack_size;x++)
	{
		new String:ent_name[128];
		ReadPackString(hEnts,ent_name,sizeof(ent_name));
		new Handle:result_found=SC_NearEntByName(client,ent_name,distance);
		if(result_found!=INVALID_HANDLE)
		{
			new size=GetArraySize(result_found);
			for(new y=0;y<size;y++)
			{
				PushArrayCell(hResults,GetArrayCell(result_found,y));
			}
			CloseHandle(result_found);
		}
	}
	if(GetArraySize(hResults)>0)
	return hResults;
	else
	{
		CloseHandle(hResults);
		return INVALID_HANDLE;
	}
}

stock Handle:SC_NearEntByName(client,String:ent_name[],Float:distance)
{
	if(distance<0.0)
	return INVALID_HANDLE; // wtf? lol
	if(client>0 && client<=MaxClients && IsClientConnected(client) && IsClientInGame(client) && IsPlayerAlive(client))
	{
		new Handle:hResults=CreateArray();
		new Float:curPos[3];
		GetClientAbsOrigin(client,curPos);
		new ent=0;
		while((ent=FindEntityByClassname(ent,ent_name))>0)
		{
			if(!IsValidEdict(ent)) continue;
			new Float:entPos[3];
			GetEntPropVector(ent,Prop_Send,"m_vecOrigin",entPos);
			new Float:dist=GetVectorDistance(curPos,entPos);
			if(dist<=distance)
			{
				PushArrayCell(hResults,ent);
			}
		}
		if(GetArraySize(hResults)>0)
		{
			return hResults;
		}
		else
		{
			CloseHandle(hResults);
		}
	}
	return INVALID_HANDLE;
}
/**
 * Stock, checks if a player is near an engineer building.
 * @param client: Client's index.
 * @param distance: Optional, how far is "near."
 * @return ADT array of results, otherwise INVALID_HANDLE
 * DO NOT FORGET TO CloseHandle() the results if they don't equal INVALID_HANDLE!!! 
 */
stock Handle:SC_NearBuilding(client,Float:distance=150.0)
{
	new Handle:hEnts=CreateDataPack();
	WritePackString(hEnts,"obj_dispenser");
	WritePackString(hEnts,"obj_sentrygun");
	WritePackString(hEnts,"obj_teleporter_entrance");
	WritePackString(hEnts,"obj_teleporter_exit");
	new Handle:result=SC_NearEntsByName(client,hEnts,4,distance);
	CloseHandle(hEnts);
	return result;
}

// THE FOLLOWING NATIVES RETRIEVE DATA CACHED ONGAMEFRAME!
// THE FUNCTIONS NAMED SC_CachedDead* ARE VALUES SET WHEN THE PLAYER DIES
// THESE ARE ADVANCED FUNCTIONS, CHANCES ARE IF U DON'T KNOW WHAT THEY MEAN
// YOU PROBABLY DON'T HAVE TO USE THEM

/**
 * Get last cached player eye angle.
 * @param client: Client index
 * @param angle[3]: Output array
 * @noreturn
 */
native SC_CachedAngle(client,Float:angle[3]);

/**
 * Get last cached player position.
 * @param client: Client index
 * @param position[3]: Output array
 * @noreturn
 */
native SC_CachedPosition(client,Float:position[3]);

/**
 * Get last cached player ducking state.
 * @param client: Client index
 * @return True or false.
 */
native bool:SC_CachedDucking(client);

/**
 * Get cached weapon entity based on iterator.
 * This function is usually called from a loop. 
 * @param client: Client index
 * @param weapon_iterator: Number from 0-9. 
 * @return Weapon entity, 0 if none.
 */
native SC_CachedWeapon(client, weapon_iterator);

/**
 * Get cached weapon entity "clip1" based on iterator.
 * This function is usually called from a loop. 
 * @param client: Client index
 * @param weapon_iterator: Number from 0-9. 
 * @return Value of clip1.
 */
native SC_CachedClip1(client, weapon_iterator);

/**
 * Get cached ammo of a player with a specific weapon ID.
 * This function is usually called from a loop. 
 * @param client: Client index
 * @param game_weapon_id: Game specific weapon identifier, this is constant for each weapon. 
 * @return Value of iAmmo.
 */
native SC_CachedAmmo(client, game_weapon_id);

/**
 * Get cached weapon entity "clip1" of iterator, only changes when a player dies.
 * This function is usually called from a loop. 
 * @param client: Client index
 * @param weapon_iterator: Number from 0-9. 
 * @return Value of clip1 from last death.
 */
native SC_CachedDeadClip1(client, weapon_iterator);

/**
 * Get cached ammo of a player with a specific weapon ID, only changes when a player dies.
 * This function is usually called from a loop. 
 * @param client: Client index
 * @param game_weapon_id: Game specific weapon identifier, this is constant for each weapon. 
 * @return Value of iAmmo from last death.
 */
native SC_CachedDeadAmmo(client, game_weapon_id);

/**
 * Get cached weapon name of iterator, only changes when a player dies.
 * This function is usually called from a loop, sets output_buffer to "" if no weapon at iterator. 
 * @param client: Client index
 * @param weapon_iterator: Number from 0-9.
 * @param output_buffer: Output buffer
 * @param output_size: Size of output buffer.   
 * @noreturn
 */
native SC_CachedDeadWeaponName(client,weapon_iterator,String:output_buffer[],output_size);

/**
 * Is player ubered (TF2)
 * @param client:
 * @return: true false
 */

stock bool:SC_IsUbered(client)
{
	new m_nPlayerCond = FindSendPropInfo("CTFPlayer","m_nPlayerCond") ;
	new cond = GetEntData(client, m_nPlayerCond);
	if(cond & 32)
	{
		return true;
	}
	return false;
}


/**
 * Is player carrying intellegence
 * @param client:
 * @return: true false
 */
stock bool:SC_HasFlag(client)
{
	new ent = -1;
	while ((ent = FindEntityByClassname(ent, "item_teamflag")) != -1)
	{
		if (GetEntPropEnt(ent, Prop_Data, "m_hOwnerEntity")==client)
			return true;
	}
	return false;
}


/**
 * Is player cloaked
 * @param client:
 * @return: true false
 */
 

stock bool:SC_IsCloaked(client)
{
	new m_nPlayerCond = FindSendPropInfo("CTFPlayer","m_nPlayerCond") ;
	new cond = GetEntData(client, m_nPlayerCond);
	if(cond & 16)
	{
		return true;
	}
	return false;
}

/*
 * forces the damage to be multiplied by @num
 * shall only be done inside SDKHOOKS damage forward (when damage hasnt been dealt yet) 
 * @noreturn
 */
native SC_DamageModPercent(Float:num);

//Sends a particle to client like "miss_text"
stock SC_TF_ParticleToClient(clienttoshowto,String:particlestr[],Float:pos[3])
{
	//GetNativeString(2, particlestr, sizeof(particlestr));
	//GetNativeArray(3,pos,3);
	return TE_ParticleToClient(clienttoshowto,particlestr,pos);
}


//LO AND BEHOLD THE COOLDOWN MANAGER, YOUR LIFE SIMPLIFIED!!!
//we essentially move the cooldown system out of our races into our main plugin
/**
 * cooldown manager
 * basically self explainatory parameters, creates a cooldown for a skill (term skill used here is generic for skill/ability/ultimate)
 * printMsgOnExpireByTime prints message to client (if alive and same race) when this skill expires by time (will not print when expired by spawn or death or force reset)
 * The skill name of the skill will be in ready and not ready messages.
 * when a cooldown expires (by time, by death, by spawn, by force reset), it will forward to OnCooldownExpired(....) forward, use if u need to
 * @noreturn
 * 
 * Usually the first 4 parameters are enough  
 */
native SC_CooldownMGR(client,Float:cooldownTime,skillid, bool:resetOnSpawn=true,bool:printMsgOnExpireByTime=true);

//tells the cooldown manager to create a predefined cooldown time when player spawns with that race. 
//cooldown is created regardless of resetOnSpawn in SC_CooldownMGR(...) calls
//only prints expired if client remains that race
//set this ONCE when u register your skills
native SC_SkillCooldownOnSpawn(skillid,Float:cooldownTime,bool:printmsgonexpire=true);

/**
 * how much time is left on this particular cooldown?
 * returns an int (rounted up from the float)
 */
native SC_CooldownRemaining(client, skillid);

/**
 * basically make this cooldown expire, this expiration is not considered "by time"
 */
native SC_CooldownReset(client, skillid);

/**
 * is this skill NOT in COOLDOWN? YOU NEED TO CHECK IF CLIENT HAS LEVELED THIS SKILL FIRST, THIS IS ONLY COOLDOWN RELATED
 * you would only do this if this skill has a cooldown and u called SC_CooldownMGR
 * printTextIfNotReady=true will print a "not ready" message
 */
native bool:SC_SkillNotInCooldown(client,skillid,bool:printTextIfNotReady=false);

/**
 * prints Skill Is Not Ready
 */
native SC_PrintSkillIsNotReady(client, skillid);

//DELAY TRACKER
//DELAY TRACKER
//DELAY TRACKER
//DELAY TRACKER
//DELAY TRACKER
//DELAY TRACKER

///registers a tracker and returns an index that you must keep. usually do this for each each player or once if global
// Register once on plugin start please!
//returns -1 if tracker is full. LogErrors on Full
/*
 usage:

 register tracker
 create delay

 repeat:{
 expired?
 create delay
 }

 */
native SC_RegisterDelayTracker();

//create a delay
native SC_TrackDelay(trackerIndex,Float:delay);

//did the delay expire?
native SC_TrackDelayExpired(trackerIndex);

///PLAYER  TRACE
///PLAYER  TRACE
///PLAYER  TRACE
///PLAYER  TRACE
///PLAYER  TRACE

//get location of where the player is aiming (trace to the end of your crosshair)
native SC_GetAimEndPoint(client,Float:endpos[3]);

//get location of where the player is aiming (trace to the end of your crosshair) limited by distance
native SC_GetAimTraceMaxLen(client,Float:endpos[3],Float:maxdistance);

//simple weapon restriction:    pass "weapon_knife,weapon_hegrenade" to only allow these weapons, separated by comma. 
//pass "" to allow all weapons again
//c4 etc is automatically allowed
//to override other restrictions, use a higher priority
//use 1 priorty for ur base race restrictions, USE AT OWN RISK!
native SC_WeaponRestrictTo(client,skillid,String:onlyallowedweaponsnames[],priority=1);

//get weaponlist
native SC_GetWeaponRestriction(client,skillid,String:buffer[],maxlength);

native Float:SC_GetPhysicalArmorMulti(client); //damage multipler for client by accounting for physical armor (warcraft physical armor, not cs armor)
native Float:SC_GetMagicArmorMulti(client); //damage multipler for client by accounting for magic armor

native SC_GetCurrentWeaponEnt(client); //get the entity of the current (active) weapon


native SC_GetMinUltLevel();

//force all supported war3 plugins into failed mode (pause plugin)
native SC_Failed(String:reason[]);

//return the game damagetype (burn, laser, etc) of the last damage (TakeDmg forward)
native SC_GetDamageType();
//get inflictor of the last damage (TakeDmg forward) (ie sentry gun  is a different object than the attacker itself)
native SC_GetDamageInflictor();

/**
 * Use this for getting a chance modifier in OnWar3TakeDamage!!
 * This is a cvar based value used for lowering chance of skill activation when a weapon such as flamethrower inflicts damage many times over a period of time.
 * If you are making a skill that has a high chance, example 1 in 10, it is advised to change it to something like 10 in 100 if using GetRandomInt, however if you are using GetRandomFloat with the chance modifier*original chance then it shouldn't be an issue. 
 * @param attacker: Attacker's client index.
 * @param inflictor: Inflictor entity index. (ie sentry gun)
 * @param damagetype: Type of damage.
 * @return Float modifier, 1.0 for 100% chance otherwise percentage between 0.0 and 1.0
 */

//helper, directly uses last inflictor and damagetype
// Acts like a DPS limiter
native Float:SC_ChanceModifier(attacker);

/**
 * Basically checks to see if this is a Owner's sentry.
 *
 * best use inside OnSC_TakeDmgBullet or OnSC_TakeDmgBullet or SDKHooks calls that have inflictors
 * where you can use this code:
 *  new inflictor = SC_GetDamageInflictor();
 *  then pass the inflictor as the entity below:
 *
 * @param client: client you wish to check as the owner
 * @param UseInternalInflictor: true if you wish the native to grab the SC_GetDamageInflictor for you.
 *         ^ only use if you are using inside a OnSC_TakeDamage function type, else use your own
 *         (Default true)
 * @param ExternalInflictor: entity you wish to check that maybe a sentry / optional
 *        Make sure you put UseInternalInflictor as false.
 *
 * @param return: true if the client is the sentry owner and the entity is the owned sentry
 *
 */
native bool:SC_IsOwnerSentry(client,bool:UseInternalInflictor=true,ExternalInflictor=0);

//print via hint engine. format accepts translations
native SC_Hint(client,SC_HintPriority:type=HINT_LOWEST,Float:duration=5.0,String:format[],any:...);

//for activatable skills only
stock bool:SkillAvailable(client,skillnumber,bool:printCooldown=true,bool:checksilenced=true,bool:printSilenced=true) {
	return SC_SkillNotInCooldown(client,skillnumber,printCooldown)&& (!checksilenced||!Silenced(client,printSilenced));
}

stock SC_SetMaxHP_INTERNAL(client, maxhp) {
	//	DP("set to %d",maxhp);
	SC_SetPlayerProp(client, iMaxHP, maxhp);
}
stock SC_GetMaxHP(client) {
	//DP("add %d",SC_GetBuffSumInt(client,iAdditionalMaxHealth));
	return SC_GetPlayerProp(client, iMaxHP);//+ SC_GetBuffSumInt(client,iAdditionalMaxHealth);
}
stock bool:SC_IsPlayerXPLoaded(client) {
	return SC_GetPlayerProp(client,xpLoaded);
}
// After a player is assigned a race in DatabaseXP
// This is the event that happens after the PlayerXPLoaded is assigned a variable.
stock bool:SC_IsPlayerRaceLoaded(client) {
	return SC_GetPlayerProp(client,dbRaceSelected);
}

stock SC_SetPoints(client, newgold) {
	SC_SetPlayerProp(client, total_points, newgold);
}
stock SC_GetPoints(client) {
	return SC_GetPlayerProp(client, total_points);
}

stock SC_IsDeveloper(client)
{
  if(ValidPlayer(client)){
    return SC_GetPlayerProp(client,isDeveloper);
  }
  return false;
}

///use SC_GetVar(hDatabase) to get the handle to the database which your xp is saved, so you dont have to connect again for your addon scipts

native bool:SC_SaveEnabled();
native SC_SaveXP(client, skillid);

native SC_Log(const String:fmt[],any:...);
native SC_LogError(const String:fmt[],any:...);
native SC_LogNotError(const String:fmt[],any:...);

//Skills
native SC_SuicideBomber(client, Float:location[], Float:damage, race_skillid, Float:radius, bool:effect=true);

//disabled due to human race requirements..for now
//native bool:SC_Teleport(client, Float:distance);

/**
 * Creates a new ward behavior. This will allow us to make ward effects modular, so people
 * can make their own ward types! Currently I don't know what I'm going to do with the name
 * and description fields, but there is definitely room for expansion of features with this
 * model.
 *
 * @param shortname: short name for the behavior
 * @param name: full name for the behavior (unused right now)
 * @param desc: description of ward behavior (unused right now)
 * @return ward behavior ID or 0 if ward behavior limit reached
 */
native _:SC_CreateWardBehavior(String:shortname[],String:name[],String:desc[]);

/**
 * Gets the number of ward behaviors loaded.
 *
 * @return number of ward behaviors loaded
 */
native _:SC_GetWardBehaviorsLoaded();
native SC_GetWardBehaviorName(id,String:retstr[],maxlen);
native SC_GetWardBehaviorShortname(id,String:retstr[],maxlen);
native SC_GetWardBehaviorDesc(id,String:retstr[],maxlen);

/**
 * Gets the ID of the ward behavior given its shortname.
 *
 * @param shortname: short name for the behavior
 * @return ward behavior ID or -1 if it does not exist
 */
native _:SC_GetWardBehaviorByShortname(String:shortname[]);

/**
 * Creates a ward.
 * 
 * Odd/special cases:
 * If a ward is created with selfInflict=false, but affinity=SELF_ONLY, you get a ward that does nothing, essentially.
 * If a ward is created with a negative/zero duration, it will last until map change or until it is removed manually.
 * 
 * @param client: owner id
 * @param location: ward location
 * @param radius: ward effect radius
 * @param duration: ward duration. If negative or zero, duration is infinite (until map change). Don't forget to remove the ward!
 * @param pulseInterval: time between effect triggerings
 * @param behavior: ward behavior short name. Every time a ward is triggered, this behavior is called on
 * @param data: Array of data to pass to the ward. This is used by the ward behavior for things like damage per skill level.
 * @param selfInflict: whether or not this ward applies effects to its owner
 * @param affinity: the targeting affinity for this ward. ENEMIES, ALLIES, ALL, or SELF_ONLY
 * @return ID for the ward created or -1 if the ward was not created
 */
native _:SC_CreateWard(client, Float:location[], radius, Float:duration, Float:pulseInterval, String:behavior[], any:data[]= {0}, bool:selfInflict=false, SC_WardAffinity:affinity=ENEMIES);

/**
 * Gets a specific ward's behavior.
 *
 * Important: This refers to a specific instance of a ward. That is, if you know the index of a
 * ward that has been placed inside the game, this will tell you what its behavior ID is.
 *
 * @param wardindex: ward ID
 * @return Ward behavior ID or -1 if the ward does not exist
 */
native _:SC_GetWardBehavior(wardindex);
native SC_GetWardLocation(wardindex, Float:location[]);
native Float:SC_GetWardInterval(wardindex);
native _:SC_GetWardRadius(wardindex);
native _:SC_GetWardOwner(wardindex);
native SC_GetWardData(wardindex, any:data[]);

/**
 * Removes a ward given an id
 * @param wardindex: ward id
 * @return True if the ward was removed. False otherwise
 */
native bool:SC_RemoveWard(wardindex);

native SC_StringMath(String:equation[]);

native SC_HasDiedThisFrame(client);

/**
 * Adds a dependency on a skill
 *
 * @param iSkillID		 Skill ID
 * @param iRequiredSkill Required Skill ID
 * @return				 true on success, otherwhise false!
 * @error				 Thrown on invalid param num/race
 */
native bool:SC_SetDependency(iSkillID, iRequiredSkill);

/**
 * Removes any known dependency from a skill(if any)
 * NOTE: you should be able to call this safetly without having to bother about anything,
 * since no error will be thrown if there currently aren't any active dependencys on this
 *
 * @param iSkillID		 Skill ID
 * @noreturn
 * @error				 Thrown on invalid param num/race
 */
native SC_RemoveDependency(iSkillID);

/**
 * Retrieves various informations about a depending skill
 * NOTE: This can be called to check if there is any dependency or not
 *
 * @param iSkillID			Skill ID
 * @param iOtherSkillID		Target skill to get informations from
 * @return					Retrieved information about the dependency
 * @error					Thrown on invalid param num/race
 */
native SC_GetDependency(iSkillID);

// BOT THINGS!!

/**
 * Force a fake client to distribute his skillpoints
 *
 * @param client: client index
 */
native bool:SC_bots_distribute_sp(client);

/**
 * FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS
 * FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS
 * FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS
 * FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS
 * FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS
 * FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS
 * FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS
 * FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS    
 * FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS
 * FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS
 * FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS
 * FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS
 * FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS
 * FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS
 * FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS
 * FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS    
 * FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS
 * FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS
 * FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS
 * FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS
 * FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS
 * FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS
 * FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS
 * FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS    
 * FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS
 * FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS
 * FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS
 * FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS
 * FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS
 * FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS
 * FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS
 * FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS    
 * FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS
 * FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS
 * FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS
 * FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS
 * FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS
 * FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS
 * FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS
 * FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS    
 */
 
///general events, see SC_EVENT enum in constants
///client may not always matter
forward On_SC_Event(SC_EVENT:event,client);

native SC_CreateEvent(SC_EVENT:event,client);

//simple system for stopping actions, send a specific event with optinal player, those hooking can use W3Deny() to deny
forward On_SC_Denyable(SC_DENY:event,client);
native bool:SC_Denied(SC_DENY:event,client); //returns FALSE if NOT DENIED
stock bool:SC_Denyable(SC_DENY:event,client) {
	return !SC_Denied(event,client);
}
native SC_Deny();

forward SC_FailedSignal(String:str[]);

/* interface side implementation, do not use */
public SC_FailedSignal(String:str[]) {
	LogError(str); //must be a non dependent native log error
	SetFailState(str);
}

//forward CheckWar3Compatability(String:w3mainInterfVersion[]);

/* interface side implementation, do not use */
//public CheckWar3Compatability(String:w3mainInterfVersion[]) {
	//if(!StrEqual(interfaceVersion,w3mainInterfVersion)) {
		//SC_LogError("FATAL ERROR, PLUGIN COMPILED INTERFACE VERSION (%s) IS DIFFERENT FROM WAR3SOURCE BASE VERSION (%s). Please Compile With Latest Version!!!",interfaceVersion,w3mainInterfVersion);
		//SetFailState("FATAL ERROR, PLUGIN COMPILED INTERFACE VERSION (%s) IS DIFFERENT FROM WAR3SOURCE BASE VERSION (%s). Please Compile With Latest Version!!!",interfaceVersion,w3mainInterfVersion);
	//}
//}

stock bool:CanSelectSkill(client,skillid,bool:silence=false) {
	if(!ValidSkill(skillid))
	{
		//SC_ChatMessage(client,"Skill is not a valid skill.");
		return false;
	}
	SC_SetVar(EventArg1,skillid);
	SC_SetVar(EventArg2,silence);
	new bool:value=SC_Denyable(DN_CanSelectSkill,client);
	//DP("dp %d",value);
	if(value==false && SC_IsDeveloper(client)) {
		//DP("dp2 %d",value);
		SC_ChatMessage(client,"You are normally not allowed to select this skill, but since you are developer we will allow you to select this skill");

		return true;
	}
	return value;
}

stock ShowChangeSkillMenu(client) {
	SC_CreateEvent(DoShowChangeSkillMenu, client);
}

/*
 * STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS
 * STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS
 * STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS
 * STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS
 * STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS
 * STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS
 * STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS
 * STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS
 * STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS
 * STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS
 * STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS
 * STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS
 * STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS
 * STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS
 * STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS
 * STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS
 * STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS
 * STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS
 * STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS
 */

stock GetRealClientCount( bool:inGameOnly = true ) {
	new clients = 0;
	for(new i=1; i<GetMaxClients()+1; i++) {
		if(((inGameOnly) ? IsClientInGame(i): IsClientConnected(i)) && !IsFakeClient(i)){
			clients++;
		}
	}
	return clients;
}

stock Float:TF2_GetClassSpeed(TFClassType:class)
{
		switch (class)
		{
				case TFClass_Scout:     return 400.0;
				case TFClass_Soldier:   return 240.0;
				case TFClass_DemoMan:   return 280.0;
				case TFClass_Medic:     return 320.0;
				case TFClass_Pyro:      return 300.0;
				case TFClass_Spy:       return 300.0;
				case TFClass_Engineer:  return 300.0;
				case TFClass_Sniper:    return 300.0;
				case TFClass_Heavy:     return 230.0;
		}
		return 0.0;
}

 //=======================================================================
//                                 Stocks
//=======================================================================
stock GetFlagCarrier(team)
{
	new ent = -1;
	while ((ent = FindEntityByClassname(ent, "item_teamflag")) != -1)
	{
		new owner = GetEntPropEnt(ent, Prop_Data, "m_hOwnerEntity");
		if (owner > 0)
		{
			if (GetClientTeam(owner) == team)
				return owner;
		}
	}
	return -1;
}

stock TE_ParticleToClient(client,
	String:Name[],
	Float:origin[3]=NULL_VECTOR,
	Float:start[3]=NULL_VECTOR,
	Float:angles[3]=NULL_VECTOR,
	entindex=-1,
	attachtype=-1,
	attachpoint=-1,
	bool:resetParticles=true,
	Float:delay=0.0)
{
	// find string table
	new tblidx = FindStringTable("ParticleEffectNames");
	if (tblidx==INVALID_STRING_TABLE) 
	{
		LogError("Could not find string table: ParticleEffectNames");
		return 0;
	}
	
	// find particle index
	new String:tmp[256];
	new count = GetStringTableNumStrings(tblidx);
	new stridx = INVALID_STRING_INDEX;
	new i;
	for (i=0; i<count; i++)
	{
		ReadStringTable(tblidx, i, tmp, sizeof(tmp));
		if (StrEqual(tmp, Name, false))
		{
			stridx = i;
			break;
		}
	}
	if (stridx==INVALID_STRING_INDEX)
	{
		LogError("Could not find particle: %s", Name);
		return 0;
	}
	
	TE_Start("TFParticleEffect");
	TE_WriteFloat("m_vecOrigin[0]", origin[0]);
	TE_WriteFloat("m_vecOrigin[1]", origin[1]);
	TE_WriteFloat("m_vecOrigin[2]", origin[2]);
	TE_WriteFloat("m_vecStart[0]", start[0]);
	TE_WriteFloat("m_vecStart[1]", start[1]);
	TE_WriteFloat("m_vecStart[2]", start[2]);
	TE_WriteVector("m_vecAngles", angles);
	TE_WriteNum("m_iParticleSystemIndex", stridx);
	if (entindex!=-1)
	{
		TE_WriteNum("entindex", entindex);
	}
	if (attachtype!=-1)
	{
		TE_WriteNum("m_iAttachType", attachtype);
	}
	if (attachpoint!=-1)
	{
		TE_WriteNum("m_iAttachmentPointIndex", attachpoint);
	}
	TE_WriteNum("m_bResetParticles", resetParticles ? 1 : 0); 
	if(client==0)
	{
		TE_SendToAll(delay);
	}
	else
	{
		TE_SendToClient(client, delay);
	}
	return 0;
}	


stock TF2_GetCurrentWeaponClass(client, String:name[], maxlength)
{
	if( client > 0 )
	{
		new index = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		if (index > 0)
			GetEntityNetClass(index, name, maxlength);
	}
}

stock TF2_GetHealingTarget(client)
{
	new String:classname[64];
	TF2_GetCurrentWeaponClass(client, classname, sizeof(classname));

	if( StrEqual(classname, "CWeaponMedigun") )
	{
		new index = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		if( GetEntProp(index, Prop_Send, "m_bHealing") == 1 )
		{
			return GetEntPropEnt(index, Prop_Send, "m_hHealingTarget");
		}
	}

	return -1;
}



stock TF_SetUberLevel(client, Float:uberlevel)
{
	new index = GetPlayerWeaponSlot(client, 1);
	if (index > 0)
		SetEntPropFloat(index, Prop_Send, "m_flChargeLevel", uberlevel*0.01);
}

stock Float:TF_GetUberLevel(client)
{
	new index = GetPlayerWeaponSlot(client, 1);
	if (index > 0)
		return GetEntPropFloat(index, Prop_Send, "m_flChargeLevel")*100.0;
	else
		return 0.0;
}

stock TF_SetCloakLevel(client, Float:cloaklevel)
{
	//new index = GetPlayerWeaponSlot(client, 1);
	//if (index > 0)
	if (ValidPlayer(client))
		SetEntPropFloat(client, Prop_Send, "m_flCloakMeter", cloaklevel);
}

stock Float:TF_GetCloakLevel(client)
{
	//new index = GetPlayerWeaponSlot(client, 1);
	if (ValidPlayer(client))
		return GetEntPropFloat(client, Prop_Send, "m_flCloakMeter");
	else
		return 0.0;
}


/**
 * Returns the client's Score. 
 *
 * @param client			Client's index.
 * @return					Score.
 */
stock SC_GetScore(client)
{
	return GetClientFrags(client);
}

/**
 * Sets the client's Score.
 *
 * @param client			Client's index.
 * @param value				Score.
 * @noreturn
 */
stock SC_SetScore(client, value)
{
	SetEntProp(client, Prop_Data, "m_iFrags", value);
}



#define MAX_MESSAGE_LENGTH 250

/** 
 * Prints a message in the chat area with [SkillCraft] pre-appended.
 * Support color tags: {default}, {green}, {lightgreen}, {red}, {blue}, {olive}.
 * 
 * @param client      Client index, pass 0 for message to all.
 * @param szMessage   Message (formatting rules).
 * @return            No return
 */
stock SC_ChatMessage(client, const String:szMessage[], any:...)
{
	if (client == 0)
	{
		decl String:szBuffer[MAX_MESSAGE_LENGTH];
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && !IsFakeClient(i))
			{
				SetGlobalTransTarget(i);
				VFormat(szBuffer, sizeof(szBuffer), szMessage, 3);
				Format(szBuffer, sizeof(szBuffer), "{green}[SkillCraft]{default} %s", szBuffer);
				CPrintToChat(i, szBuffer);
			}
		}
	}
	else
	{
		decl String:szBuffer[MAX_MESSAGE_LENGTH];
		SetGlobalTransTarget(client);
		VFormat(szBuffer, sizeof(szBuffer), szMessage, 3);
		Format(szBuffer, sizeof(szBuffer), "{green}[SkillCraft]{default} %s", szBuffer);
		CPrintToChat(client, szBuffer);
	}
}

/** 
 * Prints a message in the chat area with [SkillCraft] pre-appended.
 * Support color tags: {default}, {green}, {olive}, {teamcolor}.
 * 
 * @param client      Client index, pass 0 for message to all.
 * @param author      Author index whose color will be used for teamcolor tag.
 * @param szMessage   Message (formatting rules).
 * @return            No return
 */
stock SC_ChatMessageEx(client, author, const String:szMessage[], any:...)
{
	if (client == 0)
	{
		if (author < 0 || author > MaxClients)
		ThrowError("Invalid client index %d", author);

		if (!IsClientInGame(author))
		ThrowError("Client %d is not in game", author);

		decl String:szBuffer[MAX_MESSAGE_LENGTH];
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && !IsFakeClient(i))
			{
				//SetGlobalTransTarget(i);
				VFormat(szBuffer, sizeof(szBuffer), szMessage, 4);
				Format(szBuffer, sizeof(szBuffer), "{green}[SkillCraft]{default} %s",szBuffer);
				CPrintToChatEx(i, author, szBuffer);
			}
		}
	}
	else
	{
		decl String:szBuffer[MAX_MESSAGE_LENGTH];
		//SetGlobalTransTarget(client);
		VFormat(szBuffer, sizeof(szBuffer), szMessage, 4);
		Format(szBuffer, sizeof(szBuffer), "{green}[SkillCraft]{default} %s", szBuffer);
		CPrintToChatEx(client, author, szBuffer);
	}
}

stock bool:IS_PLAYER(x)
{
	if(x>0&&x<=MaxClients)
	return true;
	return false;
}

/*
 There are two ways to get admin
 //need 
 //good if you need the string to admin flag like "o" -> number
 id= native bool:GetAdminFlag(AdminId:id, AdminFlag:flag, AdmAccessMode:mode=Access_Effective);
 Admin_RCON,			
 Admin_Root,
 
 VS
 
 //good if u know the access level
 GetUserFlagBits(client)	
 
 ADMFLAG_RCON
 ADMFLAG_ROOT
 */

stock HasSMAccess(client, flag) {
	new flags = GetUserFlagBits(client);
	//DP("flags %d",flags);
	if (flags & (flag | ADMFLAG_ROOT)) //ADMFLAG_ROOT is "z"
	{
		return true;
	}

	return SC_IsDeveloper(client);
}

/* is a normal engine cvar empty (zero length, "") ? */
stock bool:CvarEmpty(Handle:sourcemod_convar) {
	static String:zzstr[32];
	return (GetConVarString(sourcemod_convar, zzstr, sizeof(zzstr))&&strlen(zzstr)<1);

}


//returns true/false on a chance cast. 1.0=100%, 0.1 = 10% chance
stock bool:SC_Chance(Float:chancepercent=1.0) {
	return (GetRandomFloat(0.0,1.0)<=chancepercent);
}

/**
 * Returns the amount of money you have in CS/CS:GO
 * When used in TF2 it returns the amount of money the player has in MVM
 */
stock GetCSMoney(client) {
	return GetEntProp(client, Prop_Send, "m_nCurrency");
}

/**
 * Sets the amount of money the player has in CS/CS:GO
 * When used in TF2 it sets the amount of money the player has in MVM
 */
stock SetCSMoney(client, newamount) {
	if (newamount < 0)
		newamount = 0;
	if (newamount > 32767)
		newamount = 32767;
	SetEntProp(client, Prop_Send, "m_nCurrency", newamount);
}

stock UTIL_Remove(entity) {
	if (IsValidEdict(entity))
		AcceptEntityInput(entity, "Kill");
}

stock SC_ShowSkillsInfo(client) {
	if (SC_GetSkill(client,mastery) > 0) {
		SC_SetVar(SkillinfoSkillToShow, SC_GetSkill(client,mastery));
		SC_CreateEvent(DoShowParticularSkillInfo, client);
	} else {
		SC_ChatMessage(client, "Select a mastery skill first!!/nsay changemastery");
		SC_SetVar(EventArg1,mastery);
		SC_CreateEvent(DoShowChangeSkillMenu, client);
	}
}

//get numver of players on the specified team (integer team)
stock PlayersOnTeam(team) {
	new num;
	for (new x = 1; x <= MaxClients; x++) {
		if (IsClientInGame(x) && GetClientTeam(x) == team) {
			num++;
		}
	}
	return num;
}

stock GetShortTeamName(team,String:retstr[],maxlen) {
	if(team==1) {
		Format(retstr,maxlen,"TF Spec");
		return;
	}
	if(team==TEAM_RED) {
		Format(retstr,maxlen,"TF RED");
		return;
	}
	if(team==TEAM_BLUE) {
		Format(retstr,maxlen,"TF BLU");
		return;
	}

	Format(retstr,maxlen,"Unknown Team");
	return;
}

stock GetRacesOnTeam(skillid, team, ignoreIfAdminSetRace = false) {
	new num;
	for (new y = 1; y <= MaxClients; y++) {

		if (ValidPlayer(y, false)) {

			if (SC_GetSkill(y,mastery) == skillid) {
				if (GetClientTeam(y) == team) {
					if (ignoreIfAdminSetRace&&SC_GetPlayerProp(y,SkillSetByAdmin)) {
					} else {
						num++;
					}
				}
			}
			if (SC_GetSkill(y,talent) == skillid) {
				if (GetClientTeam(y) == team) {
					if (ignoreIfAdminSetRace&&SC_GetPlayerProp(y,SkillSetByAdmin)) {
					} else {
						num++;
					}
				}
			}
			if (SC_GetSkill(y,ability) == skillid) {
				if (GetClientTeam(y) == team) {
					if (ignoreIfAdminSetRace&&SC_GetPlayerProp(y,SkillSetByAdmin)) {
					} else {
						num++;
					}
				}
			}
			if (SC_GetSkill(y,ultimate) == skillid) {
				if (GetClientTeam(y) == team) {
					if (ignoreIfAdminSetRace&&SC_GetPlayerProp(y,SkillSetByAdmin)) {
					} else {
						num++;
					}
				}
			}
		}
	}
	return num;
}

stock bool:SC_IsDamageFromMelee(const String:weapon[])
{
	return (// Logfile names
			StrEqual(weapon, "shovel") ||
			StrEqual(weapon, "wrench") ||
			StrEqual(weapon, "bat") ||
			StrEqual(weapon, "bonesaw") ||
			StrEqual(weapon, "bottle") ||
			StrEqual(weapon, "club") ||
			StrEqual(weapon, "fireaxe") ||
			StrEqual(weapon, "fists") ||
			StrEqual(weapon, "sandman") ||
			StrEqual(weapon, "pickaxe") ||
			StrEqual(weapon, "sword") ||
			StrEqual(weapon, "demoshield") ||
			StrEqual(weapon, "taunt_scout") ||
			StrEqual(weapon, "taunt_sniper") ||
			StrEqual(weapon, "taunt_pyro") ||
			StrEqual(weapon, "taunt_demoman") ||
			StrEqual(weapon, "taunt_heavy") ||
			StrEqual(weapon, "taunt_spy") ||
			StrEqual(weapon, "taunt_soldier")||
			StrEqual(weapon, "annihilator") ||
			StrEqual(weapon, "ubersaw") ||
			StrEqual(weapon, "axtinguisher") ||
			StrEqual(weapon, "gloves") ||
			StrEqual(weapon, "sandman") ||
			StrEqual(weapon, "unique_pickaxe") ||
			StrEqual(weapon, "robot_arm") ||
			StrEqual(weapon, "sledgehammer") ||
			StrEqual(weapon, "paintrain") ||
			StrEqual(weapon, "southern_hospitality") ||
			StrEqual(weapon, "wrench_golden") ||
			StrEqual(weapon, "tribalkukri") ||
			StrEqual(weapon, "battleaxe") ||
			StrEqual(weapon, "battleneedle") ||
			StrEqual(weapon, "powerjack") ||
			StrEqual(weapon, "holy_mackerel") ||
			StrEqual(weapon, "eternal_reward") ||
			StrEqual(weapon, "bushwacka") ||
			StrEqual(weapon, "gloves_running_urgently") ||
			StrEqual(weapon, "fryingpan") ||
			StrEqual(weapon, "headtaker") ||
			StrEqual(weapon, "ullapool_caber") ||
			StrEqual(weapon, "warrior_spirit") ||
			StrEqual(weapon, "candy_cane") ||
			StrEqual(weapon, "boston_basher") ||
			StrEqual(weapon, "back_scratcher") ||
			StrEqual(weapon, "claidheamohmor") ||
			StrEqual(weapon, "wrench_jag") ||
			StrEqual(weapon, "steel_fists") ||
			StrEqual(weapon, "lava_axe") ||
			StrEqual(weapon, "lava_bat") ||
			StrEqual(weapon, "warfan") ||
			StrEqual(weapon, "kunai") ||
			StrEqual(weapon, "demokatana") ||
			StrEqual(weapon, "shahanshah") ||
			StrEqual(weapon, "persian_persuader") ||
			StrEqual(weapon, "solemn_vow") ||
			StrEqual(weapon, "market_gardener") ||
			StrEqual(weapon, "saxxy") ||
			StrEqual(weapon, "eviction_notice") ||
			StrEqual(weapon, "disciplinary_action") ||
			StrEqual(weapon, "atomizer") ||
			StrEqual(weapon, "scout_sword") ||
			StrEqual(weapon, "mailbox") ||
			StrEqual(weapon, "big_earner") ||
			StrEqual(weapon, "the_maul") ||
			StrEqual(weapon, "nonnonviolent_protest") ||
			StrEqual(weapon, "nessieclub") ||
			StrEqual(weapon, "unarmed_combat") ||
			StrEqual(weapon, "voodoo_pin") ||
			StrEqual(weapon, "apocofists") ||
			StrEqual(weapon, "eureka_effect") ||
			StrEqual(weapon, "thirddegree") ||
			StrEqual(weapon, "scotland_shard") ||
			StrEqual(weapon, "sharp_dresser") ||
			StrEqual(weapon, "wrap_assassin") ||
			StrEqual(weapon, "spy_cicle") ||
			StrEqual(weapon, "holiday_punch") ||
			StrEqual(weapon, "black_rose") ||
			StrEqual(weapon, "lollichop") ||
			StrEqual(weapon, "unique_pickaxe_escape") ||
			StrEqual(weapon, "freedom_staff") ||
			// Weapon names
			StrEqual(weapon, "tf_weapon_bat") ||
			StrEqual(weapon, "tf_weapon_bat_wood") ||
			StrEqual(weapon, "tf_weapon_bat_fish") ||
			StrEqual(weapon, "tf_weapon_shovel") ||
			StrEqual(weapon, "saxxy") ||
			StrEqual(weapon, "tf_weapon_bat_giftwrap") ||
			StrEqual(weapon, "tf_weapon_fireaxe") ||
			StrEqual(weapon, "tf_weapon_sword") ||
			StrEqual(weapon, "tf_weapon_bottle") ||
			StrEqual(weapon, "tf_weapon_stickbomb") ||
			StrEqual(weapon, "tf_weapon_katana") ||
			StrEqual(weapon, "tf_weapon_fists") ||
			StrEqual(weapon, "tf_weapon_wrench") ||
			StrEqual(weapon, "tf_weapon_robot_arm") ||
			StrEqual(weapon, "tf_weapon_bonesaw") ||
			StrEqual(weapon, "tf_weapon_club") ||
			StrEqual(weapon, "tf_weapon_knife")
			);
	//return false;
}

stock bool:TF2_HasTheFlag(client)
{
	new ent = -1;
	while ((ent = FindEntityByClassname(ent, "item_teamflag")) != -1)
	{
		if (GetEntPropEnt(ent, Prop_Data, "m_hOwnerEntity")==client)
		return true;
	}
	return false;
}
stock TE_SetupKillPlayerAttachments(client) {
	TE_Start("KillPlayerAttachments");
	TE_WriteNum("m_nPlayer", client);
}

/// General callback for threaded queries.  No Actions
public SQLWar3GeneralCallback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	SQLCheckForErrors(hndl,error,"SQLWar3GeneralCallback");
}

//pass me a trie with key "query" = your query into originalqueryTrie
stock SQLCheckForErrors(Handle:hndl,const String:originalerror[],const String:prependstr[]="",Handle:originalqueryTrie=Handle:0) {
	new String:orignalquerystr[512];
	if(originalqueryTrie) {
		if(!GetTrieString(originalqueryTrie,"query",orignalquerystr,sizeof(orignalquerystr))) {
			LogError("SQLCheckForErrors: originalqueryTrie is not null but key 'query' not set from trie");
		}
		CloseHandle(originalqueryTrie);
		//DP("closed");
	}

	if(!StrEqual("", originalerror))
	LogError("SQL error: [%s] %s QUERY:%s", prependstr, originalerror,orignalquerystr);
	else if(hndl == INVALID_HANDLE)
	{
		decl String:err[512];
		SQL_GetError(hndl, err, sizeof(err));
		LogError("SQLCheckForErrors: [%s] %s QUERY:%s", prependstr, err,orignalquerystr);
	}
}

public bool:SQL_FastQueryLogOnError(Handle:DB,const String:query[]) {
	if(!SQL_FastQuery(DB,query)) {
		new String:error[256];
		SQL_GetError(DB, error, sizeof(error));
		LogError("SQLFastQuery %s failed, Error: %s",query,error);
		return false;
	}
	return true;
}

//normal query like SQL_QUERY, database must be locked 
stock bool:SQL_SC_NormalQuery(Handle:DB,String:querystr[]) {
	new Handle:result= SQL_Query(DB, querystr);
	if(result==INVALID_HANDLE) {
		new String:error[256];
		SQL_GetError(DB, error, sizeof(error));
		LogError("SQL_SC_NormalQuery %s failed, Error: %s",querystr,error);
		return false;
	}
	else {
		CloseHandle(result);
	}
	return true;
}
//fetch using column string
stock SC_SQLPlayerInt(Handle:query,const String:columnname[]) //fech from query
{
	new column;
	SQL_FieldNameToNum(query,columnname,column);
	decl String:result[16];
	SQL_FetchString(query,column,result,sizeof(result));
	return StringToInt(result);
}
//fetch using column string
stock SC_SQLPlayerFloat(Handle:query,const String:columnname[]) //fech from query
{
	new column;
	SQL_FieldNameToNum(query,columnname,column);
	decl String:result[16];
	SQL_FetchString(query,column,result,sizeof(result));
	return StringToFloat(result);
}
//fetch using column string
stock SC_SQLPlayerString(Handle:query,const String:columnname[],String:out_buffer[],size_out) //fech from query
{
	new column;
	if(SQL_FieldNameToNum(query,columnname,column))
	{
		SQL_FetchString(query,column,out_buffer,size_out);
		return true;
	}
	return false;
}

///add a column to table, be careful of parameters
///table should be locked!!!
stock AddColumn(Handle:DB,const String:columnname[],const String:datatype[],const String:table_name[])
{
	decl String:query[256];
	Format(query,256,"ALTER TABLE %s ADD COLUMN %s %s DEFAULT '0'",table_name,columnname,datatype);
	PrintToServer("[SkillCraft] Tried to ADD column in TABLE %s: %s",table_name,columnname);
	SQL_FastQueryLogOnError(DB,query);
}

///string?


// Stocks
stock StrToken(const String:inputstr[],tokennum,String:outputstr[],maxlen)
{
	new String:buf[maxlen+1];
	new cur_idx;
	new idx;
	new curind;
	idx=BreakString(inputstr,buf,maxlen);
	if(tokennum==1)
	{
		strcopy(outputstr,maxlen,buf);
		return;
	}
	curind=1;
	while(idx!=-1)
	{
		cur_idx+=idx;
		idx=BreakString(inputstr[cur_idx],buf,maxlen);
		curind++;
		if(tokennum==curind)
		{
			strcopy(outputstr,maxlen,buf);
			break;
		}
	}
}

stock StrTokenCount(const String:input[])
{
	decl String:buf[32];
	new cur_idx;
	new idx;
	new curind;
	while(idx!=-1)
	{
		cur_idx+=idx;
		idx=BreakString(input[cur_idx],buf,sizeof(buf));
		curind++;
	}
	return curind;
}

stock Float:GetPlayerDistance(client1,client2) {
	static Float:vec1[3];
	static Float:vec2[3];
	GetClientAbsOrigin(client1,vec1);
	GetClientAbsOrigin(client2,vec2);
	return GetVectorDistance(vec1,vec2);
}

//////MESSAGES


//prints [SC_S] You did %d damage to %name with SKILLNAME
//prints [SC_S] %name did %d damage to you with SKILLNAME
new String:zzname[32];
stock SC_PrintSkillDmgConsole(victim = 0, attacker, damage, skill_id) {
	GetClientName(victim, zzname, sizeof(zzname));
	new String:skillname[32];
	//SetTrans( attacker);
	SC_GetSkillName(skill_id, skillname, sizeof(skillname));
	PrintToConsole(attacker, "[SC_E] You did +%i damage to %s with %s", damage, zzname, skillname);

	if (victim > 0) {
		//SetTrans( victim);
		SC_GetSkillName(skill_id, skillname, sizeof(skillname)); //get trans again
		GetClientName(attacker, zzname, sizeof(zzname));
		PrintToConsole(victim, "[SC_S] %s did %i damage to you with %s",zzname, damage, skillname);
	}
}
//+%d damage with skill name
stock SC_PrintSkillDmgHint(victim = 0, attacker, damage, skill_id) {

	new String:skillname[32];
	//SetTrans( attacker);
	SC_GetSkillName(skill_id, skillname, sizeof(skillname));

	PrintHintText(attacker, "+%i damage with %s",damage, skillname);

	if (victim > 0) {
		//SetTrans( victim);
		SC_GetSkillName(skill_id, skillname, sizeof(skillname));
		PrintHintText(victim, "Received %i damage from %s",damage, skillname);
	}
}
stock SC_PrintSkillDmgHintConsole(victim = 0, attacker, damage, skill_id) {
	SC_PrintSkillDmgHint(victim, attacker, damage, skill_id);
	SC_PrintSkillDmgConsole(victim, attacker, damage, skill_id);
}

//colored
//prints [war3 tag] You did %d damage to %name with SKILLNAME
//prints [war3 tag] %name did %d damage to you with SKILLNAME
///automatically goes into console
//removed in favor of console and hint
/*
 stock SC_PrintSkillDmgChat(victim,attacker,damage,String:skillname[]){
 GetClientName(victim,zzname,sizeof(zzname));
 SC_ChatMessage(attacker,"%T","You did +{amount} damage to {player} with {skill}",attacker,damage,zzname,skillname);
 
 if(victim>0){
 GetClientName(attacker,zzname,sizeof(zzname));
 SC_ChatMessage(victim,"%T","{player} did {amount} damage to you with {skill}",victim,zzname,damage,skillname);
 }
 }
 */

stock SC_MsgUltNotLeveled(client) {
	new String:buffer[100];
	Format(buffer, sizeof(buffer),"Your Ultimate is not ready");
	PrintHintText(client, buffer);
}
stock SC_MsgNoTargetFound(client,Float:distancegameunits=0.0) {
	decl String:print[500];
	Format(print,sizeof(print),"No target found");
	if(distancegameunits>0.1) {
		Format(print,sizeof(print),"No target found within %.2f feet",distancegameunits/10.0);
	}
	PrintHintText(client,"%s",print);
}
stock SC_MsgCreatedWard(client, currentwardcount = 0, totalwardcount = 0) {
	decl String:print[500];
	Format(print, sizeof(print), "You created a Ward");
	if (totalwardcount > 0) {
		Format(print, sizeof(print), "You created a Ward %i/%i",currentwardcount, totalwardcount);
	}
	PrintHintText(client, "%s", print);
}
stock SC_MsgWardLocationDeny(client) {
	PrintHintText(client, "You can not build a Ward Here");
}
stock SC_MsgNoWardsLeft(client) {
	PrintHintText(client, "You have used up all your Wards!");
}
stock SC_MsgNoWardWhenInvis(client) {
	PrintHintText(client, "No Ward Placement While Invisible");
}
stock SC_MsgEvaded(victim, attacker) {
	PrintHintText(victim, "You Evaded a Shot");
	PrintHintText(attacker, "Enemy Evaded");
}
stock SC_MsgEntangle(victim, attacker) {
	PrintHintText(victim, "You are Entangled!");
	PrintHintText(attacker, "Entangled!");
}

stock SC_MsgNoCastDuringFreezetime(client) {
	PrintHintText(client, "Cannot cast during freezetime");
}
stock SC_MsgSkillBlocked(victim=0,attacker=0,String:skillname[]) {
	if(victim>0) {
		PrintHintText(victim,"Blocked enemy %s",skillname);
	}
	if(attacker>0) {
		PrintHintText(victim,"Enemy Blocked %s",skillname);
	}
}
stock SC_MsgNewbieProjectBlocked(victim=0,String:skillname[],String:chatmessage[],String:chatmessage2[]) {
	if(victim>0) {
		PrintHintText(victim,"[Newbie Project] Blocked enemy %s",skillname);
		SC_ChatMessage(victim,"{green}[Newbie Project]{lightgreen}%s{default}.",chatmessage);
		SC_ChatMessage(victim,"{green}[Newbie Project]{lightgreen}%s{default}.",chatmessage2);
	}
}

stock SC_MsgBanished(victim, attacker) {
	PrintHintText(victim, "You have been Banished");
	PrintHintText(attacker, "You Banished");
}
stock SC_MsgStoleMoney(victim, attacker, dollars) {
	PrintHintText(victim, "Enemy stole %i dollars from you",dollars);
	PrintHintText(attacker, "You Stole %i dollars",dollars);
}
stock SC_MsgStoleGold(victim, attacker, gold) {
	PrintHintText(victim, "Enemy stole %i gold from you",gold);
	PrintHintText(attacker, "You Stole %i gold", gold);
}
stock SC_MsgRevivedBM(playerrevived, savior, gold=0, xp=0, heal=0) {
	new String:clientName[64];
	GetClientName(playerrevived, clientName, sizeof(clientName));
	new String:saviorName[64];
	GetClientName(savior, saviorName, sizeof(saviorName));

	PrintHintText(savior, "You revived %s", clientName);
	SC_ChatMessage(playerrevived, "%s revived you", saviorName);
}
stock SC_MsgUsingVoodoo(client) {
	PrintHintText(client,"Activated Voodoo!");
}
stock SC_MsgVoodooEnded(client) {
	PrintHintText(client,"Voodoo has ended");
}
stock SC_MsgEnemyHasImmunity(client,bool:console=true) {
	PrintHintText(client,"Enemy has immunity!");
	PrintToConsole(client,"[SkillCraft] Enemy has immunity!");
}
stock SC_MsgUltimateNotActivatable(client) {
	PrintHintText(client, "This ultimate is not activatable"); //prints
}
stock SC_MsgUltimateBlocked(client) {
	PrintHintText(client, "Ultimate Blocked");
}
stock SC_MsgThrewKnives(client) {
	PrintHintText(client,"You threw knives around you");
}
stock SC_MsgHitByKnives(client) {
	PrintHintText(client, "Attacked by Fan of Knives");
}
stock SC_MsgActivated(client,String:postpendstr[]) {
	PrintHintText(client,"Activated %s",postpendstr);
}
stock SC_MsgAttackedBy(client,String:postpendstr[]) {
	PrintHintText(client,"Attacked By %s",postpendstr);
}
stock SC_MsgMoleIn(client,Float:timetillactivation) {
	PrintHintText(client,"WARNING! MOLE IN %i SECONDS!",timetillactivation);
	SC_ChatMessage(client,"WARNING! MOLE IN %i SECONDS!",timetillactivation);
}
stock SC_MsgNoLongerDisguised(client) {
	SC_ChatMessage(client, "You are no longer disguised");
	PrintHintText(client, "You are no longer disguised");
}
stock SC_MsgVengenceWasBlocked(client,String:reason[]) {
	SC_ChatMessage(client,"Vengence blocked (%s)",reason);
}

stock bool:Spying(client)
{
	// Can a class really be disguised if not SPY?  or cloaked if not spy??
	if(TF2_GetPlayerClass(client)==TFClass_Spy)
	{
		return (TF2_IsPlayerInCondition(client,TFCond_Disguising)||TF2_IsPlayerInCondition(client,TFCond_Disguised) || TF2_IsPlayerInCondition(client,TFCond_Cloaked));
	}
	return false;
}
//team 2 3 swapped if spying
stock GetApparentTeam(client) {
	new team = GetClientTeam(client);
	if (Spying(client)) {
		if (team == 2)
			team++;
		else if (team == 3)
			team--;
	}
	return team;
}
native SC_IsBuffInvised(client); //returns true if client alpha is <50

//invisible or cloaked?
stock IsInvis(client) {
	return (TF2_IsPlayerInCondition(client, TFCond_Cloaked)
			|| SC_IsBuffInvised(client));
}

/**
 * Prints Message to server and all chat
 * For debugging prints
 */
stock DP(const String:szMessage[], any:...)
{

	decl String:szBuffer[1000];

	VFormat(szBuffer, sizeof(szBuffer), szMessage, 2);
	PrintToServer("[DebugP %d] %s",RoundFloat(GetGameTime())%100, szBuffer);
	PrintToChatAll("[DebugP %d] %s",RoundFloat(GetGameTime())%100, szBuffer);

}
//prring plugin
stock DPP(Plugin:plugin)
{
	new String:szBuffer[1000];
	GetPluginFilename(Handle:plugin, szBuffer,sizeof(szBuffer));
	DP("[Debug PrintP] %s", szBuffer);
}

stock PrintPlugin(Handle:plugin) {
	new String:str[100];
	GetPluginFilename(Handle:plugin, str, sizeof(str));
	SC_LogNotError("%s",str);
}
stock PrintPluginError(Handle:plugin) {
	new String:str[100];
	GetPluginFilename(Handle:plugin, str, sizeof(str));
	LogError("%s",str);
	SC_LogError("%s",str);
}

///find a "string" in a war3cvar that is delimited by commas "rubbish,string" = true
stock bool:SC_FindStringInCvar(cvarid,String:findme[],max=9999) {
	decl String:cvarstr[100];
	decl String:exploded[32][32];

	SC_GetCvar(cvarid,cvarstr,sizeof(cvarstr));

	new num;
	if(strlen(cvarstr)>0) {
		num=ExplodeString(cvarstr,",",exploded,256,256);
		for(new i=0;i<num && i<max;i++) {
			//PrintToServer("'%s' compared to: '%s' num%d",exploded[i],itemShort,num);
			if(StrEqual(exploded[i],findme,false)) {
				//PrintToServer("TRUE");
				return true;
			}
		}
	}
	return false;
}

// Picks a random player currently ingame.
stock SC_GetRandomPlayer(team,bool:check_alive=false,SC_Immunity:check_immunity=Immunity_None) {

    new clients[MaxClients+1], clientCount;
    for (new i = 1; i <= MaxClients; i++)
        if (IsClientInGame(i) && (GetClientTeam(i) == team) && (!check_alive || IsPlayerAlive(i)) && (!SC_HasImmunity(i,check_immunity)))
            clients[clientCount++] = i;
    return (clientCount == 0) ? -1 : clients[GetRandomInt(0, clientCount-1)];
}

// Returns true if a and b are the same
stock bool:VectorEquals(const Float:a[3], const Float:b[3])
{
	if(a[0]==b[0] && a[1]==b[1] && a[2]==b[2]) {
		return true;
	}
	return false;
}

// Revan: This was originally a hotfix for sounds in csgo
// it just ClientCommand("playgamesound")..
// Its not required anymore because a more clean fix
// for sounds has been implemented!
// @deprecated This is here for backwards compatibility only.
stock SC_EmitSoundToAll(const String:sample[],
		entity = SOUND_FROM_PLAYER,
		channel = SNDCHAN_AUTO,
		level = SNDLEVEL_NORMAL,
		flags = SND_NOFLAGS,
		Float:volume = SNDVOL_NORMAL,
		pitch = SNDPITCH_NORMAL,
		speakerentity = -1,
		Float:origin[3] = NULL_VECTOR,
		const Float:dir[3] = NULL_VECTOR,
		bool:updatePos = true,
		Float:soundtime = 0.0)
{
	EmitSoundToAll(sample,entity,channel,level,flags,volume,pitch,speakerentity,origin,dir,updatePos,soundtime);
}

// In csgo killing 2 players in the same frame causes a crash so we use this dirty workaround
public Action:_skillcraft_Timer_DealDamage(Handle:timer, Handle:pack)
{
	ResetPack(pack); //resolve the package...
	new victim = ReadPackCell(pack);
	if(!ValidPlayer(victim,true)) {
		// immedialety exit!
		return Plugin_Stop;
	}
	new attacker = ReadPackCell(pack);
	new damage = ReadPackCell(pack);
	new bool:showDamage = bool:ReadPackCell(pack);
	new showDamage_skill = ReadPackCell(pack);
	decl String:classname[32];
	ReadPackString(pack,classname,sizeof(classname));
	if(SC_DealDamage(victim,damage,attacker,DMG_BULLET,classname) && showDamage) {
		SC_PrintSkillDmgConsole(victim,attacker,SC_GetWar3DamageDealt(),showDamage_skill);
	}
	return Plugin_Stop;
}

stock SC_DealDamageDelayed(victim,attacker,damage,String:classname[32],Float:delay=0.0,bool:showDamage=false,showDamage_skill=0) {
	new Handle:pack;
	CreateDataTimer(delay, _skillcraft_Timer_DealDamage, pack);
	WritePackCell(pack, victim);
	WritePackCell(pack, attacker);
	WritePackCell(pack, damage);
	WritePackCell(pack, showDamage);
	WritePackCell(pack, showDamage_skill);
	WritePackString(pack, classname);
}

/**
 * Returns UNIX time (integer)
 */
stock NOW() {
	return GetTime();
}
/**
 * returns the larger integer of the two
 */
stock IntMax(one, two) {
	return one > two ? one : two;
}

//what we want is something that always increments even past map changes
//not intended to matter of game pauses or not (tick)
stock Float:AbsoluteTime() {
	return GetEngineTime();
}


stock bool:IsMvM(bool:forceRecalc = false)
{
//	new String:mapname[256];
	//GetCurrentMap(mapname, 255);
	//if(StrContains(mapname,"mvm",false))
		//return true;

	static bool:found = false;
	static bool:ismvm = false;
	if (forceRecalc)
	{
		found = false;
		ismvm = false;
	}
	if (!found)
	{
		new i = FindEntityByClassname(-1, "tf_logic_mann_vs_machine");
		if (i > MaxClients && IsValidEntity(i)) ismvm = true;
		found = true;
	}
	return ismvm;
}

stock CreateTimer_DEBUG(any:f=0,any:ff=0,any:fff=0,any:ffff=0) {}


