#include <sourcemod>
#include "SkillCraft_Includes/SkillCraft_Interface"
#include "SkillCraft_Includes/SkillCraft_CommandHook_Forwards"
#include "SkillCraft_Includes/SkillCraft_MoreColors"

new Handle:Cvar_ChatBlocking;
new Handle:Cvar_serverowner_steamid;
new Handle:Cvar_serverclantag;

public Plugin:myinfo=
{
	name="SkillCraft Engine Command Hooks",
	author="SkillCraft Team",
	description="SkillCraft Core Plugins",
	version="1.0",
};

public OnPluginStart()
{
	Cvar_ChatBlocking=CreateConVar("sc_command_blocking","0","block chat commands from showing up");
	
	Cvar_serverowner_steamid=CreateConVar("sc_serverowner_steamid","0","block chat commands from showing up");
	Cvar_serverclantag=CreateConVar("sc_serverclantag","-W3E-","Change tag for your special clan chat change and use & to start chat.");

	RegConsoleCmd("say",SkillCraft_SayCommand);
	RegConsoleCmd("say_team",SkillCraft_TeamSayCommand);
	RegConsoleCmd("+ultimate",SkillCraft_UltimateCommand);
	RegConsoleCmd("-ultimate",SkillCraft_UltimateCommand);
	RegConsoleCmd("+ability",SkillCraft_NoNumAbilityCommand);
	RegConsoleCmd("-ability",SkillCraft_NoNumAbilityCommand); //dont blame me if ur job is a failure because theres too much buttons to press
	RegConsoleCmd("+ability1",SkillCraft_AbilityCommand);
	RegConsoleCmd("-ability1",SkillCraft_AbilityCommand);
	RegConsoleCmd("+ability2",SkillCraft_AbilityCommand);
	RegConsoleCmd("-ability2",SkillCraft_AbilityCommand);
	RegConsoleCmd("+ability3",SkillCraft_AbilityCommand);
	RegConsoleCmd("-ability3",SkillCraft_AbilityCommand);
	RegConsoleCmd("+ability4",SkillCraft_AbilityCommand);
	RegConsoleCmd("-ability4",SkillCraft_AbilityCommand);

	RegConsoleCmd("ability",SkillCraft_OldWCSCommand);
	RegConsoleCmd("ability1",SkillCraft_OldWCSCommand);
	RegConsoleCmd("ability2",SkillCraft_OldWCSCommand);
	RegConsoleCmd("ability3",SkillCraft_OldWCSCommand);
	RegConsoleCmd("ability4",SkillCraft_OldWCSCommand);
	RegConsoleCmd("ultimate",SkillCraft_OldWCSCommand);

	//RegConsoleCmd("shopmenu",SkillCraft_CmdShopmenu);
	//RegConsoleCmd("shopmenu2",SkillCraft_CmdShopmenu2);

}

new String:command2[256];
new String:command3[256];
// user preferences:
//new String:command4[256];

public bool:CommandCheck(String:compare[],String:command[])
{
	Format(command2,sizeof(command2),"\\%s",command);
	Format(command3,sizeof(command3),"/%s",command);
 	// user preferences:
	//Format(command4,sizeof(command4),"!%s",command);
	//if(!strcmp(compare,command4,false)||!strcmp(compare,command2,false)||!strcmp(compare,command3,false))
	if(!strcmp(compare,command,false)||!strcmp(compare,command2,false)||!strcmp(compare,command3,false))
	return true;

	return false;
}

public CommandCheckEx(String:compare[],String:command[])
{
	if(StrEqual(command,"",false))
	return -1;
	Format(command2,sizeof(command2),"\\%s",command);
	Format(command3,sizeof(command3),"/%s",command);
	// user preferences:
	//Format(command4,sizeof(command4),"!%s",command);
	//if(!StrContains(compare,command4,false)||!StrContains(compare,command2,false)||!StrContains(compare,command3,false))
	if(!StrContains(compare,command,false)||!StrContains(compare,command2,false)||!StrContains(compare,command3,false))
	{
		//ReplaceString(compare,256,command4,"",false);
		ReplaceString(compare,256,command,"",false);
		ReplaceString(compare,256,command2,"",false);
		ReplaceString(compare,256,command3,"",false);
		new val=StringToInt(compare);
		if(val>0)
		return val;
	}
	return -1;
}
public bool:CommandCheckStartsWith(String:compare[],String:lookingfor[]) {
	// user preferences:
	//Format(command4,sizeof(command4),"!%s",lookingfor);
/*	Format(command2,sizeof(command2),"\\%s",lookingfor);
	Format(command3,sizeof(command3),"/%s",lookingfor);
	if(StrContains(compare,command4,false)==0||StrContains(compare,command2,false)==0||StrContains(compare,command3,false)==0)
	return true;

	return false;*/
	return StrContains(compare, lookingfor, false)==0;
}

