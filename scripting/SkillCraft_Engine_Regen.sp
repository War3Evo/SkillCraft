#include <sourcemod>
#include "SkillCraft_Includes/SkillCraft_Interface"


public Plugin:myinfo= 
{
	name="SkillCraft Engine HP Regen",
	author="SkillCraft Team",
	description="SkillCraft Core Plugins",
	version="1.0",
};


//new Float:nextRegenTime[MAXPLAYERSCUSTOM];
new tf2displayskip[MAXPLAYERSCUSTOM]; //health sign particle
new Float:lastTickTime[MAXPLAYERSCUSTOM];

public On_SC_EventSpawn(client){
	lastTickTime[client]=GetEngineTime();
}
public OnGameFrame()
{
	decl Float:playervec[3];
		
	new Float:now=GetEngineTime();
	for(new client=1;client<=MaxClients;client++)
	{
		if(ValidPlayer(client,true))
		{
			
			new Float:fbuffsum=0.0;
			if(!SC_GetBuffHasTrue(client,bBuffDenyAll)){
				fbuffsum+=SC_GetBuffSumFloat(client,fHPRegen);
			}
			fbuffsum-=SC_GetBuffSumFloat(client,fHPDecay);
			if(fbuffsum<0.01&&fbuffsum>-0.01){ //no decay or regen, set tick time only
				lastTickTime[client]=now;
				continue;
			}
			new Float:period=FloatAbs(1.0/fbuffsum);
			if(now-lastTickTime[client]>period){
				lastTickTime[client]+=period;
				//PrintToChat(client,"regein tick %f %f",fbuffsum,now);
				if(fbuffsum>0.01){ //heal
					SC_HealToMaxHP(client,1);  
					
					tf2displayskip[client]++;
					if(tf2displayskip[client]>4 && !IsInvis(client)){
						new Float:VecPos[3];
						GetClientAbsOrigin(client,VecPos);
						VecPos[2]+=55.0;
						SC_TF_ParticleToClient(0, GetApparentTeam(client)==TEAM_RED?"healthgained_red":"healthgained_blu", VecPos);
						tf2displayskip[client]=0;
					}
				}
				
				if(fbuffsum<-0.01){ //decay
					if(SC_Chance(0.25)  && !IsInvis(client)){
						GetClientAbsOrigin(client,playervec);
						SC_TF_ParticleToClient(0, GetApparentTeam(client)==TEAM_RED?"healthlost_red":"healthlost_blu", playervec);
					}
					if(GetClientHealth(client)>1){
						SetEntityHealth(client,GetClientHealth(client)-1);
						
					}
					else{
						SC_DealDamage(client,1,_,_,"bleed_kill",_,SC_DMGTYPE_TRUEDMG);
					}
				}
			}
			
		}
	}
}
