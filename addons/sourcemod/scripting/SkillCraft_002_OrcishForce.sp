#pragma semicolon 1
#pragma tabsize 0

#include <sourcemod>
#include "SkillCraft_Includes/SkillCraft_Interface"
#include <sdktools>
#include <sdktools_functions>
#include <sdktools_tempents>
#include <sdktools_tempents_stocks>
//#include "SC_SIncs/War3Evo_WardChecking"
//#include <cstrike>

new Handle:ultCooldownCvar;

new Float:LastThunderClap[MAXPLAYERSCUSTOM];

new bool:bBeenHit[MAXPLAYERSCUSTOM][MAXPLAYERSCUSTOM]; // [caster][victim] been hit this chain lightning?

// WARDS
#define MAXWARDS 64*4 //on map LOL
#define WARDRADIUS 60
new Float:WARDDAMAGE=0.10;  // 10 percent damage  (Happens 4 times a second = 40% damage per second)
#define WARDBELOW -1000.0 // player is 60 units tall about (6 feet)
#define WARDABOVE 1000.0

new CurrentWardCount[MAXPLAYERSCUSTOM];
new Float:WardLocation[MAXWARDS][3];
new WardOwner[MAXWARDS];

new String:lightningSound[]="war3source/lightningbolt.wav";
new String:wardDamageSound[]="war3source/thunder_clap.wav";


new SKILL_CRIT,SKILL_BLITZ,SKILL_LUSTFUL_POWER,SKILL_WARD,ULT_LIGHTNING;
// Effects

new BeamSprite,HaloSprite,BloodSpray,BloodDrop; 

public Plugin:myinfo =
{
	name = "SkillCraft skills from Orcish Force",
	author = "SkillCraft Team",
	description = "Skills from The Orcish Force job for War3evo.",
	version = "1.0.0.0",
};

public OnPluginStart()
{
	ultCooldownCvar=CreateConVar("sc_orcishforce_chain_cooldown","20.0","Cooldown time for chain lightning.");
	CreateTimer(0.14,CalcWards,_,TIMER_REPEAT);
}

public On_SC_LoadSkillOrdered(num)
{
	if(num==30)
	{
		SKILL_CRIT=SC_CreateNewSkill("War Strike","WarStrike",
		"Chance of doing critical damage",
		mastery);
	}
	if(num==31)
	{
		SKILL_BLITZ=SC_CreateNewSkill("Blitz","Blitz",
		"Increases movement speed. On Burn: you have a\nchance of 100% to getting slowed by 50%/60%/70%/80%",
		talent);
	}
	if(num==32)
	{
		SKILL_LUSTFUL_POWER=SC_CreateNewSkill("Lustful Power","LustPower",
		"+ 2/4/6/8% attack speed. Magical resistance is vulnerability is increased.",
		mastery);
	}
	if(num==33)
	{
		SKILL_WARD=SC_CreateNewSkill("Serpent Wards","SerpWards",
		"(+ability) Wards that damage enemies if they touch.\n40 percent damage per second.\nEach Skill adds another ward you can place.",
		ability);
	}
	if(num==34)
	{
		ULT_LIGHTNING=SC_CreateNewSkill("Chain Lightning","cLightning",
		"Discharges a bolt of lightning that jumps to\nnearby enemies 150-300 units in range,\ndealing each damage.\nAfter Discharge you cannot attack for 4/3/2/1 seconds.",
		ultimate);
	}
}




public On_SC_PlayerAuthed(client)
{
	LastThunderClap[client]=0.0;
}

public On_SC_MasterySkillChanged(client, oldskill, newskill)
{
	if(oldskill==SKILL_LUSTFUL_POWER)
	{
		SC_SetBuff(client,fArmorMagic,SKILL_LUSTFUL_POWER,0.0);
		SC_SetBuff(client,fAttackSpeed,SKILL_LUSTFUL_POWER,1.0);
	}
	else if(newskill==SKILL_LUSTFUL_POWER)
	{
		SC_SetBuff(client,fAttackSpeed,SKILL_LUSTFUL_POWER,1.08);
		SC_SetBuff(client,fArmorMagic,SKILL_LUSTFUL_POWER,-1.50);
	}
}