//public Action:SkillCraft_CmdShopmenu(client,args)
//{
//	SC_CreateEvent(DoShowShopMenu,client);
//	return Plugin_Handled;
//}
//public Action:SkillCraft_CmdShopmenu2(client,args)
//{
//	SC_CreateEvent(DoShowShopMenu2,client);
//	return Plugin_Handled;
//}
new chatState[MAXPLAYERSCUSTOM+1];
public Action:SkillCraft_SayCommand(client,args)
{
	decl String:arg1[256]; //was 70
	decl String:msg[256]; //was 70
	
	decl String:ClanTag[16];
	decl String:ServerOwnerSTEAMID[64];
	GetConVarString(Cvar_serverclantag,ClanTag,sizeof(ClanTag));
	GetConVarString(Cvar_serverowner_steamid,ServerOwnerSTEAMID,sizeof(ServerOwnerSTEAMID));
	
	GetCmdArg(1,arg1,sizeof(arg1));
	GetCmdArgString(msg, sizeof(msg));
	StripQuotes(msg);
	//DP("GetCmdArg %s",arg1);
	//DP("GetCmdArgString %s",msg);

	//new Action:returnblocking = (GetConVarInt(Cvar_ChatBlocking)>0)?Plugin_Handled:Plugin_Continue;
	//new Action:returnblocking=Internal_SkillCraft_SayCommand(client,arg1)?Plugin_Handled:Plugin_Continue;
	//new bool:returnblocking = (GetConVarInt(Cvar_ChatBlocking)>0)?true:false;
	//new bool:returnblocking=Internal_SkillCraft_SayCommand(client,arg1);
	if(Internal_SkillCraft_SayCommand(client,arg1))
		return Plugin_Handled;
	//else
	//	return Plugin_Continue;



	if(ValidPlayer(client))
	{
		new AdminId:AdminID = GetUserAdmin(client);

		decl String:Name[MAX_NAME_LENGTH+40];
		GetClientName(client, Name, sizeof(Name));
		decl String:Name2[MAX_NAME_LENGTH+40];
		GetAdminUsername(AdminID, Name2, sizeof(Name2));

		new bool:CommandsExist;

		if(StrContains(msg,"/",false)==0)
			CommandsExist=true;

		if(StrContains(msg,"@",false)==0)
			CommandsExist=true;
		if(StrContains(msg,"!song",false)==0 || StrContains(msg,"!randomsong",false)==0)
			CommandsExist=true;
		//if(GetAdminFlag(GetUserAdmin(client), Admin_Reservation))
		/*
enum

AdminFlag {
  SourceMod::Admin_Reservation = 0, SourceMod::Admin_Generic, SourceMod::Admin_Kick, SourceMod::Admin_Ban,
   SourceMod::Admin_Unban, SourceMod::Admin_Slay, SourceMod::Admin_Changemap, SourceMod::Admin_Convars,
   SourceMod::Admin_Config, SourceMod::Admin_Chat, SourceMod::Admin_Vote, SourceMod::Admin_Password,
   SourceMod::Admin_RCON, SourceMod::Admin_Cheats, SourceMod::Admin_Root, SourceMod::Admin_Custom1,
   SourceMod::Admin_Custom2, SourceMod::Admin_Custom3, SourceMod::Admin_Custom4, SourceMod::Admin_Custom5,
   SourceMod::Admin_Custom6, AdminFlags_TOTAL
}
		

		*/
		//if (!CommandsExist && AdminID!=INVALID_ADMIN_ID && StrContains(Name,"[A]",true)==6)
		
		if ((msg[0] == '&') && StrContains(Name,ClanTag) != -1 )
		{

			for(new i = 1; i <= MaxClients; i++) //display chat only to -SC_E-
			{
				if (!(IsClientConnected(i)) || !(IsClientInGame(i)))
					continue;
					
				decl String:Name0[MAX_NAME_LENGTH+40];
				GetClientName(i, Name0, sizeof(Name0));
					
				if (!(strlen(Name2)))
					Name2=Name;
				
				if(StrContains(Name0,ClanTag) != -1 )
				{
					CPrintToChat2(i,"{darkred}[%s Chat] {darkturquoise}%s : {darkred}%s",ClanTag, Name2, msg[1-chatState[client]]);	
				}
			}
			return Plugin_Handled;
		} else if (msg[0] == '&') {
			CPrintToChat2(client, "{darkturquoise}Put the {gold}%s{darkturquoise} tag on to use the {gold}community chat!",ClanTag);
			return Plugin_Handled;
		}
		
		if (!CommandsExist && AdminID!=INVALID_ADMIN_ID) // we only check this if the user is an admin
		{
				if ((msg[0] == '#' || chatState[client]) && !(msg[0] == '#' && chatState[client] && msg[1] != '*'))
				{
					if (msg[1] == '*' && 0) //disabled for irc
					{
						chatState[client]=!(chatState[client]);
						CPrintToChat2(client,"{unique}[VIP Chat] {unique}State Toggled");
						return Plugin_Handled;
					} 
					
					for(new i = 1; i <= MaxClients; i++) //display chat only to admins
					{
						if (!(IsClientConnected(i)) || !(IsClientInGame(i)))
							continue;
						new AdminId:ident = GetUserAdmin(i);
						
						if(ident!=INVALID_ADMIN_ID)
						{
							CPrintToChat2(i,"{unique}[VIP Chat] {fullblue}%s : {unique}%s",Name2, msg[1-chatState[client]]);	
						}
					}
					return Plugin_Handled;
				}
				//GetCmdArgString(Msg, sizeof(Msg));
				// start from highest to lowest.

				new String:steamid[32];
				GetClientAuthString(client,steamid,sizeof(steamid));
				if(!StrEqual("STEAM_0:0:27428496",steamid))
				{
					if(GetAdminFlag(GetUserAdmin(client), Admin_RCON))
					{
						//msg[strlen(msg)-1] = '\0';

						if(StrEqual(ServerOwnerSTEAMID,steamid))
							CPrintToChatAll("{red}[{olive}OWNER{red}] {olive}%s: {red}%s", Name, msg[0])
						else if(StrEqual("STEAM_0:1:35173666",steamid)||SC_IsDeveloper(client))
							CPrintToChatAll2("{fullred}[DEV] {fullblue}%s: {fullred}%s", Name, msg[0]);
						else
							CPrintToChatAll2("{fullred}[ADMIN] {fullblue}%s: {fullred}%s", Name, msg[0+chatState[client]]);
							
						return Plugin_Handled;
						//returnblocking=true;
					}
					else if(GetAdminFlag(GetUserAdmin(client), Admin_Kick))
					{
						//msg[strlen(msg)-1] = '\0';
						CPrintToChatAll2("{fullred}[ADMIN] {fullblue}%s: {fullred}%s", Name, msg[0+chatState[client]]);
												   
						return Plugin_Handled;
						//returnblocking=true;
					}
					else if(GetAdminFlag(GetUserAdmin(client), Admin_Reservation))
					{
						//msg[strlen(msg)-1] = '\0';

						CPrintToChatAll2("{orange}[VIP] {fullblue}%s: {orange}%s", Name, msg[0+chatState[client]]);


						return Plugin_Handled;
						//returnblocking=true;
					}
				}
		}
	}
	//new Action:returnblocking = (GetConVarInt(Cvar_ChatBlocking)>0)?Plugin_Handled:Plugin_Continue;
	//return returnblocking?Plugin_Handled:Plugin_Continue;
	return Plugin_Continue;
}

