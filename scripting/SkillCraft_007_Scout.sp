#pragma semicolon 1
 
#include <sourcemod>
#include "SkillCraft_Includes/SkillCraft_Interface"
#include <sdktools>

new SKILL_INVIS, SKILL_TRUESIGHT, SKILL_DISARM, ULT_MARKSMAN, SKILL_FADE;

// Chance/Data Arrays
new Float:InvisDrain=0.05; //as a percent of your health
new Handle:InvisEndTimer[MAXPLAYERSCUSTOM];
new bool:InInvis[MAXPLAYERSCUSTOM];

// SKILL FADE
new bool:InFade[MAXPLAYERSCUSTOM];


new const STANDSTILLREQ=10;


new bool:bDisarmed[MAXPLAYERSCUSTOM];
new Float:lastvec[MAXPLAYERSCUSTOM][3];
new standStillCount[MAXPLAYERSCUSTOM];

new AuraID;

public Plugin:myinfo = 
{
	name = "SkillCraft skills from Scout",
	author = "SkillCraft Team",
	description = "SkillCraft skills from Scout Race.",
	version = "1.0.0.0",
};

public OnPluginStart()
{
	CreateTimer(0.1,DeciSecondTimer,_,TIMER_REPEAT);
}

public On_SC_LoadSkillOrdered(num)
{
	if(num==70)
	{
		SKILL_INVIS=SC_CreateNewSkill("Vanish","Vanish",
		"(+ability) Turn invisible at the cost of 5% health / sec for 6-9 seconds.\nCannot shoot for 1 second out of invis.\nLeave invis early by using ability again",
		ability);
	}
	if(num==71)
	{
		SKILL_TRUESIGHT=SC_CreateNewSkill("TrueSight","TrueSight",
		"Enemies cannot be invisible or partially invisible around you. \n800 units.\nDoes not affect spy cloak",mastery);
	}
	if(num==72)
	{
		SKILL_DISARM=SC_CreateNewSkill("Disarm","Disarm",
		"15% chance to disarm the enemy on hit\n1.2 seconds to disarm victim.",mastery);
	}
	if(num==73)
	{
		ULT_MARKSMAN=SC_CreateNewSkill("Marksman (Passive)","Marksman",
		"(Passive) Standing still for 1 second, scout is able to deal 1.2-1.6x damage the further the target.\n1000 units or more deals maximum damage",ultimate);
	}
	if(num==74)
	{
		SKILL_FADE=SC_CreateNewSkill("Blink (Passive)","Blink",
		"(Passive) If standing still for 8 seconds, you go completely invisible.\nAny movement or damage (to or from you) makes you visible.",ultimate); 
	}
	if(num==75)
	{
		//AuraID =SC_RegisterChangingDistanceAura("scout_reveal",true);
		AuraID = SC_RegisterAura("scout_reveal",600.0,true);
	}
}

public On_SC_MasterySkillChanged(client, oldskill, newskill)
{
	if(oldskill==SKILL_TRUESIGHT)
	{
		SC_RemovePlayerAura(AuraID,client);
	}
	else if(newskill==SKILL_TRUESIGHT)
	{
		SC_SetAuraFromPlayer(AuraID,client,true);
	}
}