public On_SC_TalentSkillChanged(client, oldskill, newskill)
{
	if(oldskill==SKILL_BLITZ)
	{
		SC_SetBuff(client,fSlow,SKILL_BLITZ,1.0);
		SC_SetBuff(client,fMaxSpeed,SKILL_BLITZ,1.0);
	}
	else if(newskill==SKILL_BLITZ)
	{
		SC_SetBuff(client,fSlow,SKILL_BLITZ,1.0);
		SC_SetBuff(client,fMaxSpeed,SKILL_BLITZ,1.25);
	}
}

public On_SC_UltimateSkillChanged(client, oldskill, newskill)
{
	if(oldskill==ULT_LIGHTNING)
	{
		SC_SetBuff(client,bDisarm,ULT_LIGHTNING,false);
	}
	else if(newskill==ULT_LIGHTNING)
	{
		SC_SetBuff(client,bDisarm,ULT_LIGHTNING,false);
	}
}

public TF2_OnConditionAdded(client, TFCond:condition)
{
	if(ValidPlayer(client))
	{
		if(TF2_IsPlayerInCondition(client,TFCond_OnFire) && SC_GetSkill(client,talent)==SKILL_BLITZ)
		{
			//DP("Player is on fire!");

			SC_SetBuff(client,fMaxSpeed,SKILL_BLITZ,1.0);
			SC_SetBuff(client,fSlow,SKILL_BLITZ,0.80);
		}
	}
}

public TF2_OnConditionRemoved(client, TFCond:condition)
{
	if(ValidPlayer(client))
	{
		if(!(TF2_IsPlayerInCondition(client,TFCond_OnFire)) && SC_GetSkill(client,talent)==SKILL_BLITZ)
		{
			SC_SetBuff(client,fSlow,SKILL_BLITZ,1.0);
			SC_SetBuff(client,fMaxSpeed,SKILL_BLITZ,1.40);
		}
	}
}

public DoChain(client,Float:distance,Float:dmg,bool:first_call,last_target)
{
	new target=0;
	new Float:target_dist=distance+1.0; // just an easy way to do this
	new caster_team=GetClientTeam(client);
	new Float:start_pos[3];
	if(last_target<=0)
		GetClientAbsOrigin(client,start_pos);
	else
		GetClientAbsOrigin(last_target,start_pos);
	for(new x=1;x<=MaxClients;x++)
	{
		if(ValidPlayer(x,true)&&!bBeenHit[client][x]&&caster_team!=GetClientTeam(x)&&!SC_HasImmunity(x,Immunity_Ultimates))
		{
			new Float:this_pos[3];
			GetClientAbsOrigin(x,this_pos);
			new Float:dist_check=GetVectorDistance(start_pos,this_pos);
			if(dist_check<=target_dist)
			{
				// found a candidate, whom is currently the closest
				target=x;
				target_dist=dist_check;
			}
		}
	}
	if(target<=0)
	{
	//DP("no target");
		// no target, if first call dont do cooldown
		if(first_call)
		{
			SC_MsgNoTargetFound(client,distance);
		}
		else
		{
			// alright, time to cooldown
			new Float:cooldown=GetConVarFloat(ultCooldownCvar);
			//native SC_CooldownMGR(client,Float:cooldownTime,skillid, bool:resetOnSpawn=true,bool:printMsgOnExpireByTime=true);
			SC_CooldownMGR(client,cooldown,ULT_LIGHTNING,_,_);
			SC_SetBuff(client,bDisarm,ULT_LIGHTNING,true); //since this is where the cooldown activates it seems appropriate to activate the disarm here - Dagothur 1/16/2013
			//DP("CD %f %d %d",cooldown,thisRaceID,ULT_LIGHTNING);
		}
	}
	else
	{
	// found someone
		new myDmg=RoundFloat(float(SC_GetMaxHP(target))*dmg);
		new String:buffer[512];
		GetClientName(target, buffer, sizeof(buffer));
		SC_ChatMessage(client,"(Chain Damage) %i to %s!",myDmg,buffer);
		bBeenHit[client][target]=true; // don't let them get hit twice

		SC_DealDamage(target,myDmg,client,DMG_ENERGYBEAM,"chainlightning");
		PrintHintText(target,"Hit by Chain Lightning -%i HP",SC_GetWar3DamageDealt());
		SC_FlashScreen(target,RGBA_COLOR_RED);
		start_pos[2]+=30.0; // offset for effect
		decl Float:target_pos[3],Float:vecAngles[3];
		GetClientAbsOrigin(target,target_pos);
		target_pos[2]+=30.0;
		TE_SetupBeamPoints(start_pos,target_pos,BeamSprite,HaloSprite,0,35,1.0,25.0,25.0,0,10.0,{255,100,255,255},40);
		TE_SendToAll();
		GetClientEyeAngles(target,vecAngles);
		TE_SetupBloodSprite(target_pos, vecAngles, {200, 20, 20, 255}, 28, BloodSpray, BloodDrop);
		TE_SendToAll();
		EmitSoundToAll( lightningSound , target,_,SNDLEVEL_TRAIN);
		new Float:new_dmg=dmg*0.80;
	
		DoChain(client,distance,new_dmg,false,target);//
	
	}
}

