
/*  This program is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation, either version 3 of the License, or
	(at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with this program.  If not, see <http://www.gnu.org/licenses/>.
	
	SkillCraft has derived from War3Source.   Many coding similarities
	still exist.   The functions have been renamed and reworked to
	fit the format of SkillCraft.
	
	War3source written by PimpinJuice (anthony) and Ownz (Dark Energy)
	
	SkillCraft written by SkillCraft Team
	
	All rights reserved.
*/	

/*
* File: SkillCraft.sp
* Description: The main file for SkillCraft.
* Author(s): SkillCraft Team
* All handle leaks have been considered.
* If you don't like it, read through the whole thing yourself and prove yourself wrong.
*/


// SkillCraft written in TABS only and if found in spaces, please convert
// to tabs.  Thanks.

// SkillCraft is a work in progress.  It is being converted from
// War3Source.
 
#pragma semicolon 1

#define VERSION_NUM "Beta 0.1.0.0"

#define AUTHORS "SkillCraft Team"

// SourceMod stuff
#include <sourcemod>
#include <tf2>
//#include <cstrike>
#include <tf2_stocks>
#include <sdktools>
#include <sdktools_functions>
#include <keyvalues>

// SkillCraft stuff
#include "sdkhooks"
#include "SkillCraft_Includes/SkillCraft_Interface"

#include "SkillCraft_Includes/SkillCraft_vars"
#include "SkillCraft_Includes/SkillCraft_cvar"


//#include "SkillCraft_Includes/SkillCraft_forwards2"
// moved natives around... delete the following line when working:
//#include "SkillCraft_Includes/SkillCraft_natives"

//#include "SkillCraft_Includes/SkillCraft_offsets"

//#include "SkillCraft_Includes/SkillCraft_gameevents"

//#include "SkillCraft_Includes/SkillCraft_racesutils"

// Events
new Handle:g_On_SC_EventSpawnFH;
new Handle:g_On_SC_EventDeathFH;

new bHasDiedThisFrame[MAXPLAYERSCUSTOM]; 


// El Diablo's Quick Map change convars
new Handle:hLoadWar3CFGEveryMapCvar;
new bool:LoadWar3CFGEveryMap;
new bool:war3source_config_loaded;
new bool:MapStart;

//forwards

//new Handle:g_CheckCompatabilityFH;
new Handle:g_War3InterfaceExecFH;





public Plugin:myinfo= 
{
	name="SkillCraft",
	author=AUTHORS,
	description="Brings a SkillCraft like gamemode to the Source engine.",
	version=VERSION_NUM,
};

public APLRes:SC_AskPluginLoad2Custom(Handle:myself,bool:late,String:error[],err_max)
{
	
	PrintToServer("--------------------------SC_AskPluginLoad2Custom----------------------\n[SkillCraft] Plugin loading...");
	

	new String:version[64];
	Format(version,sizeof(version),"%s by %s",VERSION_NUM,AUTHORS);
	//new String:Eversion[64];
	//Format(Eversion,sizeof(Eversion),"%s by %s",eVERSION_NUM,eAUTHORS);
	CreateConVar("skillcraft_version",version,"War3Evo SkillCraft version.",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);


	//if(!Init_SC_NativesForwards())
	//{
		//LogError("[SkillCraft] There was a failure in creating the native/forward based functions, definately halting.");
		//return APLRes_Failure;
	//}
	//if(!War3Source_InitForwards2())
	//{
		//LogError("[SkillCraft] There was a failure in creating the forward based functions, definately halting.");
		//return APLRes_Failure;
	//}
	if(!SC_InitForwards()) 
	{
		LogError("[SkillCraft] There was a failure in creating the forward based functions, definately halting.");
		return APLRes_Failure;
	}
	
	return APLRes_Success;
}

