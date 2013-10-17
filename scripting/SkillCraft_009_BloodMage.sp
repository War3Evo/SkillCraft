#pragma semicolon 1

#include <sourcemod>
#include "SkillCraft_Includes/SkillCraft_Interface"
#include <sdktools>
#include <sdktools_functions>
#include <sdktools_tempents>
#include <sdktools_tempents_stocks>

new SKILL_REVIVE, SKILL_BANISH, ULT_FLAMESTRIKE;

new Handle:ClientReviveMessage;

//skill 1
new Float:MaxRevivalChance[MAXPLAYERSCUSTOM]; //chance for first attempt at revival
new Float:CurrentRevivalChance[MAXPLAYERSCUSTOM]; //decays by half per revival attempt, will stay at minimum of 10% after decays
new Float:RevivalChancesArr=0.7;
new RevivedBy[MAXPLAYERSCUSTOM];
new bool:bRevived[MAXPLAYERSCUSTOM];
new Float:fLastRevive[MAXPLAYERSCUSTOM];

// Team switch checker
new bool:Can_Player_Revive[MAXPLAYERSCUSTOM+1];
 
//skill 2
new Float:BanishChance[MAXPLAYERSCUSTOM];
new Float:BanishChancesArr=0.30;

//ultimate
new Float:ultCooldownCvar=20.0;
new Handle:hrevivalDelayCvar;

new Float:UltimateMaxDistance=1000.0; //max distance u can target your ultimate
new UltimateDamageDuration=14; ///how many times damage is taken (like pyro's fire)

new BurnsRemaining[MAXPLAYERSCUSTOM]; //burn count for victims
new BeingBurnedBy[MAXPLAYERSCUSTOM];
new UltimateUsed[MAXPLAYERSCUSTOM];

new ULT_DAMAGE_TF = 10;

new String:reviveSound[]="war3source/reincarnation.mp3";

new BeamSprite,HaloSprite,FireSprite;
new BloodSpray,BloodDrop;

public Plugin:myinfo =
{
	name = "SkillCraft skills from Race - Blood Mage",
	author = "SkillCraft Team",
	description = "SkillCraft skills from The Blood Mage race for War3Source.",
	version = "1.0.0.0",
};

public OnPluginStart()
{
	HookEvent("player_spawn",PlayerSpawnEvent);
	HookEvent("round_start",RoundStartEvent);
	hrevivalDelayCvar=CreateConVar("sc_mage_revive_delay","2.0","Delay when reviving a teammate (since death)");
	
	HookEvent("player_death",PlayerDeathEvent);
	HookEvent("player_team",PlayerTeamEvent);
	
	ClientReviveMessage = CreateHudSynchronizer();
	
	CreateTimer(0.1,ResWarning,_,TIMER_REPEAT);
}

new bool:RESwarn[MAXPLAYERSCUSTOM];
public Action:ResWarning(Handle:timer,any:userid)
{
	for(new client=1;client<=MaxClients;client++)
	{
		if(RESwarn[client] && ValidPlayer(client) && !IsPlayerAlive(client))
		{
			SetHudTextParams(-1.0, -1.0, 0.1, 255, 255, 0, 255);
			ShowSyncHudText(client, ClientReviveMessage, "PREPARE FOR CHANCE TO REVIVE!");
		}
	}
}

public On_SC_LoadSkillOrdered(num)
{
	if(num==90)
	{
		SKILL_REVIVE=SC_CreateNewSkill("Phoenix (passive)","Phoenix",
		"(passive) 70% chance to revive your teammates that die.\nEach time you revive, chance is reduced by half\nto a minimum of 2-8%",ability);
	}
	if(num==91)
	{
		SKILL_BANISH=SC_CreateNewSkill("Banish","Banish",
		"30% of making enemy blind and disoriented for 0.2 seconds",mastery);
	}
	if(num==92)
	{
		ULT_FLAMESTRIKE=SC_CreateNewSkill("Flame Strike","FlameStrike",
		"Burn the enemy over time for 10 damage 14 times.\n100ft. range",ultimate); 
	}
	
}

public On_SC_UltimateSkillChanged(client, oldskill, newskill)
{
	if(oldskill==ULT_FLAMESTRIKE)
	{
		new userid=GetClientUserId(client);
		for(new i=1;i<=MaxClients;i++)
		{
			if(ValidPlayer(i) && BurnsRemaining[i]>0)
			{
				if(BeingBurnedBy[i]==userid)
				{
					BurnsRemaining[i]=0;
					SC_ResetPlayerColor(i,ULT_FLAMESTRIKE);
				}
			}
		}
	}
}

