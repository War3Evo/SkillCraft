#pragma semicolon 1

#include <sourcemod>
#include "SkillCraft_Includes/SkillCraft_Interface"
#include <sdktools>
#include <sdktools_functions>
#include <sdktools_tempents>
#include <sdktools_tempents_stocks>
//#include "SkillCraft_Includes/SkillCraft_WardChecking"

new String:teleportSound[]="war3source/blinkarrival.mp3";

//skill 1
new Float:FanOfKnivesTFChanceArr=0.2;
new const Float:Knives_Damage_Percent_of_Max_Victim_health = 0.05; 
new const Float:KnivesTFRadius = 300.0;
 
//skill 3
new const ShadowStrikeInitialDamage=20;
new const ShadowStrikeTrailingDamage=5;
new Float:ShadowStrikeChanceArr=0.2;
new Float:ultTeleChance=1.00;
new Float:ImpShadowStrike=2.0;
new ShadowStrikeTimes=5;
new BeingStrikedBy[MAXPLAYERSCUSTOM];
new StrikesRemaining[MAXPLAYERSCUSTOM];

//ultimate
new Handle:ultCooldownCvar;

//skill5
//new Float:AuraPushChance[5] = { 0.0, 0.15, 0.20, 0.25, 0.30 };
new Float:PushPower=700.0;



new Float:VengenceTFHealHPPercent=1.0;

#define IMMUNITYBLOCKDISTANCE 300.0


new SKILL_FANOFKNIVES, SKILL_SHADOWSTRIKE,ULT_VENGENCE,SKILL_PUSH;

//new String:shadowstrikestr[]="war3source/shadowstrikebirth.wav";
//new String:ultimateSound[]="war3source/MiniSpiritPissed1.wav";

new String:shadowstrikestr[]="war3source/shadowstrikebirth.mp3";
new String:ultimateSound[]="war3source/MiniSpiritPissed1.mp3";

new BeamSprite;
new HaloSprite;

public Plugin:myinfo =
{
	name = "SkillCraft skills from Race - Warden",
	author = "SkillCraft Team",
	description = "SkillCraft skills from The Warden race for War3Source.",
	version = "1.0.0.0",
};

public OnPluginStart()
{
	ultCooldownCvar=CreateConVar("sc_warden_vengence_cooldown","20.0","Cooldown between Warden Vengence (ultimate)");
}

public On_SC_LoadSkillOrdered(num)
{
	if(num==120)
	{
		SKILL_FANOFKNIVES=SC_CreateNewSkill("Fan of Knives","FanOfKnives",
		"5% chance to activate when attacked\nDeals 5% of max victim health as damage in a 30.0 feet radius around you",
		talent);
	}
	if(num==121)
	{
		SKILL_SHADOWSTRIKE=SC_CreateNewSkill("Shadow Strike (Passive)","ShadowStrike",
		"20% chance to poison an enemy on hit\nDeals initial damage and damage over time",
		ability);
	}
	if(num==122)
	{
		ULT_VENGENCE=SC_CreateNewSkill("Vengance","Vengance",
		"(+ultimate) Heals a percentage of your max HP, capped at 150\n(Passive) Heal is halved if no enemies are afflicted with Shadow Strike\n(Passive) Chance to teleport the Warden to an enemy afflicted by Shadow Strike",
		ultimate);
	}
	if(num==123)
	{
		SKILL_PUSH = SC_CreateNewSkill("Force Staff","ForceStaff",
		"(+ability) Pushes enemies away from you in a large radius\n(Passive) Does not respect skill immunity\n(Passive) 50% chance to push enemies damaged by fan of knives at 50% power\nif you have Fan of Knifes talent.",
		ability);
	}
}

public OnMapStart()
{
	SC_PrecacheSound(shadowstrikestr);
	SC_PrecacheSound(ultimateSound);
	SC_PrecacheSound(teleportSound);
	BeamSprite=SC_PrecacheBeamSprite();
	HaloSprite=SC_PrecacheHaloSprite();
}

