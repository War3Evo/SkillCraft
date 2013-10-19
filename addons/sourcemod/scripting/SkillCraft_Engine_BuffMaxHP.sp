 	
////BUFF SYSTEM
#pragma semicolon 1

#include <sourcemod>
#include "sdkhooks"
#include "SkillCraft_Includes/SkillCraft_Interface"
//#include "tf2attributes.inc"
//#include "SC_SIncs/War3Evo_WardChecking"


public Plugin:myinfo= 
{
	name="SkillCraft Buff MAXHP",
	author="SkillCraft Team",
	description="SkillCraft Core Plugins",
	version="1.1",
};


//new Float:ClientTimer[MAXPLAYERSCUSTOM];

//new Handle:setMaxTimer[MAXPLAYERSCUSTOM];
//new Handle:mytimer[MAXPLAYERSCUSTOM]; //INVLAID_HHANDLE is default 0
//new Float:LastDamageTime[MAXPLAYERSCUSTOM];

//public OnPluginStart()
//{
//	for (new i = 1; i < MAXPLAYERSCUSTOM; i++)
//	{
//		mytimer2[i]=INVALID_HANDLE;
//	}
//}//mytimer2[i]=INVALID_HANDLE;

//public OnClientDisconnect(client)
//{
	//KillTimer(mytimer2[client]);
//}

public OnConfigsExecuted()
{
		for (new i = 1; i <= MaxClients; i++)
		{
				if (ValidPlayer(i))
				{
						SDKHook(i, SDKHook_GetMaxHealth, OnGetMaxHealth);
				}
		}
}

public OnClientPutInServer(client)
{
		SDKHook(client, SDKHook_GetMaxHealth, OnGetMaxHealth);
}

new ORIGINALHP[MAXPLAYERSCUSTOM];


//fkoafkopasfk dasop  ?// NEED TO WORK ON MAKING WAR3SOURCE_ENGINE_BUFFSYSTEM AND COMBINE WITH BUFFMAX HP... so that it works properly for regen.

public Action:OnGetMaxHealth(client, &maxhealth)
{
	if (ValidPlayer(client))
	{
		//new Float:vec[3];
		//GetClientAbsOrigin(client, vec);
		//if (SC_IsInSpawn(vec))
		//{
		
		//new Float:fbuffsum=0.0;
		//if(!SC_GetBuffHasTrue(client,bBuffDenyAll)){
			//fbuffsum+=SC_GetBuffSumFloat(client,fHPRegen);
		//}
		//fbuffsum-=SC_GetBuffSumFloat(client,fHPDecay);
		
		if(SC_GetBuffSumInt(client,iAdditionalMaxHealth)>0 && !SC_GetBuffHasTrue(client,bBuffDenyAll))
		{
			maxhealth+=SC_GetBuffSumInt(client,iAdditionalMaxHealth);
		}
		
		//PrintToChat(client,"DEBUG: set max hp: %i",maxhealth);
			
		//if(SC_GetMaxHP(client)>GetClientHealth(client) && ClientTimer[client]<=GetGameTime() && fbuffsum>-0.01)
		//{
			//SetEntityHealth(client,GetClientHealth(client)+1);
			//ClientTimer[client]=GetGameTime()+0.15;
		//}
      
		//if(SC_GetMaxHP(client)<GetClientHealth(client) && ClientTimer[client]<=GetGameTime())
		//{
			//SetEntityHealth(client,GetClientHealth(client)-1);
			//ClientTimer[client]=GetGameTime()+0.15;
		//}

		return Plugin_Handled;
		//}
	}
	return Plugin_Continue;
}

setMax(client)
{
	if(ValidPlayer(client))
	{
		new maxHP = ORIGINALHP[client] + SC_GetBuffSumInt(client,iAdditionalMaxHealth);

		if(maxHP<=0)
			return;

		SC_SetMaxHP_INTERNAL(client,maxHP);
		//PrintToServer("set max hp: %i",maxHP);
	
		// Temporary removed till sourcemod fixes TF2Items problems:
		//TF2Attrib_SetByName(client,"max health additive bonus", 1.0*SC_GetBuffSumInt(client,iAdditionalMaxHealth));
	
		//if (spawning)
	
		//SetEntData(client, FindDataMapOffs(client, "m_iHealth"), maxHP, 4, true);
		//SetEntProp(client, Prop_Data, "m_iMaxHealth", maxHP);
		//SetEntData(client, FindDataMapOffs(client, "m_iMaxHealth"), maxHP, 4, true);
	
		//new Float:vec[3];
		//GetClientAbsOrigin(client, vec);
		//if(SC_IsInSpawn(vec))
		//{
			//SetEntData(client, FindDataMapOffs(client, "m_iHealth"), maxHP, 4, true);
			//SetEntityHealth(client,maxHP);
		//}
	}
}
//new bool:bHealthAddedThisSpawn[MAXPLAYERSCUSTOM];

public OnWar3EventSpawn(client)
{

	//CreateTimer(0.1, timer_PlayerSpawn, client);
	
	//mytimer2[client]=CreateTimer(0.1,CheckHPBuffChange,client);
	//1 is 0.1 delay for spawn set, 0/Null is immediate
	if(ValidPlayer(client))
	{
		ORIGINALHP[client]=GetClientHealth(client) - SC_GetBuffSumInt(client,iAdditionalMaxHealth);
		setMax(client);
		new MaxHP=SC_GetMaxHP(client);
		if(MaxHP>0)
		{
			SetEntityHealth(client,MaxHP);
		}
	}
	//CreateTimer(1.0,SetHPBuffChange,client);
}