public OnPluginStart()
{
	
	PrintToServer("--------------------------OnPluginStart----------------------");
	
	if(GetExtensionFileStatus("sdkhooks.ext") < 1)
		SetFailState("SDK Hooks is not loaded.");
	
	if(!SkillCraft_HookEvents())
		SetFailState("[SkillCraft] There was a failure in initiating event hooks.");
	if(!SkillCraft_InitCVars()) //especially sdk hooks
		SetFailState("[SkillCraft] There was a failure in initiating console variables.");

	//if(!SkillCraft_InitOffset())
		//SetFailState("[SkillCraft] There was a failure in finding the offsets required.");
		
	hLoadWar3CFGEveryMapCvar = CreateConVar("sc_load_skillcraft_cfg_every_map", "0", "Will Speed up map changes if disabled.");
	LoadWar3CFGEveryMap=GetConVarBool(hLoadWar3CFGEveryMapCvar);
	HookConVarChange(hLoadWar3CFGEveryMapCvar, hLoadWar3CFGEveryMapCvarChanged);
	


	CreateTimer(0.1,DeciSecondLoop,_,TIMER_REPEAT);
		
	PrintToServer("[SkillCraft] Plugin finished loading.\n-------------------END OnPluginStart-------------------");	
}

public hLoadWar3CFGEveryMapCvarChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	LoadWar3CFGEveryMap=GetConVarBool(hLoadWar3CFGEveryMapCvar);
}


public Action:DeciSecondLoop(Handle:timer)
{
	for(new client=1;client<=MaxClients;client++)
	{
		if(ValidPlayer(client,true))
		{
			//for(new i=0;i<=W3GetItemsLoaded()+War3_GetRacesLoaded();i++)
			//{
			//	PrintToServer("denybuff val: %d iter %d", buffdebuff[client][bBuffDeny][i],i);
			//}
			if(!SC_IsPlayerXPLoaded(client))
			{
				if(GetGameTime()>LastLoadingHintMsg[client]+4.0)
				{
					PrintHintText(client,"Loading SkillCraft Database... Please Wait");
					LastLoadingHintMsg[client]=GetGameTime();
				}
				continue;
			}
		}
	}
}

public OnMapStart()
{
	PrintToServer("OnMapStart");

	if(!MapStart)
	{
		Do_SC_InterfaceExecForward();
	}


	MapStart=true;

	Delayed_SC_SourceCfgExecute();
	
	//CreateTimer(5.0, CheckCvars, 0);

	// No Reason to check interface versions
	//OneTimeForwards();

}

