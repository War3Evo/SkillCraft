#pragma semicolon 1

#include <sourcemod>
#include "SkillCraft_Includes/SkillCraft_Interface"
//see u only include this file
#include <sdktools>


new m_vecVelocity_0, m_vecVelocity_1, m_vecBaseVelocity; //offsets

new bool:bTrapped[MAXPLAYERSCUSTOM];

new SKILL_LEAP, SKILL_REWIND, SKILL_TIMELOCK, ULT_SPHERE;

//leap
new Float:leapPower=500.0;
new Float:leapPowerTF=650.0;

//rewind
new Float:RewindChance=0.25; 
new RewindHPAmount[MAXPLAYERSCUSTOM];

//bash
new Float:TimeLockChance=0.25;

//sphere
new Float:ultRange=200.0;
new Handle:ultCooldownCvar;
new Float:SphereTime=4.5;

new String:leapsnd[256]; //="war3source/chronos/timeleap.mp3";
new String:spheresnd[256]; //="war3source/chronos/sphere.mp3";

new Float:sphereRadius=150.0;

new bool:hasSphere[MAXPLAYERSCUSTOM];
new Float:SphereLocation[MAXPLAYERSCUSTOM][3];
new Float:SphereEndTime[MAXPLAYERSCUSTOM];


new BeamSprite;
new HaloSprite;


stock oldbuttons[MAXPLAYERSCUSTOM];
new bool:lastframewasground[MAXPLAYERSCUSTOM];
public Plugin:myinfo = 
{
	name = "SkillCraft skills from Race - Chronos",
	author = "SkillCraft Team",
	description = "SkillCraft skills from Chronos",
	version = "1.0.0.0",
};

public OnPluginStart()
{
	ultCooldownCvar=CreateConVar("war3_chronos_ult_cooldown","20");
	
	m_vecVelocity_0 = FindSendPropOffs("CBasePlayer","m_vecVelocity[0]");
	m_vecVelocity_1 = FindSendPropOffs("CBasePlayer","m_vecVelocity[1]");
	m_vecBaseVelocity = FindSendPropOffs("CBasePlayer","m_vecBaseVelocity");
}

new glowsprite;
public OnMapStart()
{
	strcopy(leapsnd,sizeof(leapsnd),"war3source/chronos/timeleap.mp3");
	strcopy(spheresnd,sizeof(spheresnd),"war3source/chronos/sphere.mp3");

	SC_PrecacheSound(leapsnd);
	SC_PrecacheSound(spheresnd);
	glowsprite=PrecacheModel("sprites/strider_blackball.spr");
	
	BeamSprite=SC_PrecacheBeamSprite();
	HaloSprite=SC_PrecacheHaloSprite();

	PrecacheModel("models/props_halloween/bombonomicon.mdl", true);
}

public On_SC_LoadSkillOrdered(num)
{	
	if(num==140)
	{
		SKILL_LEAP=SC_CreateNewSkill("Time Leap","TimeLeap",
		"Leap in the direction you are moving (auto on jump)",talent);
	}
	if(num==141)
	{
		SKILL_REWIND=SC_CreateNewSkill("Rewind","Rewind",
		"Chance to regain the damage you took",talent);
	}
	if(num==142)
	{
		SKILL_TIMELOCK=SC_CreateNewSkill("Time Lock","TimeLock",
		"Chance to stun your enemy",mastery);
	}
	if(num==143)
	{
		ULT_SPHERE=SC_CreateNewSkill("Chronosphere","ChronoSphere",
		"Rip space and time to trap enemy.\nTrapped victims cannot move and can only deal/receive melee damage,\nSphere protects chornos from outside damage.\nIt lasts 3/3.5/4/4.5 seconds",ultimate);
	}
}

public PlayerJumpEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
	new client=GetClientOfUserId(GetEventInt(event,"userid"));

	if(ValidPlayer(client,true)){
		if (SC_HasSkill(client,SKILL_LEAP))
		{
			if(!Hexed(client)&&SkillAvailable(client,SKILL_LEAP,false))
			{
				
				new Float:velocity[3]={0.0,0.0,0.0};
				velocity[0]= GetEntDataFloat(client,m_vecVelocity_0);
				velocity[1]= GetEntDataFloat(client,m_vecVelocity_1);
				new Float:len=GetVectorLength(velocity);
				if(len>3.0){
					//PrintToChatAll("pre  vec %f %f %f",velocity[0],velocity[1],velocity[2]);
					ScaleVector(velocity,leapPower/len);
					
					//PrintToChatAll("post vec %f %f %f",velocity[0],velocity[1],velocity[2]);
					SetEntDataVector(client,m_vecBaseVelocity,velocity,true);
					SC_EmitSoundToAll(leapsnd,client);
					SC_EmitSoundToAll(leapsnd,client);
					SC_CooldownMGR(client,10.0,SKILL_LEAP,_,_);
				}
			}
		}
	}
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{

	if (buttons & IN_JUMP) //assault for non CS games
	{
		if (SC_HasSkill(client,SKILL_LEAP))
		{
			//assaultskip[client]--;
			//if(assaultskip[client]<1&&
			new bool:lastwasgroundtemp=lastframewasground[client];
			lastframewasground[client]=bool:(GetEntityFlags(client) & FL_ONGROUND);
			if( !Hexed(client) && SC_SkillNotInCooldown(client,SKILL_LEAP) &&  lastwasgroundtemp && !(GetEntityFlags(client) & FL_ONGROUND) )
			{
				if (TF2_HasTheFlag(client))
					return Plugin_Continue;
				
				decl Float:velocity[3]; 
				GetEntDataVector(client, m_vecVelocity_0, velocity); //gets all 3
				
				new Float:oldz=velocity[2];
				velocity[2]=0.0; //zero z
				new Float:len=GetVectorLength(velocity);
				if(len>3.0){
					ScaleVector(velocity,leapPowerTF/len);
					velocity[2]=oldz;
					TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, velocity);
				}
				
				
				SC_EmitSoundToAll(leapsnd,client);
				SC_EmitSoundToAll(leapsnd,client);
				
				SC_CooldownMGR(client,10.0,SKILL_LEAP,_,_);
			}
		}
	}
	return Plugin_Continue;
}

public OnUltimateCommand(client,bool:pressed,bool:bypass)
{
	if(SC_HasSkill(client,ULT_SPHERE) && IsPlayerAlive(client) && pressed)
	{
		if(!Silenced(client)&&SC_SkillNotInCooldown(client,ULT_SPHERE,true)){
		
			new Float:endpos[3];
			SC_GetAimTraceMaxLen(client,endpos,ultRange);
			
			new Float:down[3];
			down[0]=endpos[0];
			down[1]=endpos[1];
			down[2]=endpos[2]-200;
			TR_TraceRay(endpos,down,MASK_ALL,RayType_EndPoint);
			TR_GetEndPosition(endpos);
			
			SC_EmitSoundToAll(spheresnd,0,_,_,_,_,_,_,endpos);
			SC_EmitSoundToAll(spheresnd,0,_,_,_,_,_,_,endpos);
			SC_EmitSoundToAll(spheresnd,0,_,_,_,_,_,_,endpos);
			
			new Float:life=SphereTime;
			
			for(new i=0;i<3;i++)
				SphereLocation[client][i]=endpos[i];
			
			SphereEndTime[client]=GetGameTime()+life;
			hasSphere[client]=true;
			CreateTimer(0.1,sphereLoop,client);
				
			//new Float:angles[10]={
			//TE_SetupBeamRingPoint(effect_vec,45.0,44.0,BeamSprite,HaloSprite,0,15,entangle_time,5.0,0.0,{0,255,0,255},10,0);
			
			new Float:tempdiameter;
			for(new i=-1;i<=8;i++){
				new Float:rad=float(i*10)/360.0*(3.14159265*2);
				tempdiameter=sphereRadius*Cosine(rad)*2;
				new Float:heightoffset=sphereRadius*Sine(rad);
				
				//PrintToChatAll("degree %d rad %f sin %f cos %f radius %f offset %f",i*10,rad,Sine(rad),Cosine(rad),radius,heightoffset);
				
				new Float:origin[3];
				origin[0]=endpos[0];
				origin[1]=endpos[1];
				origin[2]=endpos[2]+heightoffset;
				TE_SetupBeamRingPoint(origin, tempdiameter-0.1, tempdiameter, BeamSprite, HaloSprite, 0, 0, life, 2.0, 0.0, {80,200,255,122}, 10, 0);
				TE_SendToAll();
			}
			
			
			
			
			sphereLoop(INVALID_HANDLE,client);
			
			CreateTimer(life,sphereend,client);
			
			TE_SetupGlowSprite(endpos,glowsprite,life,3.57,255);
			TE_SendToAll();
			SC_CooldownMGR(client,GetConVarFloat(ultCooldownCvar),ULT_SPHERE,_,_);
		}
	}
}
public Action:sphereLoop(Handle:h,any:client){
	if(hasSphere[client]&&SphereEndTime[client]>GetGameTime()){
		new Float:victimpos[3];
		new team=GetClientTeam(client);
		for(new i=1;i<=MaxClients;i++){
			if(ValidPlayer(i,true)&&(GetClientTeam(i)!=team&&!bTrapped[i]&&!SC_HasImmunity(i,Immunity_Ultimates))){
				GetClientEyePosition(i,victimpos);
				if(GetVectorDistance(SphereLocation[client],victimpos)<sphereRadius+10)
				{
					CreateTimer(SphereEndTime[client]-GetGameTime(),unBashUlt,i);
					SC_SetBuff(i,bBashed,ULT_SPHERE,true);
				
					//War3_SetBuff(i,fAttackSpeed,thisRaceID,0.33);
					SC_SetBuff(i,bImmunitySkills,ULT_SPHERE,false);
					SC_SetBuff(i,bImmunityUltimates,ULT_SPHERE,false);
					bTrapped[i]=true;
					PrintHintText(i,"You have been trapped by a Chronosphere! You can only receive Melee damage");
				
					//EmitSoundToClient(i,spheresnd);
				}
			}
		}
	
		CreateTimer(0.1,sphereLoop,client);
	}



	
}
public Action:unBashUlt(Handle:h,any:client){
	SC_SetBuff(client,bBashed,ULT_SPHERE,false);
	//SC_SetBuff(client,fAttackSpeed,thisRaceID,1.0);
	bTrapped[client]=false;
	SC_SetBuff(client,bImmunitySkills,ULT_SPHERE,false);
	SC_SetBuff(client,bImmunityUltimates,ULT_SPHERE,false);
	
}
public Action:sphereend(Handle:h,any:client){
	hasSphere[client]=false;
	
}

