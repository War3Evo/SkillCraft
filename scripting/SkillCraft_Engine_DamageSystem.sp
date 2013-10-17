//DAMAGE SYSTEM

#pragma semicolon 1

#include <sourcemod>
#include "sdkhooks"
#include "SkillCraft_Includes/SkillCraft_Interface"

///would you like to see the damage stack print out?
//#define DEBUG

new Handle:FHOnSC_TakeDmgAllPre;
new Handle:FHOnSC_TakeDmgBulletPre;
new Handle:FHOnSC_TakeDmgAll;
new Handle:FHOnSC_TakeDmgBullet;

new Handle:g_OnWar3EventPostHurtFH;

new Handle:PyroSC_ChanceModifierCvar;
new Handle:HeavySC_ChanceModifierCvar;

new g_CurDamageType=-99;
new g_CurInflictor=-99; //variables from sdkhooks, natives retrieve them if needed
new g_CurDamageIsWarcraft=0; //for this damage only
new g_CurDamageIsTrueDamage=0; //not used yet?

new Float:g_CurDMGModifierPercent=-99.9;

new g_CurLastActualDamageDealt=-99;

new bool:g_CanSetDamageMod=false; //default false, you may not change damage percent when there is none to change
new bool:g_CanDealDamage=true; //default true, you can initiate damage out of nowhere
//for deal damage only
new g_NextDamageIsWarcraftDamage=0; 
new g_NextDamageIsTrueDamage=0;

new dummyresult;

//global
new ownerOffset;

new damagestack=0;

new Float:LastDamageDealtTime[MAXPLAYERSCUSTOM];
new Float:ChanceModifier[MAXPLAYERSCUSTOM];

public Plugin:myinfo= 
{
	name="SkillCraft Engine Damage",
	author="SkillCraft Team",
	description="SkillCraft Core Plugins",
	version="1.0",
};


public OnPluginStart()
{
	PyroSC_ChanceModifierCvar=CreateConVar("war3_pyro_w3chancemod","0.500","Float 0.0 - 1.0");
	HeavySC_ChanceModifierCvar=CreateConVar("war3_heavy_w3chancemod","0.666","Float 0.0 - 1.0");

	//HookEvent("player_hurt", EventPlayerHurt);   ERRORS ON STACK.. TOOK THE NEW CODE FROM WAR3SOURCE 2.0 INSTEAD:
	                                           // USES OnTakeDamagePostHook  FROM SDKHOOKS NOW.

	ownerOffset = FindSendPropInfo("CBaseObject", "m_hBuilder");
}

//cvar handle
new Handle:ChanceModifierSentry;
new Handle:ChanceModifierSentryRocket;
public bool:Init_SC_NativesForwards()
{
	CreateNative("SC_DamageModPercent",Native_SC_DamageModPercent);

	CreateNative("SC_GetDamageType",Native_SC_GetDamageType);
	CreateNative("SC_GetDamageInflictor",Native_SC_GetDamageInflictor);
	CreateNative("SC_GetDamageIsBullet",Native_SC_GetDamageIsBullet);
	CreateNative("SC_ForceDamageIsBullet",Native_SC_ForceDamageIsBullet);
	
	CreateNative("SC_DealDamage",Native_SC_DealDamage);
	CreateNative("SC_GetWar3DamageDealt",Native_SC_GetWar3DamageDealt);

	CreateNative("SC_GetDamageStack",Native_SC_GetDamageStack);

	CreateNative("SC_ChanceModifier",Native_SC_ChanceModifier);

	CreateNative("SC_IsOwnerSentry",Native_SC_IsOwnerSentry);


	FHOnSC_TakeDmgAllPre=CreateGlobalForward("On_SC_TakeDmgAllPre",ET_Hook,Param_Cell,Param_Cell,Param_Cell);
	FHOnSC_TakeDmgBulletPre=CreateGlobalForward("On_SC_TakeDmgBulletPre",ET_Hook,Param_Cell,Param_Cell,Param_Cell);
	FHOnSC_TakeDmgAll=CreateGlobalForward("On_SC_TakeDmgAll",ET_Hook,Param_Cell,Param_Cell,Param_Cell);
	FHOnSC_TakeDmgBullet=CreateGlobalForward("On_SC_TakeDmgBullet",ET_Hook,Param_Cell,Param_Cell,Param_Cell);


	g_OnWar3EventPostHurtFH=CreateGlobalForward("On_SC_EventPostHurt",ET_Ignore,Param_Cell,Param_Cell,Param_Cell,Param_String,Param_Cell);


	ChanceModifierSentry=CreateConVar("sc_chancemodifier_sentry","","None to use attack rate dependent chance modifier. Set from 0.0 to 1.0 chance modifier for sentry, this will override time dependent chance modifier");
	ChanceModifierSentryRocket=CreateConVar("sc_chancemodifier_sentryrocket","","None to use attack rate dependent chance modifier. Set from 0.0 to 1.0 chance modifier for sentry, this will override time dependent chance modifier");

	return true;
}

