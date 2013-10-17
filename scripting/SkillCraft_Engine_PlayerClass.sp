
#pragma semicolon 1

#include <sourcemod>
#include "SkillCraft_Includes/SkillCraft_Interface"

new p_properties[MAXPLAYERSCUSTOM][SC_PlayerProp];

//new String:levelupSound[256]; //="war3source/levelupcaster.mp3";

new Handle:g_On_Any_Skill_Changed;
new Handle:g_On_Mastery_Skill_Changed;
new Handle:g_On_Talent_Skill_Changed;
new Handle:g_On_Ability_Skill_Changed;
new Handle:g_On_Ultimate_Skill_Changed;

public Plugin:myinfo= 
{
	name="SkillCraft Engine player class",
	author="El Diablo",
	description="SkillCraft Core Plugins",
	version="1.0",
};


public OnPluginStart()
{
	RegConsoleCmd("scnotdev",cmdscnotdev);
	HookEvent("player_team", Event_PlayerTeam);
}
//public OnMapStart()
//{
	//strcopy(levelupSound,sizeof(levelupSound),"war3source/levelupcaster.mp3");

	//SC_PrecacheSound(levelupSound);
//}

public bool:Init_SC_NativesForwards()
{
	// Use Any sparely:
	g_On_Any_Skill_Changed=CreateGlobalForward("On_SC_AnySkillChanged",ET_Ignore,Param_Cell,Param_Cell,Param_Cell);
	// Use these more often to help split the load:
	g_On_Mastery_Skill_Changed=CreateGlobalForward("On_SC_MasterySkillChanged",ET_Ignore,Param_Cell,Param_Cell,Param_Cell);
	g_On_Talent_Skill_Changed=CreateGlobalForward("On_SC_TalentSkillChanged",ET_Ignore,Param_Cell,Param_Cell,Param_Cell);
	g_On_Ability_Skill_Changed=CreateGlobalForward("On_SC_AbilitySkillChanged",ET_Ignore,Param_Cell,Param_Cell,Param_Cell);
	g_On_Ultimate_Skill_Changed=CreateGlobalForward("On_SC_UltimateSkillChanged",ET_Ignore,Param_Cell,Param_Cell,Param_Cell);
	
	CreateNative("SC_SetSkill",Native_SC_SetSkill); 
	CreateNative("SC_GetSkill",Native_SC_GetSkill); 
	
	CreateNative("SC_HasSkill",Native_SC_HasSkill); 

	CreateNative("SC_SetPlayerProp",Native_SC_SetPlayerProp);
	CreateNative("SC_GetPlayerProp",Native_SC_GetPlayerProp);
	
	return true;
}