public On_SC_MasterySkillChanged(client, oldskill, newskill)
{
	if(newskill==SKILL_BANISH)
	{
		BanishChance[client]=BanishChancesArr;
	}
}
public On_SC_AbilitySkillChanged(client, oldskill, newskill)
{
	if(newskill==SKILL_REVIVE)
	{
		MaxRevivalChance[client]=RevivalChancesArr;
	}
}

public OnMapStart()
{
	{
		strcopy(reviveSound,sizeof(reviveSound),"war3source/reincarnation.mp3");
	}
	BeamSprite=SC_PrecacheBeamSprite();
	HaloSprite=SC_PrecacheHaloSprite();
	//we gonna use theese bloodsprite as "money blood"(change color)
	BloodSpray = PrecacheModel("sprites/bloodspray.vmt");
	BloodDrop = PrecacheModel("sprites/blood.vmt");
	FireSprite	 = PrecacheModel("materials/sprites/fireburst.vmt");

	SC_PrecacheSound(reviveSound);

	// Reset Can Player Revive
	for(new i=1;i<=MaxClients;i++)    // was MAXPLAYERSCUSTOM
	{
		Can_Player_Revive[i]=true;
	}
}

public OnClientDisconnect(client)
{
	RESwarn[client]=false;
}

public On_SC_PlayerAuthed(client)
{
	fLastRevive[client]=0.0;
	Can_Player_Revive[client]=true;
	RESwarn[client]=false;
}


new FireEntityEffect[MAXPLAYERSCUSTOM];
public OnUltimateCommand(client,bool:pressed,bool:bypass)
{
	new userid=GetClientUserId(client);
	if(pressed && userid>1 && IsPlayerAlive(client) )
	{
		if(SC_HasSkill(client,ULT_FLAMESTRIKE))
		{
			
			if(!Silenced(client)&&(bypass||SC_SkillNotInCooldown(client,ULT_FLAMESTRIKE,true)))
			{
				/////Flame Strike
				new target = SC_GetTargetInViewCone(client,UltimateMaxDistance,false,23.0,IsBurningFilter);
				if(target>0)
				{
					++UltimateUsed[client];
					BeingBurnedBy[target]=GetClientUserId(client);
					BurnsRemaining[target]=UltimateDamageDuration;
					CreateTimer(1.0,BurnLoop,GetClientUserId(target));
					SC_CooldownMGR(client,ultCooldownCvar,ULT_FLAMESTRIKE,_,_);
					PrintHintText(client,"Flame Strike!");
					PrintHintText(target,"You have been struck with Flame Strike!");
					SC_SetPlayerColor(target,ULT_FLAMESTRIKE,255,128,0,_,GLOW_ULTIMATE);
					new Float:effect_vec[3];
					GetClientAbsOrigin(target,effect_vec);
					effect_vec[2]+=150.0;
					TE_SetupGlowSprite(effect_vec, FireSprite, 2.0, 4.0, 255);
					TE_SendToAll();
					effect_vec[2]-=180;
					ThrowAwayParticle("weapon_molotov_thrown_glow", effect_vec, 3.5);
					AttachParticle(target, "burning_character", effect_vec, "rfoot");
					effect_vec[2]+=180;
				}
				else
				{
					SC_MsgNoTargetFound(client,UltimateMaxDistance);
				}
			}
			
		}
		else
		{
			SC_MsgUltNotLeveled(client);
		}
	}
}
public bool:IsBurningFilter(client)
{
//native SC_Hint(client,SC_HintPriority:type=HINT_LOWEST,Float:duration=5.0,String:format[],any:...);
	if(SC_HasImmunity(client,Immunity_Ultimates))
		SC_Hint(client,HINT_NORMAL,5.0,"Target is immune to Ultimates.");
	if(BurnsRemaining[client]>0)
		SC_Hint(client,HINT_NORMAL,5.0,"Can't target a burning target!");
	
	return (BurnsRemaining[client]<=0 && !SC_HasImmunity(client,Immunity_Ultimates));
}
public Action:BurnLoop(Handle:timer,any:userid)
{
	new victim=GetClientOfUserId(userid);
	new attacker=GetClientOfUserId(BeingBurnedBy[victim]);
	if(victim>0 && attacker>0 && BurnsRemaining[victim]>0 && IsClientInGame(victim) && IsClientInGame(attacker) && IsPlayerAlive(victim))
	{
		BurnsRemaining[victim]--;
		new damage = ULT_DAMAGE_TF;
		SC_DealDamage(victim,damage,attacker,DMG_BURN,"flamestrike",_,SC_DMGTYPE_MAGIC);
		CreateTimer(1.0,BurnLoop,userid);
		SC_FlashScreen(victim,RGBA_COLOR_ORANGE);
		if(BurnsRemaining[victim]<=0)
		{
			SC_ResetPlayerColor(victim,ULT_FLAMESTRIKE);
			if (IsValidEdict(FireEntityEffect[victim]))
			{
				AcceptEntityInput(FireEntityEffect[victim], "Kill");
				FireEntityEffect[victim]=-1;
			}
		} 
	}
}


