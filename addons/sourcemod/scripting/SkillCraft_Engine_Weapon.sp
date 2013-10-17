#include <sourcemod>
#include "sdkhooks"
#include "SkillCraft_Includes/SkillCraft_Interface"
#include <cstrike>


new m_OffsetActiveWeapon;
new m_OffsetNextPrimaryAttack;

new String:weaponsAllowed[MAXPLAYERSCUSTOM][MAXSKILLS][300];
new restrictionPriority[MAXPLAYERSCUSTOM][MAXSKILLS];
new highestPriority[MAXPLAYERSCUSTOM];
new bool:restrictionEnabled[MAXPLAYERSCUSTOM][MAXSKILLS]; ///if restriction has length, then this should be true (caching allows quick skipping)
new bool:hasAnyRestriction[MAXPLAYERSCUSTOM]; //if any of the races said client has restriction, this is true (caching allows quick skipping)



new g_iWeaponRateQueue[MAXPLAYERSCUSTOM][2]; //ent, client
new g_iWeaponRateQueueLength;

new timerskip;

new Handle:hweaponFiredFwd;
public Plugin:myinfo= 
{
	name="SkillCraft Engine Weapons",
	author="SkillCraft Team",
	description="SkillCraft Core Plugins",
	version="1.0",
};


public OnPluginStart()
{
	CreateTimer(0.1,DeciSecondTimer,_,TIMER_REPEAT);
	
	m_OffsetActiveWeapon=FindSendPropOffs("CBasePlayer","m_hActiveWeapon");
	if(m_OffsetActiveWeapon==-1)
	{
		LogError("[SkillCraft] Error finding active weapon offset.");
	}
	m_OffsetNextPrimaryAttack= FindSendPropOffs("CBaseCombatWeapon","m_flNextPrimaryAttack");
	if(m_OffsetNextPrimaryAttack==-1)
	{
		LogError("[SkillCraft] Error finding active weapon offset.");
	}
	//RegConsoleCmd("w3dropweapon",cmddroptest);
}

/*
public Action:cmddroptest(client,args){
	if(SC_IsDeveloper(client)){
		SC_WeaponRestrictTo(client, SC_GetRace(client),"weapon_knife",1);
	}
	return Plugin_Handled;
} */

public bool:Init_SC_NativesForwards()
{
	CreateNative("SC_WeaponRestrictTo",Native_SC_WeaponRestrictTo);
	CreateNative("SC_GetWeaponRestriction",Native_SC_GetWeaponRestrict);
	CreateNative("SC_GetCurrentWeaponEnt",Native_SC_GetCurrentWeaponEnt);
	CreateNative("SC_DropWeapon",Native_SC_DropWeapon);
	
	hweaponFiredFwd=CreateGlobalForward("OnWeaponFired",ET_Ignore,Param_Cell);
	return true;
}

public Native_SC_GetCurrentWeaponEnt(Handle:plugin,numParams){
	return GetCurrentWeaponEnt(GetNativeCell(1));
}
GetCurrentWeaponEnt(client){
	return GetEntDataEnt2(client,m_OffsetActiveWeapon);
}

public Native_SC_DropWeapon(Handle:plugin,numParams)
{
	new client = GetNativeCell(1)
	new wpent = GetNativeCell(2);
	if (ValidPlayer(client,true) && IsValidEdict(wpent)){
		CS_DropWeapon(client,wpent,true);
		//SDKHooks_DropWeapon(client, wpent);
	}
}

public Native_SC_WeaponRestrictTo(Handle:plugin,numParams)
{
	
	new client=GetNativeCell(1);
	new skillid=GetNativeCell(2);
	new String:restrictedto[300];
	GetNativeString(3,restrictedto,sizeof(restrictedto));
	
	restrictionPriority[client][skillid]=GetNativeCell(4);
	//new String:pluginname[100];
	//GetPluginFilename(plugin, pluginname, 100);
	//PrintToServer("%s NEW RESTRICTION: %s",pluginname,restrictedto);
	//LogError("%s NEW RESTRICTION: %s",pluginname,restrictedto);
	//PrintIfDebug(client,"%s NEW RESTRICTION: %s",pluginname,restrictedto);
	strcopy(weaponsAllowed[client][skillid],200,restrictedto);
	CalculateWeaponRestCache(client);
}

