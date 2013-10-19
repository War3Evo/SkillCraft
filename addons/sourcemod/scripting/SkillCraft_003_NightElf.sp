#pragma semicolon 1
 
#include <sourcemod>
#include "SkillCraft_Includes/SkillCraft_Interface"
#include <sdktools>
#include <sdkhooks>

// Skill Evade
new Float:skill_evade_chance = 0.03;

new Float:skill_thorns_damage_multiplier = 0.10;
// anything over 1.0 is the percent of extra damage for trueshot
new Float:skill_trueshot_modpercent = 1.05;

// for every 1 foot multiply by 10
new Float:entangle_distance = 600.0;
new Float:entangle_time=1.25;

new bool:bIsEntangled[MAXPLAYERSCUSTOM];

new bool:Phlogistinator[MAXPLAYERSCUSTOM];

new Handle:EntangleCooldownCvar; // cooldown

//new Handle:hWeaponDrop;


new SKILL_EVADE, SKILL_THORNS, SKILL_TRUESHOT, ULT_ENTANGLE;

new String:entangleSound[]="war3source/entanglingrootsdecay1.mp3";
//new String:entangleSound[256]; //="war3source/entanglingrootsdecay1.mp3";

// Effects
new TeleBeam,BeamSprite,HaloSprite;

//new String:RaceShortName[]="nightelf";
 
public Plugin:myinfo = 
{
	name = "Skills from of Night Elf",
	author = "SkillCraft Team",
	description = "Skills from Night Elf",
	version = "1.0.0.0",
};

public OnPluginStart()
{
	EntangleCooldownCvar=CreateConVar("sc_nightelf_entangle_cooldown","20","Cooldown timer.");
}


public OnMapStart()
{
	strcopy(entangleSound,sizeof(entangleSound),"war3source/entanglingrootsdecay1.mp3");
	TeleBeam=PrecacheModel("materials/sprites/tp_beam001.vmt");

	BeamSprite=SC_PrecacheBeamSprite();
	HaloSprite=SC_PrecacheHaloSprite();
	
	SC_PrecacheSound(entangleSound);
}

/* ***************************  On_SC_LoadRaceOrItemOrdered2 *************************************/

public On_SC_LoadSkillOrdered(num)
{
	if(num==40)
	{
		SKILL_EVADE=SC_CreateNewSkill("Evasion","Evasion",
		"3 percent chance of evading a shot",talent);
	}
	if(num==41)
	{
		SKILL_THORNS=SC_CreateNewSkill("Thorns Aura","ThornsAura",
		"You deal 10 percent of damage recieved to your attacker",mastery);
	}
	if(num==42)
	{
		SKILL_TRUESHOT=SC_CreateNewSkill("Trueshot Aura","TrueshotAura",
		"Your attacks deal 5 percent more damage\nPhlogistinator messes with your aura and can not trigger this skill.",mastery);
	}
	if(num==43)
	{
		ULT_ENTANGLE=SC_CreateNewSkill("Entangling Roots","EntangleRoot",
		"Bind enemies to the ground,\nrendering them immobile for 1.25 seconds\nDistance of 60 feet.",ultimate);
	}
}

public SDK_OnWeaponSwitchPost(client, weapon)
{

	if(ValidPlayer(client))
	{
		if(SC_HasSkill(client,SKILL_TRUESHOT) && weapon>-1)
		{
			new weaponindex = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
			if(weaponindex==594)
			{
				Phlogistinator[client]=true;
			}
		}
		else
		Phlogistinator[client]=false;
	}
}

public OnClientDisconnect(client){
	SDKUnhook(client,SDKHook_WeaponSwitchPost,SDK_OnWeaponSwitchPost);
	Phlogistinator[client]=false;
}

/* ****************************** SKILL_TRUESHOT RemovePassiveSkills ************************** */
RemovePassiveSkills(client)
{
	SDKUnhook(client,SDKHook_WeaponSwitchPost,SDK_OnWeaponSwitchPost);
	Phlogistinator[client]=false;
}

/* ****************************** SKILL_TRUESHOT InitPassiveSkills ************************** */
InitPassiveSkills(client)
{
	new activeweapon = FindSendPropOffs("CTFPlayer", "m_hActiveWeapon");
	new activeweapondata = GetEntDataEnt2(client, activeweapon);
	if(IsValidEntity(activeweapondata))
	{
		new weaponindex = GetEntProp(activeweapondata, Prop_Send, "m_iItemDefinitionIndex");
		if(weaponindex==594)
		{
			Phlogistinator[client]=true;
		}
	}
	SDKHook(client,SDKHook_WeaponSwitchPost,SDK_OnWeaponSwitchPost);
}