public Native_SC_SetSkill(Handle:plugin,numParams)
{
	//set old skillid
	new client=GetNativeCell(1);
	new newskillid=GetNativeCell(2);
	if(newskillid<0||newskillid>SC_GetSkillsLoaded()){
		SC_LogError("WARNING SET INVALID SKILL for client %d to skillid %d",client,newskillid);
		return;
	}
	if (client > 0 && client <= MaxClients)
	{
		if(SC_IsSkillMastery(newskillid))
		{
			new oldskillid=p_properties[client][Current_Mastery_Skill];
			if(oldskillid==newskillid){
				//WTF ABORT
			}
			else
			{
				//SC_SetVar(oldskillid,p_properties[client][Current_Mastery_Skill]);
			
				//if(oldskillid>0&&ValidPlayer(client)){
					//SC_SaveXP(client,oldskillid);
				//}
			
			
				p_properties[client][Current_Mastery_Skill]=newskillid;
			
				//announce skillid change
				Call_StartForward(g_On_Mastery_Skill_Changed);
				Call_PushCell(client);
				Call_PushCell(oldskillid);
				Call_PushCell(newskillid);
				Call_Finish(dummy);
			
				//announce any skillid change
				Call_StartForward(g_On_Any_Skill_Changed);
				Call_PushCell(client);
				Call_PushCell(oldskillid);
				Call_PushCell(newskillid);
				Call_Finish(dummy);
		
				if(newskillid>0) {
					// Maybe add different sound that isn't so much... like a click or something.
					// If we do add this.. add it to all the others below:
					//if(IsPlayerAlive(client)){
					//EmitSoundToAll(levelupSound,client);
					//}
					//else{
						//EmitSoundToClient(client,levelupSound);
					//}
				
					// When ever we add it saving characters:
					//if(SC_SaveEnabled()){ //save enabled
					//}
					//else {//if(oldskillid>0)
						//SC_DoLevelCheck(client);
					//}
				
					decl String:buf[64];
					SC_GetSkillName(newskillid,buf,sizeof(buf));
					SC_ChatMessage(client,"Mastery: %s Set!",buf);
				
					//if(oldskillid==0){
					//	SC_ChatMessage(client,"%T","say war3bug <description> to file a bug report",client);
					//}
				
					// What items?  Check later.
					//SC_CreateEvent(DoCheckRestrictedItems,client);
				}
			
			}
		}
		if(SC_IsSkillTalent(newskillid))
		{
			new oldskillid=p_properties[client][Current_Talent_Skill];
			if(oldskillid==newskillid){
				//WTF ABORT
			}
			else
			{
				//SC_SetVar(OldSkill,p_properties[client][Current_Talent_Skill]);
			
				//if(oldskillid>0&&ValidPlayer(client)){
					//SC_SaveXP(client,oldskillid);
				//}
			
			
				p_properties[client][Current_Talent_Skill]=newskillid;
			
				//announce skillid change
				Call_StartForward(g_On_Talent_Skill_Changed);
				Call_PushCell(client);
				Call_PushCell(oldskillid);
				Call_PushCell(newskillid);
				Call_Finish(dummy);
			
				//announce any skillid change
				Call_StartForward(g_On_Any_Skill_Changed);
				Call_PushCell(client);
				Call_PushCell(oldskillid);
				Call_PushCell(newskillid);
				Call_Finish(dummy);
		
				if(newskillid>0) {

					decl String:buf[64];
					SC_GetSkillName(newskillid,buf,sizeof(buf));
					SC_ChatMessage(client,"Talent: %s Set!",buf);
				
				}
			
			}
		}
		if(SC_IsSkillAbility(newskillid))
		{
			new oldskillid=p_properties[client][Current_Ability_Skill];
			if(oldskillid==newskillid){
				//WTF ABORT
			}
			else
			{
				//SC_SetVar(OldSkill,p_properties[client][Current_Ability_Skill]);
			
				//if(oldskillid>0&&ValidPlayer(client)){
					//SC_SaveXP(client,oldskillid);
				//}
			
			
				p_properties[client][Current_Ability_Skill]=newskillid;
			
				//announce skillid change
				Call_StartForward(g_On_Ability_Skill_Changed);
				Call_PushCell(client);
				Call_PushCell(oldskillid);
				Call_PushCell(newskillid);
				Call_Finish(dummy);
			
				//announce any skillid change
				Call_StartForward(g_On_Any_Skill_Changed);
				Call_PushCell(client);
				Call_PushCell(oldskillid);
				Call_PushCell(newskillid);
				Call_Finish(dummy);
		
				if(newskillid>0) {
				
					decl String:buf[64];
					SC_GetSkillName(newskillid,buf,sizeof(buf));
					SC_ChatMessage(client,"Ability: %s Set!",buf);
				
				}
			
			}
		}
		if(SC_IsSkillUltimate(newskillid))
		{
			new oldskillid=p_properties[client][Current_Ultimate_Skill];
			if(oldskillid==newskillid){
				//WTF ABORT
			}
			else
			{
				//SC_SetVar(OldSkill,p_properties[client][Current_Ultimate_Skill]);
			
				//if(oldskillid>0&&ValidPlayer(client)){
					//SC_SaveXP(client,oldskillid);
				//}
			
			
				p_properties[client][Current_Ultimate_Skill]=newskillid;
			
				//announce skillid change
				Call_StartForward(g_On_Ultimate_Skill_Changed);
				Call_PushCell(client);
				Call_PushCell(oldskillid);
				Call_PushCell(newskillid);
				Call_Finish(dummy);
			
				//announce any skillid change
				Call_StartForward(g_On_Any_Skill_Changed);
				Call_PushCell(client);
				Call_PushCell(oldskillid);
				Call_PushCell(newskillid);
				Call_Finish(dummy);
		
				if(newskillid>0) {
			
					decl String:buf[64];
					SC_GetSkillName(newskillid,buf,sizeof(buf));
					SC_ChatMessage(client,"Ultimate: %s Set!",buf);
				
				}
			
			}
		}
		if(newskillid<=0)
		{
			//Clear All Skills
			new oldskillid=p_properties[client][Current_Ultimate_Skill];
			if(oldskillid==newskillid){
				//WTF ABORT
			}
			else
			{
				//SC_SetVar(OldSkill,p_properties[client][Current_Ultimate_Skill]);
			
				//if(oldskillid>0&&ValidPlayer(client)){
					//SC_SaveXP(client,oldskillid);
				//}
			
				p_properties[client][Current_Mastery_Skill]=0;
				p_properties[client][Current_Talent_Skill]=0;
				p_properties[client][Current_Ability_Skill]=0;
				p_properties[client][Current_Ultimate_Skill]=0;
			
				//announce any skillid change
				Call_StartForward(g_On_Any_Skill_Changed);
				Call_PushCell(client);
				Call_PushCell(oldskillid);
				Call_PushCell(newskillid);
				Call_Finish(dummy);
		
				SC_ChatMessage(client,"Skill 0 Set!");
			}
		}
		return;
	}
}
public Native_SC_GetSkill(Handle:plugin,numParams){
	new client = GetNativeCell(1);
	new SKILLTYPE:typeofskill = GetNativeCell(2);
	if (client > 0 && client <= MaxClients)
	{
		switch(typeofskill)
		{
			case mastery:
			{
				return p_properties[client][Current_Mastery_Skill];
			}
			case talent:
			{
				return p_properties[client][Current_Talent_Skill];
			}
			case ability:
			{
				return p_properties[client][Current_Ability_Skill];
			}
			case ultimate:
			{
				return p_properties[client][Current_Ultimate_Skill];
			}
		}
	}
	
	return -2; //return -2 because u usually compare your skillid
}

