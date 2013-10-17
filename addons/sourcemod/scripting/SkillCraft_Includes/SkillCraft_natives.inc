//public Native_SC_GetSC_Revision(Handle:plugin,numParams){
	//return 0;
//}
public Native_SC_GetSC_Version(Handle:plugin,numParams){	
	SetNativeString(1,VERSION_NUM,GetNativeCell(2));
}
public Native_SC_InFreezeTime(Handle:plugin,numParams)
{
	return (bInFreezeTime)?1:0;
}






public Native_SC_FlashScreen(Handle:plugin,numParams)
{
	new client=GetNativeCell(1);
	new color[4];
	GetNativeArray(2,color,4);
	new Float:holdduration=GetNativeCell(3);
	new Float:fadeduration=GetNativeCell(4);
	new flags=GetNativeCell(5);
	if(ValidPlayer(client,false))
	{
		new Handle:hBf=StartMessageOne("Fade",client);
		if(hBf!=INVALID_HANDLE)
		{
			BfWriteShort(hBf,RoundFloat(255.0*fadeduration));
			BfWriteShort(hBf,RoundFloat(255.0*holdduration)); //holdtime
			BfWriteShort(hBf,flags);
			BfWriteByte(hBf,color[0]);
			BfWriteByte(hBf,color[1]);
			BfWriteByte(hBf,color[2]);
			BfWriteByte(hBf,color[3]);
			EndMessage();
		}
	}
}

public Native_SC_ShakeScreen(Handle:plugin,numParams)
{
	new client=GetNativeCell(1);
	new Float:duration=GetNativeCell(2);
	new Float:magnitude=GetNativeCell(3);
	new Float:noise=GetNativeCell(4);
	if(ValidPlayer(client,false))
	{
		new Handle:hBf=StartMessageOne("Shake",client);
		if(hBf!=INVALID_HANDLE)
		{
			BfWriteByte(hBf,0);
			BfWriteFloat(hBf,magnitude);
			BfWriteFloat(hBf,noise);
			BfWriteFloat(hBf,duration);
			EndMessage();
		}
	}
}

public Native_SC_SpawnPlayer(Handle:plugin,numParams)
{
	new client=GetNativeCell(1);
	new ignore_check=GetNativeCell(2);
	if(ValidPlayer(client,false) && (ignore_check!=0 || !IsPlayerAlive(client)))
	{
		SC_Respawn(client);
	}
}



public Native_SC_IsUbered(Handle:plugin,numParams)
{
	new client = GetNativeCell(1);
	new m_nPlayerCond = FindSendPropInfo("CTFPlayer","m_nPlayerCond") ;
	new cond = GetEntData(client, m_nPlayerCond);
	if(cond & 32)
	{
		return true;
	}
	return false;
}


public Native_SC_HasFlag(Handle:plugin,numParams)
{
	new client = GetNativeCell(1);
	new ent = -1;
	while ((ent = FindEntityByClassname(ent, "item_teamflag")) != -1)
	{
		if (GetEntPropEnt(ent, Prop_Data, "m_hOwnerEntity")==client)
			return true;
	}
	return false;
}


public Native_SC_IsCloaked(Handle:plugin,numParams)
{
	new client = GetNativeCell(1);
	new m_nPlayerCond = FindSendPropInfo("CTFPlayer","m_nPlayerCond") ;
	new cond = GetEntData(client, m_nPlayerCond);
	if(cond & 16)
	{
		return true;
	}
	return false;
}

public Native_SC_TF_PTC(Handle:plugin,numParams)
{
	
	new client = GetNativeCell(1);
	new String:str[32];
	GetNativeString(2, str, sizeof(str));
	new Float:pos[3];
	GetNativeArray(3,pos,3);
	return TE_ParticleToClient(client,str,pos);
}



public Native_SC_HTMHP(Handle:plugin,numParams)
{
	new client = GetNativeCell(1);
	new addhp = GetNativeCell(2);
	new maxhp=SC_GetMaxHP(client);
	new currenthp=GetClientHealth(client);
	if(currenthp<maxhp){ ///do not make hp lower
		new newhp=GetClientHealth(client)+addhp;
		if (newhp>maxhp){
			newhp=maxhp;
		}
		nsEntity_SetHealth(client,newhp);
	}
	return 0;
}
public Native_SC_HTBHP(Handle:plugin,numParams)
{
	new client = GetNativeCell(1);
	new addhp = GetNativeCell(2);
	new maxhp=RoundFloat(float(SC_GetMaxHP(client))*1.5);
	new currenthp=GetClientHealth(client);
	if(currenthp<maxhp){ ///do not make hp lower
		new newhp=GetClientHealth(client)+addhp;
		if (newhp>maxhp){
			newhp=maxhp;
		}
		nsEntity_SetHealth(client,newhp);
	}
}

public Native_SC_DecreaseHP(Handle:plugin,numParams)
{
	new client = GetNativeCell(1);
	new dechp = GetNativeCell(2);
	new newhp=GetClientHealth(client)-dechp;
	if(newhp<1){
		newhp=1;
	}
	nsEntity_SetHealth(client,newhp);
}





public bool:Init_SC_NativesForwards()
{
	///LIST ALL THESE NATIVES IN INTERFACE
	
	CreateNative("SC_GetSC_Version",Native_SC_GetSC_Version);
	//CreateNative("SC_GetSC_Revision",Native_SC_GetSC_Revision);
	
	CreateNative("SC_InFreezeTime",Native_SC_InFreezeTime);
	
	
	
	CreateNative("SC_FlashScreen",Native_SC_FlashScreen);
	CreateNative("SC_ShakeScreen",Native_SC_ShakeScreen);

	CreateNative("SC_SpawnPlayer",Native_SC_SpawnPlayer);


	CreateNative("SC_IsUbered",Native_SC_IsUbered);
	
	//CreateNative("SC_PrecacheSound",Native_SC_PrecacheSound);
	
	CreateNative("SC_IsCloaked",Native_SC_IsUbered);
	
	
	CreateNative("SC_TF_ParticleToClient",Native_SC_TF_PTC);
	
	
	return true;
}


public Native_SC_IsDeveloper(Handle:plugin,numParams)
{
	new client=GetNativeCell(1); //offical SC_ developers
	if(ValidPlayer(client)){
		return SC_GetPlayerProp(client,isDeveloper);
	}
	return false;
}


public GetStatsVersion(){
	//return SC_GetStatsVersion();
}


