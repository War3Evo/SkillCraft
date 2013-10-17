#pragma semicolon 1

#include <sourcemod>
#include "SkillCraft_Includes/SkillCraft_Interface"

new SKILL_LEECH,SKILL_SPEED,SKILL_LOWGRAV,SKILL_SUICIDE;

public Plugin:myinfo = 
{
	name = "SkillCraft skills from Race - Undead Scourge",
	author = "SkillCraft Team",
	description = "SkillCraft skills from The Undead Scourge race for War3Source.",
	version = "1.0",
};


public On_SC_LoadSkillOrdered(num)
{
	// DEBUGGING:
	//PrintToServer("On_SC_LoadSkillOrdered(%d)",num); 
	if(num==10)
	{
		PrintToServer("skill vampaura");
		SKILL_LEECH=SC_CreateNewSkill("Vampiric Aura","vampaura","Leech Health\nYou recieve 25% of your damage dealt as Health",talent);
	}
	if(num==11)
	{
		PrintToServer("skill unholyaura");
		SKILL_SPEED=SC_CreateNewSkill("Unholy Aura","unholyaura","You run 20% faster",talent);	
	}
	if(num==13)
	{
		PrintToServer("skill levitate");
		SKILL_LOWGRAV=SC_CreateNewSkill("Levitation","levitate","You can jump higher\n0.5 less gravity",talent);
	}
	// temporary disabled does not work right
	//if(num==14)
	//{
		//PrintToServer("skill sbomber");
		//SKILL_SUICIDE=SC_CreateNewSkill("Suicide Bomber","sbomber","You explode when you die, can be manually activated via +ultimate\nBlast radius: 200-333 \nBlast damage: 50-200 divided by distance",ultimate); 
	//}
}


public OnUltimateCommand(client,bool:pressed,bool:bypass)
{
	if(pressed && SC_GetSkill(client,ultimate)==SKILL_SUICIDE && IsPlayerAlive(client) && !Silenced(client))
	{
		if(!Spying(client))
		{
			decl Float:location[3];
			GetClientAbsOrigin(client,location);
			SC_SuicideBomber(client, location, 200.0, SKILL_SUICIDE, 300.0);
			//ForcePlayerSuicide(client);
		}
		else
		{
			PrintHintText(client,"No cloaking/disguised to use ultimate");
		}
	}
}

public On_SC_TalentSkillChanged(client, oldskill, newskill)
{
	if(oldskill==SKILL_LEECH)
	{
		SC_SetBuff(client, fVampirePercent, SKILL_LEECH, 0.0);
	}
	else if(newskill==SKILL_LEECH)
	{
		SC_SetBuff(client,fVampirePercent,SKILL_LEECH,0.10);
	}

	if(oldskill==SKILL_LOWGRAV)
	{
		SC_SetBuff(client, fLowGravitySkill, SKILL_LOWGRAV, 1.0);
	}
	else if(newskill==SKILL_LOWGRAV)
	{
		SC_SetBuff(client,fLowGravitySkill,SKILL_LOWGRAV,0.40);
	}
	
	if(oldskill==SKILL_SPEED)
	{
		SC_SetBuff(client, fSlow, SKILL_SPEED, 1.0);
		SC_SetBuff(client, fMaxSpeed, SKILL_SPEED, 1.0);
	}
	else if(newskill==SKILL_SPEED)
	{
		SC_SetBuff(client, fSlow, SKILL_SPEED, 1.0);
		SC_SetBuff(client,fMaxSpeed,SKILL_SPEED,1.30);
	}
}


public On_SC_EventDeath(victim, attacker)
{
	if(SC_GetSkill(victim,ultimate)==SKILL_SUICIDE && !Hexed(victim) && !Spying(victim))
	{
		decl Float:location[3];
		GetClientAbsOrigin(victim,location);
		SC_SuicideBomber(victim, location, 200.0, SKILL_SUICIDE, 300.0);
	}
}