public Native_SC_DamageModPercent(Handle:plugin,numParams)
{
	if(!g_CanSetDamageMod){
		LogError("	");
		ThrowError("You may not set damage mod percent here, use ....Pre forward");
		//SC_LogError("You may not set damage mod percent here, use ....Pre forward");
		//PrintPluginError(plugin);
	}

	new Float:num=GetNativeCell(1); 
	#if defined DEBUG
	PrintToServer("percent change %f",num);
	#endif
	g_CurDMGModifierPercent*=num;
	
}



public Native_SC_GetDamageType(Handle:plugin,numParams){
	return g_CurDamageType;
}
public Native_SC_GetDamageInflictor(Handle:plugin,numParams){
	return g_CurInflictor;
}
public Native_SC_GetDamageIsBullet(Handle:plugin,numParams){
	return _:(!g_CurDamageIsWarcraft);
}
public Native_SC_ForceDamageIsBullet(Handle:plugin,numParams){
	g_CurDamageIsWarcraft=false;
}
public Native_SC_GetDamageStack(Handle:plugin,numParams){
	return damagestack;
}


// Damage Engine needs to know about sentries and dispensers and stuff...
public OnEntityCreated(entity, const String:classname[])
{
	// Errors from this event... gives massive negative values.. should use entity > 0
	// DONT REMOVE entity>0
	if(entity>0 && IsValidEntity(entity))
	{
		//if(StrEqual(classname,"eyeball_boss")||StrEqual(classname,"headless_hatman")
		//||StrContains(classname,"obj_sentrygun",false)==0||StrContains(classname,"obj_teleporter",false)==0||StrContains(classname,"obj_dispenser",false)==0)
		//{
		SDKHook(entity, SDKHook_OnTakeDamage, SDK_Forwarded_OnTakeDamage);
	}
}

public OnClientPutInServer(client){
	SDKHook(client,SDKHook_OnTakeDamage,SDK_Forwarded_OnTakeDamage);
	SDKHook(client, SDKHook_OnTakeDamagePost, OnTakeDamagePostHook);
}
public OnClientDisconnect(client){
	SDKUnhook(client,SDKHook_OnTakeDamage,SDK_Forwarded_OnTakeDamage);
	SDKUnhook(client, SDKHook_OnTakeDamagePost, OnTakeDamagePostHook);
}

public Native_SC_IsOwnerSentry(Handle:plugin,numParams)
{
	new client=GetNativeCell(1);
	new bool:UseInternalInflictor=GetNativeCell(2);
	new pSentry;
	if(UseInternalInflictor)
		pSentry=g_CurInflictor;
	else
		pSentry=GetNativeCell(3);

	if(ValidPlayer(client))
	{
		if(IsValidEntity(pSentry)&&TF2_GetPlayerClass(client)==TFClass_Engineer)
		{
			decl String:netclass[32];
			GetEntityNetClass(pSentry, netclass, sizeof(netclass));

			if (strcmp(netclass, "CObjectSentrygun") == 0 || strcmp(netclass, "CObjectTeleporter") == 0 || strcmp(netclass, "CObjectDispenser") == 0)
			{
	if (GetEntDataEnt2(pSentry, ownerOffset) == client)
		return true;
			}
		}
	}
	return false;
}