public OnUltimateCommand(client,bool:pressed,bool:bypass)
{
	if(pressed && SC_GetSkill(client,ultimate)==ULT_LIGHTNING && IsPlayerAlive(client))
	{
		if((bypass||SC_SkillNotInCooldown(client,ULT_LIGHTNING,true))&&!Silenced(client))
		{
				
			for(new x=1;x<=MaxClients;x++)
				bBeenHit[client][x]=false;
	
			DoChain(client,450.0,0.35,true,0); // This function should also handle if there aren't targets
			
			CreateTimer(1.0,Enable_Attack,GetClientUserId(client));
		}
		else
		{
			SC_MsgUltNotLeveled(client);
		}
	}
}

public Action:Enable_Attack(Handle:timer,any:userid)
{
	new client=GetClientOfUserId(userid);
	if(ValidPlayer(client))
	{
		SC_SetBuff(client,bDisarm,ULT_LIGHTNING,false);
	}
}


new totalChecks;   // dont use int:totalChecks; gave tagmismatch
new checkArray[20][4];

public OnMapStart()
{
	decl String:mapname[128];
    GetCurrentMap(mapname, sizeof(mapname));
	//DP(mapname);
	if (strcmp(mapname, "pl_goldrush", false) == 0) {
		totalChecks = 2;
		checkArray[0][0] = -2200; //x < 
		checkArray[0][1] = -3700; //x >
		checkArray[0][2] = 1700; //y >
		checkArray[0][3] = 2200; //y <
		
		checkArray[1][0] = -4100;
		checkArray[1][1] = -4700;
		checkArray[1][2] = -2666;
		checkArray[1][3] = -2255;
	} else if (strcmp(mapname, "koth_nucleus", false) == 0)	{
		totalChecks = 6;
		checkArray[0][0] = -1300; //x < 
		checkArray[0][1] = -1500; //x >
		checkArray[0][2] = -450; //y >
		checkArray[0][3] = 400; //y <
		
		checkArray[1][0] = 1500; //x < 
		checkArray[1][1] = 1200; //x >
		checkArray[1][2] = -400; //y >
		checkArray[1][3] = 400; //y <
		
		checkArray[2][0] = 2000; //x < not bugged
		checkArray[2][1] = 1600; //x >
		checkArray[2][2] = 100; //y >
		checkArray[2][3] = 400; //y <
		
		checkArray[3][0] = 1800; //x < not bugged
		checkArray[3][1] = 1100; //x >
		checkArray[3][2] = -1000; //y >
		checkArray[3][3] = -700; //y <
		
		checkArray[4][0] = -1100; //x < not bugged
		checkArray[4][1] = -1900; //x >
		checkArray[4][2] = -1000; //y >
		checkArray[4][3] = -700; //y <
		
		checkArray[5][0] = -1600; //x < not bugged
		checkArray[5][1] = -2000; //x >
		checkArray[5][2] = 100; //y >]
		checkArray[5][3] = 400; //y <
		
	}	 else if (strcmp(mapname, "koth_viaduct", false) == 0)	{
		totalChecks = 2;
		checkArray[0][0] = -928; //x < 
		checkArray[0][1] = -1800; //x >
		checkArray[0][2] = 2823; //y >
		checkArray[0][3] = 3224; //y <
		
		checkArray[1][0] = -1000;
		checkArray[1][1] = -1700;
		checkArray[1][2] = -3200;
		checkArray[1][3] = -2800;
	}  else if (strcmp(mapname, "koth_lakeside_final", false) == 0)	{
		totalChecks = 2;
		checkArray[0][0] = 3400; //x < 
		checkArray[0][1] = 2800; //x >
		checkArray[0][2] = -1000; //y >
		checkArray[0][3] = -50; //y <
		
		checkArray[1][0] = -2600;
		checkArray[1][1] = -3400;
		checkArray[1][2] = -1000;
		checkArray[1][3] = 50;
	} else if (strcmp(mapname, "koth_harvest_final", false) == 0)	{
		totalChecks = 2;
		checkArray[0][0] = 900; //x < 
		checkArray[0][1] = 27; //x >
		checkArray[0][2] = 1700; //y >
		checkArray[0][3] = 2100; //y <
		
		checkArray[1][0] = -27;
		checkArray[1][1] = -900;
		checkArray[1][2] = -2100;
		checkArray[1][3] = -1700;
	}  else if (strcmp(mapname, "pl_badwater", false) == 0)	{
		totalChecks = 5;
		checkArray[0][0] = -1000; //x < 
		checkArray[0][1] = -1300; //x >
		checkArray[0][2] = -80; //y >
		checkArray[0][3] = 200; //y <
		
		checkArray[1][0] = 255;
		checkArray[1][1] = -230;
		checkArray[1][2] = -90;
		checkArray[1][3] = 300;
		
		checkArray[2][0] = 550; //x < 
		checkArray[2][1] = 375; //x >
		checkArray[2][2] = 150; //y >
		checkArray[2][3] = 900; //y <
		
		checkArray[3][0] = 3200;


		checkArray[3][1] = 2650;
		checkArray[3][2] = -2000;
		checkArray[3][3] = -400;
		
		checkArray[4][0] = -1500; //x < 
		checkArray[4][1] = -2250; //x >
		checkArray[4][2] = -1100; //y >
		checkArray[4][3] = -725; //y <
	} else if (strcmp(mapname, "pl_upward", false) == 0)	{
		totalChecks = 6;
		checkArray[0][0] = -600; //x < 
		checkArray[0][1] = -1000; //x >
		checkArray[0][2] = -2300; //y >
		checkArray[0][3] = -1900; //y <
		
		checkArray[1][0] = -1600; //x < 
		checkArray[1][1] = -2000; //x >
		checkArray[1][2] = -1700; //y >
		checkArray[1][3] = -1400; //y <
		
		checkArray[2][0] = -1150; //x < not bugged
		checkArray[2][1] = -1400; //x >
		checkArray[2][2] = -1300; //y >
		checkArray[2][3] = -800; //y <
		
		checkArray[3][0] = 720; //x < not bugged
		checkArray[3][1] = 300; //x >
		checkArray[3][2] = 1000; //y >
		checkArray[3][3] = 1400; //y <
		
		checkArray[4][0] = 1000; //x < not bugged
		checkArray[4][1] = 88; //x >
		checkArray[4][2] = -25; //y >
		checkArray[4][3] = 730; //y <
		
		checkArray[5][0] = 2000; //x < not bugged
		checkArray[5][1] = 1500; //x >
		checkArray[5][2] = -800; //y >]
		checkArray[5][3] = -475; //y <		

		
	}  else if (strcmp(mapname, "cp_dustbowl", false) == 0)	{
		totalChecks = 7;
		checkArray[0][0] = -1750; //x < 
		checkArray[0][1] = -2500; //x >
		checkArray[0][2] = 2264; //y >
		checkArray[0][3] = 3100; //y <
		
		checkArray[1][0] = -1550; //x < 
		checkArray[1][1] = -1800; //x >
		checkArray[1][2] = 1400; //y >
		checkArray[1][3] = 2100; //y <
		
		checkArray[2][0] = 2900; //x < not bugged
		checkArray[2][1] = 1400; //x >
		checkArray[2][2] = -350; //y >
		checkArray[2][3] = 1100; //y <
		
		checkArray[3][0] = -1300; //x < not bugged
		checkArray[3][1] = -2655; //x >
		checkArray[3][2] = -1750; //y >
		checkArray[3][3] = -560; //y <
		
		checkArray[4][0] = -215; //x < not bugged
		checkArray[4][1] = -1300; //x >
		checkArray[4][2] = 250; //y >
		checkArray[4][3] = 1315; //y <
		
		checkArray[5][0] = 300; //x < not bugged
		checkArray[5][1] = -100; //x >
		checkArray[5][2] = 600; //y >]
		checkArray[5][3] = 1000; //y <
		
		checkArray[6][0] = 1300; //x < not bugged
		checkArray[6][1] = 800; //x >
		checkArray[6][2] = 600; //y >]
		checkArray[6][3] = 1000; //y <

	} else if (strcmp(mapname, "pl_hoodoo_final", false) == 0)	{
		totalChecks = 5;
		checkArray[0][0] = 5700; //x < 
		checkArray[0][1] = 5000; //x >
		checkArray[0][2] = 340; //y >
		checkArray[0][3] = 1400; //y <
		
		checkArray[1][0] = 2700; //x < 
		checkArray[1][1] = 1450; //x >
		checkArray[1][2] = -3800; //y >
		checkArray[1][3] = -1750; //y <
		
		checkArray[2][0] = -3400; //x < not bugged
		checkArray[2][1] = -3900; //x >
		checkArray[2][2] = -1650; //y >
		checkArray[2][3] = -1200; //y <
		
		checkArray[3][0] = -4200; //x < not bugged
		checkArray[3][1] = -4800; //x >
		checkArray[3][2] = -1300; //y >
		checkArray[3][3] = -300; //y <
		
		checkArray[4][0] = -7700; //x < not bugged
		checkArray[4][1] = -8800; //x >
		checkArray[4][2] = -1100; //y >
		checkArray[4][3] = 0; //y <
		

		
	} else {
		totalChecks = 0;
	}
	
	BeamSprite=PrecacheModel("materials/sprites/lgtning.vmt");
	HaloSprite=PrecacheModel("materials/sprites/halo01.vmt");
	
	BloodSpray = PrecacheModel("sprites/bloodspray.vmt");
	BloodDrop = PrecacheModel("sprites/blood.vmt");
	
	SC_PrecacheSound(lightningSound);
	SC_PrecacheSound(wardDamageSound);

}

