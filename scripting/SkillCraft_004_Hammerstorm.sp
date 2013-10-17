#pragma semicolon 1	///WE RECOMMEND THE SEMICOLON

#include <sourcemod>
#include "SkillCraft_Includes/SkillCraft_Interface"

public Plugin:myinfo = 
{
	name = "Skills Mixed from Hammerstorm",
	author = "SkillCraft Team",
	description = "Hammerstorm skill mixup.",
	version = "1.2",
};

new thisRaceID;
new SKILL_BOLT, SKILL_CLEAVE, SKILL_WARCRY, ULT_STRENGTH;

// Tempents
new g_BeamSprite;
new g_HaloSprite;

// Storm Bolt 
new Float:BoltStunDuration=0.3;
new Float:StormCooldownTime=15.0;


new const StormCol[4] = {255, 255, 255, 155}; // Color of the beacon




// Gods Strength
new bool:bStrengthActivated[MAXPLAYERSCUSTOM];
new Handle:ultCooldownCvar; // cooldown

// Sounds
new String:hammerboltsound[256]; //="war3source/hammerstorm/stun.mp3";
new String:ultsnd[256]; //="war3source/hammerstorm/ult.mp3";
//new String:galvanizesnd[]="war3source/hammerstorm/galvanize.mp3";

public On_SC_LoadSkillOrdered(num)
{
	if(num==50)
	{
		SKILL_BOLT=SC_CreateNewSkill("Storm Bolt","StormBolt",
		"(+Ability) Stuns enemies in 225 radius\nfor 0.3 seconds, deals 20 damage",ability);
	}
	if(num==51)
	{
		SKILL_CLEAVE=SC_CreateNewSkill("Great Cleave","GreatCleave",
		"Your attacks splash 40 percent\ndamage to enemys within 150 units",mastery);
	}
	if(num==52)
	{
		SKILL_WARCRY=SC_CreateNewSkill("War Cry","WarCry",
		"Gain 1.7 physical armor,\nincreases your speed by 15 percent",talent);
	}
	if(num==53)
	{
		ULT_STRENGTH=SC_CreateNewSkill("Gods Strength","GodsStrength",
		"Greatly enhance your damage\nby 50 percent for a short\namount of time.",ultimate); 
	}
}

public OnPluginStart()
{
	ultCooldownCvar=CreateConVar("sc_hammerstorm_strength_cooldown","20","Cooldown timer.");
}


public OnMapStart()
{
	strcopy(hammerboltsound,sizeof(hammerboltsound),"war3source/hammerstorm/stun.mp3");
	strcopy(ultsnd,sizeof(ultsnd),"war3source/hammerstorm/ult.mp3");

	// Precache the stuff for the beacon ring
	g_BeamSprite = SC_PrecacheBeamSprite();
	g_HaloSprite = SC_PrecacheHaloSprite(); 
	//Sounds
	SC_PrecacheSound(hammerboltsound);
	SC_PrecacheSound(ultsnd);
}

InitPassiveSkills(client)
{
	if(SC_HasSkill(client,SKILL_WARCRY))
	{
		SC_SetBuff(client,fMaxSpeed,thisRaceID,1.15);
		SC_SetBuff(client,fArmorPhysical,thisRaceID,1.8);
	}
	else
	{
		SC_SetBuff(client,fMaxSpeed,thisRaceID,1.0);
		SC_SetBuff(client,fArmorPhysical,thisRaceID,0.0);
	}
}

public OnWar3EventSpawn(client)
{
	InitPassiveSkills(client);
	
	bStrengthActivated[client] = false;
	SC_ResetPlayerColor(client, thisRaceID);
}

public On_SC_TalentSkillChanged(client, oldskill, newskill)
{
	if(oldskill==SKILL_WARCRY)
	{
		SC_SetBuff(client,fMaxSpeed,thisRaceID,1.0);
		SC_SetBuff(client,fArmorPhysical,thisRaceID,0.0);
	}
	else if(newskill==SKILL_WARCRY)
	{
		SC_SetBuff(client,fMaxSpeed,thisRaceID,1.15);
		SC_SetBuff(client,fArmorPhysical,thisRaceID,1.8);
	}
}


public On_SC_TakeDmgBulletPre(victim,attacker,Float:damage){
	if(ValidPlayer(victim,true)&&ValidPlayer(attacker,false)&&GetClientTeam(victim)!=GetClientTeam(attacker))
	{
		if(SC_HasSkill(attacker,ULT_STRENGTH))
		{
			if(bStrengthActivated[attacker])
			{
				SC_DamageModPercent(1.50);
				
			}
		}
	}
}
			
