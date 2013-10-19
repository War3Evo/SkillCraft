#pragma semicolon 1

#include <sourcemod>
#include "SkillCraft_Includes/SkillCraft_Interface"
#include <sdktools>
#include <sdktools_functions>
#include <sdktools_tempents>
#include <sdktools_tempents_stocks>

new SKILL_HEALINGWAVE, SKILL_RECARN_WARD, ULT_VOODOO;

//skill 3
// Healing Ward Specific
#define MAXWARDS 64*4 //on map LOL
#define WARDRADIUS 70
// WARDHEAL WAS 4
#define WARDHEAL 25
#define WARDBELOW -2.0 // player is 60 units tall about (6 feet)
#define WARDABOVE 160.0
new CurrentWardCount[MAXPLAYERSCUSTOM];
new Float:WardLocation[MAXWARDS][3];
new WardOwner[MAXWARDS];


//ultimate
new Handle:ultCooldownCvar;

new bool:flashedscreen[MAXPLAYERSCUSTOM];

new bool:bVoodoo[65];

new String:ultimateSound[]="war3source/divineshield.wav";
new String:wardDamageSound[]="war3source/thunder_clap.wav";

new bool:particled[MAXPLAYERSCUSTOM]; //heal particle


new BeamSprite,HaloSprite; //wards
//new AuraID;
public Plugin:myinfo = 
{
	name = "Skills from Shadow Paladin Race",
	author = "SkillCraft Team",
	description = "Skills from Shadow Paladin Race",
	version = "1.0.0.0",
};

public OnPluginStart()
{
	ultCooldownCvar=CreateConVar("sc_hunter_voodoo_cooldown","20","Cooldown between Big Bad Voodoo (ultimate)");
	CreateTimer(1.0,CalcWards,_,TIMER_REPEAT);
	CreateTimer(1.0,CalcHexHealWaves,_,TIMER_REPEAT);
}

public On_SC_LoadSkillOrdered(num)
{
	if(num==60)
	{
		SKILL_HEALINGWAVE=SC_CreateNewSkill("Healing Wave","HealingWave",
		"Heal teammates around you (8hp/s)",talent);
	}
	if(num==60)
	{
		SKILL_RECARN_WARD=SC_CreateNewSkill("Healing Ward","HealingWard",
		"Use +ability to make healing wards!\nBe strategic, ward heals both teams!",ability);
	}
	if(num==60)
	{
		ULT_VOODOO=SC_CreateNewSkill("Big Bad Voodoo","BigBadVoodoo",
		"You are invulnerable from physical attacks for 2.0 seconds",ultimate);
	}

}

public On_SC_EventSpawn(client){
	bVoodoo[client]=false;
	RemoveWards(client);
}

public OnMapStart()
{
	BeamSprite=PrecacheModel("materials/sprites/lgtning.vmt");
	HaloSprite=PrecacheModel("materials/sprites/halo01.vmt");
	
	SC_PrecacheSound(ultimateSound);
	SC_PrecacheSound(wardDamageSound);
}

public On_SC_PlayerAuthed(client)
{
	bVoodoo[client]=false;
}

public On_SC_TalentSkillChanged(client, oldskill, newskill)
{
	if(oldskill==SKILL_HEALINGWAVE)
	{
		SC_SetBuff(client,fHPRegen,SKILL_HEALINGWAVE,0.0);
	}
	else if(oldskill==SKILL_RECARN_WARD)
	{
		RemoveWards(client);
	}
}

public OnUltimateCommand(client,bool:pressed,bool:bypass)
{
	new userid=GetClientUserId(client);
	if(SC_HasSkill(client,ULT_VOODOO) && pressed && userid>1 && IsPlayerAlive(client) )
	{
		if(!Silenced(client)&&SC_SkillNotInCooldown(client,ULT_VOODOO,true))
		{
			bVoodoo[client]=true;
			
			SC_SetPlayerColor(client,ULT_VOODOO,255,200,0,_,GLOW_ULTIMATE); //255,200,0);
			CreateTimer(2.0,EndVoodoo,client);
			new Float:cooldown=	GetConVarFloat(ultCooldownCvar);
			SC_CooldownMGR(client,cooldown,ULT_VOODOO,_,_);
			SC_MsgUsingVoodoo(client);
			EmitSoundToAll(ultimateSound,client);
			EmitSoundToAll(ultimateSound,client);
		}
	}
}