/* SHADOW HUNTER SWAP ABILITY BELOW */
public bool:wardCheck(client)
{
	
	if (!totalChecks)
		return false;
	
	
	new Float:vec[3];
	GetClientAbsOrigin(client, vec);
	
	for(new x=0;x<totalChecks;x++) {
		if (vec[0] < checkArray[x][0] && vec[0] > checkArray[x][1] && vec[1] > checkArray[x][2] && vec[1] < checkArray[x][3]) {
			SC_ChatMessage(client, "You cannot place wards here, cheapo!");
			return true;
		} 
	}
	return false;
}
public OnAbilityCommand(client,abilitybutton,bool:pressed,bool:bypass)
{
	if(SC_GetSkill(client,ability)==SKILL_WARD && abilitybutton==0 && pressed && IsPlayerAlive(client))
	{
		if(!Silenced(client)&&CurrentWardCount[client]<4)
		{
			new iTeam=GetClientTeam(client);
			new bool:conf_found=false;
			new Handle:hCheckEntities=SC_NearBuilding(client);
			new size_arr=0;
			if(hCheckEntities!=INVALID_HANDLE)
				size_arr=GetArraySize(hCheckEntities);
			for(new x=0;x<size_arr;x++)
			{
				new ent=GetArrayCell(hCheckEntities,x);
				if(!IsValidEdict(ent)) continue;
				new builder=GetEntPropEnt(ent,Prop_Send,"m_hBuilder");
				if(builder>0 && ValidPlayer(builder) && GetClientTeam(builder)!=iTeam)
				{
					conf_found=true;
					break;
				}
			}
			if(size_arr>0)
				CloseHandle(hCheckEntities);
			if(conf_found)
			{
				SC_MsgWardLocationDeny(client);
			}
			else
			{
				if(SC_IsCloaked(client))
				{
					SC_MsgNoWardWhenInvis(client);
					return;
				}
				if (CheckWard(client))
				{
					SC_ChatMessage(client,"This ward is too close to another ward");
				} else {
					CreateWard(client);
					CurrentWardCount[client]++;
					SC_MsgCreatedWard(client,CurrentWardCount[client],4);
				}
			}
		}
		else
		{
			SC_MsgNoWardsLeft(client);
		}
	}
}