public OnSC_TakeDmgBullet(victim,attacker,Float:damage)
{
	if(IS_PLAYER(victim)&&IS_PLAYER(attacker)&&attacker!=victim&&GetClientTeam(attacker)!=GetClientTeam(victim))
	{
		if(!SC_IsOwnerSentry(attacker))
		{
			//new Float:chance_mod=SC_ChanceModifier(attacker);	
			if(IsPlayerAlive(attacker)&&IsPlayerAlive(victim))
			{
				if(!SC_HasImmunity(victim,Immunity_Skills))
				{
					if(SC_HasSkill(attacker,SKILL_BANISH))
					{
						//if(!Hexed(attacker,false)&&GetRandomFloat(0.0,1.0)<=BanishChancesArr*chance_mod)
						if(!Hexed(attacker,false)&&GetRandomFloat(0.0,1.0)<=BanishChancesArr)
						{
							if(SC_HasImmunity(victim,Immunity_Skills))
							{
								SC_MsgSkillBlocked(victim,attacker,"Banish");
							}
							else 
							{
								// TODO: Sound effects?
								//new Float:oldangle[3];
								//GetClientEyeAngles(victim,oldangle);
								//oldangle[0]+=GetRandomFloat(-20.0,20.0);
								//oldangle[1]+=GetRandomFloat(-20.0,20.0);
								//TeleportEntity(victim, NULL_VECTOR, oldangle, NULL_VECTOR);
								SC_MsgBanished(victim,attacker);
								SC_FlashScreen(victim,{0,0,0,255},0.4,_,FFADE_STAYOUT);
								CreateTimer(0.2,Unbanish,GetClientUserId(victim));
								
								new Float:effect_vec[3];
								GetClientAbsOrigin(attacker,effect_vec);
								new Float:effect_vec2[3];
								GetClientAbsOrigin(victim,effect_vec2);
								effect_vec[2]+=40;
								effect_vec2[2]+=40;
								TE_SetupBeamPoints(effect_vec,effect_vec2,BeamSprite,BeamSprite,0,50,1.0,30.0,10.0,0,12.0,{140,150,255,255},40);
								TE_SendToAll();
								effect_vec2[2]+=18;
								TE_SetupBeamPoints(effect_vec,effect_vec2,BeamSprite,BeamSprite,0,50,1.0,30.0,10.0,0,12.0,{140,150,255,255},40);
								TE_SendToAll();
							}
						}
					}
				}
			}
		}
	}
}

stock siphonsfx(victim) {
	decl Float:vecAngles[3];
	GetClientEyeAngles(victim,vecAngles);
	decl Float:target_pos[3];
	GetClientAbsOrigin(victim,target_pos);
	target_pos[2]+=45;
	TE_SetupBloodSprite(target_pos, vecAngles, {250, 250, 28, 255}, 35, BloodSpray, BloodDrop);
	TE_SendToAll();
}

stock respawnsfx(target) {
	new Float:effect_vec[3];
	GetClientAbsOrigin(target,effect_vec);
	effect_vec[2]+=15.0;
	TE_SetupBeamRingPoint(effect_vec,60.0,1.0,BeamSprite,HaloSprite,0,15,1.5,8.0,1.0,{255,255,20,255},10,0);
	TE_SendToAll();
	effect_vec[2]+=15.0;
	TE_SetupBeamRingPoint(effect_vec,60.0,1.0,BeamSprite,HaloSprite,0,15,1.5,8.0,1.0,{255,255,20,255},10,0);
	TE_SendToAll();
	effect_vec[2]+=15.0;
	TE_SetupBeamRingPoint(effect_vec,60.0,1.0,BeamSprite,HaloSprite,0,15,1.5,8.0,1.0,{255,255,20,255},10,0);
	TE_SendToAll();
}