public Action:EndVoodoo(Handle:timer,any:client)
{
	bVoodoo[client]=false;
	SC_ResetPlayerColor(client,ULT_VOODOO);
	if(ValidPlayer(client,true))
	{
		SC_MsgVoodooEnded(client);
	}
}

public Action:CalcHexHealWaves(Handle:timer,any:userid)
{
	if(SKILL_HEALINGWAVE>0)
	{
		for(new i=1;i<=MaxClients;i++)
		{
			particled[i]=false;
			if(ValidPlayer(i,true))
			{
				if(SC_HasSkill(i,SKILL_HEALINGWAVE))
				{
					HealWave(i); //check leves later
				}
			}
		}
	}
}

/* ORC SWAP ABILITY BELOW */

public OnAbilityCommand(client,abilitybutton,bool:pressed)
{
	if(SC_HasSkill(client,SKILL_RECARN_WARD) && abilitybutton==0 && pressed && IsPlayerAlive(client))
	{
		if(!Silenced(client))
		{
			if(CurrentWardCount[client]<4)
			{
				CreateWard(client);
				CurrentWardCount[client]++;

				SC_MsgCreatedWard(client,CurrentWardCount[client],4);
			}
			else
			{
				SC_MsgNoWardsLeft(client);
			}
		}
	}
}



public OnSC_TakeDmgAllPre(victim,attacker,Float:damage)
{
	if(IS_PLAYER(victim)&&IS_PLAYER(attacker)&&victim>0&&attacker>0) //block self inflicted damage
	{
		if(bVoodoo[victim]&&attacker==victim){
			SC_DamageModPercent(0.0);
			return;
		}
		new vteam=GetClientTeam(victim);
		new ateam=GetClientTeam(attacker);
		
		
		if(vteam!=ateam)
		{
			if(bVoodoo[victim])
			{
				if(!SC_HasImmunity(attacker,Immunity_Ultimates))
				{
					decl Float:pos[3];
					GetClientEyePosition(victim, pos);
					pos[2] += 4.0;
					SC_TF_ParticleToClient(0, "miss_text", pos); //to the attacker at the enemy pos

					//SC_TF_ParticleToClient(0, "healthgained_blu", pos);
					SC_DamageModPercent(0.0);
				}
				else
				{
					SC_MsgEnemyHasImmunity(victim,true);
				}
			}
		}
	}
	return;
}

public HealWave(client)
{
	//assuming client exists and has this race
	if(!Hexed(client,false))
	{
		new Float:dist = 400.0;
		new HealerTeam = GetClientTeam(client);
		new Float:HealerPos[3];
		GetClientAbsOrigin(client,HealerPos);
		new Float:VecPos[3];

		for(new i=1;i<=MaxClients;i++)
		{
			if(ValidPlayer(i,true)&&GetClientTeam(i)==HealerTeam)
			{
				GetClientAbsOrigin(i,VecPos);
				if(GetVectorDistance(HealerPos,VecPos)<=dist)
				{
					SC_SetBuff(i,fHPRegen,SKILL_HEALINGWAVE,8.0);

					if(!particled[i]){
						particled[i]=true;
						VecPos[2]+=65.0;

						SC_TF_ParticleToClient(0, HealerTeam==2?"healthgained_red":"healthgained_blu", VecPos);

					}
				}
				else
				{
					if(!SC_HasSkill(i,SKILL_HEALINGWAVE))
					{
						SC_SetBuff(i,fHPRegen,SKILL_HEALINGWAVE,0.0);
					}
				}
			}
		}
	}
}

//=======================================================================
//                  HEALING WAVE PARTICLE EFFECT (TF2 ONLY!)
//=======================================================================