public Native_SC_ChanceModifier(Handle:plugin,numParams)
{

	new attacker=GetNativeCell(1);
	//new inflictor=SC_GetDamageInflictor();
	//new damagetype=SC_GetDamageType();
	if(attacker<=0 || attacker>MaxClients || !IsValidEdict(attacker)){
		return _:1.0;
	}

	new Float:tempChance = GetRandomFloat(0.0,1.0);
	switch (TF2_GetPlayerClass(attacker))
	{
		case TFClass_Heavy:
		{
			if (tempChance <= GetConVarFloat(HeavySC_ChanceModifierCvar)) //heavy cvar here, replaces 0.666
				return _:0.0;
		}
		case TFClass_Pyro:
		{
			if (tempChance <= GetConVarFloat(PyroSC_ChanceModifierCvar)) //pyro cvar here, replaces 0.500
				return _:0.0;
		}
	}
	return _:ChanceModifier[attacker];
}

public Action:SDK_Forwarded_OnTakeDamage(victim,&attacker,&inflictor,&Float:damage,&damagetype)
{
	
	if(ValidPlayer(victim,true)){
		//store old variables on local stack!
	
		new old_DamageType= g_CurDamageType;
		new old_Inflictor= g_CurInflictor;
		new old_IsWarcraftDamage= g_CurDamageIsWarcraft;
		new Float:old_DamageModifierPercent = g_CurDMGModifierPercent;
		new old_IsTrueDamage = g_CurDamageIsTrueDamage;

		//new piercing_item = 0;
		new attacker_Owns_item = 0;

		if(ValidPlayer(attacker,true)&&!SC_HasImmunity(victim,Immunity_Items))
		{
			attacker_Owns_item = SC_GetSkillIDByShortname("piercing");
			//new piercing_item = SC_GetItemIdByShortname("piercing");
			//attacker_Owns_item = SC_GetOwnsItem(attacker,piercing_item);
			//if((attacker_Owns_item==1))
			//	DP("attacker owes piercing");
		}

		
		//set these to global
		g_CurDamageType=damagetype;
		g_CurInflictor=inflictor;
		g_CurDMGModifierPercent=1.0;
		g_CurDamageIsWarcraft=g_NextDamageIsWarcraftDamage;
		g_CurDamageIsTrueDamage=g_NextDamageIsTrueDamage;
		
		
		//#if defined DEBUG
		//new String:skill[32];
		//SC_GetSkillName(SC_GetSkill(attacker),skillid,sizeof(skill));
		//DP2("sdktakedamage %d->%d atskill %s damage [%.2f]",attacker,victim,skill,damage);
		//#endif
		
		damagestack++;
		
		if(g_CurDamageIsWarcraft){
			damage=FloatMul(damage,SC_GetMagicArmorMulti(victim));
			//PrintToChatAll("magic %f %d to %d",SC_GetMagicArmorMulti(victim),attacker,victim);
		}
		else if((attacker_Owns_item!=1)&&!g_CurDamageIsTrueDamage){ //bullet
			damage=FloatMul(damage,SC_GetPhysicalArmorMulti(victim));
			
			//PrintToChatAll("physical %f %d to %d",SC_GetPhysicalArmorMulti(victim),attacker,victim);
			//g_CurDamageIsWarcraft=false;
		}
		if(!g_CurDamageIsWarcraft && ValidPlayer(attacker)){
			new Float:now=GetGameTime();
			
			new Float:value=now-LastDamageDealtTime[attacker];
			if(value>1.0||value<0.0){
				ChanceModifier[attacker]=1.0;
			}
			else{
				ChanceModifier[attacker]=value;
			}
			//DP("%f",ChanceModifier[attacker]);
			LastDamageDealtTime[attacker]=GetGameTime();
		}
		if(attacker!=inflictor)
		{
			if(inflictor>0 && IsValidEdict(inflictor))
			{
	new String:ent_name[64];
	GetEdictClassname(inflictor,ent_name,64);
			//	DP("ent name %s",ent_name);
	if(StrContains(ent_name,"obj_sentrygun",false)==0	&&!CvarEmpty(ChanceModifierSentry))
	{
		ChanceModifier[attacker]=GetConVarFloat(ChanceModifierSentry);
	}
	else if(StrContains(ent_name,"tf_projectile_sentryrocket",false)==0 &&!CvarEmpty(ChanceModifierSentryRocket))
	{
		ChanceModifier[attacker]=GetConVarFloat(ChanceModifierSentryRocket);
	}
	
			}
		}
	//	DP("%f",ChanceModifier[attacker]);
		//else it is true damage
		//PrintToChatAll("takedmg %f BULLET %d   lastiswarcraft %d",damage,isBulletDamage,g_CurDamageIsWarcraft);
		
		new bool:old_CanSetDamageMod=g_CanSetDamageMod;
		new bool:old_CanDealDamage=g_CanDealDamage;
		g_CanSetDamageMod=true;
		g_CanDealDamage=false;
		Call_StartForward(FHOnSC_TakeDmgAllPre);
		Call_PushCell(victim);
		Call_PushCell(attacker);
		Call_PushCell(damage);
		Call_Finish(dummyresult); //this will be returned to
		
		if(!g_CurDamageIsWarcraft){
		
		
			Call_StartForward(FHOnSC_TakeDmgBulletPre);
			Call_PushCell(victim);
			Call_PushCell(attacker);
			Call_PushCell(damage);
			Call_Finish(dummyresult); //this will be returned to
			
		}
		g_CanSetDamageMod=false;
		g_CanDealDamage=true;
		if(g_CurDMGModifierPercent>0.001){ //so if damage is already canceled, no point in forwarding the second part , do we dont get: evaded but still recieve warcraft damage proc)
		
		
			Call_StartForward(FHOnSC_TakeDmgAll);
			Call_PushCell(victim);
			Call_PushCell(attacker);
			Call_PushCell(damage);
			Call_Finish(dummyresult); //this will be returned to
			
			
			if(!g_CurDamageIsWarcraft){
				Call_StartForward(FHOnSC_TakeDmgBullet);
				Call_PushCell(victim);
				Call_PushCell(attacker);
				Call_PushCell(damage);
				Call_Finish(dummyresult); //this will be returned to
			}
		}
		g_CanSetDamageMod=old_CanSetDamageMod;
		g_CanDealDamage=old_CanDealDamage;	
		//modify final damage
		//DP("Damage before modifier %f %d to %d",damage,attacker,victim);
		damage=damage*g_CurDMGModifierPercent; ////so we calculate the percent
		//DP("Damage after modifier %f %d to %d",damage,attacker,victim);
	
		//nobobdy retrieves our global variables outside of the forward call, restore old stack vars
		g_CurDamageType= old_DamageType;
		g_CurInflictor= old_Inflictor;
		g_CurDamageIsWarcraft= old_IsWarcraftDamage;
		g_CurDMGModifierPercent = old_DamageModifierPercent;
		g_CurDamageIsTrueDamage = old_IsTrueDamage;
		
		
		
		damagestack--;
		#if defined DEBUG
		
		DP2("sdktakedamage %d->%d END dmg [%.2f]",attacker,victim,damage);
		#endif
	
	}
	
	return Plugin_Changed;
}


