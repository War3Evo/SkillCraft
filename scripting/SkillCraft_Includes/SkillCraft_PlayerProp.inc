//Basically Instance variables for the Player Class
enum SC_PlayerProp
{
	bool:bPutInServer,

	Current_Mastery_Skill,
	Current_Talent_Skill,
	Current_Ability_Skill,
	Current_Ultimate_Skill,

	Pending_Mastery_Skill,
	Pending_Talent_Skill,
	Pending_Ability_Skill,
	Pending_Ultimate_Skill,
	
	Float:SkillChosenTime,
	bool:SkillSetByAdmin,

	iMaxHP,
	bIsDucking,
	
	bool:xpLoaded,
	bool:SpawnedOnce, //if player has spawned once
	Float:sqlStartLoadXPTime,
	
	bool:isDeveloper,
	Float:LastChangeTeamTime,
	bool:bStatefulSpawn, //set true if spawn is a non repeated spawn. set to true on join and death, set false after spawn forward is finished.
	iGoldDiamondHud,   // Player preferences (Gold Hud on / off)
	//bool:dbRaceSelected, //used in spawn camper.
	iBuffChatInfo, // Player preferences (Detailed Buff messages)
	iDetailedOnDeathMsgs, // Player preferences (Detailed Buff messages)
	iBuffChatInfo2, // Player preferences (Detailed Buff messages)
	iIntroSong, // Player preferences
	iSaySounds, // Player preferences
	
	// part of a different system:
	// need to double check and remove later:
	iHlstatsx,
	iAutoBuyMaxGoldItem,
	iServerAds,
	iIrcCrossServerChat,
	iFragRadio,
	
	// Keep this:
	iRotateHUD,
}

native SC_SetPlayerProp(client,SC_PlayerProp:property,any:value);
native any:SC_GetPlayerProp(client,SC_PlayerProp:property);

stock bool:ValidPlayer(client,bool:check_alive=false,bool:alivecheckbyhealth=false) {
	if(client>0 && client<=MaxClients && IsClientConnected(client) && IsClientInGame(client))
	{
		if(check_alive && !IsPlayerAlive(client))
		{
			return false;
		}
		if(alivecheckbyhealth&&GetClientHealth(client)<1) {
			return false;
		}
		return true;
	}
	return false;
}