public OnSC_TakeDmgAllPre(victim,attacker,Float:damage){
	if(bTrapped[victim]){ ///trapped people can only be damaged with knife
		if(ValidPlayer(attacker,true)){
			new wpnent = SC_GetCurrentWeaponEnt(attacker);
			if(wpnent>0&&IsValidEdict(wpnent)){
				decl String:WeaponName[32];
				GetEdictClassname(wpnent, WeaponName, 32);
				if(StrContains(WeaponName,"weapon_knife",false)<0&&!SC_IsDamageFromMelee(WeaponName)){
					
					//PrintToChatAll("block");
					SC_DamageModPercent(0.0);
				}
			}
			else{
				PrintToChatAll("chronosblock no wpn detected");
				SC_DamageModPercent(0.0);
			}
		}
		else{
			//PrintToChatAll("chronosblock no valid attacker");
			//SC_DamageModPercent(0.0);
			//some damage burn here? allow
		}
	}
	
	if(ValidPlayer(attacker,true) && bTrapped[attacker]){ //if the attacker is inside the sphere...
		new wpnent2 = SC_GetCurrentWeaponEnt(attacker);
		if(wpnent2>0&&IsValidEdict(wpnent2)){
				decl String:WeaponName2[32];
				GetEdictClassname(wpnent2, WeaponName2, 32);		
				if(StrContains(WeaponName2,"weapon_knife",false)<0&&!SC_IsDamageFromMelee(WeaponName2)){ //and the attacker isn't dealing melee damage...
					
					//PrintToChatAll("block");
					PrintToServer("attacker in sphere tried to deal ranged damage!");
					SC_DamageModPercent(0.0); //then no damage for the attacker.
				}
		}
		
	}
//	if(ValidPlayer(attacker)&&bTrapped[attacker]){ //trapped people can only use knife
//	}
	if(ValidPlayer(attacker,true)&&IsInOwnSphere(victim)&&!bTrapped[attacker]&&!SC_HasImmunity(attacker,Immunity_Ultimates)){ //cant shoot to inside the sphere	
		SC_DamageModPercent(0.0);	
	}
	if(ValidPlayer(attacker,true)&&IsInOwnSphere(attacker)&&!bTrapped[victim]){	//cant shoot outside of your sphere
		SC_DamageModPercent(0.0);	
	}
	//OnSC_TakeDmgAllPre_func(victim,attacker,Float:damage);
	
}
IsInOwnSphere(client){
	if(hasSphere[client]){
		new Float:pos[3];
		GetClientEyePosition(client,pos);
		if(GetVectorDistance(SphereLocation[client],pos)<sphereRadius+10.0){ //chronos is in his sphere
			return true;
		}
	}
	return false;
}
public On_SC_EventPostHurt(victim,attacker,dmgamount)
{
//	new dmgamount=RoundToFloor(damage);
	//PrintToChatAll("Damage: %i",dmgamount);
	//PrintToChatAll("Post Damage Triggered!");
	//PrintToChatAll("Post Damage Triggered!");
	if(ValidPlayer(victim,true)&&ValidPlayer(attacker,true))
	{	
		
		//we do a chance roll here, and if its less than our limit (RewindChance) we proceede i a with u
		// allow self damage rewind
		if(victim!=attacker && GetClientTeam(victim)!=GetClientTeam(attacker) && SC_HasSkill(victim,SKILL_REWIND) && SC_Chance(RewindChance) && !SC_HasImmunity(attacker,Immunity_Skills)&&!Hexed(victim)) //chance roll, and attacker isnt immune to skills
		{
			if(TF2_IsPlayerInCondition(victim,TFCond_DeadRingered))
				{
					new Float:mathx=float(dmgamount)*0.10;
					dmgamount=RoundToNearest(mathx);
				}
			PrintToConsole(victim,"Rewind +%i HP!",dmgamount);
			RewindHPAmount[victim]+=dmgamount;//we create this variable
			PrintHintText(victim,"Rewind +%i HP!",dmgamount);
			SC_FlashScreen(victim,RGBA_COLOR_GREEN);
		}
		
		if(SC_HasSkill(attacker,SKILL_TIMELOCK) && victim!=attacker)
		{
			if(SC_Chance(TimeLockChance)&& !SC_HasImmunity(victim,Immunity_Skills) && !Stunned(victim)&&!Hexed(attacker))
			{
				PrintHintText(victim,"You got Time Locked");
				PrintHintText(attacker,"Time Lock!");
				
				
				SC_FlashScreen(victim,RGBA_COLOR_BLUE);
				CreateTimer(0.15,UnfreezeStun,victim);
				
				SC_SetBuff(victim,bStunned,SKILL_TIMELOCK,true);
			}
		}
		
	}
}