//SetHPBuffChange(any:client)
//{
	//if(ValidPlayer(client))
	//{
		//setMax(client);
	//}
//}


/*
public Action:CheckHP(Handle:h,any:client){
//DP("TIMERHIT");
	mytimer[client]=INVALID_HANDLE;
	//if(ValidPlayer(client,true) && !bHealthAddedThisSpawn[client] && !SC_GetBuffHasTrue(client,fHPRegenDeny)){
	if(ValidPlayer(client,true) && !bHealthAddedThisSpawn[client] && !SC_GetBuffHasTrue(client,fHPRegenDeny)){
		new hpadd=SC_GetBuffSumInt(client,iAdditionalMaxHealth);
		//if(!IsFakeClient(client))
		//DP("oroginal %d, additonal %d",ORIGINALHP[client],hpadd);
		new curhp=GetClientHealth(client);
		SetEntityHealth(client,curhp+hpadd);
		SC_SetMaxHP_INTERNAL(client,ORIGINALHP[client]+hpadd);
		//if(!IsFakeClient(client))
		//DP("CheckHP was curhp %d, set to %d",curhp,GetClientHealth(client));
		LastDamageTime[client]=GetEngineTime()-100.0;
	}
}*/


public OnWar3Event(SC_EVENT:event,client){
	if(event==OnBuffChanged)
	{
		if(SC_GetVar(EventArg1)==iAdditionalMaxHealth&&ValidPlayer(client,false)){
				//PrintToChatAll("BEFORE INVALID HANDLE CHECK %i vs %i",ORIGINALHP[client] + SC_GetBuffSumInt(client,iAdditionalMaxHealth),SC_GetMaxHP(client));
				//if(mytimer2[client]==INVALID_HANDLE){
				//mytimer2[client]=CreateTimer(1.0,SetHPBuffChange,client);
				/*new oldbuff=SC_GetMaxHP(client)-ORIGINALHP[client];
				new newbuff=SC_GetBuffSumInt(client,iAdditionalMaxHealth);
				SC_SetMaxHP_INTERNAL(client,ORIGINALHP[client]+newbuff); //set max hp*/
				//PrintToChatAll("%i vs %i",ORIGINALHP[client] + SC_GetBuffSumInt(client,iAdditionalMaxHealth),SC_GetMaxHP(client));
				if ((ORIGINALHP[client] + SC_GetBuffSumInt(client,iAdditionalMaxHealth)) != SC_GetMaxHP(client))
				{
					//DP("SetHPBuffChange OnWar3Event");
					//SetHPBuffChange(client);
					setMax(client);
					new MaxHP=SC_GetMaxHP(client);
					if(MaxHP>0 && SC_GetPlayerProp(client,bStatefulSpawn))
					{
						SetEntityHealth(client,MaxHP);      //TFCond_Overhealed
						SC_SetMaxHP_INTERNAL(client,GetClientHealth(client));
					}
					//SC_SetMaxHP_INTERNAL(client,GetClientHealth(client));
				}
				
			//}
		}
		//DP("EVENT OnBuffChanged",event);
	}
	//DP("EVENT %d",event);
}


/*
public OnWar3EventPostHurt(victim,attacker,damage){
	if (ValidPlayer(victim)) {
		LastDamageTime[victim]=GetEngineTime();
	}
}
*/

/*
public Action:TFHPBuff(Handle:h,any:data){


	new Float:now=GetEngineTime();
	//only create timer of TF2
	for(new i=1;i<=MaxClients;i++){
		if(ValidPlayer(i,true)){
			if(now>LastDamageTime[i]+10.0){

					// Devotion Aura
					new curhp =GetClientHealth(i);
					new hpadd=SC_GetBuffSumInt(i,iAdditionalMaxHealth);
					new maxhp =SC_GetMaxHP(i)-hpadd; //nomal player hp

					if(curhp>=maxhp&&curhp<maxhp+hpadd){ ///we should add
						new newhp=curhp+2;
						if(newhp>maxhp+hpadd){
							newhp=maxhp+hpadd;
						}
						//SetEntPropEnt(entity, PropType:type, const String:prop[], other);
						//SetEntPropEnt(client,SetEntPropEnt(entity, PropType:type, const String:prop[], other);
						//SetEntityHealth(i,newhp);
						//SetEntProp(i, Prop_Data , "m_iMaxHealth", maxhp+hpadd);
						//if(!SC_GetBuffHasTrue(i,fHPRegenDeny)) // MAYBE ADD FOR BUG FIX?
						SetEntityHealth(i, newhp);

						//SetEntProp(i, Prop_Send, "m_iHealth", newhp , 1);

					//curhp =GetClientHealth(i);
					//if(curhp>maxhp&&curhp<=maxhp+hpadd)
					//{
					//	TF2_AddCondition(i, TFCond_Healing, 1.0); //TF2 AUTOMATICALLY ADDS PARTICLES?
					//	}
					//else{
					//}
				}
			}
		}
	}
}*/