public On_SC_EventSpawn(client)
{
	RemoveWards(client);
	for(new x=1;x<=MaxClients;x++)
		bBeenHit[client][x]=false;
/*	if(ValidPlayer(client))
	{
		if(IsFakeClient(client))
		{
			if(SC_GetRace(client)==thisRaceID)
			{
			}
		}
	}*/
}

new damagestackcritmatch=-1;
new Float:critpercent=0.0;
public OnSC_TakeDmgBulletPre(victim,attacker,Float:damage)
{
	if(IS_PLAYER(victim)&&IS_PLAYER(attacker)&&victim>0&&attacker>0&&attacker!=victim)
	{
		new vteam=GetClientTeam(victim);
		new ateam=GetClientTeam(attacker);
		if(vteam!=ateam)
		{
			new skill_attacker=SC_GetSkill(attacker,mastery);
			new Float:chance_mod=SC_ChanceModifier(attacker);
			if(skill_attacker==SKILL_CRIT)
			{
				if(!Hexed(attacker,false))
				{
					new Float:chance=0.15*chance_mod;
					if( GetRandomFloat(0.0,1.0)<=chance && !SC_HasImmunity(victim,Immunity_Skills))
					{
						damagestackcritmatch=SC_GetDamageStack();
						new Float:percent=0.25; //0.0 = zero effect -1.0 = no damage 1.0=double damage
						SC_DamageModPercent(percent+1.0);
						critpercent=percent;
					}
				}
			}
		}
	}
}

