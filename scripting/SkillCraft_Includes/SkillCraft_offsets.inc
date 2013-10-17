new Handle:hSpawnPlayer;


public bool:SkillCraft_InitOffset()
{
	new bool:ret=true;
		
	
	
	new Handle:hGameConf=INVALID_HANDLE;
	hGameConf=LoadGameConfigFile("sm-tf2.games");
	if(hGameConf)
	{
		StartPrepSDKCall(SDKCall_Entity);
		PrepSDKCall_SetFromConf(hGameConf,SDKConf_Virtual,"ForceRespawn");
		hSpawnPlayer=EndPrepSDKCall();
		CloseHandle(hGameConf);
	}
	else
	{
		PrintToServer("[SkillCraft] Error, could not find configuration file for game.");
		ret=false;
	}
	return ret;
}

public SC_Respawn(client)
{
	SDKCall(hSpawnPlayer,client);
}
