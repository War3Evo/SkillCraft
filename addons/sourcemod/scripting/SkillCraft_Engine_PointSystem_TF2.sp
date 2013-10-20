#include <sourcemod>
#include "SkillCraft_Includes/SkillCraft_Interface"

public Plugin:myinfo=
{
	name="SkillCraft Point System TF2",
	author="SkillCraft Team",
	description="SkillCraft Core Plugins",
	version="1.0",
};

// tf
new Handle:PointCapturePointsCvar;
new Handle:PointCapBlockPointsCvar;
new Handle:CaptureFlagPointsCvar;
new Handle:TeleporterPointsCvar;
new Handle:TeleporterDistancePointsCvar;
new Handle:ExtinguishPointsCvar;

new Handle:DestroyedTelePointsCvar;
new Handle:DestroyedDispenserPointsCvar;
new Handle:DestroyedSentryPointsCvar;
new Handle:DestroyedSapperPointsCvar;

new Handle:MvMMoneyPointsCvar;
new Handle:MvMMoneyScoutPointsCvar;
new Handle:MvMTankPointsCvar;
new Handle:MvMBombResetPointsCvar;
new Handle:MvMMedicSharedPowerupPointsCvar;

public OnPluginStart()
{
	PointCapturePointsCvar=CreateConVar("sc_percent_tf_pointcapture_points","3","Points awarded to the capturing team");
	PointCapBlockPointsCvar=CreateConVar("sc_percent_tf_blockcapture_points","2","Points awarded for blocking a capture");
	CaptureFlagPointsCvar=CreateConVar("sc_percent_tf_flagcapture_points","10","Points awarded for capturing the flag");
	TeleporterPointsCvar=CreateConVar("sc_percent_tf_teleporter_points","1","Points awarded");
	TeleporterDistancePointsCvar=CreateConVar("sc_tf_teleporter_distance","1000.0","Distance to teleport before awarding Points");
	ExtinguishPointsCvar=CreateConVar("sc_percent_tf_extinguish_points","1","Points awarded");

	DestroyedTelePointsCvar = CreateConVar("sc_percent_tf_tele_points","3","Points awarded");
	DestroyedDispenserPointsCvar = CreateConVar("sc_percent_tf_dispenser_points","5","Points awarded");
	DestroyedSentryPointsCvar = CreateConVar("sc_tf_destroyed_sentry_points","5","Points awarded");
	DestroyedSapperPointsCvar = CreateConVar("sc_tf_destroyed_by_sapper_sentry_points","8","Points awarded");

	MvMMoneyPointsCvar = CreateConVar("sc_percent_tf_mvm_money_pickup_points", "2", "How much of the picked up money should be converted to Points");
	MvMMoneyScoutPointsCvar = CreateConVar("sc_percent_tf_mvm_scout_money_pickup_points", "1", "How much of the picked up money should be converted to Points for a Scout");
	MvMTankPointsCvar = CreateConVar("sc_percent_tf_mvm_tank_points", "20", "Points awarded for destroying a tank");
	MvMBombResetPointsCvar = CreateConVar("sc_percent_tf_mvm_bombreset_points", "10", "Points awarded for resetting the bomb");
	MvMMedicSharedPowerupPointsCvar = CreateConVar("sc_percent_tf_mvm_share_points", "10", "Points awarded for sharing a canteen as medic");

	//if(!HookEventEx("teamplay_round_win",SC_RoundOverEvent))
	//{
	//	PrintToServer("[War3Evo] Could not hook the teamplay_round_win event.");
	//
	//}
	if(!HookEventEx("teamplay_point_captured",SC_PointCapturedEvent))
	{
		PrintToServer("[War3Evo] Could not hook the teamplay_point_captured event.");
	}
	if(!HookEventEx("teamplay_capture_blocked",SC_PointCapBlockedEvent))
	{
		PrintToServer("[War3Evo] Could not hook the teamplay_capture_blocked event.");
	}
	if(!HookEventEx("teamplay_flag_event",SC_FlagEvent))
	{
		PrintToServer("[War3Evo] Could not hook the teamplay_flag_event event.");
	}
	if(!HookEventEx("object_destroyed", SC_ObjectDestroyedEvent))
	{
		PrintToServer("[War3Evo] Could not hook the object_destroyed event.");
	}
	if(!HookEventEx("mvm_pickup_currency", SC_MvMCurrencyEvent))
	{
		PrintToServer("[War3Evo] Could not hook the mvm_pickup_currency event.");
	}
	if(!HookEventEx("mvm_tank_destroyed_by_players", SC_MvMTankBustedEvent))
	{
		PrintToServer("[War3Evo] Could not hook the mvm_tank_destroyed_by_players event.");
	}
	if(!HookEventEx("mvm_bomb_reset_by_player", SC_MvMResetBombEvent))
	{
		PrintToServer("[War3Evo] Could not hook the mvm_bomb_reset_by_player event.");
	}
	if(!HookEventEx("mvm_medic_powerup_shared", SC_MvMSharedCanteenEvent))
	{
		PrintToServer("[War3Evo] Could not hook the mvm_medic_powerup_shared event.");
	}

	HookEvent("player_teleported",TF_XP_teleported);
	HookEvent("player_extinguished",TF_XP_player_extinguished);
}

