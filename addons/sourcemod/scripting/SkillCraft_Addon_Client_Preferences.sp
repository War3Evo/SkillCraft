/* ========================================================================== */
/*                                                                            */
/*   Filename.c                                                               */
/*   (c) 2001 Author                                                          */
/*                                                                            */
/*   Description                                                              */
/*                                                                            */
/* ========================================================================== */

#include <clientprefs>
#include <sdktools>
#include "SkillCraft_Includes/SkillCraft_Interface"
//#include "SkillCraft_Includes/SkillCraft_PlayerProp"
//#include "SkillCraft_Includes/SkillCraft_stocks_misc"

new Handle:g_hCookieHud = INVALID_HANDLE;
new Handle:g_hCookieBuffChatInfo = INVALID_HANDLE;
new Handle:g_hCookieBuffChatInfo2 = INVALID_HANDLE;
new Handle:g_hCookieOnDeathMsgDetailed = INVALID_HANDLE;
new Handle:g_hCookieIntroSong = INVALID_HANDLE;
new Handle:g_hRotateHUD = INVALID_HANDLE;
//new Handle:g_CookieTag = INVALID_HANDLE;
//new Handle:g_CookieLevel = INVALID_HANDLE;
	//new CookieMenuHandler:CallBack_CookieMenuHandler;

//new String:introSound[256]; //="war3source/blinkarrival.wav";
public Plugin:myinfo=
{
	name="SkillCraft Addon - Client Preferences",
	author="SkillCraft Team",
	description="Skillcraft Addon Plugin",
	version="1.0.0.2",
};

public OnPluginStart()
{
	SetCookieMenuItem(War3Prefs, 0, "SkillCraft Server Settings");
	
	g_hCookieHud = RegClientCookie("skillcraft.hud", "SkillCraft Hud", CookieAccess_Public);
	g_hCookieBuffChatInfo = RegClientCookie("skillcraft.buff.chat.info", "War3Evo show buffs on race change", CookieAccess_Public);
	g_hCookieBuffChatInfo2 = RegClientCookie("skillcraft.buff.chat.info2", "War3Evo show buffs during play", CookieAccess_Public);
	g_hCookieOnDeathMsgDetailed = RegClientCookie("skillcraft.detailed.death.msg", "War3Evo Detailed OnDeath Messages", CookieAccess_Public);
	g_hRotateHUD = RegClientCookie("skillcraft.rotateHUD", "Automatically rotate gold/diamond/plat HUD", CookieAccess_Public);
	AddCommandListener(Command_ShowCookieMenu, "say");
	AddCommandListener(Command_ShowCookieMenu, "say_team");
}
public War3Prefs(client, CookieMenuAction:action, any:info, String:buffer[], maxlen)
{
	if (action == CookieMenuAction_SelectOption)
	{
		ShowWar3PrefsMenu(client);
	}
}

ShowWar3PrefsMenu(client,page=0)
{

	new Handle:menu = CreateMenu(CallBack_CookieMenuHandler);
	decl String:buffer[100];
	
	Format(buffer, sizeof(buffer), "SkillCraft Server Settings");
	SetMenuTitle(menu, buffer);

	AddMenuItem(menu, "b", "<- Back To Prefs Menu");
	
	if(SC_GetPlayerProp(client,iGoldDiamondHud)==1)
	{
		Format(buffer, sizeof(buffer), "[ON] Toggle HUD of Skills");
	} else {
		Format(buffer, sizeof(buffer), "[OFF] Toggle HUD of Skills");
	}
	AddMenuItem(menu, "1", buffer);
	
	if(SC_GetPlayerProp(client,iBuffChatInfo)==1)
	{
		Format(buffer, sizeof(buffer), "[ON] Toggle SkillCraft Buff Display on Skill Change");
	} else {
		Format(buffer, sizeof(buffer), "[OFF] Toggle SkillCraft Buff Display on Skill Change");
	}

	AddMenuItem(menu, "2", buffer);
	
	if(SC_GetPlayerProp(client,iDetailedOnDeathMsgs)==1)
	{
		Format(buffer, sizeof(buffer), "[ON] Toggle Detailed SkillCraft Info on Kill/Death");
	} else {
		Format(buffer, sizeof(buffer), "[OFF] Toggle Detailed SkillCraft Info on Kill/Death");
	}
	AddMenuItem(menu, "3", buffer);
	
	if(SC_GetPlayerProp(client,iBuffChatInfo2)==1)
	{
		Format(buffer, sizeof(buffer), "[ON] Toggle SkillCraft Buff Display Throughout Game Play");
	} else {
		Format(buffer, sizeof(buffer), "[OFF] Toggle SkillCraft Buff Display Throughout Game Play");
	}	
	
	AddMenuItem(menu, "4", buffer); 
	
	if(SC_GetPlayerProp(client,iIntroSong)==1)
	{
		Format(buffer, sizeof(buffer), "[ON] Toggle Hearing Introduction Music");
	} else {
		Format(buffer, sizeof(buffer), "[OFF] Toggle Hearing Introduction Music");
	}	
	
	AddMenuItem(menu, "5", buffer);

	if(SC_GetPlayerProp(client,iRotateHUD)==1)
	{
		Format(buffer, sizeof(buffer), "[MODE 1] HUD Display Type");
	} else if (SC_GetPlayerProp(client,iRotateHUD)==2) {
		Format(buffer, sizeof(buffer), "[MODE 2] HUD Display Type");	
	} else {
		Format(buffer, sizeof(buffer), "[MODE 3] HUD Display Type");
	}	
	
	AddMenuItem(menu, "12", buffer);
	
	new bool:multipage=GetMenuItemCount(menu)>9; 
	if(!multipage){
		SetMenuPagination(menu, MENU_NO_PAGINATION);
	}

	
	
	
	
	SetMenuExitButton(menu, true);
	if(multipage){
		DisplayMenuAtItem(menu, client, page*7, MENU_TIME_FOREVER);
	}else{
		DisplayMenu(menu, client, MENU_TIME_FOREVER);
	}

}