// Events
public PlayerSpawnEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
	new userid=GetEventInt(event,"userid");
	new client=GetClientOfUserId(userid);
	if(client>0)
	{
		
		UltimateUsed[client]=0;
		if(SC_HasSkill(client,SKILL_REVIVE))
		{
			if(!bRevived[client])
			{
				CurrentRevivalChance[client]=RevivalChancesArr;
			}
		}
		bRevived[client]=false;
	}
	
}

public RoundStartEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
	
	for(new i=1;i<=MaxClients;i++)
	{
		//Reset revival chance
		if(ValidPlayer(i) && SC_HasSkill(i,SKILL_REVIVE))
		{
			CurrentRevivalChance[i]=RevivalChancesArr;
		}
		//reset everyone's ultimate
		
	}
}

public Action:DoRevival(Handle:timer,any:userid)
{
	new client=GetClientOfUserId(userid);
	if(Can_Player_Revive[client]==false)
	{
		return Plugin_Handled;
	}
	//new client=GetClientOfUserId(userid);
	if(client>0)
	{
		new savior = RevivedBy[client];
		if(ValidPlayer(savior,true) && ValidPlayer(client))
		{
			if(GetClientTeam(savior)==GetClientTeam(client)&&!IsPlayerAlive(client))
			{
				//PrintToChatAll("omfg remove true");
				//SetEntityMoveType(client, MOVETYPE_NOCLIP);
				SC_SpawnPlayer(client);
				SC_EmitSoundToAll(reviveSound,client);
				
				SC_MsgRevivedBM(client,savior);
					
				new Float:VecPos[3];
				new Float:Angles[3];
				SC_CachedAngle(client,Angles);
				SC_CachedPosition(client,VecPos);
				
				
				
				
				TeleportEntity(client, VecPos, Angles, NULL_VECTOR);
				RESwarn[client]=false;

				testhull(client);
				
				
				fLastRevive[client]=GetGameTime();
				//test noclip method
				
				//SetEntityMoveType(client, MOVETYPE_WALK);
				
			}
			else
			{
				//this guy changed team?
				CurrentRevivalChance[savior]*=2.0;
				RevivedBy[client]=0;
				bRevived[client]=false;
				RESwarn[client]=false; 
			}
		}
		else
		{
			// savior left or something? maybe dead?
			RevivedBy[client]=0;
			bRevived[client]=false; 
			RESwarn[client]=false;
		}

	}
	return Plugin_Continue;
}

bool:CooldownRevive(client)
{
	if(GetGameTime() >= (fLastRevive[client]+30.0))
		return true;
	return false;
}

public PlayerTeamEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
// Team Switch checker
	new userid=GetEventInt(event,"userid");
	new client=GetClientOfUserId(userid);
	// For testing purposes:
	//new String:clientname[64];
	//GetClientName(client, clientname, sizeof(clientname));
	//DP("Player %s Switched Teams (Can not be revived for 15 seconds)",clientname);
	Can_Player_Revive[client]=false;
	RESwarn[client]=false;
	CreateTimer(30.0,PlayerCanRevive,userid);
}

public Action:PlayerCanRevive(Handle:timer,any:userid)
{
// Team Switch checker
	new client=GetClientOfUserId(userid);
	// For testing purposes:
	//new String:clientname[64];
	//GetClientName(client, clientname, sizeof(clientname));
	//DP("Player %s can be revived by bloodmages",clientname);
	Can_Player_Revive[client]=true;
}

public PlayerDeathEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
	new userid=GetEventInt(event,"userid");
	new victim=GetClientOfUserId(userid);
	if(victim>0)
	{
		BurnsRemaining[victim]=0;
		SC_ResetPlayerColor(victim,ULT_FLAMESTRIKE);
		new victimTeam = GetClientTeam(victim);
		new skillevel;
		
		if (IsValidEdict(FireEntityEffect[victim]))
		{
			AcceptEntityInput(FireEntityEffect[victim], "TurnOff");
			FireEntityEffect[victim]=-1;
		}
		
		new deathFlags = GetEventInt(event, "death_flags");
		
		if (deathFlags & 32)
		{
			//PrintToChat(client,"war3 debug: dead ringer kill");
		}
		else
		{
			
			//
			
			//TEST!! remove!!
			//DP("Auto revival  Remove this line CreateTimer(0.1,DoRevival,victim);");
			//CreateTimer(0.1,DoRevival,victim);
			//RevivedBy[victim]=GetClientOfUserId(userid);
			//PrintToChatAll("blood mage");
			
			//find a revival

			// Can_Player_Revive is the team switch checking variable
			if(CooldownRevive(victim)&&Can_Player_Revive[victim]) {
			//if(Can_Player_Revive[victim]) {
				for(new i=1;i<=MaxClients;i++)
				{
					if(i!=victim&&ValidPlayer(i,true)&&GetClientTeam(i)==victimTeam)
					{
						if(SC_HasSkill(i,SKILL_REVIVE)&&!Hexed(i,false))
						{
							if(GetRandomFloat(0.0,1.0)<=CurrentRevivalChance[i])
							{
								CurrentRevivalChance[i]/=2.0;
								if(CurrentRevivalChance[i]<0.020*skillevel){
									CurrentRevivalChance[i]=0.020*skillevel;
								}
								RevivedBy[victim]=i;
								bRevived[victim]=true;
								RESwarn[victim]=true;
								CreateTimer(GetConVarFloat(hrevivalDelayCvar),DoRevival,GetClientUserId(victim));
								break;
							}
						}
					}
				}
			}
		}
	}
}



public Action:Unbanish(Handle:timer,any:userid)
{
	// never EVER use client in a timer. userid is safe
	new client=GetClientOfUserId(userid);
	if(client>0)
	{
		SC_FlashScreen(client,{0,0,0,0},0.1,_,(FFADE_IN|FFADE_PURGE));
	}
}

new absincarray[]={0,4,-4,8,-8,12,-12,18,-18,22,-22,25,-25,27,-27,30,-30};//,33,-33,40,-40};

public bool:testhull(client){
	
	//PrintToChatAll("BEG");
	new Float:mins[3];
	new Float:maxs[3];
	GetClientMins(client,mins);
	GetClientMaxs(client,maxs);
	
	//PrintToChatAll("min : %.1f %.1f %.1f MAX %.1f %.1f %.1f",mins[0],mins[1],mins[2],maxs[0],maxs[1],maxs[2]);
	new absincarraysize=sizeof(absincarray);
	new Float:originalpos[3];
	GetClientAbsOrigin(client,originalpos);
	
	new limit=5000;
	for(new x=0;x<absincarraysize;x++){
		if(limit>0){
			for(new y=0;y<=x;y++){
				if(limit>0){
					for(new z=0;z<=y;z++){
						new Float:pos[3]={0.0,0.0,0.0};
						AddVectors(pos,originalpos,pos);
						pos[0]+=float(absincarray[x]);
						pos[1]+=float(absincarray[y]);
						pos[2]+=float(absincarray[z]);
						
						//PrintToChatAll("hull at %.1f %.1f %.1f",pos[0],pos[1],pos[2]);
						//PrintToServer("hull at %d %d %d",absincarray[x],absincarray[y],absincarray[z]);
						TR_TraceHullFilter(pos,pos,mins,maxs,CONTENTS_SOLID|CONTENTS_MOVEABLE,CanHitThis,client);
						//new ent;
						if(TR_DidHit(_))
						{
							//PrintToChatAll("2");
							//ent=TR_GetEntityIndex(_);
							//PrintToChatAll("hit %d self: %d",ent,client);
						}
						else{
							TeleportEntity(client,pos,NULL_VECTOR,NULL_VECTOR);
							limit=-1;
							break;
						}
					
						if(limit--<0){
							break;
						}
					}
					
					if(limit--<0){
						break;
					}
				}
			}
			
			if(limit--<0){
				break;
			}
			
		}
		
	}
	//PrintToChatAll("END");
}

public bool:CanHitThis(entityhit, mask, any:data)
{
	if(entityhit == data )
	{// Check if the TraceRay hit the itself.
		return false; // Don't allow self to be hit, skip this result
	}
	if(ValidPlayer(entityhit)&&ValidPlayer(data)&&GetClientTeam(entityhit)==GetClientTeam(data)){
		return false; //skip result, prend this space is not taken cuz they on same team
	}
	return true; // It didn't hit itself
}