SC_GivePoints_internal(client,_points,String:capture_award_reason[])
{
	SC_SetPoints(client,_points+SC_GetPoints(client));
	SC_ChatMessage(client,"%d points for %s",_points,capture_award_reason);	
}

public SC_PointCapturedEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
	new team=GetEventInt(event,"team");
	if(team>1)
	{
		for(new i=1;i<=MaxClients;i++)
		{

			if(ValidPlayer(i,true)&& GetClientTeam(i)==team)
			{
				SC_GivePoints_internal(i,GetConVarInt(PointCapturePointsCvar),"being on the capturing team");
			}
		}
	}
}

public SC_PointCapBlockedEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
	new blocker_uid=GetEventInt(event,"blocker");
	if(blocker_uid>0)
	{
		new client=GetClientOfUserId(blocker_uid);

		if(ValidPlayer(client))
		{
			SC_GivePoints_internal(client,GetConVarInt(PointCapBlockPointsCvar),"blocking point capture");
		}
	}
}

public SC_FlagEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
	new userid=GetEventInt(event,"carrier");
	if(userid>0)
	{
		new client=GetClientOfUserId(userid);
		new type=GetEventInt(event,"eventtype");
		if(ValidPlayer(client) && type==2)
		{
			SC_GivePoints_internal(client,GetConVarInt(CaptureFlagPointsCvar),"capturing the flag");
		}
	}
}

public TF_XP_teleported(Handle:event,const String:name[],bool:dontBroadcast)
{
	new teleported=GetClientOfUserId(GetEventInt(event,"userid"));
	new client=GetClientOfUserId(GetEventInt(event,"builderid"));
	new Float:distance=GetEventFloat(event,"dist");

	if(ValidPlayer(client) && (teleported != client) ) {
		if( distance>=GetConVarFloat(TeleporterDistancePointsCvar)) {
			SC_GivePoints_internal(client,GetConVarInt(TeleporterPointsCvar),"teleporter use");
		}
		else {
			SC_ChatMessage(client,"Teleporter distance too short, 1000 minimum for points. Current distance: %.2f",distance);
		}
	}

}
public TF_XP_player_extinguished(Handle:event,const String:name[],bool:dontBroadcast)
{
	new client=GetClientOfUserId(GetEventInt(event,"healer"));
	if(ValidPlayer(client)) {
		SC_GivePoints_internal(client,GetConVarInt(ExtinguishPointsCvar),"extinguishing fire");
	}

}