public On_SC_EventSpawn(client){
	if(bDisarmed[client]){
		EndInvis2(INVALID_HANDLE,client);
	}
	if(InInvis[client]||InFade[client]){
		SC_SetBuff(client,fInvisibilitySkill,SKILL_FADE,1.0);
		SC_SetBuff(client,fInvisibilitySkill,SKILL_INVIS,1.0);
		SC_SetBuff(client,fHPDecay,SKILL_INVIS,0.0);
		InInvis[client]=false;
		InFade[client]=false;
	}
}
public OnAbilityCommand(client,abilitybutton,bool:pressed)
{
	if(SC_HasSkill(client,SKILL_INVIS) && pressed && IsPlayerAlive(client))
	{
		if(ValidPlayer(client) && InInvis[client]){
			TriggerTimer(InvisEndTimer[client]);
			
		}
		else if(!Silenced(client)&&SC_SkillNotInCooldown(client,SKILL_INVIS,true))
		{	
			if(ValidPlayer(client) && !InFade[client])
			{
				SC_SetBuff(client,bDisarm,SKILL_INVIS,true);
				bDisarmed[client]=true;
				SC_SetBuff(client,fInvisibilitySkill,SKILL_INVIS,0.03);
				SC_SetBuff(client,fHPDecay,SKILL_INVIS,SC_GetMaxHP(client)*InvisDrain);
				InvisEndTimer[client]=CreateTimer(9.0,EndInvis,client);
			
			
				PrintHintText(client,"You sacrificed part of yourself for invis");
				InInvis[client]=true;
				SC_CooldownMGR(client,15.0,SKILL_INVIS);
			}
			else
			{
				PrintHintText(client,"You cannot invis while blinked!");
			}
			
		}
	}
}

public EndFade(client)
{
	if(ValidPlayer(client,true,true))
	{
		InFade[client]=false;
		SC_SetBuff(client,fInvisibilitySkill,SKILL_FADE,1.0);
		PrintHintText(client,"You Blink into the Light!");
		SC_CooldownMGR(client,8.0,SKILL_FADE);
	}
	
}
public Action:EndInvis(Handle:timer,any:client)
{
	InInvis[client]=false;
	if(!InFade[client])
	{
		SC_SetBuff(client,fInvisibilitySkill,SKILL_INVIS,1.0);
	}
	SC_SetBuff(client,fHPDecay,SKILL_INVIS,0.0);
	// Got an Error in the logs, so added ValidPlayer for checking.
	if (ValidPlayer(client))
		CreateTimer(1.0,EndInvis2,client);
	PrintHintText(client,"No Longer Invis! Cannot shoot for 1 sec!");
	
}
public Action:EndInvis2(Handle:timer,any:client){
	SC_SetBuff(client,bDisarm,SKILL_INVIS,false);
	bDisarmed[client]=false;
}

public On_SC_TakeDmgAll(victim,attacker,Float:damage)
{
	if(ValidPlayer(victim)&&ValidPlayer(attacker))
	{
		if(SC_HasSkill(attacker,SKILL_FADE))
		{
			if(InFade[attacker]){ //stood still for 10 second
			if(ValidPlayer(attacker))
				EndFade(attacker);
			}
		}
		else
		if(SC_HasSkill(victim,SKILL_FADE))
		{
			if(InFade[victim]){ //stood still for 10 second
			if(ValidPlayer(victim))
				EndFade(victim);
			}
		}
	}
}


public On_SC_TakeDmgBulletPre(victim,attacker,Float:damage)
{
	if(ValidPlayer(victim)&&ValidPlayer(attacker))
	{
		new vteam=GetClientTeam(victim);
		new ateam=GetClientTeam(attacker);
		if(vteam!=ateam)
		{
			if(SC_HasSkill(victim,ULT_MARKSMAN) && !SC_HasImmunity(victim,Immunity_Skills)){
				if(standStillCount[attacker]>=STANDSTILLREQ){ //stood still for 1 second
					new Float:vicpos[3];
					new Float:attpos[3];
					GetClientAbsOrigin(victim,vicpos);
					GetClientAbsOrigin(attacker,attpos);
					new Float:distance=GetVectorDistance(vicpos,attpos);
					
					if(distance>1000.0){ //0-512 normal damage 512-1024 linear increase, 1024-> maximum
						distance=1000.0;
					}
					new Float:multi=distance*0.6/1000.0;
					SC_DamageModPercent(multi+1.0);
					PrintToConsole(attacker,"[SkillCraft] %.2fX dmg by marksman shot",multi);
					
				}
			}
		}
	}
}