// Written by FoxMulder with some tweaks by me https://forums.alliedmods.net/showpost.php?p=909189&postcount=7
/*
AttachParticles(ent, String:particleType[], controlpoint)
{
	if(SC_GetGame() == Game_TF)
	{
		new particle  = CreateEntityByName("info_particle_system");
		new particle2 = CreateEntityByName("info_particle_system");
		if (IsValidEdict(particle))
		{
			new String:tName[128];
			Format(tName, sizeof(tName), "target%i", ent);
			DispatchKeyValue(ent, "targetname", tName);

			new String:cpName[128];
			Format(cpName, sizeof(cpName), "target%i", controlpoint);
			DispatchKeyValue(controlpoint, "targetname", cpName);

			//--------------------------------------
			new String:cp2Name[128];
			Format(cp2Name, sizeof(cp2Name), "tf2particle%i", controlpoint);

			DispatchKeyValue(particle2, "targetname", cp2Name);
			DispatchKeyValue(particle2, "parentname", cpName);

			SetVariantString(cpName);
			AcceptEntityInput(particle2, "SetParent");

			SetVariantString("flag");
			AcceptEntityInput(particle2, "SetParentAttachment");
			//-----------------------------------------------

			DispatchKeyValue(particle, "targetname", "tf2particle");
			DispatchKeyValue(particle, "parentname", tName);
			DispatchKeyValue(particle, "effect_name", particleType);
			DispatchKeyValue(particle, "cpoint1", cp2Name);

			DispatchSpawn(particle);

			SetVariantString(tName);
			AcceptEntityInput(particle, "SetParent");

			SetVariantString("flag");
			AcceptEntityInput(particle, "SetParentAttachment");

			//The particle is finally ready
			ActivateEntity(particle);
			AcceptEntityInput(particle, "start");

			ParticleEffect[ent][controlpoint] = particle;
		}
	}
}

StopParticleEffect(client, bKill)
{
	if(SC_GetGame() == Game_TF)
	{
		for(new i=1; i <= MaxClients; i++)
		{
			decl String:className[64];
			decl String:className2[64];

			if(IsValidEdict(ParticleEffect[client][i]))
				GetEdictClassname(ParticleEffect[client][i], className, sizeof(className));
			if(IsValidEdict(ParticleEffect[i][client]))
			GetEdictClassname(ParticleEffect[i][client], className2, sizeof(className2));

			if(StrEqual(className, "info_particle_system"))
			{
				if(IsValidEntity(ParticleEffect[i][client]))
				{
					AcceptEntityInput(ParticleEffect[i][client], "stop");
				}
//				AcceptEntityInput(ParticleEffect[client][i], "stop");
				if(bKill && IsValidEntity(ParticleEffect[client][i]))
					{
						AcceptEntityInput(ParticleEffect[client][i], "kill");
						ParticleEffect[client][i] = 0;
					}
			}

			if(StrEqual(className2, "info_particle_system"))
			{
				if(IsValidEntity(ParticleEffect[i][client]))
				{
					AcceptEntityInput(ParticleEffect[i][client], "stop");
				}
				if(bKill && IsValidEntity(ParticleEffect[i][client]))
					{
						AcceptEntityInput(ParticleEffect[i][client], "kill");
						ParticleEffect[i][client] = 0;
					}
			}
		}
	}
}


public Action:HealingWaveParticleTimer(Handle:timer, any:userid)
{
	if(SC_GetGame() == Game_TF)
		for(new client=1; client <= MaxClients; client++)
			if(ValidPlayer(client, true))
				if(SC_GetRace(client) == thisRaceID)
				{
	 				new skill = SC_GetSkillLevel(client,thisRaceID,SKILL_HEALINGWAVE) + SC_GetSkillLevel(client,thisRaceID,SKILL_IMPROVEDHEALING);
					if(skill > 0)
					{
						new Float:HealerPos[3];
						new Float:TeammatePos[3];
						new Float:maxDistance = HealingWaveDistanceArr[skill];

						GetClientAbsOrigin(client, HealerPos);

						for(new i=1; i <= MaxClients; i++)
							if(ValidPlayer(i, true) && GetClientTeam(i) == GetClientTeam(client) && (i != client))
							{
								if(IsValidEdict(ParticleEffect[client][i]))
								{
									decl String:className[64];
									GetEdictClassname(ParticleEffect[client][i], className, sizeof(className));

									GetClientAbsOrigin(i, TeammatePos);
									if(GetVectorDistance(HealerPos, TeammatePos) <= maxDistance)
									{
										if(StrEqual(className, "info_particle_system"))
											AcceptEntityInput(ParticleEffect[client][i], "start");
										else
											switch(GetClientTeam(client))
											{
												case(2):
													AttachParticles(client, "medicgun_beam_red", i);
													//AttachParticles(client, "medicgun_beam_red", i);
												case(3):
												//	AttachParticles(client, "medicgun_beam_blue", i);
													AttachParticles(client, "medicgun_beam_blue", i);
											}
									}
									else
									{
										if(StrEqual(className, "info_particle_system"))
											AcceptEntityInput(ParticleEffect[client][i], "stop");
									}
								}
							}
					}
				}
}



 ******************** ORC HEALING ****************************** */