//need event for weapon string
public On_SC_EventPostHurt(victim,attacker,dmg){
	// Trigger Ultimate on bots 5% chance
	if(ValidPlayer(victim))
	{
		if(IsFakeClient(victim) && SC_GetSkill(victim,ultimate)==ULT_LIGHTNING && SC_Chance(0.05))
		{
			//DP("ultimate should trigger");
			OnUltimateCommand(victim,true,false);
			new Float:cooldown=GetConVarFloat(ultCooldownCvar);
			SC_CooldownMGR(victim,cooldown,ULT_LIGHTNING,true,false);
		}
	}
	if(victim>0&&attacker>0&&victim!=attacker)
	{
		new skill_attacker=SC_GetSkill(attacker,mastery);
		
		if(skill_attacker==SKILL_CRIT)
		{
			if(damagestackcritmatch==SC_GetDamageStack())
			{
				damagestackcritmatch=-1;
				SC_PrintSkillDmgHintConsole(victim,attacker,RoundFloat(float(dmg)*critpercent/(critpercent+1.0)),SKILL_CRIT);	
				SC_FlashScreen(victim,RGBA_COLOR_RED);	
			}
		}
	}
}

/*
public On_SC_EventDeath(index,attacker)
{
} */
CheckWard(client)
{
	new Float:loc[3];
	GetClientAbsOrigin(client,loc);
	for(new i=0;i<MAXWARDS;i++)
	{
		if(WardOwner[i]!=0)
		{
			PrintToServer("%i",i);
			new Float:loc2[3];
			loc2=WardLocation[i];
			if (GetVectorDistance(loc,loc2) < 185.0)
				return 1;
		}
	}
	return 0;
}
/* *********************** SHADOW HUNTER SWAP ************************* */