public Native_SC_HasSkill(Handle:plugin,numParams){
	new client = GetNativeCell(1);
	new skillid = GetNativeCell(2);
	if (client > 0 && client <= MaxClients)
	{
	
		if(skillid==p_properties[client][Current_Mastery_Skill]||
		skillid==p_properties[client][Current_Talent_Skill]||
		skillid==p_properties[client][Current_Ability_Skill]||
		skillid==p_properties[client][Current_Ultimate_Skill])
		{
			return true;
		}
	}
	
	return false;
}

public Native_SC_GetPlayerProp(Handle:plugin,numParams){
	new client=GetNativeCell(1);
	if (client > 0 && client <= MaxClients)
	{
		return p_properties[client][SC_PlayerProp:GetNativeCell(2)];		
	}
	else
		return 0;
}

public Native_SC_SetPlayerProp(Handle:plugin,numParams){
	new client=GetNativeCell(1);
	if (client > 0 && client <= MaxClients)
	{	
		p_properties[client][SC_PlayerProp:GetNativeCell(2)]=GetNativeCell(3);
	}
}

public Event_PlayerTeam(Handle:event,  const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	SC_SetPlayerProp(client,LastChangeTeamTime,GetEngineTime());
}

public Action:cmdscnotdev(client,args){
	if(ValidPlayer(client)){
		SC_SetPlayerProp(client,isDeveloper,false);
		
	}
	return Plugin_Handled;
}

public On_SC_Event(SC_EVENT:event,client){
	if(event==InitPlayerVariables){
		new String:steamid[32];
		GetClientAuthString(client,steamid,sizeof(steamid));
		// Old Developer Steam ids:
		//if(StrEqual(steamid,"STEAM_0:1:9724315",false)||StrEqual(steamid,"STEAM_0:1:6121386",false)||StrEqual(steamid,"STEAM_0:0:11672517",false)){
		
		// El Diablo's Steam ID:  ... I"m too lazy to look up Dagothur's, you'll have to add yours in.
		if(StrEqual(steamid,"STEAM_0:1:35173666",false)){
			SC_SetPlayerProp(client,isDeveloper,true);    // Default is true
		}

	}
	if(event==ClearPlayerVariables)
	{
		//set xp loaded first, to block saving xp after skillid change
		SC_SetPlayerProp(client,xpLoaded,false);
		
		SC_SetPlayerProp(client,Pending_Mastery_Skill,0);
		SC_SetPlayerProp(client,Pending_Talent_Skill,0);
		SC_SetPlayerProp(client,Pending_Ability_Skill,0);
		SC_SetPlayerProp(client,Pending_Ultimate_Skill,0);
		SC_SetSkill(client,0); //need the skillid change event fired
		//SC_SetPlayerProp(client,dbSkillSelected,false);

		SC_SetPlayerProp(client,iMaxHP,0);
		SC_SetPlayerProp(client,bIsDucking,false);
		
		//SC_SetPlayerProp(client,SkillChosenTime,0.0);
		//SC_SetPlayerProp(client,SkillSetByAdmin,false);
		SC_SetPlayerProp(client,SpawnedOnce,false);
		SC_SetPlayerProp(client,sqlStartLoadXPTime,0.0);
		SC_SetPlayerProp(client,isDeveloper,false);
		SC_SetPlayerProp(client,LastChangeTeamTime,0.0);
		SC_SetPlayerProp(client,bStatefulSpawn,true);
		//bResetSkillsOnSpawn[client]=false;
	}

}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if(ValidPlayer(client)){
		p_properties[client][bIsDucking]=(buttons & IN_DUCK)?true:false; //hope its faster
		
		
		if(SC_GetBuffHasTrue(client,bStunned)||SC_GetBuffHasTrue(client,bDisarm)){
			if((buttons & IN_ATTACK) || (buttons & IN_ATTACK2))
			{
				buttons &= ~IN_ATTACK;
				buttons &= ~IN_ATTACK2;
			}
		}
	}
	return Plugin_Continue;
}