public SC_ObjectDestroyedEvent(Handle:event, const String:name[], bool:dontBroadcast)
{

	/*short	 userid	 user ID who died
	 short	 attacker	 user ID who killed
	 short	 assister	 user ID of assister
	 string	 weapon	 weapon name killer used
	 short	 weaponid	 id of the weapon used
	 short	 objecttype	 type of object destroyed
	 short	 index	 index of the object destroyed
	 bool	 was_building	 object was being built when it died*/

	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new assister = GetClientOfUserId(GetEventInt(event, "assister"));
	new objecttype = GetEventInt(event, "objecttype");

	//decl String:weapon[64];
	//GetEventString(event, "weapon", weapon, sizeof(weapon));
	new bool:was_building = GetEventBool(event, "was_building");
	new Float:modifier = 1.0;

	if (was_building == true)
	{
		modifier = 0.5;
	}
	
	if(objecttype == 0)
	{
		if (ValidPlayer(attacker))
		{
			SC_GivePoints_internal(attacker,RoundToCeil(GetConVarInt(DestroyedDispenserPointsCvar) * modifier),"Destroying a Dispenser");
		}

		if (ValidPlayer(assister))
		{
			SC_GivePoints_internal(assister,RoundToCeil(GetConVarInt(DestroyedDispenserPointsCvar) * modifier),"Assisting in destroying a Dispenser");
		}

	}
	else if(objecttype == 1)
	{
		if (ValidPlayer(attacker))
		{
			SC_GivePoints_internal(attacker,RoundToCeil(GetConVarInt(DestroyedTelePointsCvar) * modifier),"Destroying a Teleporter");
		}

		if (ValidPlayer(assister))
		{
			SC_GivePoints_internal(assister,RoundToCeil(GetConVarInt(DestroyedTelePointsCvar) * modifier),"Assisting in destroying a Teleporter");
		}
	}
	else if(objecttype == 2)
	{
		if (ValidPlayer(attacker))
		{
			SC_GivePoints_internal(attacker,RoundToCeil(GetConVarInt(DestroyedSentryPointsCvar) * modifier),"Destroying a Sentry");
		}

		if (ValidPlayer(assister))
		{
			SC_GivePoints_internal(assister,RoundToCeil(GetConVarInt(DestroyedSentryPointsCvar) * modifier),"Assisting in destroying a Sentry");
		}
	}
	else if(objecttype == 3)
	{
		if (ValidPlayer(attacker))
		{
			SC_GivePoints_internal(attacker,RoundToCeil(GetConVarInt(DestroyedSapperPointsCvar) * modifier),"Destroying a Sapper");
		}

		if (ValidPlayer(assister))
		{
			SC_GivePoints_internal(assister,RoundToCeil(GetConVarInt(DestroyedSapperPointsCvar) * modifier),"Assisting in destroying a Sapper");
		}
	}
}

public SC_MvMCurrencyEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
	new client = GetEventInt(event, "player");
	//new currency = GetEventInt(event, "currency");

	if (ValidPlayer(client, true))
	{
		if (TF2_GetPlayerClass(client) == TFClass_Scout)
		{
			if(SC_Chance(0.05))
			{
				SC_GivePoints_internal(client,GetConVarInt(MvMMoneyScoutPointsCvar),"for picking up money");
			}
		}
		else
		{
			SC_GivePoints_internal(client,GetConVarInt(MvMMoneyPointsCvar),"for picking up money");
		}
	}
}

public SC_MvMTankBustedEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
	for(new i=1; i<=MaxClients; i++)
	{
		if(ValidPlayer(i, true) && GetClientTeam(i) == TEAM_RED)
		{
			SC_GivePoints_internal(i,GetConVarInt(MvMTankPointsCvar),"destroying a tank");
		}
	}
}

public SC_MvMResetBombEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
	new client = GetEventInt(event, "player");

	if (ValidPlayer(client, true))
	{
		SC_GivePoints_internal(client,GetConVarInt(MvMBombResetPointsCvar),"resetting the bomb");
	}
}

public SC_MvMSharedCanteenEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
	new client = GetEventInt(event, "player");

	if (ValidPlayer(client, true))
	{
		SC_GivePoints_internal(client,GetConVarInt(MvMMedicSharedPowerupPointsCvar),"sharing a canteen");
	}
}