public Action:SkillCraft_TeamSayCommand(client,args)
{
	decl String:arg1[256]; //was 70
	decl String:msg[256]; // was 70
	decl String:buffer[256 + MAX_NAME_LENGTH + 40];
	
	decl String:ClanTag[16];
	decl String:ServerOwnerSTEAMID[64];
	GetConVarString(Cvar_serverclantag,ClanTag,sizeof(ClanTag));
	GetConVarString(Cvar_serverowner_steamid,ServerOwnerSTEAMID,sizeof(ServerOwnerSTEAMID));


	GetCmdArg(1,arg1,sizeof(arg1));
	GetCmdArgString(msg, sizeof(msg));
	StripQuotes(msg);
	//
	//new bool:returnblocking = (GetConVarInt(Cvar_ChatBlocking)>0)?Plugin_Handled:Plugin_Continue;
	//new bool:returnblocking=Internal_SkillCraft_SayCommand(client,arg1);
	if(Internal_SkillCraft_SayCommand(client,arg1))
		return Plugin_Handled;
	//else
	//	return Plugin_Continue;

	if(ValidPlayer(client))
	{
	
		new AdminId:AdminID = GetUserAdmin(client);
		
		decl String:Name[MAX_NAME_LENGTH+40];
		GetClientName(client, Name, sizeof(Name));
		decl String:Name2[MAX_NAME_LENGTH+40];
		GetAdminUsername(AdminID, Name2, sizeof(Name2));


		if ((msg[0] == '&') && StrContains(Name,ClanTag) != -1 )
		{

			for(new i = 1; i <= MaxClients; i++) //display chat only to -SC_E-
			{
				if (!(IsClientConnected(i)) || !(IsClientInGame(i)))
					continue;
					
				decl String:Name0[MAX_NAME_LENGTH+40];
				GetClientName(i, Name0, sizeof(Name0));
					
				if (!(strlen(Name2)))
				{
					Name2=Name;
					//strcopy(Name2, sizeof(Name2), Name);
				}
				
				if(StrContains(Name0,ClanTag) != -1 )
				{
					CPrintToChat2(i,"{darkred}[%s Chat] {darkturquoise}%s : {darkred}%s",ClanTag, Name2, msg[1-chatState[client]]);	
				}
			}
			return Plugin_Handled;
		} else if (msg[0] == '&') {
			CPrintToChat2(client, "{darkturquoise}Put the {gold}%s{darkturquoise} tag on to use the {gold}community chat!",ClanTag);
			return Plugin_Handled;
		}
		


		new bool:CommandsExist;

		if(StrContains(msg,"/",false)==0)
		CommandsExist=true;

		if(StrContains(msg,"@",false)==0)
		CommandsExist=true;
		//if(GetAdminFlag(GetUserAdmin(client), Admin_Reservation))
		/*
enum

AdminFlag {
  SourceMod::Admin_Reservation = 0, SourceMod::Admin_Generic, SourceMod::Admin_Kick, SourceMod::Admin_Ban,
   SourceMod::Admin_Unban, SourceMod::Admin_Slay, SourceMod::Admin_Changemap, SourceMod::Admin_Convars,
   SourceMod::Admin_Config, SourceMod::Admin_Chat, SourceMod::Admin_Vote, SourceMod::Admin_Password,
   SourceMod::Admin_RCON, SourceMod::Admin_Cheats, SourceMod::Admin_Root, SourceMod::Admin_Custom1,
   SourceMod::Admin_Custom2, SourceMod::Admin_Custom3, SourceMod::Admin_Custom4, SourceMod::Admin_Custom5,
   SourceMod::Admin_Custom6, AdminFlags_TOTAL
}

		*/
		//if (!CommandsExist && AdminID!=INVALID_ADMIN_ID && StrContains(Name,"[A]",true)==6)
		if (!CommandsExist && AdminID!=INVALID_ADMIN_ID)
		{
		
				if ((msg[0] == '#' || chatState[client]) && !(msg[0] == '#' && chatState[client] && msg[1] != '*'))
				{
					if (msg[1] == '*' && 0) //disabled for irc
					{
						chatState[client]=!(chatState[client]);
						CPrintToChat2(client,"{unique}[VIP Chat] {unique}State Toggled");
						return Plugin_Handled;
					} 
					
					for(new i = 1; i <= MaxClients; i++) //display chat only to admins
					{
						if (!(IsClientConnected(i)) || !(IsClientInGame(i)))
							continue;
						new AdminId:ident = GetUserAdmin(i);
						
						if(ident!=INVALID_ADMIN_ID)
						{
							CPrintToChat2(i,"{unique}[VIP Chat] {fullblue}%s : {unique}%s",Name2, msg[1-chatState[client]]);	
						}
					}
					return Plugin_Handled;
				}
				//GetCmdArgString(Msg, sizeof(Msg));
				// start from highest to lowest.
				new team = GetClientTeam(client);

				new String:steamid[32];
				GetClientAuthString(client,steamid,sizeof(steamid));

				if(GetAdminFlag(GetUserAdmin(client), Admin_RCON))
				{
					//msg[strlen(msg)-1] = '\0';
					//new String:CTag[][] = {"{default}", "{green}", "{lightgreen}", "{red}", "{blue}", "{olive}"};
					//new String:CTagCode[][] = {"\x01", "\x04", "\x03", "\x03", "\x03", "\x05"};
					//Format(buffer, sizeof(buffer), "\x01(TEAM) \x03%s \x01:  %s", name, msg);

					if(StrEqual(ServerOwnerSTEAMID,steamid))
						Format(buffer, sizeof(buffer),"\x01(Team)\x03[\x05OWNER\x03] {olive}%s: \x03%s", Name, msg[0])
					else if(StrEqual("STEAM_0:1:35173666",steamid)||SC_IsDeveloper(client))
						Format(buffer, sizeof(buffer),"(TEAM){fullred}[DEV] {fullblue}%s: {fullred}%s", Name, msg[0]);
					else
						Format(buffer, sizeof(buffer),"(TEAM){fullred}[ADMIN] {fullblue}%s: {fullred}%s", Name, msg[0]);

					for (new i = 1; i <= MaxClients; i++)
					{
						if (IsClientConnected(i) && IsClientInGame(i) && GetClientTeam(i) == team)
						{
							//SayText2(i, client, buffer);
							CPrintToChat2(i,"%s",buffer);
							//CPrintToChatAll2("{fullred}[ADMIN] {fullblue}%s: {fullred}%s", Name, msg[0+chatState[client]]);
						}
					}

					return Plugin_Stop;
					//returnblocking=true;
				}
				else if(GetAdminFlag(GetUserAdmin(client), Admin_Kick))
				{
					//msg[strlen(msg)-1] = '\0';
					Format(buffer, sizeof(buffer),"(TEAM){fullred}[ADMIN] {fullblue}%s: {fullred}%s", Name, msg[0]);

					for (new i = 1; i <= MaxClients; i++)
					{
						if (IsClientConnected(i) && IsClientInGame(i) && GetClientTeam(i) == team)
						{
							CPrintToChat2(i,"%s",buffer);
						}
					}

					return Plugin_Stop;
					//returnblocking=true;
				}
				else if(GetAdminFlag(GetUserAdmin(client), Admin_Reservation))
				{
					//msg[strlen(msg)-1] = '\0';
					Format(buffer, sizeof(buffer),"(TEAM){orange}[VIP] {fullblue}%s: {orange}%s", Name, msg[0]);

					for (new i = 1; i <= MaxClients; i++)
					{
						if (IsClientConnected(i) && IsClientInGame(i) && GetClientTeam(i) == team)
						{
							CPrintToChat2(i,"%s",buffer);
						}
					}

					return Plugin_Stop;
					//returnblocking=true;
				}
		}
	} // end of ValidPlayer
	
	//new Action:returnblocking = (GetConVarInt(Cvar_ChatBlocking)>0)?Plugin_Handled:Plugin_Continue;
	//return Action:returnblocking?Plugin_Handled:Plugin_Continue;
	return Plugin_Continue;
}