public On_SC_TakeDmgBullet(victim,attacker,Float:damage){
	if(ValidPlayer(victim,true)&&ValidPlayer(attacker,false)&&GetClientTeam(victim)!=GetClientTeam(attacker))
	{
		if(SC_HasSkill(attacker,SKILL_CLEAVE))
		{
			// Cleave
			new splashdmg = RoundToFloor(damage * 0.4);
			// AWP? AWP!
			if(splashdmg>40)
			{
				splashdmg = 40;
			}
			new Float:dist = 150.0;
			new AttackerTeam = GetClientTeam(attacker);
			new Float:OriginalVictimPos[3];
			GetClientAbsOrigin(victim,OriginalVictimPos);
			new Float:VictimPos[3];
			
			if(attacker>0)
			{
				for(new i=1;i<=MaxClients;i++)
				{
					if(ValidPlayer(i,true)&&(GetClientTeam(i)!=AttackerTeam)&&(victim!=i))
					{
						GetClientAbsOrigin(i,VictimPos);
						if(GetVectorDistance(OriginalVictimPos,VictimPos)<=dist)
						{
							SC_DealDamage(i,splashdmg,attacker,_,"greatcleave");
							SC_PrintSkillDmgConsole(i,attacker,SC_GetWar3DamageDealt(),SKILL_CLEAVE);
						}
					}
				}
			}
		}
	}
}

public OnAbilityCommand(client,abilitybutton,bool:pressed,bool:bypass)
{
	if(SC_HasSkill(client,SKILL_BOLT) && abilitybutton==0 && pressed && IsPlayerAlive(client))
	{
		if(!Silenced(client)&&(bypass||SC_SkillNotInCooldown(client,SKILL_BOLT,true)))
		{
			new damage = 20;
			new Float:AttackerPos[3];
			GetClientAbsOrigin(client,AttackerPos);
			new AttackerTeam = GetClientTeam(client);
			new Float:VictimPos[3];
			
			TE_SetupBeamRingPoint(AttackerPos, 10.0, 500.0, g_BeamSprite, g_HaloSprite, 0, 25, 0.5, 5.0, 0.0, StormCol, 10, 0);
			TE_SendToAll();
			AttackerPos[2]+=10.0;
			TE_SetupBeamRingPoint(AttackerPos, 10.0, 500.0, g_BeamSprite, g_HaloSprite, 0, 25, 0.5, 5.0, 0.0, StormCol, 10, 0);
			TE_SendToAll();
			
			SC_EmitSoundToAll(hammerboltsound,client);
			SC_EmitSoundToAll(hammerboltsound,client);
			
			for(new i=1;i<=MaxClients;i++)
			{
				if(ValidPlayer(i,true)){
					GetClientAbsOrigin(i,VictimPos);
					if(GetVectorDistance(AttackerPos,VictimPos)<500.0)
					{
						if(GetClientTeam(i)!=AttackerTeam&&!SC_HasImmunity(client,Immunity_Skills))
						{
							SC_DealDamage(i,damage,client,DMG_BURN,"stormbolt",SC_DMGORIGIN_SKILL);
							SC_PrintSkillDmgConsole(i,client,SC_GetWar3DamageDealt(),SKILL_BOLT);
								
							SC_SetPlayerColor(i,SKILL_BOLT, StormCol[0], StormCol[1], StormCol[2], StormCol[3]); 
							SC_SetBuff(i,bStunned,SKILL_BOLT,true);

							SC_FlashScreen(i,RGBA_COLOR_RED);
							CreateTimer(BoltStunDuration,UnstunPlayer,i);
							
							PrintHintText(i,"You were stunned by Storm Bolt");
						
						}
					}
				}
			}
			//EmitSoundToAll(hammerboltsound,client);
			SC_CooldownMGR(client,StormCooldownTime,SKILL_BOLT);
		}
	}
}


public Action:UnstunPlayer(Handle:timer,any:client)
{
	SC_SetBuff(client,bStunned,SKILL_BOLT,false);
	SC_ResetPlayerColor(client, SKILL_BOLT);
}

public OnUltimateCommand(client,bool:pressed,bool:bypass)
{
	if(SC_HasSkill(client,ULT_STRENGTH) && pressed && ValidPlayer(client,true))
	{
		if(!Silenced(client)&&SC_SkillNotInCooldown(client,ULT_STRENGTH,true ))
		{
			SC_EmitSoundToAll(ultsnd,client);
			SC_EmitSoundToAll(ultsnd,client);
			PrintHintText(client,"The gods lend you their strength");
			bStrengthActivated[client] = true;
			CreateTimer(2.5,stopUltimate,client);
			
			//EmitSoundToAll(ultsnd,client);  
			SC_CooldownMGR(client,GetConVarFloat(ultCooldownCvar),ULT_STRENGTH);
		}
	}
}


public Action:stopUltimate(Handle:t,any:client){
	bStrengthActivated[client] = false;
	if(ValidPlayer(client,true)){
		PrintHintText(client,"You feel less powerful");
	}
}