/* ***************************  SKILL_TRUESHOT SKILL CHANGE *************************************/
public On_SC_MasterySkillChanged(client, oldskill, newskill)
{
	if(oldskill==SKILL_TRUESHOT)
	{
		RemovePassiveSkills(client);
	}
	else if(newskill==SKILL_TRUESHOT)
	{
		InitPassiveSkills(client);
	}
}




public DropWeapon(client,weapon)
{
//	new Float:angle[3];
//	GetClientEyeAngles(client,angle);
//	new Float:dir[3];
//	GetAngleVectors(angle,dir,NULL_VECTOR,NULL_VECTOR);
//	ScaleVector(dir,20.0);
//	SDKCall(hWeaponDrop,client,weapon,NULL_VECTOR,dir);
}


new ClientTracer;

public bool:AimTargetFilter(entity,mask)
{
	return !(entity==ClientTracer);
}

public bool:ImmunityCheck(client)
{
	if(bIsEntangled[client]||SC_HasImmunity(client,Immunity_Ultimates))
	{
		return false;
	}
	return true;
}

public OnUltimateCommand(client,bool:pressed,bool:bypass)
{
	if(SC_HasSkill(client,ULT_ENTANGLE) && IsPlayerAlive(client) && pressed)
	{
		// Spys should be visible to use this ultimate
		if(!Spying(client))
		{
			if(!Silenced(client) && SC_SkillNotInCooldown(client,ULT_ENTANGLE,true))
			{
			
				new target; // easy support for both
				new Float:our_pos[3];
				GetClientAbsOrigin(client,our_pos);
		
				target=SC_GetTargetInViewCone(client,entangle_distance,false,23.0,ImmunityCheck);
				if(ValidPlayer(target,true))
				{
			
					bIsEntangled[target]=true;
			
					SC_SetBuff(target,bNoMoveMode,ULT_ENTANGLE,true);
					CreateTimer(entangle_time,StopEntangle,target);
					new Float:effect_vec[3];
					GetClientAbsOrigin(target,effect_vec);
					effect_vec[2]+=15.0;
					TE_SetupBeamRingPoint(effect_vec,45.0,44.0,BeamSprite,HaloSprite,0,15,entangle_time,5.0,0.0,{0,255,0,255},10,0);
					TE_SendToAll();
					effect_vec[2]+=15.0;
					TE_SetupBeamRingPoint(effect_vec,45.0,44.0,BeamSprite,HaloSprite,0,15,entangle_time,5.0,0.0,{0,255,0,255},10,0);
					TE_SendToAll();
					effect_vec[2]+=15.0;
					TE_SetupBeamRingPoint(effect_vec,45.0,44.0,BeamSprite,HaloSprite,0,15,entangle_time,5.0,0.0,{0,255,0,255},10,0);
					TE_SendToAll();
					our_pos[2]+=25.0;
					TE_SetupBeamPoints(our_pos,effect_vec,BeamSprite,HaloSprite,0,50,4.0,6.0,25.0,0,12.0,{80,255,90,255},40);
					TE_SendToAll();
					new String:name[64];
					GetClientName(target,name,64);
					//SC_ChatMessage(target,"You have been entangled");//%s!")//,(SC_GetGame()==Game_TF)?", your weapons are POWERLESS until you are released":"");
					SC_EmitSoundToAll(entangleSound,target);
					SC_EmitSoundToAll(entangleSound,target);
				
					SC_MsgEntangle(target,client);
			
				
					SC_CooldownMGR(client,GetConVarFloat(EntangleCooldownCvar),ULT_ENTANGLE,_,_);
				}
				else
				{
					SC_MsgNoTargetFound(client,entangle_distance);
				}
			}
		}
		else
		{
			PrintHintText(client,"You must not be disguised/cloaked!");
		}
	}
}


public Action:StopEntangle(Handle:timer,any:client)
{

	bIsEntangled[client]=false;
	SC_SetBuff(client,bNoMoveMode,ULT_ENTANGLE,false);
	
}

public On_SC_EventSpawn(client)
{	
	if(bIsEntangled[client])
	{
		bIsEntangled[client]=false;
		SC_SetBuff(client,bNoMoveMode,ULT_ENTANGLE,false);
	}
}