public Action:UnfreezeStun(Handle:h,any:client) //always keep timer data generic
{
	SC_SetBuff(client,bStunned,SKILL_TIMELOCK,false);
}
public On_SC_EventDeath(victim,attacker){
	RewindHPAmount[victim]=0;
}
new skip;
public OnGameFrame() //this is a sourcemod forward?, every game frame it is called. forwards if u implement it sourcemod will call you
{
	if(skip==0){
	
		for(new i=1;i<=MaxClients;i++){
			if(ValidPlayer(i,true))//valid (in game and shit) and alive (true parameter)k
			{
				if(RewindHPAmount[i]>0){
					SC_HealToMaxHP(i,1);
					SC_TFHealingEvent(i,1);
					RewindHPAmount[i]--;
				}
			}
			
		}
		skip=2;
	}
	skip--;
	/*
	new entity = -1; 
	while ((entity=FindEntityByClassname(entity, "info_target"))!=INVALID_ENT_REFERENCE)
	{
		if(IsValidEntity(entity))
		{
			if(RemovePortals)
			{
				decl String:targetname[128];
				GetEntPropString(entity, Prop_Data, "m_iName", targetname, sizeof(targetname));
				if(StrEqual(targetname, "spawn_purgatory", false))
				{
					AcceptEntityInput(entity, "kill");
				}
			}
		}
	}*/
}

/* ***************************	ability *************************************/