// Wards
public CreateWard(client)
{
	for(new i=0;i<MAXWARDS;i++)
	{
		if(WardOwner[i]==0)
		{
			WardOwner[i]=client;
			GetClientAbsOrigin(client,WardLocation[i]);
			break;
		}
	}
}

public RemoveWards(client)
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
	for(new i=0;i<=MaxClients;i++){
		flashedscreen[i]=false;
	}
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
				WardEffectAndHeal(client,i);
			}
		}
	}
}
//healing wards
public WardEffectAndHeal(owner,wardindex)
{
	new beamcolor[]={0,255,0,150};
	new Float:start_pos[3];
	new Float:end_pos[3];
	new Float:tempVec1[]={0.0,0.0,WARDBELOW};
	new Float:tempVec2[]={0.0,0.0,WARDABOVE};
	AddVectors(WardLocation[wardindex],tempVec1,start_pos);
	AddVectors(WardLocation[wardindex],tempVec2,end_pos);
	TE_SetupBeamPoints(start_pos,end_pos,BeamSprite,HaloSprite,0,GetRandomInt(30,100),1.2,float(WARDRADIUS),float(WARDRADIUS),0,30.0,beamcolor,10);
	TE_SendToAll();
	new Float:BeamXY[3];
	for(new x=0;x<3;x++) BeamXY[x]=start_pos[x]; //only compare xy
	new Float:BeamZ= BeamXY[2];
	BeamXY[2]=0.0;
	new Float:VictimPos[3];
	new Float:tempZ;

	for(new i=1;i<=MaxClients;i++)
	{
		if(ValidPlayer(i,true))
		{
			GetClientAbsOrigin(i,VictimPos);
			tempZ=VictimPos[2];
			VictimPos[2]=0.0; //no Z
			if(GetVectorDistance(BeamXY,VictimPos) < WARDRADIUS) ////ward RADIUS
			{
				// now compare z
				if(tempZ>BeamZ+WARDBELOW && tempZ < BeamZ+WARDABOVE)
				{
					//Heal!!
					new DamageScreen[4];
					DamageScreen[0]=beamcolor[0];
					DamageScreen[1]=beamcolor[1];
					DamageScreen[2]=beamcolor[2];
					DamageScreen[3]=20; //alpha
					new cur_hp=GetClientHealth(i);
					new new_hp=cur_hp+WARDHEAL;
					new max_hp=SC_GetMaxHP(i);
					if(new_hp>max_hp)	new_hp=max_hp;
					if(cur_hp<new_hp)
					{
						if(!flashedscreen[i]){
							flashedscreen[i]=true;
							SC_FlashScreen(i,DamageScreen);
						}
						//SetEntityZHealth(i,new_hp);
						SC_HealToMaxHP(i,WARDHEAL);
						VictimPos[2]+=65.0;
						SC_TF_ParticleToClient(0, GetApparentTeam(i)==2?"healthgained_red":"healthgained_blu", VictimPos);
					}
				}
			}
		}
	}
}