public Native_SC_GetWeaponRestrict(Handle:plugin,numParams)
{
	new client=GetNativeCell(1);
	new skillid=GetNativeCell(2);
	//new String:restrictedto[300];
	new maxsize=GetNativeCell(4);
	if(maxsize>0) SetNativeString(3, weaponsAllowed[client][skillid], maxsize, false);
}
CalculateWeaponRestCache(client){
	new num=0;
	new limit=SC_GetSkillsLoaded();
	new highestpri=0;
	for(new skillid=0;skillid<=limit;skillid++){
		restrictionEnabled[client][skillid]=(strlen(weaponsAllowed[client][skillid])>0)?true:false;
		if(restrictionEnabled[client][skillid]){
			
			
			num++;
			if(restrictionPriority[client][skillid]>highestpri){
				highestpri=restrictionPriority[client][skillid];
			}
		}
	}
	hasAnyRestriction[client]=num>0?true:false;
	
	
	highestPriority[client]=highestpri;
	
	timerskip=0; //force next timer to check weapons
}

public OnClientPutInServer(client){
	//SC_WeaponRestrictTo(client,0,""); //REMOVE RESTICTIONS ON JOIN
	new limit=SC_GetSkillsLoaded();
	for(new skillid=0;skillid<=limit;skillid++){
		restrictionEnabled[client][skillid]=false;
		//Format(weaponsAllowed[client][i],3,"");
		
	}
	CalculateWeaponRestCache(client);
	SDKHook(client, SDKHook_WeaponCanUse, OnWeaponCanUse); //weapon touch and equip only
}
public OnClientDisconnect(client){
	SDKUnhook(client,SDKHook_WeaponCanUse,OnWeaponCanUse); 
}

bool:CheckCanUseWeapon(client,weaponent){
	decl String:WeaponName[32];
	GetEdictClassname(weaponent, WeaponName, sizeof(WeaponName));
	
	if(StrContains(WeaponName,"c4")>-1){ //allow c4
		return true;
	}
	
	new limit=SC_GetSkillsLoaded();
	for(new skillid=0;skillid<=limit;skillid++){
		if(restrictionEnabled[client][skillid]&&restrictionPriority[client][skillid]==highestPriority[client]){ //cached strlen is not zero
			if(StrContains(weaponsAllowed[client][skillid],WeaponName)<0){ //weapon name not found
				return false;
			}
		}
	}
	return true; //allow
}