public On_SC_EventSpawn(client){
	StrikesRemaining[client]=0;
}

public OnUltimateCommand(client,bool:pressed,bool:bypass)
{
	// TODO: Increment UltimateUsed[client]
	if(pressed && IsPlayerAlive(client))
	{
		if(SC_HasSkill(client,ULT_VENGENCE))
		{
			if(!Silenced(client)&&(bypass||SC_SkillNotInCooldown(client,ULT_VENGENCE,true)))
			{
				if(!blockingVengence(client))
				{
					new gogo=0;
					for(new i=1;i<=MaxClients;i++)
					{
						if(StrikesRemaining[i]>0 && ValidPlayer(BeingStrikedBy[i]) && ValidPlayer(i,true) && BeingStrikedBy[i]==client )
						{

							gogo=1;
							break;
						}
					}
					

						
				
					new maxhp=SC_GetMaxHP(client);
				
					new heal=RoundToCeil(float(maxhp)*VengenceTFHealHPPercent);
					if (heal > 150)
						heal=150;
					if (!gogo)
					{
						heal=RoundToCeil(heal/2.0);
						SC_ChatMessage(client,"(Vengence) No enemies afflicted with poison! Healed %i",heal);
					} else {
						SC_ChatMessage(client,"(Vengence) Your enemy's life force is sapped! Healed %i",heal);
					}
					
					SC_HealToBuffHP(client,heal);
					SC_FlashScreen(client,{0,255,0,20},0.5,_,FFADE_OUT);
					PrintToConsole(client,"ult activated");
					SC_EmitSoundToAll(ultimateSound,client);
					SC_EmitSoundToAll(ultimateSound,client);
					
					SC_CooldownMGR(client,GetConVarFloat(ultCooldownCvar),ULT_VENGENCE,false,true);
					
					if(GetRandomFloat(0.0,1.0)>ultTeleChance)
						return;
					
					for(new i=1;i<=MaxClients;i++)
					{
						if(StrikesRemaining[i]>0 && ValidPlayer(BeingStrikedBy[i]) && ValidPlayer(i,true) && BeingStrikedBy[i]==client )
						{
								PrintToConsole(client,"%i",StrikesRemaining[i]);
								
								new Float:vec[3];
								GetClientAbsOrigin(i, vec);
					
								//if (!SC_IsInSpawn(vec,0))
								if(Teleport(client,i))
									break;
						}

					}
				}
				else
				{
					SC_MsgUltimateBlocked(client);
				}
				
			}
			
		}
	}
}
new Float:emptypos[3];