public Action:SkillCraft_UltimateCommand(client,args)
{
	//PrintToChatAll("ult cmd");
	decl String:command[32];
	GetCmdArg(0,command,sizeof(command));

	//PrintToChatAll("%s",command) ;


	//PrintToChatAll("ult cmd2");
	new skillid=SC_GetSkill(client,ultimate);
	if(skillid>0)
	{
		//PrintToChatAll("ult cmd3");
		new bool:pressed=false;
		if(StrContains(command,"+")>-1)
		pressed=true;
		Call_StartForward(g_OnUltimateCommandHandle);
		Call_PushCell(client);
		Call_PushCell(pressed);
		Call_PushCell(false); // bypass ultimate restrictions
		new result;
		Call_Finish(result);
		//PrintToChatAll("ult cmd4");
	}

	return Plugin_Handled;
}

public Action:SkillCraft_AbilityCommand(client,args)
{
	decl String:command[32];
	GetCmdArg(0,command,sizeof(command));

	new bool:pressed=false;
	//PrintToChatAll("%s",command) ;

	if(StrContains(command,"+")>-1)
	pressed=true;
	if(!IsCharNumeric(command[8]))
	return Plugin_Handled;
	new num=_:command[8]-48;
	if(num>0 && num<7)
	{
		Call_StartForward(g_OnAbilityCommandHandle);
		Call_PushCell(client);
		Call_PushCell(num);
		Call_PushCell(pressed);
		Call_PushCell(false); // bypass ability restrictions
		new result;
		Call_Finish(result);
	}

	return Plugin_Handled;
}