public OnMapStart()
{
	//disabled atm
	//strcopy(introSound,sizeof(introSound),"war3source/clickboom.mp3");
	//SC_PrecacheSound(introSound);
}


ShowPrefsMenuItemsInfo(client)
{
	ShowCookieMenu(client);
}


//public CallBack_CookieMenuHandler(client, CookieMenuAction:action, any:info, String:buffer[], maxlen)
									//
public CallBack_CookieMenuHandler(Handle:menu, MenuAction:action, param1, param2)
{

		if(action==MenuAction_Select)
		{
			decl String:info[32];
			if(!GetMenuItem(menu, param2, info, sizeof(info))){
				return;
			}
			if(StrEqual(info, "b")){ 
				ShowCookieMenu(param1);
				return;
			}
			//PrintToServer("info %s",buffer);
			new iTempInt=0;
			decl String:iSTR[5];

			if(StrEqual(info, "1"))   // GOLD DIAMOND HUD 1
			{
				if(SC_GetPlayerProp(param1,iGoldDiamondHud)==1)
				{
					iTempInt = 0;
					strcopy(iSTR,sizeof(iSTR),"0");
				}
				else
				{
					iTempInt = 1;
					strcopy(iSTR,sizeof(iSTR),"1");
				}
				SetClientCookie(param1, g_hCookieHud, iSTR);
				SC_SetPlayerProp(param1,iGoldDiamondHud,iTempInt);
			} //end of info==1

			if(StrEqual(info, "2"))   // BUFF CHAT INFO
			{
				if(SC_GetPlayerProp(param1,iBuffChatInfo)==1)
				{
					iTempInt = 0;
					strcopy(iSTR,sizeof(iSTR),"0");
				}
				else
				{
					iTempInt = 1;
					strcopy(iSTR,sizeof(iSTR),"1");
				}
				SetClientCookie(param1, g_hCookieBuffChatInfo, iSTR);
				SC_SetPlayerProp(param1,iBuffChatInfo,iTempInt);
			} //end of info==2

			if(StrEqual(info, "3"))   // DETAILED ON DEATH MSG
			{
				if(SC_GetPlayerProp(param1,iDetailedOnDeathMsgs)==1)
				{
					iTempInt = 0;
					strcopy(iSTR,sizeof(iSTR),"0");
				}
				else
				{
					iTempInt = 1;
					strcopy(iSTR,sizeof(iSTR),"1");
				}
				SetClientCookie(param1, g_hCookieOnDeathMsgDetailed, iSTR);
				SC_SetPlayerProp(param1,iDetailedOnDeathMsgs,iTempInt);
			} //end of info==3

			if(StrEqual(info, "4"))  // BUFF CHAT INFO 2
			{
				if(SC_GetPlayerProp(param1,iBuffChatInfo2)==1)
				{
					iTempInt = 0;
					strcopy(iSTR,sizeof(iSTR),"0");
				}
				else
				{
					iTempInt = 1;
					strcopy(iSTR,sizeof(iSTR),"1");
				}
				SetClientCookie(param1, g_hCookieBuffChatInfo2, iSTR);
				SC_SetPlayerProp(param1,iBuffChatInfo2,iTempInt);
			} //end of info==4

			if(StrEqual(info, "5"))  //  INTRO SONG
			{
				if(SC_GetPlayerProp(param1,iIntroSong)==1)
				{
					iTempInt = 0;
					strcopy(iSTR,sizeof(iSTR),"0");
				}
				else
				{
					iTempInt = 1;
					strcopy(iSTR,sizeof(iSTR),"1");
				}
				SetClientCookie(param1, g_hCookieIntroSong, iSTR);
				SC_SetPlayerProp(param1,iIntroSong,iTempInt);
			} //end of info==5

			if(StrEqual(info, "12"))      // HUD TYPE
			{
				if(SC_GetPlayerProp(param1,iRotateHUD)==1)
				{
					iTempInt = 2;
					strcopy(iSTR,sizeof(iSTR),"2");
				}
				else if(SC_GetPlayerProp(param1,iRotateHUD)==2) 
				{
					iTempInt = 0;
					strcopy(iSTR,sizeof(iSTR),"0");					
				}
				else
				{
					iTempInt = 1;
					strcopy(iSTR,sizeof(iSTR),"1");
				}
				SetClientCookie(param1, g_hRotateHUD, iSTR);
				SC_SetPlayerProp(param1,iRotateHUD,iTempInt);
			}

			ShowWar3PrefsMenu(param1);
		}
}