public Action:OnGetGameDescription(String:gameDesc[64])
{
	if(GetConVarInt(hChangeGameDescCvar)>0)
	{
		Format(gameDesc,sizeof(gameDesc),"SC %s",VERSION_NUM);
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public OnAllPluginsLoaded() //called once only, will not call again when map changes
{
	PrintToServer("OnAllPluginsLoaded");
}


Delayed_SC_SourceCfgExecute()
{
	if(LoadWar3CFGEveryMap)
	{
		if(FileExists("cfg/skillcraft.cfg"))
		{
			ServerCommand("exec skillcraft.cfg");
			PrintToServer("[SkillCraft] Executing skillcraft.cfg");
			war3source_config_loaded=true;
		}
		else
		{
			PrintToServer("[SkillCraft] Could not find skillcraft.cfg, we recommend all servers have this file");
		}
	}
	else if(!LoadWar3CFGEveryMap&&!war3source_config_loaded)
	{
		if(FileExists("cfg/skillcraft.cfg"))
		{
			ServerCommand("exec skillcraft.cfg");
			PrintToServer("[SkillCraft] Executing skillcraft.cfg");
			war3source_config_loaded=true;
		}
		else
		{
			PrintToServer("[SkillCraft] Could not find skillcraft.cfg, we recommend all servers have this file");
		}
	}
}

public OnClientPutInServer(client)
{
	LastLoadingHintMsg[client]=GetGameTime();
	//DatabaseSaveXP now handles clearing of vars and triggering retrieval
}

public OnClientDisconnect(client)
{
	//DatabaseSaveXP now handles clearing of vars and triggering retrieval
}

bool:SC_InitForwards()
{
	g_On_SC_EventSpawnFH=CreateGlobalForward("On_SC_EventSpawn",ET_Ignore,Param_Cell);
	g_On_SC_EventDeathFH=CreateGlobalForward("On_SC_EventDeath",ET_Ignore,Param_Cell,Param_Cell,Param_Cell,Param_Cell,Param_Cell,Param_Cell,Param_Cell);

	//g_CheckCompatabilityFH=CreateGlobalForward("CheckWar3Compatability",ET_Ignore,Param_String);
	g_War3InterfaceExecFH=CreateGlobalForward("War3InterfaceExec",ET_Ignore);
	
	CreateNative("SC_HasDiedThisFrame",Native_SC_HasDiedThisFrame);
	CreateNative("SC_InFreezeTime",Native_SC_InFreezeTime);

    
	return true;
}

new iRoundNumber;

public bool:SkillCraft_HookEvents()
{
	// Events for all games
	if(!HookEventEx("player_spawn",SC_PlayerSpawnEvent,EventHookMode_Pre)) //,EventHookMode_Pre
	{
		PrintToServer("[SkillCraft] Could not hook the player_spawn event.");
		return false;
	}
	if(!HookEventEx("player_death",SC_PlayerDeathEvent,EventHookMode_Pre))
	{
		PrintToServer("[SkillCraft] Could not hook the player_death event.");
		return false;
	}
	if(!HookEventEx("teamplay_round_win",SC_RoundOverEvent))
	{
		PrintToServer("[SkillCraft] Could not hook the teamplay_round_win event.");
		return false;
	}

	return true;
	
}


Do_SC_InterfaceExecForward(){
	Call_StartForward(g_War3InterfaceExecFH);
	Call_Finish(dummyreturn);
}

DoForward_On_SC_EventSpawn(client){
		//new Handle:prof=CreateProfiler();
		//StartProfiling(prof);
		Call_StartForward(g_On_SC_EventSpawnFH);
		Call_PushCell(client);
		Call_Finish(dummyreturn);
		//StopProfiling(prof);
		//new String:RaceSTRname[32];
		//War3_GetRaceShortname(War3_GetRace(client),RaceSTRname,sizeof(RaceSTRname));
		//DP("%s: %f",RaceSTRname,GetProfilerTime(prof));
		//CloseHandle(prof);
}

DoForward_On_SC_EventDeath(victim,killer,distance,attacker_hpleft){
		Call_StartForward(g_On_SC_EventDeathFH);
		Call_PushCell(victim);
		Call_PushCell(killer);
		Call_PushCell(distance);
		Call_PushCell(attacker_hpleft);
		Call_Finish(dummyreturn);
}

public SC_PlayerSpawnEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
	new userid=GetEventInt(event,"userid");
	if(userid>0)
	{
		new client=GetClientOfUserId(userid);
		if(ValidPlayer(client,true))
		{

			//DP("spawn %d",client);

			//bIgnoreTrackGF[client]=false;
			SC_SetMaxHP_INTERNAL(client,GetClientHealth(client));
			//PrintToChatAll("%d",GetClientHealth(index)); 
			
			CheckPendingSkill(client);
			if(IsFakeClient(client)&&SC_IsPlayerXPLoaded(client)&&SC_GetSkill(client,mastery)==0&&GetConVarInt(botsetraces)){ //SC_IsPlayerXPLoaded(client) is for skipping until putin server is fired (which cleared variables)
				new tries=100;
				//new motherbot = SC_GetRaceIDByShortname("motherbot");
				while(tries>0)
				{
					new skillid=GetRandomInt(1,SC_GetSkillsLoaded());
					if(!SC_SkillHasFlag(skillid,"nobots")) // may want to remove race!=motherbot then put "nobots" for motherbot along with hidden
					{
						tries=0;
						//PrintToServer("race to be %d",race);
						SC_SetSkill (client,skillid);
					}
					tries--;
				}
				//PrintToServer("race %d level %d %d",SC_GetRace(client),SC_GetLevel(client,race),SC_GetSkillLevel(client,race,0));
					// Check Bots for classname assignment
				//CreateTimer(10.0,Check_Bot_ClassName_Timer,userid);
			}
			new skillid=SC_GetSkill(client,mastery);
			if(!SC_GetPlayerProp(client,SpawnedOnce))
			{
				SC_SetPlayerProp(client,SpawnedOnce,true);
			}
			else if(skillid<1&&SC_IsPlayerXPLoaded(client))
			{
				ShowChangeSkillMenu(client);
			}
			
			// fix later:
			//else if(skillid>0&&GetConVarInt(hSkillLimitEnabled)>0&&GetSkillsOnTeam(skillid,GetClientTeam(client),true)>SC_GetSkillMaxLimitTeam(skillid,GetClientTeam(client))){
				//CheckSkillTeamLimit(skillid,GetClientTeam(client));  //show changerace inside
			//}
			
			
			//forward to all other plugins last
			DoForward_On_SC_EventSpawn(client);
			
			SC_SetPlayerProp(client,bStatefulSpawn,false); //no longer a "stateful" spawn
		}
	}
}

public  Action:SC_PlayerDeathEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
	new uid_victim = GetEventInt(event, "userid");
	new uid_attacker = GetEventInt(event, "attacker");
	//new uid_entity = GetEventInt(event, "entityid");
	
	new victimIndex = 0;
	new attackerIndex = 0;

	new victim = GetClientOfUserId(uid_victim);
	new attacker = GetClientOfUserId(uid_attacker);

	new distance=0;
	new attacker_hpleft=0;

	//new String:weapon[32];
	//GetEventString(event, "weapon", weapon, 32);
	//ReplaceString(weapon, 32, "WEAPON_", "");

	if(victim>0&&attacker>0)
	{
		//Get the distance
		new Float:victimLoc[3];
		new Float:attackerLoc[3];
		GetClientAbsOrigin(victim,victimLoc);
		GetClientAbsOrigin(attacker,attackerLoc);
		distance = RoundToNearest(FloatDiv(calcDistance(victimLoc[0],attackerLoc[0], victimLoc[1],attackerLoc[1], victimLoc[2],attackerLoc[2]),12.0));

		attacker_hpleft = GetClientHealth(attacker);

	}

	
	if(uid_attacker>0){
		attackerIndex=GetClientOfUserId(uid_attacker);
	}
	
	if(uid_victim>0){
		victimIndex=GetClientOfUserId(uid_victim);
	}	
	
	new bool:deadringereath=false;
	if(uid_victim>0)
	{	
		new deathFlags = GetEventInt(event, "death_flags");
		if (deathFlags & 32) //TF_DEATHFLAG_DEADRINGER
		{
			deadringereath=true;
			//PrintToChat(client,"war3 debug: dead ringer kill");
			
			//new assister=GetClientOfUserId(GetEventInt(event,"assister"));

		}
	}
	
	if(bHasDiedThisFrame[victimIndex]>0){
		return Plugin_Handled;
	}
	bHasDiedThisFrame[victimIndex]++;
	//lastly
	//DP("died? %d",bHasDiedThisFrame[victimIndex]);
	if(victimIndex&&!deadringereath) //forward to all other plugins last
	{

		new Handle:oldevent=SC_GetVar(SmEvent);
	//	DP("new event %d",event);
		SC_SetVar(SmEvent,event); //stacking on stack 
		
		///pre death event, internal event
		SC_SetVar(EventArg1,attackerIndex);
		SC_CreateEvent(OnDeathPre,victimIndex);
		
		//post death event actual forward
		//DoForward_OnWar3EventDeath(victimIndex,attackerIndex,distance,attacker_hpleft,weapon);
		DoForward_On_SC_EventDeath(victimIndex,attackerIndex,distance,attacker_hpleft);
		
		SC_SetVar(SmEvent,oldevent); //restore on stack , if any
		//DP("restore event %d",event);
		//then we allow change race AFTER death forward
		SC_SetPlayerProp(victimIndex,bStatefulSpawn,true);//next spawn shall be stateful
		CheckPendingSkill(victimIndex);
		
	}
	return Plugin_Continue;
}
public Float:calcDistance(Float:x1,Float:x2,Float:y1,Float:y2,Float:z1,Float:z2){
	//Distance between two 3d points
	new Float:dx = x1-x2;
	new Float:dy = y1-y2;
	new Float:dz = z1-z2;

	return(SquareRoot(dx*dx + dy*dy + dz*dz));
}
public OnGameFrame(){
	for(new i=1;i<MaxClients;i++){   // was MAXPLAYERSCUSTOM
		bHasDiedThisFrame[i]=0;
	}
}
public Action:EndFreezeTime(Handle:timer,any:roundNum)
{
	if(roundNum==iRoundNumber)
	{
		bInFreezeTime=false;
	}
}