/*
public OnAbilityCommand(client,ability,bool:pressed)
{
	if(ValidPlayer(client,true,true) && SC_GetRace(client)==thisRaceID && ability==0 && pressed && GetClientTeam(client)!=1)
	{
		new skill_levels=SC_GetSkillLevel(client,thisRaceID,ABILITY_SKILL_ENTRANCE);
		if(skill_levels>=1 && SC_SkillNotInCooldown(client,thisRaceID,ABILITY_SKILL_ENTRANCE))
		{
			SetPortalEntrance(client);
			SC_CooldownMGR(client,ManaEntrance[skill_levels],thisRaceID,ABILITY_SKILL_ENTRANCE,_,_);
		}
	}
	if(ValidPlayer(client,true,true) && SC_GetRace(client)==thisRaceID && ability==2 && pressed && max_exits_per_map[client]<3 && GetClientTeam(client)!=1)
	{
		new skill_levels=SC_GetSkillLevel(client,thisRaceID,ABILITY_SKILL_EXIT);
		if(skill_levels>=1 && SC_SkillNotInCooldown(client,thisRaceID,ABILITY_SKILL_EXIT))
		{
			SetPortalExit(client);
			max_exits_per_map[client]++;
			SC_CooldownMGR(client,ManaExit[skill_levels],thisRaceID,ABILITY_SKILL_EXIT,_,_);
		}
	}
}

SetPortalExit(client)
{
	new target = CreateEntityByName("info_target");	
	if(IsValidEntity(target))
	{
		new Float:g_pos_portal[3];
		GetClientAbsOrigin(client,g_pos_portal);
		TeleportEntity(target, g_pos_portal, NULL_VECTOR, NULL_VECTOR);
		DispatchKeyValue(target, "targetname", "spawn_purgatory");
		DispatchSpawn(target);
		PrintToChat(client, "Portal Exit %d of 3 has Been Spawned per round!",max_exits_per_map[client]);
	}
}

SetPortalEntrance(client)
{
					new Float:playerVec[3];
					GetClientAbsOrigin(client,playerVec);
					//new Float:otherVec[3];
					//MAY NOT USE SOME OF THIS STUFF BELOW.. SEE LOGS
					for(new i=1;i<=MaxClients;i++)
					{
						if(ValidPlayer(i,true))
						{
							GetClientAbsOrigin(i,otherVec);
							if(GetVectorDistance(playerVec,otherVec)<150.0)
							{
								SC_FlashScreen(i,RGBA_COLOR_WHITE);
								SC_FlashScreen(client, RGBA_COLOR_WHITE);
								//position = vector to hold the victim's location
								new Float:position[3];
								//fill victim's vector with his location 
								GetEntPropVector(i, Prop_Send, "m_vecOrigin", position);
								//position2 victim= vector to hold the warden's location
								new Float:position2[3];
								GetEntPropVector(client, Prop_Send, "m_vecOrigin", position2);
								//diff is a temp vector used to hold the vector between the two players
								new Float:diff[3]; 
								diff[0] = position[0] - position2[0];
								diff[1] = position[1] - position2[1]; 
								//go vector holds the 'normalization' of the difference vector
								new Float:go[3];
								NormalizeVector(diff, go);
								//knock back of 500 'normalized' units ... z axis is statically set to be 450
								go[0]/=400.0;
								go[1]/=400.0;
								go[2]=40.0;
								TeleportEntity(i, NULL_VECTOR, NULL_VECTOR, go);
							}
							GetClientAbsOrigin(i,otherVec);
							if(GetVectorDistance(playerVec,otherVec)<30.0 && i!=client)
							{
								SC_HealToMaxHP(i,500);
								TF2_AddCondition(i,TFCond_Ubercharged,6.0);
								SC_SetBuff(i,bDisarm,thisRaceID,true);
								SC_SetBuff(i,bFlyMode,thisRaceID,true);
								PlayerImmune[i]=true;
								SavedLocationPos[i]=otherVec;
								GetClientEyeAngles(i,SavedLocationAng[i]);
							}
						}
					}
					new portal = CreateEntityByName("teleport_vortex");	
					if(IsValidEntity(portal))
					{
						SetEntProp(portal, Prop_Send, "m_iState", 1);
						DispatchSpawn(portal);
						new Float:g_pos_portal[3];
						GetClientAbsOrigin(client,g_pos_portal);
						g_pos_portal[2]+=160;
						TeleportEntity(portal, g_pos_portal, NULL_VECTOR, NULL_VECTOR);
						PrintToChat(client, "Portal Has been spawned!");
					}
					CreateTimer(5.0, RemoveAllTeleport, client);
}

public Action:RemoveAllTeleport(Handle:timer, any:client)
{
	//new Float:playerVec[3];
	//GetClientAbsOrigin(client,playerVec);
	//new Float:otherVec[3];
	for(new i=1;i<=MaxClients;i++)
	{
		if(ValidPlayer(i,true))
		{
			if(PlayerImmune[i])
			{
				//SC_HealToMaxHP(i,150);
				TeleportEntity(i, SavedLocationPos[i], SavedLocationAng[i], NULL_VECTOR);
				SC_SetBuff(i,bDisarm,thisRaceID,false);
				SC_SetBuff(i,bFlyMode,thisRaceID,false);
				//otherVec=SavedLocationPos[i];
				PlayerImmune[i]=false;
			}
		}
	}
}

*/