public Action:Command_ShowCookieMenu(client, const String:command[], args)
{
	if(!client) return Plugin_Continue;
	
	decl String:szArg[255];
	GetCmdArgString(szArg, sizeof(szArg));

	StripQuotes(szArg);
	TrimString(szArg);	

	if (StrEqual(szArg, "prefs", false)||StrEqual(szArg, "!prefs", false)||StrEqual(szArg, "/prefs", false)||StrEqual(szArg, "preps", false))
	{
		ShowPrefsMenuItemsInfo(client);

		return Plugin_Handled;
	}	
	return Plugin_Continue;
}

public OnClientDisconnect(iClient)
{
	if(IsFakeClient(iClient))
	{
		SC_SetPlayerProp(iClient,iGoldDiamondHud,0);
		SC_SetPlayerProp(iClient,iBuffChatInfo,0);
		SC_SetPlayerProp(iClient,iDetailedOnDeathMsgs,0);
		SC_SetPlayerProp(iClient,iBuffChatInfo2,0);
		SC_SetPlayerProp(iClient,iIntroSong,0);
		SC_SetPlayerProp(iClient,iRotateHUD,0);
		return;
	}
	//DEFAULTS
	SC_SetPlayerProp(iClient,iGoldDiamondHud,1);
	SC_SetPlayerProp(iClient,iBuffChatInfo,0);
	SC_SetPlayerProp(iClient,iDetailedOnDeathMsgs,0);
	SC_SetPlayerProp(iClient,iBuffChatInfo2,0);
	SC_SetPlayerProp(iClient,iIntroSong,1);
	SC_SetPlayerProp(iClient,iRotateHUD,1);
}

public OnClientCookiesCached(client)
{
	// Initializations and preferences loading
	loadClientCookiesFor(client);	
}

public OnClientPutInServer(iClient)
{
	if(ValidPlayer(iClient) && SC_GetPlayerProp(iClient,iIntroSong)==1)
	{
		//PrintToServer("PLAY INTRO MUSIC");
		//EmitSoundToClient(iClient,introSound);
		//EmitSoundToClient(iClient,introSound);
	}
}