bool:Teleport(client,attempt){

	new Float:eyepos[3]; //current eyes
	new Float:endpos[3]; //victim's position
	new Float:vel[3]; //velocity vector
	new max = 3;
	new Float:tryThese[max][3][3];

	tryThese[0][0][0]=0.0;
	tryThese[0][0][1]=0.0;
	tryThese[0][0][2]=80.0; //700 units on top

	tryThese[0][1][0]=0.0;
	tryThese[0][1][1]=0.0;
	tryThese[0][1][2]=700.0; //700 units up

	tryThese[0][2][0]=89.0; //looking straight down
	tryThese[0][2][1]=0.0;
	tryThese[0][2][2]=0.0;
	
	
	tryThese[1][0][0]=0.0;
	tryThese[1][0][1]=50.0;
	tryThese[1][0][2]=20.0; //700 units on top

	tryThese[1][1][0]=0.0;
	tryThese[1][1][1]=600.0;
	tryThese[1][1][2]=600.0; //700 units up

	tryThese[1][2][0]=35.0; //looking straight down
	tryThese[1][2][1]=-90.0;
	tryThese[1][2][2]=0.0;
	
	tryThese[2][0][0]=0.0;
	tryThese[2][0][1]=-50.0;
	tryThese[2][0][2]=20.0; //700 units on top

	tryThese[2][1][0]=0.0;
	tryThese[2][1][1]=-600.0;
	tryThese[2][1][2]=600.0; //700 units up

	tryThese[2][2][0]=35.0; //looking straight down
	tryThese[2][2][1]=90.0;
	tryThese[2][2][2]=0.0;

	new myct = 0;

	
	do {

		if (myct==max) {
			return false;
		}
			


		PrintToConsole(client,"enter %i %i",myct,max);
		
		emptypos[0]=0.0;
		emptypos[1]=0.0;
		emptypos[2]=0.0;
		
		GetClientAbsOrigin(attempt,endpos);
		GetClientEyeAngles(client,eyepos);
		
		endpos[0]+=tryThese[myct][0][0];
		endpos[1]+=tryThese[myct][0][1];
		endpos[2]+=tryThese[myct][0][2];
		
		vel[0]=tryThese[myct][1][0];
		vel[1]=tryThese[myct][1][1];
		vel[2]=tryThese[myct][1][2];
		
		eyepos[0]=tryThese[myct][2][0];
		eyepos[1]=tryThese[myct][2][1];
		eyepos[2]=tryThese[myct][2][2];
		myct++;
		PrintToConsole(client,"attempt %i",myct);
			
		getEmptyLocationHull(client,endpos);
	} while (GetVectorLength(emptypos)<1.0);

	TeleportEntity(client,emptypos,eyepos,vel);
	EmitSoundToAll(teleportSound,client);
	EmitSoundToAll(teleportSound,client);
	
	return true;

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
new absincarray[]={0,4,-4,8,-8,12,-12,18,-18,22,-22,25,-25};//,27,-27,30,-30,33,-33,40,-40}; //for human it needs to be smaller
public bool:getEmptyLocationHull(client,Float:originalpos[3]){
	
	new Float:mins[3];
	new Float:maxs[3];
	GetClientMins(client,mins);
	GetClientMaxs(client,maxs);
	
	new absincarraysize=sizeof(absincarray);
	
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
						
						TR_TraceHullFilter(pos,pos,mins,maxs,MASK_SOLID,CanHitThis,client);
						//new ent;
						if(!TR_DidHit(_))
						{
							AddVectors(emptypos,pos,emptypos); ///set this gloval variable
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
	
} 



public OnSC_TakeDmgBullet(victim,attacker,Float:damage)
{
	if(IS_PLAYER(victim)&&IS_PLAYER(attacker)&&victim>0&&attacker>0&&attacker!=victim)
	{
		if(IsPlayerAlive(attacker)&&IsPlayerAlive(victim)&&GetClientTeam(victim)!=GetClientTeam(attacker))
		{
			//VICTIM IS WAREN!!! 
			if(SC_HasSkill(victim,SKILL_FANOFKNIVES))
			{
				//( !Hexed( attacker, false ) && GetRandomFloat( 0.0, 1.0 ) <= AuraPushChance[skill_push] && !SC_HasImmunity( victim, Immunity_Skills ) )

				//new Float:chance_mod=SC_ChanceModifier(victim);
				// CHANCE MOD BY ATTACKER
				//if(!Hexed(victim,false)&&GetRandomFloat(0.0,1.0)<=chance_mod*FanOfKnivesTFChanceArr)
				if(!Hexed(victim,false)&&GetRandomFloat(0.0,1.0)<=FanOfKnivesTFChanceArr)
				{
					//knives damage hp around the victim
					SC_MsgThrewKnives(victim);
					SC_ChatMessage(victim,"(Fan of Knives) You threw knives!");
					new Float:playerVec[3];
					GetClientAbsOrigin(victim,playerVec);

					playerVec[2]+=20;
					TE_SetupBeamRingPoint(playerVec, 10.0, KnivesTFRadius, BeamSprite, HaloSprite, 0, 15, 0.5, 10.0, 10.0, {255,255,255,155}, 100, 0);
					TE_SendToAll();
					playerVec[2]-=20;

					new Float:otherVec[3];
					new team = GetClientTeam(victim);

					//GetClientAbsOrigin(victim, AttackerVec);
					
					for(new i=1;i<=MaxClients;i++)
					{
						if(ValidPlayer(i,true)&&GetClientTeam(i)!=team)
						{
							GetClientAbsOrigin(i,otherVec);
							if(GetVectorDistance(playerVec,otherVec)<KnivesTFRadius)
							{
								new Damage_Percent_of_Max_Victim_health = RoundToCeil(FloatMul(float(SC_GetMaxHP(victim)),Knives_Damage_Percent_of_Max_Victim_health));
								if(SC_DealDamage(i,Damage_Percent_of_Max_Victim_health,victim,DMG_BULLET,"knives",SC_DMGORIGIN_SKILL,SC_DMGTYPE_MAGIC))
								{
									
									SC_FlashScreen(i,RGBA_COLOR_RED);
									SC_MsgHitByKnives(i);
									new String:buffer[512];
									GetClientName(i, buffer, sizeof(buffer));
									SC_ChatMessage(victim,"(Fan of Knives) Damaged %s!",buffer);
									
									SC_FlashScreen(victim, RGBA_COLOR_RED );
									
									

									decl Float:StartPos[3];
									GetClientAbsOrigin(victim,StartPos);
									StartPos[2]+=40;
									TE_SetupBeamRingPoint(StartPos, 150.0, 10.0, BeamSprite, HaloSprite, 0, 10, 0.8, 20.0, 0.0, {255,50,130,255}, 1600, FBEAM_SINENOISE);
									TE_SendToAll();
									TE_SetupBeamRingPoint(StartPos, 150.0, 10.0, BeamSprite, HaloSprite, 0, 10, 0.8, 20.0, 0.0, {255,50,130,255}, 1600, FBEAM_SINENOISE);
									TE_SendToAll(0.3);
									TE_SetupBeamRingPoint(StartPos, 150.0, 10.0, BeamSprite, HaloSprite, 0, 10, 0.8, 20.0, 0.0, {255,50,130,255}, 1600, FBEAM_SINENOISE);
									TE_SendToAll(0.6);
									TE_SetupBeamRingPoint(StartPos, 10.0, 200.0, BeamSprite, HaloSprite, 0, 10, 0.5, 20.0, 0.0, {255,50,130,255}, 1600, FBEAM_SINENOISE);
									TE_SendToAll(0.8);
									
									
									if(!SC_HasSkill(victim,SKILL_PUSH))
										return;

									if(GetRandomFloat(0.0,1.0)>0.50)
										return;
									
									SC_ChatMessage(victim,"(Fan of Knives) Pushed %s!",buffer);
									
									//i == victim's ID. i.e. the warden's victim; the player who is getting hit by fan of knives
									//position = vector to hold the victim's location
									new Float:position[3];

									//fill victim's vector with his location 
									GetEntPropVector(i, Prop_Send, "m_vecOrigin", position);

									//position2 victim= vector to hold the warden's location
									new Float:position2[3];
									GetEntPropVector(victim, Prop_Send, "m_vecOrigin", position2);

									//diff is a temp vector used to hold the vector between the two players
									new Float:diff[3]; 
									diff[0] = position[0] - position2[0];
									diff[1] = position[1] - position2[1]; 

									//go vector holds the 'normalization' of the difference vector
									new Float:go[3];
									NormalizeVector(diff, go);

									//knock back of 500 'normalized' units ... z axis is statically set to be 450
									go[0]*=PushPower/2;
									go[1]*=PushPower/2;
									go[2]=450.0/2;

									TeleportEntity(i, NULL_VECTOR, NULL_VECTOR, go);
									

									
								}
								else {
									new String:buffer[512];
									GetClientName(i, buffer, sizeof(buffer));
									SC_ChatMessage(victim,"(Fan of Knives) Blocked by %s!",buffer);
								}
							}
						}
					} //
				}
			}
			//ATTACKER IS WARDEN
			if(SC_HasSkill(attacker,SKILL_SHADOWSTRIKE))
			{
				
				//shadow strike poison
				new Float:chance_mod=SC_ChanceModifier(attacker);
				/// CHANCE MOD BY VICTIM
				if(StrikesRemaining[victim]==0 && !Hexed(attacker,false)&&GetRandomFloat(0.0,1.0)<=chance_mod*(ShadowStrikeChanceArr*ImpShadowStrike))
				{
					if(SC_HasImmunity(victim,Immunity_Skills))
					{
						SC_MsgSkillBlocked(victim,attacker,"Shadow Strike");
					}
					else
					{
						SC_MsgAttackedBy(victim,"Shadow Strike");
						SC_MsgActivated(attacker,"Shadow Strike");
						
						BeingStrikedBy[victim]=attacker;
						StrikesRemaining[victim]=RoundToCeil(ShadowStrikeTimes*ImpShadowStrike);
						SC_DealDamage(victim,RoundToCeil(ShadowStrikeInitialDamage/ImpShadowStrike),attacker,DMG_BULLET,"shadowstrike");
						SC_FlashScreen(victim,RGBA_COLOR_RED);
						new String:buffer[512];
						GetClientName(victim, buffer, sizeof(buffer));
						SC_ChatMessage(attacker,"(Shadow Strike) Poisoned %s!",buffer);
						SC_EmitSoundToAll(shadowstrikestr,attacker);
						SC_EmitSoundToAll(shadowstrikestr,attacker);
						CreateTimer(1.0,ShadowStrikeLoop,GetClientUserId(victim));
					}
				}
			}
		}
	}
}
public Action:ShadowStrikeLoop(Handle:timer,any:userid)
{
	new victim = GetClientOfUserId(userid);
	if(StrikesRemaining[victim]>0 && ValidPlayer(BeingStrikedBy[victim]) && ValidPlayer(victim,true))
	{
		SC_DealDamage(victim,RoundToCeil(ShadowStrikeTrailingDamage/ImpShadowStrike),BeingStrikedBy[victim],DMG_BULLET,"shadowstrike");
		StrikesRemaining[victim]--;
		SC_FlashScreen(victim,RGBA_COLOR_RED);
		CreateTimer(1.0,ShadowStrikeLoop,userid);
		decl Float:StartPos[3];
		GetClientAbsOrigin(victim,StartPos);
		TE_SetupDynamicLight(StartPos,255,255,100,100,100.0,0.3,3.0);
		TE_SendToAll();
		SC_FlashScreen(BeingStrikedBy[victim],{237,245,10,7});	 
 
	}
}

stock TE_SetupDynamicLight(const Float:vecOrigin[3], r,g,b,iExponent,Float:fRadius,Float:fTime,Float:fDecay)
{
	TE_Start("Dynamic Light");
	TE_WriteVector("m_vecOrigin",vecOrigin);
	TE_WriteNum("r",r);
	TE_WriteNum("g",g);
	TE_WriteNum("b",b);
	TE_WriteNum("exponent",iExponent);
	TE_WriteFloat("m_fRadius",fRadius);
	TE_WriteFloat("m_fTime",fTime);
	TE_WriteFloat("m_fDecay",fDecay);
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

public bool:blockingVengence(client)  //TF2 only
{
	//ELIMINATE ULTIMATE IF THERE IS IMMUNITY AROUND
	new Float:playerVec[3];
	GetClientAbsOrigin(client,playerVec);
	new Float:otherVec[3];
	new team = GetClientTeam(client);

	for(new i=1;i<=MaxClients;i++)
	{
		if(ValidPlayer(i,true)&&GetClientTeam(i)!=team&&SC_HasImmunity(i,Immunity_Ultimates))
		{
			GetClientAbsOrigin(i,otherVec);
			if(GetVectorDistance(playerVec,otherVec)<IMMUNITYBLOCKDISTANCE)
			{
				return true;
			}
		}
	}
	return false;
}

public OnAbilityCommand(client,abilitybutton,bool:pressed,bool:bypass)
{
	if(abilitybutton==0 && pressed && IsPlayerAlive(client))
	{
		//DP("warden ability button pressed");
		if(SC_HasSkill(client,SKILL_PUSH) && (bypass||SC_SkillNotInCooldown(client,SKILL_PUSH,true)))
		{
			//DP("client has skill push");
			
			new Float:playerVec[3];
			
			GetClientAbsOrigin(client,playerVec);

			new hitOne=0;

			new Float:otherVec[3];
			new team = GetClientTeam(client);
			
			//GetClientAbsOrigin(victim, AttackerVec);
			
			for(new i=1;i<=MaxClients;i++)
			{
				//DP("Searching client #%d",i);
				if(ValidPlayer(i,true)&&GetClientTeam(i)!=team)
				{
					GetClientAbsOrigin(i,otherVec);



					if(GetVectorDistance(playerVec,otherVec)<600.0)
					{
						//DP("Found GetVectorDistance < 600");
						SC_FlashScreen(i,RGBA_COLOR_RED);
						//SC_MsgHitByKnives(i);
						decl Float:StartPos[3];

						if (!(hitOne)) {
							//DP("! HitOne line 602");
							//playerVec[2]+=20;
							//TE_SetupBeamRingPoint(playerVec, 10.0, 600.0, BeamSprite, HaloSprite, 0, 15, 0.5, 10.0, 10.0, {255,255,255,155}, 100, 0);
							//TE_SendToAll();
							//playerVec[2]-=20;

							GetClientAbsOrigin(client,StartPos);
							new Float:mult=1.2;
							new colour[4]={51,129,255,255}; 
							new Float:StartPos2[3];
							StartPos2=StartPos;
							
							StartPos[2]+=40;
							TE_SetupBeamRingPoint(StartPos, 10.0, 600.0, BeamSprite, HaloSprite, 0, 10, 0.5*mult, 20.0, 0.0, colour, 1600, FBEAM_SINENOISE);
							TE_SendToAll();
							
							StartPos[2]+=25;
							TE_SetupBeamRingPoint(StartPos, 10.0, 600.0, BeamSprite, HaloSprite, 0, 10, 0.4*mult, 20.0, 0.0, colour, 1600, FBEAM_SINENOISE);
							TE_SendToAll(0.1*mult); 
							StartPos[2]+=25;
							TE_SetupBeamRingPoint(StartPos, 10.0, 600.0, BeamSprite, HaloSprite, 0, 10, 0.3*mult, 20.0, 0.0, colour, 1600, FBEAM_SINENOISE);
							TE_SendToAll(0.2*mult);
							StartPos[2]+=25;
							TE_SetupBeamRingPoint(StartPos, 10.0, 600.0, BeamSprite, HaloSprite, 0, 10, 0.2*mult, 20.0, 0.0, colour, 1600, FBEAM_SINENOISE);
							TE_SendToAll(0.3*mult);
							StartPos[2]+=25;
							TE_SetupBeamRingPoint(StartPos, 10.0, 600.0, BeamSprite, HaloSprite, 0, 10, 0.1*mult, 20.0, 0.0, colour, 1600, FBEAM_SINENOISE);
							TE_SendToAll(0.4*mult);
							StartPos[2]+=25;
							
							StartPos2[2]-=25;
							TE_SetupBeamRingPoint(StartPos2, 10.0, 600.0, BeamSprite, HaloSprite, 0, 10, 0.4*mult, 20.0, 0.0, colour, 1600, FBEAM_SINENOISE);
							TE_SendToAll(0.1*mult); 
							StartPos2[2]-=25;
							TE_SetupBeamRingPoint(StartPos2, 10.0, 600.0, BeamSprite, HaloSprite, 0, 10, 0.3*mult, 20.0, 0.0, colour, 1600, FBEAM_SINENOISE);
							TE_SendToAll(0.2*mult);
							StartPos2[2]-=25;
							TE_SetupBeamRingPoint(StartPos2, 10.0, 600.0, BeamSprite, HaloSprite, 0, 10, 0.2*mult, 20.0, 0.0, colour, 1600, FBEAM_SINENOISE);
							TE_SendToAll(0.3*mult);
							StartPos2[2]-=25;
							TE_SetupBeamRingPoint(StartPos2, 10.0, 600.0, BeamSprite, HaloSprite, 0, 10, 0.1*mult, 20.0, 0.0, colour, 1600, FBEAM_SINENOISE);
							TE_SendToAll(0.4*mult);
							StartPos2[2]-=25;
							/*
							TE_SetupBeamRingPoint(StartPos, 300.0, 10.0, BeamSprite, HaloSprite, 0, 10, 0.8, 20.0, 0.0, {255,50,130,255}, 1600, FBEAM_SINENOISE);
							TE_SendToAll();
							TE_SetupBeamRingPoint(StartPos, 300.0, 10.0, BeamSprite, HaloSprite, 0, 10, 0.8, 20.0, 0.0, {255,50,130,255}, 1600, FBEAM_SINENOISE);
							TE_SendToAll(0.3);
							TE_SetupBeamRingPoint(StartPos, 300.0, 10.0, BeamSprite, HaloSprite, 0, 10, 0.8, 20.0, 0.0, {255,50,130,255}, 1600, FBEAM_SINENOISE);
							TE_SendToAll(0.6);
						    */
							

						}					

						hitOne++;
						
						//DP("hitOne++;");

						//i == victim's ID. i.e. the warden's victim; the player who is getting hit by fan of knives
						//position = vector to hold the victim's location
						new Float:position[3];

						//fill victim's vector with his location 
						GetEntPropVector(i, Prop_Send, "m_vecOrigin", position);
						
						//DP("GetEntPropVector(i, Prop_Send");

						//position2 victim= vector to hold the warden's location
						new Float:position2[3];
						GetEntPropVector(client, Prop_Send, "m_vecOrigin", position2);
						
						//DP("GetEntPropVector(i, Prop_Send");
						
						//diff is a temp vector used to hold the vector between the two players
						new Float:diff[3]; 
						diff[0] = position[0] - position2[0];
						diff[1] = position[1] - position2[1]; 

						//go vector holds the 'normalization' of the difference vector
						new Float:go[3];
						NormalizeVector(diff, go);
						
						//DP("NormalizeVector");
						
						PrintToConsole(client,"norm %f norm %f",go[0],go[1]);
						//knock back of 500 'normalized' units ... z axis is statically set to be 450
						go[0]*=PushPower;
						go[1]*=PushPower;
						go[2]=450.0;
						PrintToConsole(client,"on %i doing %f %f %f",i,go[0],go[1],go[2]);
						TeleportEntity(i, NULL_VECTOR, NULL_VECTOR, go);
						
						//DP("TeleportEntity");
						
						new String:buffer[512];
						GetClientName(i, buffer, sizeof(buffer));
						SC_ChatMessage(client,"(Force Staff) Pushed %s!",buffer);
						PrintToConsole(client,"diff %f diff %f norm %f norm %f",diff[0],diff[1],go[0],go[1]);
						SC_FlashScreen(client, RGBA_COLOR_RED );

						SC_CooldownMGR(client,15.0,SKILL_PUSH,false,true);
						
						//DP("cooldownMGR");
					}
					else {
						//SC_MsgSkillBlocked(i,_,"Force Staff");
						//DP("Force staff was blocked? vector >600");
					}
				}
			}
			if (!(hitOne)) {
				SC_ChatMessage(client,"(Force Staff) No valid targets!");
			} else {
				SC_ChatMessage(client,"(Force Staff) Pushed %i players!",hitOne);
			}
		}
	}
}