public War3Source_RoundStartEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
	bInFreezeTime=true;
	++iRoundNumber;
	new Handle:freezeTimeCvar=FindConVar("mp_freezetime");
	if(freezeTimeCvar==INVALID_HANDLE)
	{
		bInFreezeTime=false;		
	}
	else
	{
		new Float:fFreezeTime=GetConVarFloat(freezeTimeCvar);
		if(fFreezeTime>0.0)
		{
			CreateTimer(fFreezeTime,EndFreezeTime,iRoundNumber);
		}
	}
}

public SC_RoundOverEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
	// cs - int winner
	// tf2 - int team
	//new team=GetEventInt(event,"team");
	if(GetEventInt(event,"team")>-1)
	{
		//winner team...
	}
}

CheckPendingSkill(client){
	new pendingskill=SC_GetPendingSkill(client,mastery);
	if(pendingskill>0)
	{
		SC_SetPendingSkill(client,mastery,-1);
		
		
		/*GetConVarInt(SC_GetVar(hRaceLimitEnabledCvar))>0&&
		GetRacesOnTeam(pendingrace,GetClientTeam(client))>=SC_GetRaceMaxLimitTeam(pendingrace,GetClientTeam(client))*/
		if(	CanSelectSkill(client,pendingskill)||SC_IsDeveloper(client)){
			SC_SetSkill(client,pendingskill); 
		}
		else
		{   //already at limit
			//SC_ChatMessage(client,"%T","Race limit for your team has been reached, please select a different race. (MAX {amount})",GetTrans(),SC_GetRaceMaxLimitTeam(pendingrace,GetClientTeam(client)));
			//SC_Log("race %d blocked on client %d due to restrictions limit (CheckPendingRace)",pendingrace,client);
			
			
			//SC_CreateEvent(DoShowChangeRaceMenu,client);
		}
		
	}
	pendingskill=SC_GetPendingSkill(client,talent);
	if(pendingskill>0)
	{
		SC_SetPendingSkill(client,talent,-1);
		
		
		/*GetConVarInt(SC_GetVar(hRaceLimitEnabledCvar))>0&&
		GetRacesOnTeam(pendingrace,GetClientTeam(client))>=SC_GetRaceMaxLimitTeam(pendingrace,GetClientTeam(client))*/
		if(	CanSelectSkill(client,pendingskill)||SC_IsDeveloper(client)){
			SC_SetSkill(client,pendingskill); 
		}
		else
		{   //already at limit
			//SC_ChatMessage(client,"%T","Race limit for your team has been reached, please select a different race. (MAX {amount})",GetTrans(),SC_GetRaceMaxLimitTeam(pendingrace,GetClientTeam(client)));
			//SC_Log("race %d blocked on client %d due to restrictions limit (CheckPendingRace)",pendingrace,client);
			
			
			//SC_CreateEvent(DoShowChangeRaceMenu,client);
		}
		
	}
	pendingskill=SC_GetPendingSkill(client,ability);
	if(pendingskill>0)
	{
		SC_SetPendingSkill(client,ability,-1);
		
		
		/*GetConVarInt(SC_GetVar(hRaceLimitEnabledCvar))>0&&
		GetRacesOnTeam(pendingrace,GetClientTeam(client))>=SC_GetRaceMaxLimitTeam(pendingrace,GetClientTeam(client))*/
		if(	CanSelectSkill(client,pendingskill)||SC_IsDeveloper(client)){
			SC_SetSkill(client,pendingskill); 
		}
		else
		{   //already at limit
			//SC_ChatMessage(client,"%T","Race limit for your team has been reached, please select a different race. (MAX {amount})",GetTrans(),SC_GetRaceMaxLimitTeam(pendingrace,GetClientTeam(client)));
			//SC_Log("race %d blocked on client %d due to restrictions limit (CheckPendingRace)",pendingrace,client);
			
			
			//SC_CreateEvent(DoShowChangeRaceMenu,client);
		}
		
	}
	pendingskill=SC_GetPendingSkill(client,ultimate);
	if(pendingskill>0)
	{
		SC_SetPendingSkill(client,ultimate,-1);
		
		
		/*GetConVarInt(SC_GetVar(hRaceLimitEnabledCvar))>0&&
		GetRacesOnTeam(pendingrace,GetClientTeam(client))>=SC_GetRaceMaxLimitTeam(pendingrace,GetClientTeam(client))*/
		if(	CanSelectSkill(client,pendingskill)||SC_IsDeveloper(client)){
			SC_SetSkill(client,pendingskill); 
		}
		else
		{   //already at limit
			//SC_ChatMessage(client,"%T","Race limit for your team has been reached, please select a different race. (MAX {amount})",GetTrans(),SC_GetRaceMaxLimitTeam(pendingrace,GetClientTeam(client)));
			//SC_Log("race %d blocked on client %d due to restrictions limit (CheckPendingRace)",pendingrace,client);
			
			
			//SC_CreateEvent(DoShowChangeRaceMenu,client);
		}
		
	}
	///wasnt pending
	else if(SC_GetSkill(client,mastery)==0){
		SC_SetVar(EventArg1,mastery);
		SC_CreateEvent(DoShowChangeSkillMenu,client);
	}
	else if(SC_GetSkill(client,talent)==0){
		SC_SetVar(EventArg1,talent);
		SC_CreateEvent(DoShowChangeSkillMenu,client);
	}
	else if(SC_GetSkill(client,ability)==0){
		SC_SetVar(EventArg1,ability);
		SC_CreateEvent(DoShowChangeSkillMenu,client);
	}
	else if(SC_GetSkill(client,ultimate)==0){
		SC_SetVar(EventArg1,ultimate);
		SC_CreateEvent(DoShowChangeSkillMenu,client);
	}
	//else if(SC_GetSkill(client,mastery)>0){
		//if(!CanSelectRace(client,SC_GetSkill(client,mastery))){
		//if(!CanSelectRace(client,SC_GetSkill(client,mastery))){
			//SC_SetSkill(client,0);
			//PrintToConsole(client,"debug: skill is set to zero via gameevents.inc");
		//}
	//}
}

public Native_SC_HasDiedThisFrame(Handle:plugin,numParams){
	new client=GetNativeCell(1);
	return ValidPlayer(client)&&bHasDiedThisFrame[client];
}

public Native_SC_InFreezeTime(Handle:plugin,numParams)
{
	return (bInFreezeTime)?1:0;
}