public On_SC_TakeDmgBulletPre(victim,attacker,Float:damage)
{
	if(ValidPlayer(victim,true,true)&&ValidPlayer(attacker,true,true)&&attacker!=victim)
	{
		new vteam=GetClientTeam(victim);
		new ateam=GetClientTeam(attacker);
		if(vteam!=ateam)
		{
			//new race_attacker=SC_GetRace(attacker);
			//new race_victim=SC_GetRace(victim);
			
			//evade
			//if they are not this race thats fine, later check for race
			if(SC_HasSkill(victim,SKILL_EVADE)) 
			{
				if(!Hexed(victim,false) && GetRandomFloat(0.0,1.0)<=skill_evade_chance && !SC_HasImmunity(attacker,Immunity_Skills))
				{
					
					SC_FlashScreen(victim,RGBA_COLOR_BLUE);
					
					SC_DamageModPercent(0.0); //NO DAMAMGE
					
					SC_MsgEvaded(victim,attacker);
					decl Float:pos[3];
					GetClientEyePosition(victim, pos);
					pos[2] += 4.0;
					SC_TF_ParticleToClient(0, "miss_text", pos); //to the attacker at the enemy pos
				}
				
			/*	//thorns only if he didnt evade
				else if( skill_level_thorns>0 && IsPlayerAlive(attacker)&&!Hexed(victim,false))
				{                                                                                
					if(!SC_HasImmunity(attacker,Immunity_Skills))
					{
					
						new damage_i=RoundToFloor(damage*ThornsReturnDamage[skill_level_thorns]);
						if(damage_i>0)
						{
							if(damage_i>40) damage_i=40; // lets not be too unfair ;]
							
							//PrintToChatAll("1 %d",SC_GetDamageIsBullet());
							SC_DealDamage(attacker,damage_i,victim,_,"thorns",_,SC_DMGTYPE_PHYSICAL);
						//	PrintToChatAll("2 %d",SC_GetDamageIsBullet());
							//SC_ForceDamageIsBullet();
							
							SC_PrintSkillDmgConsole(attacker,victim,SC_GetWar3DamageDealt(),SKILL_THORNS);	
						}
						//}
					}
				}*/
			}
			
			// Trueshot Aura
			if(SC_HasSkill(attacker,SKILL_TRUESHOT) && IsPlayerAlive(attacker))
			{
				if(Phlogistinator[attacker])
				{
					SC_DamageModPercent(0.75);
				}
				else if(!SC_HasImmunity(victim,Immunity_Skills) && !Hexed(attacker,false))
				{
					SC_DamageModPercent(skill_trueshot_modpercent);
					SC_FlashScreen(victim,RGBA_COLOR_RED);
				}
			}
		}
	}
}
//public On_SC_EventPostHurt(victim,attacker,damage){
public On_SC_TakeDmgAll(victim,attacker,Float:damage)
{
	if(SC_GetDamageIsBullet()&&ValidPlayer(victim,true)&&ValidPlayer(attacker,true)&&GetClientTeam(victim)!=GetClientTeam(attacker))
	{
		
		if(SC_HasSkill(victim,SKILL_THORNS))
		{
			if(!Hexed(victim,false))
			{
				if(!SC_HasImmunity(attacker,Immunity_Skills))
				{
					new damage_i=RoundToFloor(FloatMul(damage,skill_thorns_damage_multiplier));
					if(damage_i>0)
					{
						if(damage_i>40) damage_i=40; // lets not be too unfair ;]
						
						if(SC_DealDamage(attacker,damage_i,victim,_,"thorns",_,SC_DMGTYPE_PHYSICAL))
						{
							decl Float:iVec[3];
							decl Float:iVec2[3];
							GetClientAbsOrigin(attacker, iVec);
							GetClientAbsOrigin(victim, iVec2);
							iVec[2]+=35.0, iVec2[2]+=40.0;
							TE_SetupBeamPoints(iVec, iVec2, TeleBeam, TeleBeam, 0, 45, 0.4, 10.0, 10.0, 0, 0.5, {255,35,15,255}, 30);
							TE_SendToAll();
							iVec2[0]=iVec[0];
							iVec2[1]=iVec[1];
							iVec2[2]=80+iVec[2];
							TE_SetupBubbles(iVec, iVec2, HaloSprite, 35.0,GetRandomInt(6,8),8.0);
							TE_SendToAll();
						}
					}
				}
			}
		}
	}
}

stock TE_SetupBubbles(const Float:vecOrigin[3], const Float:vecFinish[3],modelIndex,const Float:heightF,count,const Float:speedF)
{
	TE_Start("Bubbles");
	TE_WriteVector("m_vecMins", vecOrigin);
	TE_WriteVector("m_vecMaxs", vecFinish);
	TE_WriteFloat("m_fHeight", heightF);
	TE_WriteNum("m_nModelIndex", modelIndex);
	TE_WriteNum("m_nCount", count);
	TE_WriteFloat("m_fSpeed", speedF);
}