public OnTakeDamagePostHook(victim, attacker, inflictor, Float:damage, damagetype, weapon, const Float:damageForce[3], const Float:damagePosition[3])
{
		// GHOSTS!!
		if (weapon == -1 && inflictor == -1)
		{
				//SC_LogError("OnTakeDamagePostHook: Who was pho^H^H^Hweapon?");
				return;
		}
		
		//Block uber hits (no actual damage)
		if(SC_IsUbered(victim))
		{
				//DP("ubered but SDK OnTakeDamagePostHook called, damage %f",damage);
				return;
		}
		damagestack++;
		
		new bool:old_CanDealDamage=g_CanDealDamage;
		g_CanSetDamageMod=true;
		
		g_CurInflictor = inflictor;
		
		// war3source 2.0 uses this:
		//Figure out what really hit us. A weapon? A sentry gun?
		new String:weaponName[64];
		new realWeapon = weapon == -1 ? inflictor : weapon;
		GetEntityClassname(realWeapon, weaponName, sizeof(weaponName));

		//SC_LogInfo("OnTakeDamagePostHook called with weapon \"%s\"", weaponName);

		Call_StartForward(g_OnWar3EventPostHurtFH);
		Call_PushCell(victim);
		Call_PushCell(attacker);
		Call_PushCell(RoundToFloor(damage));

		// new war3source 2.0 uses this.. we don't
		//Call_PushFloat(damage);
		Call_PushString(weaponName);
		Call_PushCell(g_CurDamageIsWarcraft);
		Call_Finish(dummyresult);
		
		g_CanDealDamage=old_CanDealDamage;
		
		damagestack--;
		
		g_CurLastActualDamageDealt = RoundToFloor(damage);
}