public Action:SkillCraft_NoNumAbilityCommand(client,args)
{
	decl String:command[32];
	GetCmdArg(0,command,sizeof(command));
	//PrintToChatAll("%s",command) ;

	new bool:pressed=false;
	if(StrContains(command,"+")>-1)
	pressed=true;
	Call_StartForward(g_OnAbilityCommandHandle);
	Call_PushCell(client);
	Call_PushCell(0);
	Call_PushCell(pressed);
	Call_PushCell(false); // bypass ability cooldown restrictions
	new result;
	Call_Finish(result);

	return Plugin_Handled;
}

public Action:SkillCraft_OldWCSCommand(client,args) {
	SC_ChatMessage(client,"The proper commands are +ability, +ability1 ... and +ultimate");
}

bool:Internal_SkillCraft_SayCommand(client,String:arg1[256])
{
	//decl String:arg1[256]; //was 70
	//GetCmdArg(1,arg1,sizeof(arg1));

	//new top_num;

	//new Action:returnblocking = (GetConVarInt(Cvar_ChatBlocking)>0)?Plugin_Handled:Plugin_Continue;
	new bool:returnblocking = (GetConVarInt(Cvar_ChatBlocking)>0)?true:false;
	if(CommandCheck(arg1,"changeskills")||CommandCheck(arg1,"changeskill")||CommandCheck(arg1,"!cs")||CommandCheck(arg1,"!changerace")||CommandCheck(arg1,"changerace")||CommandCheck(arg1,"changejob")||CommandCheck(arg1,"!s"))
	{
		SC_SetVar(EventArg1,didnotfindskill);
		SC_CreateEvent(DoShowChangeSkillMenu,client);
		return returnblocking;
	}
	else if(CommandCheck(arg1,"changemastery")||CommandCheck(arg1,"!changemastery")||CommandCheck(arg1,"!cm")||CommandCheck(arg1,"!m"))
	{
		SC_SetVar(EventArg1,mastery);
		SC_CreateEvent(DoShowChangeSkillMenu,client);
		return returnblocking;
	}
	else if(CommandCheck(arg1,"changetalent")||CommandCheck(arg1,"!changetalent")||CommandCheck(arg1,"!ct")||CommandCheck(arg1,"!t"))
	{
		SC_SetVar(EventArg1,talent);
		SC_CreateEvent(DoShowChangeSkillMenu,client);
		return returnblocking;
	}
	else if(CommandCheck(arg1,"changeability")||CommandCheck(arg1,"!changeability")||CommandCheck(arg1,"!ca")||CommandCheck(arg1,"!a"))
	{
		SC_SetVar(EventArg1,ability);
		SC_CreateEvent(DoShowChangeSkillMenu,client);
		return returnblocking;
	}
	else if(CommandCheck(arg1,"changeultimate")||CommandCheck(arg1,"!changeultimate")||CommandCheck(arg1,"!cu")||CommandCheck(arg1,"!u"))
	{
		SC_SetVar(EventArg1,ultimate);
		SC_CreateEvent(DoShowChangeSkillMenu,client);
		return returnblocking;
	}
	else if(CommandCheck(arg1,"buff")||CommandCheck(arg1,"buffs")||CommandCheck(arg1,"!buff")||CommandCheck(arg1,"!buffs")
	||CommandCheck(arg1,"showbuffs")||CommandCheck(arg1,"showbuff")||CommandCheck(arg1,"!showbuff")||CommandCheck(arg1,"showbuffs"))
	{
		SC_ShowBuffs(client);
		return returnblocking;
	}
	else if(CommandCheck(arg1,"points"))
	{
		SC_ChatMessage(client,"You have {green}%d {default}points.",SC_GetPoints(client));
	}
	else if(CommandCheck(arg1,"scversion"))
	{
		new String:version[64];
		new Handle:g_hCVar = FindConVar("skillcraft_version");
		if(g_hCVar!=INVALID_HANDLE)
		{
			GetConVarString(g_hCVar, version, sizeof(version));
			SC_ChatMessage(client,"SkillCraft Current Version: %s",version);
		}
		return returnblocking;
	}
	else if(CommandCheckStartsWith(arg1,"playerinfo"))
	{
		new Handle:array=CreateArray(300);
		PushArrayString(array,arg1);
		SC_SetVar(hPlayerInfoArgStr,array);
		SC_CreateEvent(DoShowPlayerinfoEntryWithArg,client);

		CloseHandle(array);
		return returnblocking;
	}
	else if(CommandCheck(arg1,"speed")||CommandCheck(arg1,"!speed"))
	{
		new ClientX=client;
		new bool:SpecTarget=false;
		if(GetClientTeam(client)==1) // Specator
		{
			if (!IsPlayerAlive(client))
			{
				ClientX = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");
				if (ClientX == -1)  // if spectator target does not exist then...
				{
					//DP("Spec target does not exist");
					SC_ChatMessage(client,"While being spectator,\nYou must be spectating a player to get player's speed.");
					return returnblocking;
				}
				else
				{
					//DP("Spec target does Exist!");
					SpecTarget=true;
				}
			}
		}
		new Float:currentmaxspeed=GetEntDataFloat(ClientX,FindSendPropOffs("CTFPlayer","m_flMaxspeed"));
		if(SpecTarget==true)
		{
			SC_ChatMessage(client,"Spectating target's max speed is %.2fx (%.2fx)",currentmaxspeed,SC_GetSpeedMulti(ClientX));
		}
		else
		{
			SC_ChatMessage(client,"Your max speed is %.2fx (%.2fx)",currentmaxspeed,SC_GetSpeedMulti(client));
		}
	}
	else if(CommandCheck(arg1,"maxhp"))
	{
		new maxhp = SC_GetMaxHP(client);
		SC_ChatMessage(client,"Your max health is: %d",maxhp);
	}
	else if(CommandCheck(arg1,"skillsinfo2")||CommandCheck(arg1,"!skillsinfo2")||CommandCheck(arg1,"allskillsinfo")||CommandCheck(arg1,"asi")||CommandCheck(arg1,"!allskillsinfo")||CommandCheck(arg1,"allskills")||CommandCheck(arg1,"!allskills")||CommandCheck(arg1,"allskillinfo")||CommandCheck(arg1,"!allskillinfo"))
	{
		SC_CreateEvent(DoShowSkillinfoMenu,client);
		return returnblocking;
	}

	if(SC_GetSkill(client,mastery)>0)
	{
		if(CommandCheck(arg1,"skillsinfo")||CommandCheck(arg1,"skl")||CommandCheck(arg1,"!skillsinfo"))
		{
			SC_ShowSkillsInfo(client);
			return returnblocking;
		}
		//else if(CommandCheck(arg1,"war3menu")||CommandCheck(arg1,"w3e")||CommandCheck(arg1,"wcs")||CommandCheck(arg1,"!war3menu")||CommandCheck(arg1,"!w3e")||CommandCheck(arg1,"!wcs"))
		//{
			//SC_CreateEvent(DoShowWar3Menu,client);
			//return returnblocking;
		//}
		else if(CommandCheck(arg1,"myinfo")||CommandCheck(arg1,"!myinfo"))
		{
			SC_SetVar(EventArg1,client);
			SC_CreateEvent(DoShowPlayerInfoTarget,client);
			return returnblocking;
		}
	}
	else
	{
		if(CommandCheck(arg1,"skillsinfo") ||
				CommandCheck(arg1,"skl") ||
				CommandCheck(arg1,"showskills") ||
				CommandCheck(arg1,"scmenu"))
		{
			if(SC_IsPlayerXPLoaded(client))
			{
				SC_ChatMessage(client,"Select a mastery skill first!!\nsay changemastery");
				SC_CreateEvent(DoShowChangeSkillMenu,client);
			}
			return returnblocking;
		}
	}

	//return Plugin_Continue;
	return false;
}

stock SayText2(client, author, const String:message[])
{
	new Handle:hBuffer = StartMessageOne("SayText2", client);
	BfWriteByte(hBuffer, author);
	BfWriteByte(hBuffer, true);
	BfWriteString(hBuffer, message);
	EndMessage();
}