//public OnClientPostAdminCheck(iClient)
loadClientCookiesFor(iClient)
{
		if(IsFakeClient(iClient))
		{
			SC_SetPlayerProp(iClient,iGoldDiamondHud,0);
			SC_SetPlayerProp(iClient,iBuffChatInfo,0);
			SC_SetPlayerProp(iClient,iDetailedOnDeathMsgs,0);
			SC_SetPlayerProp(iClient,iBuffChatInfo2,0);
			SC_SetPlayerProp(iClient,iIntroSong,0);
			SC_SetPlayerProp(iClient,iRotateHUD,0);
			return;
		}
		//DEFAULTS
		//PrintToServer("SETTING CLIENT COOKIES DEFAULT");
		SC_SetPlayerProp(iClient,iGoldDiamondHud,1);
		SC_SetPlayerProp(iClient,iBuffChatInfo,0);
		SC_SetPlayerProp(iClient,iDetailedOnDeathMsgs,0);
		SC_SetPlayerProp(iClient,iBuffChatInfo2,0);
		SC_SetPlayerProp(iClient,iIntroSong,1);
		SC_SetPlayerProp(iClient,iRotateHUD,1);

		decl String:buffer[5];
	
		//PrintToServer("LOAD CLIENT COOKIES");

		// GOLD / DIAMOND / PLATINUM HUD
		GetClientCookie(iClient, g_hCookieHud, buffer, 5);
		if(!StrEqual(buffer, ""))
		{
			new iTempInt = StringToInt(buffer);
			SC_SetPlayerProp(iClient,iGoldDiamondHud,iTempInt);
			//PrintToServer("USER PREF: HUD %d",SC_GetPlayerProp(iClient,iGoldDiamondHud));
		}
		else
		{
			//default  1
			SC_SetPlayerProp(iClient,iGoldDiamondHud,1);
			//PrintToServer("DEFAULT: GHUD %d",SC_GetPlayerProp(iClient,iGoldDiamondHud));
		}
		
		// BUFF CHAT INFORMATION MESSAGES on job change
		GetClientCookie(iClient, g_hCookieBuffChatInfo, buffer, 5);
		if(!StrEqual(buffer, ""))
		{
			new iTempInt = StringToInt(buffer);
			SC_SetPlayerProp(iClient,iBuffChatInfo,iTempInt);
			//PrintToServer("USER PREF: BUFF CHAT INFO1 %d",SC_GetPlayerProp(iClient,iBuffChatInfo));
		}
		else
		{
			//default  0
			SC_SetPlayerProp(iClient,iBuffChatInfo,0);
			//PrintToServer("DEFAULT: BUFF CHAT INFO1 %d",SC_GetPlayerProp(iClient,iBuffChatInfo));
		}
		

		// DETAILED ON DEATH MESSAGES
		GetClientCookie(iClient, g_hCookieOnDeathMsgDetailed, buffer, 5);
		if(!StrEqual(buffer, ""))
		{
			new iTempInt = StringToInt(buffer);
			SC_SetPlayerProp(iClient,iDetailedOnDeathMsgs,iTempInt);
			//PrintToServer("USE PREF: ON DEATH MESSAGES %d",SC_GetPlayerProp(iClient,iDetailedOnDeathMsgs));
		}
		else
		{
			//default   0
			SC_SetPlayerProp(iClient,iDetailedOnDeathMsgs,0);
			//PrintToServer("DEFAULT: ON DEATH MESSAGES %d",SC_GetPlayerProp(iClient,iDetailedOnDeathMsgs));
		}


		// BUFF CHAT INFORMATION MESSAGES during play
		GetClientCookie(iClient, g_hCookieBuffChatInfo2, buffer, 5);
		if(!StrEqual(buffer, ""))
		{
			new iTempInt = StringToInt(buffer);
			SC_SetPlayerProp(iClient,iBuffChatInfo2,iTempInt);
			//PrintToServer("USE PREF: BUFF CHAT INFORMATION MESSAGES during play %d",SC_GetPlayerProp(iClient,iBuffChatInfo2));
		}
		else
		{
			//default   0
			SC_SetPlayerProp(iClient,iBuffChatInfo2,0);
			//PrintToServer("DEFAULT: BUFF CHAT INFORMATION MESSAGES during play %d",SC_GetPlayerProp(iClient,iBuffChatInfo2));
		}

		// INTRO SONG
		GetClientCookie(iClient, g_hCookieIntroSong, buffer, 5);
		if(!StrEqual(buffer, ""))
		{
			new iTempInt = StringToInt(buffer);
			SC_SetPlayerProp(iClient,iIntroSong,iTempInt);
			//PrintToServer("USE PREF: INTRO SONG %d",SC_GetPlayerProp(iClient,iIntroSong));
		}
		else
		{
			//default  1
			SC_SetPlayerProp(iClient,iIntroSong,1);
			//PrintToServer("DEFAULT: INTRO SONG %d",SC_GetPlayerProp(iClient,iIntroSong));
		}

		// HUD TYPE
		GetClientCookie(iClient, g_hRotateHUD, buffer, 5);
		if(!StrEqual(buffer, ""))
		{
			new iTempInt = StringToInt(buffer);
			SC_SetPlayerProp(iClient,iRotateHUD,iTempInt);
		}
		else
		{
			//default  1
			SC_SetPlayerProp(iClient,iRotateHUD,1);
		}

		//PrintToServer("END OF: SETTING CLIENT COOKIES DEFAULT");
}