public Action:OnWeaponCanUse(client, weaponent)
{
	if(hasAnyRestriction[client]){
		if(CheckCanUseWeapon(client,weaponent))
		{
			return Plugin_Continue; //ALLOW
		}
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

public Action:DeciSecondTimer(Handle:h,any:a){
	timerskip--;
	if(timerskip<1){
		timerskip=10;
		for(new client=1;client<=MaxClients;client++){
			/*if(true){ //test
			new wpnent = GetCurrentWeaponEnt(client);
			if(FindSendPropOffs("CWeaponUSP","m_bSilencerOn")>0){
			
			SetEntData(wpnent,FindSendPropOffs("CWeaponUSP","m_bSilencerOn"),true,true);
			}
			
			}*/
			if(hasAnyRestriction[client]&&ValidPlayer(client,true)){
				
				new String:name[32];
				GetClientName(client,name,sizeof(name));
				//PrintToChatAll("ValidPlayer %d",client);
				
				new wpnent = GetCurrentWeaponEnt(client);
				//PrintIfDebug(client,"   weapon ent %d %d",client,wpnent);
				//new String:WeaponName[32];
				
				//if(IsValidEdict(wpnent)){
				
				//	}
				
				//PrintIfDebug(client,"    %s res: (%s) weapon: %s",name,weaponsAllowed[client],WeaponName);		
				//	if(strlen(weaponsAllowed[client])>0){
				if(wpnent>0&&IsValidEdict(wpnent)){
					
					
					if (CheckCanUseWeapon(client,wpnent)){
						//allow
					}
					else
					{
						//RemovePlayerItem(client,wpnent);
						
						//PrintIfDebug(client,"            drop");
						
						CS_DropWeapon(client,wpnent,true);
						//SDKHooks_DropWeapon(client, wpnent);
						//AcceptEntityInput(wpnent, "Kill");
						//UTIL_Remove(wpnent);
						
					}
					
				}
				else{
					//PrintIfDebug(client,"no weapon");
					//PrintToChatAll("no weapon");
				}
				//	}
			}
		}
	}
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if(ValidPlayer(client,true)){
		static bool:wasdisarmed[MAXPLAYERSCUSTOM];
		if(SC_GetBuffHasTrue(client,bStunned)||SC_GetBuffHasTrue(client,bDisarm)){
			wasdisarmed[client]=true;
			new ent = GetCurrentWeaponEnt(client);
			if(ent != -1)
			{
				 SetEntPropFloat(ent, Prop_Send, "m_flNextPrimaryAttack", GetGameTime()+0.2);
			} 
		}
		else if(	wasdisarmed[client]){
			wasdisarmed[client]=false;
			
			new ent = GetCurrentWeaponEnt(client);
			if(ent != -1)
			{
				 SetEntPropFloat(ent, Prop_Send, "m_flNextPrimaryAttack", GetGameTime());
			} 
		}
	}
	return Plugin_Continue;
}

public WeaponFireEvent(Handle:event,const String:name[],bool:dontBroadcast)
{ 
	
	new client = GetClientOfUserId(GetEventInt(event,"userid"));
	
	///PrintToServer("3");
	//SetEntPropVector(client, Prop_Send, "m_vecPunchAngle", Float:{0.0,0.0,0.0});
	
	//if(!IsRace(client))
	//  return;
	// if( (g_fDuration[client] < Getgametime()) || ( g_fMulti[client] < 1.0 ) ) //g_fDuratioin is for "in the fast attack speed mode"
	//    return;
	new ent = GetCurrentWeaponEnt(client);
	if(ent != -1)
	{
		//fill the stack for next frame
		g_iWeaponRateQueue[g_iWeaponRateQueueLength][0] = ent;
		g_iWeaponRateQueue[g_iWeaponRateQueueLength++][1] = client;
	} 
	new Handle:oldevent=SC_GetVar(SmEvent);
	SC_SetVar(SmEvent,event);
	Call_StartForward(hweaponFiredFwd);
	Call_PushCell(client);
	Call_Finish(dummy);	
	SC_SetVar(SmEvent,oldevent);
}

public Action:TF2_CalcIsAttackCritical(client, weapon, String:weaponname[], &bool:result)
{
	// new client = GetClientOfUserId(GetEventInt(event,"userid"));
	//if(!IsRace(client))
	//  return;
	// if( (g_fDuration[client] < Getgametime()) || ( g_fMulti[client] < 1.0 ) ) //g_fDuratioin is for "in the fast attack speed mode"
	//    return;
	new ent = GetEntDataEnt2(client,m_OffsetActiveWeapon);
	if(ent != -1)
	{
		//fill the stack for next frame
		g_iWeaponRateQueue[g_iWeaponRateQueueLength][0] = ent;
		g_iWeaponRateQueue[g_iWeaponRateQueueLength][1] = client;
		g_iWeaponRateQueueLength++;
	} 
	
	Call_StartForward(hweaponFiredFwd);
	Call_PushCell(client);
	Call_Finish(dummy);
}

public OnGameFrame(){
	if(g_iWeaponRateQueueLength>0)       //see events
	{
		decl ent, client, Float:time;
		new Float:gametime = GetGameTime();
		for(new i = 0; i < g_iWeaponRateQueueLength; i++) {
			ent = g_iWeaponRateQueue[i][0];
			if(IsValidEntity(ent)) {   //weapon ent is valid
				
				client = g_iWeaponRateQueue[i][1];
				new Float:multi = SC_GetBuffMaxFloat(client,fAttackSpeed);
				if(multi!=1.0){        //do we need to change it?
					time = (GetEntDataFloat(ent,m_OffsetNextPrimaryAttack) - gametime) / multi;
					SetEntDataFloat(ent,m_OffsetNextPrimaryAttack,time + gametime,true);
				}
			}
		} 
		g_iWeaponRateQueueLength = 0; 
	}
}