/*
public EventPlayerHurt(Handle:event,const String:name[],bool:dontBroadcast)
{
	new victim_userid=GetEventInt(event,"userid");
	new attacker_userid=GetEventInt(event,"attacker");
	new damage=GetEventInt(event,"dmg_health");
	damage=GetEventInt(event,"damageamount");



	new victim=GetClientOfUserId(victim_userid);
	
	new attacker=GetClientOfUserId(attacker_userid);     CHECK ERROR LOGS -- 
	
L 07/22/2013 - 02:29:37: [SM] Plugin encountered error 8: Not enough space on the stack
L 07/22/2013 - 02:29:37: [SM] Native "GetClientOfUserId" reported: 
L 07/22/2013 - 02:29:37: [SM] Displaying call stack tskill for plugin "War3Source_Engine_DamageSystem.smx":
L 07/22/2013 - 02:29:37: [SM]   [0]  Line 376, War3Source_Engine_DamageSystem.sp::EventPlayerHurt()
L 07/22/2013 - 02:29:47: [serverhop.smx] Server 192.73.237.230:27015 is down: socket error 6 (errno 111)
L 07/22/2013 - 02:30:35: [SM] Plugin encountered error 8: Not enough space on the stack
L 07/22/2013 - 02:30:35: [SM] Native "GetClientOfUserId" reported: 
L 07/22/2013 - 02:30:35: [SM] Displaying call stack tskill for plugin "War3Source_Engine_DamageSystem.smx":
L 07/22/2013 - 02:30:35: [SM]   [0]  Line 376, War3Source_Engine_DamageSystem.sp::EventPlayerHurt()
L 07/22/2013 - 02:30:47: [serverhop.smx] Server 192.73.237.230:27015 is down: socket error 6 (errno 111)
L 07/22/2013 - 02:30:52: [SM] Plugin encountered error 8: Not enough space on the stack
L 07/22/2013 - 02:30:52: [SM] Native "GetClientOfUserId" reported: 
L 07/22/2013 - 02:30:52: [SM] Displaying call stack tskill for plugin "War3Source_Engine_DamageSystem.smx":
L 07/22/2013 - 02:30:52: [SM]   [0]  Line 376, War3Source_Engine_DamageSystem.sp::EventPlayerHurt()
	
	
	
	#if defined DEBUG
	DP2("PlayerHurt %d->%d  dmg [%d] ",attacker,victim,damage);
	#endif
	damagestack++;
	
	new bool:old_CanDealDamage=g_CanDealDamage;
	g_CanSetDamageMod=true;
	
	new Handle:oldevent=SC_GetVar(SmEvent);
	SC_SetVar(SmEvent,event); //stacking on stack 
	
	//do the forward
	Call_StartForward(g_OnWar3EventPostHurtFH);
	Call_PushCell(victim);
	Call_PushCell(attacker);
	Call_PushCell(damage);
	Call_PushCell(g_CurDamageIsWarcraft);
	Call_Finish(dummyresult);
	

	
	SC_SetVar(SmEvent,oldevent); //restore on stack , if any
	g_CanDealDamage=old_CanDealDamage;
	
	
	damagestack--;
	#if defined DEBUG
	
	DP2("PlayerHurt %d->%d  dmg [%d] END ",attacker,victim,damage);
	
	if(	damagestack==0){
	
	PrintToServer("   ");
	PrintToChatAll("   ");
	PrintToServer("   ");
	PrintToChatAll("   ");
	}
	#endif
	
	g_CurLastActualDamageDealt=damage;
}
*/