CreateWard(client)
{
	for(new i=0;i<MAXWARDS;i++)
	{
		if(WardOwner[i]==0)
		{
			WardOwner[i]=client;
			GetClientAbsOrigin(client,WardLocation[i]);
			break;
			////CHECK BOMB HOSTAGES TO BE IMPLEMENTED
		}
	}
}

RemoveWards(client)
{
	for(new i=0;i<MAXWARDS;i++)
	{
		if(WardOwner[i]==client)
		{
			WardOwner[i]=0;
		}
	}
	CurrentWardCount[client]=0;
}

public Action:CalcWards(Handle:timer,any:userid)
{
	new client;
	for(new i=0;i<MAXWARDS;i++)
	{
		if(WardOwner[i]!=0)
		{
			client=WardOwner[i];
			if(!ValidPlayer(client,true))
			{
				WardOwner[i]=0; //he's dead, so no more wards for him
				--CurrentWardCount[client];
			}
			else
			{
				WardEffectAndDamage(client,i);
			}
		}
	}
}
public WardEffectAndDamage(owner,wardindex)
{
	new ownerteam=GetClientTeam(owner);
	new beamcolor[]={0,0,200,255};
	if(ownerteam==2)
	{ //TERRORISTS/RED in TF?
		beamcolor[0]=255;
		beamcolor[1]=0;
		beamcolor[2]=0;

		beamcolor[3]=155; //red blocks more than blue, so less alpha
	}


	new Float:start_pos[3];
	new Float:end_pos[3];

	new Float:tempVec1[]={0.0,0.0,WARDBELOW};
	new Float:tempVec2[]={0.0,0.0,WARDABOVE};
	AddVectors(WardLocation[wardindex],tempVec1,start_pos);
	AddVectors(WardLocation[wardindex],tempVec2,end_pos);

	TE_SetupBeamPoints(start_pos,end_pos,BeamSprite,HaloSprite,0,GetRandomInt(30,100),0.17,float(WARDRADIUS),float(WARDRADIUS),0,0.0,beamcolor,10);
	TE_SendToAll();

	new Float:BeamXY[3];
	for(new x=0;x<3;x++) BeamXY[x]=start_pos[x]; //only compare xy
	//new Float:BeamZ= BeamXY[2];
	BeamXY[2]=0.0;


	new Float:VictimPos[3];
	//new Float:tempZ;
	for(new i=1;i<=MaxClients;i++)
	{
		if(ValidPlayer(i,true)&& GetClientTeam(i)!=ownerteam )
		{
			GetClientAbsOrigin(i,VictimPos);
			//tempZ=VictimPos[2];
			VictimPos[2]=0.0; //no Z

			if(GetVectorDistance(BeamXY,VictimPos) < WARDRADIUS) ////ward RADIUS
			{
				// now compare z
				//if(tempZ>BeamZ+WARDBELOW && tempZ < BeamZ+WARDABOVE)
				//{
				if(SC_HasImmunity(i,Immunity_Wards))
				{
					SC_MsgSkillBlocked(i,_,"Wards");
				}
				else
				{
					new newWARDDAMAGE=RoundToCeil(FloatMul(WARDDAMAGE,float(SC_GetMaxHP(i))));
					new newOwner=owner;
					//Boom!
					new DamageScreen[4];
					DamageScreen[0]=beamcolor[0];
					DamageScreen[1]=beamcolor[1];
					DamageScreen[2]=beamcolor[2];
					DamageScreen[3]=50; //alpha
					SC_FlashScreen(i,DamageScreen);

					SC_FlashScreen(owner,DamageScreen);
					new String:buffer[512];
					GetClientName(i, buffer, sizeof(buffer));
					SC_ChatMessage(owner,"(Ward Damage) %i to %s!",newWARDDAMAGE,buffer);

					if(SC_DealDamage(i,newWARDDAMAGE,newOwner,DMG_ENERGYBEAM,"wards",_,SC_DMGTYPE_MAGIC))
					{
						if(LastThunderClap[i]<GetGameTime()-2)
						{
							EmitSoundToAll(wardDamageSound,i,SNDCHAN_WEAPON);
							LastThunderClap[i]=GetGameTime();
						}
					}
				}
				//}
			}
		}
	}

}
