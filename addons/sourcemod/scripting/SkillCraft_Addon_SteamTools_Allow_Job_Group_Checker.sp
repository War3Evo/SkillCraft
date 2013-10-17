/* ========================================================================== */
/*             steamtools (check if user in steam group)                     */
/* ========================================================================== */
#pragma semicolon 1

#pragma semicolon 1    ///WE RECOMMEND THE SEMICOLON
#include <sourcemod>
#undef REQUIRE_EXTENSIONS
#include "steamtools"
#define REQUIRE_EXTENSIONS
//#include "SC_SIncs/cssclantags"
#include "SkillCraft_Includes/SkillCraft_Interface"
//#include "SC_SIncs/War3evo"

new Handle:g_hClanID = INVALID_HANDLE;

new bool:g_bSteamTools = false;
new bool:bIsInGroup[MAXPLAYERSCUSTOM] = false;

#define PLUGIN_VERSION "0.0.1"

public Plugin:myinfo = {
	name        = "SteamTools Group Checker Addon",
	author      = "SkillCraft Team",
	description = "SteamTools Group checker for races.",
	version     = "1.0.0.0",
};
new myChecker[MAXPLAYERSCUSTOM+1];
public OnPluginStart()
{
	// War3Evo's Clan ID for Default (You can change this id thru your skillcraft.cfg file)
	g_hClanID = CreateConVar("sc_clan_id","4174523","If GroupID is non-zero the plugin will use steamtools to identify clan players(Overrides 'sc_bonusclan_name')");
	
	// tells if steamtools is loaded and(if used from a client console) if you're member of the war3_bonusclan_id group
	RegConsoleCmd("sc_bonusclan", Command_TellStatus);
	
	// refreshes groupcache
	RegServerCmd("sc_bonusclan_refresh", Command_Refresh);
}

public bool:Init_SC_NativesForwards()
{
	MarkNativeAsOptional("Steam_RequestGroupStatus");
	CreateNative("SC_IsInSteamGroup",Native_SC__isingroup);
	return true;  // prevents log errors
}

public OnClientConnected(client)
{
	myChecker[client]=0;
}
public Native_SC__isingroup(Handle:plugin,numParams)
{
	new client=GetNativeCell(1);
	return bIsInGroup[client];

}

public Action:Command_Refresh(args)
{
	for(new client=1;client<=MaxClients;client++)
	{
		if(ValidPlayer(client,false) && !IsFakeClient(client))
		{
			Steam_RequestGroupStatus(client, GetConVarInt(g_hClanID));
		}
	}
	PrintToServer("[SC] Repolling groupstatus...");
}

public Action:Command_TellStatus(client,args)
{
	if(g_bSteamTools) {
		ReplyToCommand(client,"[SC] Steamtools detected!");
	}
	else {
		ReplyToCommand(client,"[SC] Steamtools wasn't recognized!");
	}
	if(IS_PLAYER(client)) {
		ReplyToCommand(client,"[SC] Membership status of Group(%i) is: %s",GetConVarInt(g_hClanID),(bIsInGroup[client]?"member":"nobody"));
	}
	return Plugin_Handled;
}

public OnClientPutInServer(client)
{
	if (IsFakeClient(client))
	return;

	if(ValidPlayer(client))
	{
		CreateTimer (30.0, WelcomeAdvertTimer, client);

		// reset cached group status
		bIsInGroup[client] = false;
		// repoll
		if(check_steamtools()) {
			new iGroupID = GetConVarInt(g_hClanID);
			if(iGroupID != 0) {
				Steam_RequestGroupStatus(client, iGroupID);
			}
		}
	}
}

public Action:WelcomeAdvertTimer (Handle:timer, any:client)
{
	for(new x=1;x<=MaxClients;x++)
	{
		if(ValidPlayer(x,false) && !IsFakeClient(x))
		{
			Steam_RequestGroupStatus(x, GetConVarInt(g_hClanID));
		}
	}
	//PrintToServer("[SC_S] Repolling groupstatus...");

	decl String:ClientName[64] = "";
	if (ValidPlayer(client) && !IsFakeClient(client))
	{
		GetClientName (client, ClientName, sizeof (ClientName));
		decl String:buffer2[32] = "-SkillCraft!";

		Format(ClientName, sizeof(ClientName), "\x01\x03%s\x01", ClientName);
		Format(buffer2, sizeof(buffer2), "\x01\x04%s\x01", buffer2);
		if(bIsInGroup[client])
		{
			PrintToChat(client, "\x01\x04[SkillCraft]\x01 Welcome to the our Steam Group!",ClientName,buffer2);
		}
		else
		{
			//PrintToChat(client, "\x01\x04[SkillCraft]\x01 Welcome %s\x01! Please join our steam group for bonus jobs and items. Type !join to get started.",ClientName,buffer2);
			//PrintToChat(client, "\x01\x04[SkillCraft]\x01 Type !join to join");
		}
		//PrintToChat (client, "\x01\x04[SkillCraft]\x01 Welcome! Please join our Steam Group ");
	}

	return Plugin_Stop;
}



/* SteamTools */


public Steam_FullyLoaded()
{
	g_bSteamTools = true;
}

public Steam_Shutdown()
{
	g_bSteamTools = false;
}

public Steam_GroupStatusResult(client, groupID, bool:bIsMember, bool:bIsOfficer)
{
	if(groupID == GetConVarInt(g_hClanID)) {
		if(ValidPlayer(client) && !IsFakeClient(client))
		{
			bIsInGroup[client] = bIsMember;
			if(!bIsMember)
			{
				//PrintToChat(client, "\x01\x04[SkillCraft]\x01 Please join our steam group for bonus jobs and items. Type !join to get started.");
			}
			else
			{
				if (myChecker[client] == 0) {
					//PrintToChat(client, "\x01\x04[SkillCraft]\x01 Thanks for joining our steam group!");
					myChecker[client] = 1;
				} 
			}
		}
	}
}

// Checks if steamtools is currently running properly
stock bool:check_steamtools()
{
	/*if(HAS_STEAMTOOLS()) {
		if(!g_bSteamTools) {
			LogError("SteamTools was detected but not properly loaded");
			return false;
		}
		return true;
	}
	return false;*/
	return g_bSteamTools;
}