public On_SC_EventPostHurt(victim,attacker,damage){
	if(SC_GetDamageIsBullet()&&ValidPlayer(victim,true)&&ValidPlayer(attacker,true)&&GetClientTeam(victim)!=GetClientTeam(attacker))
	{	
		if(SC_HasSkill(attacker,SKILL_DISARM))
		{
			if(!Hexed(attacker,false))
			{
				if(!SC_HasImmunity(victim,Immunity_Skills) && !bDisarmed[victim]){
					//if(  SC_Chance(0.25*SC_ChanceModifier(attacker) )  ){
					if(  SC_Chance(0.15)  ){
						SC_SetBuff(victim,bDisarm,SKILL_DISARM,true);
						CreateTimer(1.2,Undisarm,victim);
					}
				}
			}
		}
	}		   
}
public Action:Undisarm(Handle:t,any:client){
	SC_SetBuff(client,bDisarm,SKILL_DISARM,false);
}


public Action:DeciSecondTimer(Handle:t){
	for(new client=1;client<=MaxClients;client++)
	{
		if(ValidPlayer(client,true,true) && SC_HasSkill(client,SKILL_FADE))
		{
			static Float:vec[3];
			GetClientAbsOrigin(client,vec);
			if(GetVectorDistance(vec,lastvec[client])>1.0)
			{
				standStillCount[client]=0;
				if(ValidPlayer(client,true,true) && InFade[client])
					EndFade(client);
			}
			else
			{
				standStillCount[client]++;
				/*
				FIXES  THE PROBLEM WHEN YOU SHOOT AND BECOME VISIBLE FOR A SECOND
				if(InFade[client])
					standStillCount[client]=10;
				*/
				if(InFade[client])
					standStillCount[client]=80-10;
				//if(InFade[client] && standStillCount[client]>600)
					//standStillCount[client]=600;
			}
			lastvec[client][0]=vec[0];
			lastvec[client][1]=vec[1];
			lastvec[client][2]=vec[2];
		}
		//PrintToChatAll("stand still client %i count %i",client,standStillCount[client]);
		if(ValidPlayer(client,true) && SC_HasSkill(client,SKILL_FADE))
		{
			if(standStillCount[client]>=80 && SC_SkillNotInCooldown(client,SKILL_FADE,true))
			{
				//FADE
				if(!InFade[client])
				{
					InFade[client]=true;
					//EndFadeTimer[client]=CreateTimer(FadeDurationT[skilllvl],EndFade,client);
					/*
					//FIXES  THE PROBLEM WHEN YOU SHOOT AND BECOME VISIBLE FOR A SECOND
					standStillCount[client]=10;
					*/
					standStillCount[client]=80-10;
					//if(InFade[client] && standStillCount[client]>600)
						//standStillCount[client]=600;
					
					SC_SetBuff(client,fInvisibilitySkill,SKILL_FADE,0.03);
					SC_Hint(client,HINT_SKILL_STATUS,5.0,"You Blink into darkness..");
				}
			}
		}
	}
}

public OnUltimateCommand(client,bool:pressed,bool:bypass)
{
	if(SC_HasSkill(client,SKILL_TRUESIGHT) && IsPlayerAlive(client) && pressed)
	{
		if(!Silenced(client)&&SC_SkillNotInCooldown(client,SKILL_TRUESIGHT,true)){
		}
		else
		{
			//print no eyes availabel
		}
	}
}
public On_SC_PlayerAuraStateChanged(client,tAuraID,bool:inAura){
	if(tAuraID==AuraID)
	{
		//DP(inAura?"in aura":"not in aura");
		if(!SC_HasImmunity(client,Immunity_Skills))
		{
			SC_SetBuff(client,bInvisibilityDenyAll,SKILL_TRUESIGHT,inAura);
		}
		else
		{
			SC_SetBuff(client,bInvisibilityDenyAll,SKILL_TRUESIGHT,false);
		}
	}
	
}