stock DP2(const String:szMessage[], any:...)
{
	new String:szBuffer[1000];
	new String:pre[132];
	for(new i=0;i<damagestack;i++){
		StrCat(pre,sizeof(pre),"	");
	}
	VFormat(szBuffer, sizeof(szBuffer), szMessage, 2);
	PrintToServer("[DP2] %s%s %s",pre,szBuffer,SC_GetDamageIsBullet()?"B":"",!g_NextDamageIsWarcraftDamage?"NB":"");
	PrintToChatAll("[DP2] %s%s %s", pre, szBuffer,SC_GetDamageIsBullet()?"B":"",!g_NextDamageIsWarcraftDamage?"NB":"");
	
}














//dealdamage reaches far into the stack:
/*
[DP2]	 playerHurt 1->10  dmg [34]  B
[DP2]	 dealdamage 10->1 { 
[DP2]		 sdktakedamage 10->1 atskill Night Elf damage [6.00] 
[DP2]		 sdktakedamage 10->1 END dmg [6.00] 
[DP2]		 PlayerHurt 10->1  dmg [3]  
[DP2]		 PlayerHurt 10->1  dmg [3] END  
	^^^^coplies the damage to global
[DP2]	 dealdamage 10->1 } B
[*/
public Native_SC_DealDamage(Handle:plugin,numParams)
{
	new bool:whattoreturn=true;
	
	new bool:noWarning = false;
	if (numParams >= 9)
		noWarning = GetNativeCell(9);
	
	if(!g_CanDealDamage && !noWarning){
		LogError("	");
		ThrowError("SC_DealDamage called when DealDamage is not suppose to be called, please use the non PRE forward");
		//LogError("SC_DealDamage called when DealDamage is not suppose to be called, please use the non PRE forward");
		//SC_LogError("SC_DealDamage called when DealDamage is not suppose to be called, please use the non PRE forward");
		//PrintPluginError(plugin);
	}
	
		
	decl victim;
	victim=GetNativeCell(1);
	decl damage;
	damage=GetNativeCell(2);
	decl attacker;
	attacker=GetNativeCell(3);
		
	
	if(ValidPlayer(victim,true) && damage>0)
	{
		//new old_DamageDealt=g_CurActualDamageDealt;
		new old_IsWarcraftDamage= g_CurDamageIsWarcraft;
		new old_IsTrueDamage = g_CurDamageIsTrueDamage;
		
		new old_NextDamageIsWarcraftDamage=g_NextDamageIsWarcraftDamage; 
		new old_NextDamageIsTrueDamage=g_NextDamageIsTrueDamage;
		
		g_CurLastActualDamageDealt=-88;
		
		
		new dmg_type;
		dmg_type=GetNativeCell(4);  //original weapon damage type
		decl String:weapon[64];
		GetNativeString(5,weapon,64);
		
		
		
		decl SC_DamageOrigin:SC_DMGORIGIN;
		SC_DMGORIGIN=GetNativeCell(6);
		decl SC_DamageType:SC_DMGTYPE;
		SC_DMGTYPE=GetNativeCell(7);
		
		decl bool:respectVictimImmunity;
		respectVictimImmunity=GetNativeCell(8);
		
		if(ValidPlayer(victim) && respectVictimImmunity){
			switch(SC_DMGORIGIN){
	case SC_DMGORIGIN_SKILL:  {
		if(SC_HasImmunity(victim,Immunity_Skills) ){
			return false;
		}
	}
	case SC_DMGORIGIN_ULTIMATE:  {
		if(SC_HasImmunity(victim,Immunity_Ultimates) ){
			return false;
		}
	}
	case SC_DMGORIGIN_ITEM:  {
		if(SC_HasImmunity(victim,Immunity_Items) ){
			return false;
		}
	}
	
			}
			
			
			switch(SC_DMGTYPE){
	case SC_DMGTYPE_PHYSICAL:  {
		if(SC_HasImmunity(victim,Immunity_PhysicalDamage) ){
			return false;
		}
	}
	case SC_DMGTYPE_MAGIC:  {
		if(SC_HasImmunity(victim,Immunity_MagicDamage) ){
			return false;
		}
	}
			}
		}
		new bool:countAsFirstTriggeredDamage;
		countAsFirstTriggeredDamage=GetNativeCell(9);
		
		if(countAsFirstTriggeredDamage){
			g_NextDamageIsWarcraftDamage=false;
		}
		else {
			g_NextDamageIsWarcraftDamage=true;
		}
		g_CurDamageIsWarcraft=g_NextDamageIsWarcraftDamage;
		///sdk immediately follows, we must expose this to posthurt once sdk exists
		//new bool:settobullet=bool:SC_GetDamageIsBullet(); //just in case someone dealt damage inside this forward and made it "not bullet"

		g_NextDamageIsTrueDamage=(SC_DMGTYPE==SC_DMGTYPE_TRUEDMG);
		g_CurDamageIsTrueDamage=(SC_DMGTYPE==SC_DMGTYPE_TRUEDMG);
		

		#if defined DEBUG
		DP2("dealdamage %d->%d {",attacker,victim);
		damagestack++;
		#endif
		
		decl String:dmg_str[16];
		IntToString(damage,dmg_str,sizeof(dmg_str));
		decl String:dmg_type_str[32];
		IntToString(dmg_type,dmg_type_str,sizeof(dmg_type_str));
		
		new pointHurt=CreateEntityByName("point_hurt");
		if(pointHurt)
		{
			//	PrintToChatAll("%d %d %d",victim,damage,g_CurActualDamageDealt);
			DispatchKeyValue(victim,"targetname","war3_hurtme"); //set victim as the target for damage
			DispatchKeyValue(pointHurt,"Damagetarget","war3_hurtme");
			DispatchKeyValue(pointHurt,"Damage",dmg_str);
			DispatchKeyValue(pointHurt,"DamageType",dmg_type_str);
			if(!StrEqual(weapon,""))
			{
				DispatchKeyValue(pointHurt,"classname",weapon);
			}
			else{
				DispatchKeyValue(pointHurt,"classname","war3_point_hurt");
			}
			DispatchSpawn(pointHurt);
			AcceptEntityInput(pointHurt,"Hurt",(attacker>0)?attacker:-1);
			//DispatchKeyValue(pointHurt,"classname","point_hurt");
			DispatchKeyValue(victim,"targetname","war3_donthurtme"); //unset the victim as target for damage
			RemoveEdict(pointHurt);
			//	PrintToChatAll("%d %d %d",victim,damage,g_CurActualDamageDealt);
		}
		//removed for now... SDKHooks_TakeDamage(victim, attacker, attacker, float(damage), dmg_type);
		//damage has been dealt BY NOW
		
		if(g_CurLastActualDamageDealt==-88){
			g_CurLastActualDamageDealt=0;
			whattoreturn=false;
		}
		#if defined DEBUG
		damagestack--;
		DP2("dealdamage %d->%d }",attacker,victim);
		#endif
		
		g_CurDamageIsWarcraft= old_IsWarcraftDamage;
	
		g_CurDamageIsTrueDamage = old_IsTrueDamage;
		
		g_NextDamageIsWarcraftDamage=old_NextDamageIsWarcraftDamage; 
		g_NextDamageIsTrueDamage=old_NextDamageIsTrueDamage;
	}
	else{
		//player is already dead
		whattoreturn=false;
		g_CurLastActualDamageDealt=0;
	}

	
	
	return whattoreturn;
}
public Native_SC_GetWar3DamageDealt(Handle:plugin,numParams) {
	return g_CurLastActualDamageDealt;
}
