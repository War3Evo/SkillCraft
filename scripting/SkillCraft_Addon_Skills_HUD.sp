
#pragma semicolon 1

#include <sourcemod>
#include "SkillCraft_Includes/SkillCraft_Interface"

new Handle:HudGoldDiamondMessage1;
new Handle:HudGoldDiamondMessage2;
new Handle:HudGoldDiamondMessage3;
new Handle:HudGoldDiamondMessage4;

///////////////////////////////////////////////////////////////////
// Plugin Info
//////////////////////////////////////////////////////////////////

public Plugin:myinfo =
{
	name = "SkillCraft Skills HUD",
	author = "SkillCraft Team",
	description = "SkillCraft Addons",
	version = "1.0",
};

public OnPluginStart()
{
	HudGoldDiamondMessage1 = CreateHudSynchronizer();
	HudGoldDiamondMessage2 = CreateHudSynchronizer();
	HudGoldDiamondMessage3 = CreateHudSynchronizer();
	HudGoldDiamondMessage4 = CreateHudSynchronizer();
	
	RegConsoleCmd("+myinfo",SkillCraft_MyinfoCommand);
	RegConsoleCmd("-myinfo",SkillCraft_MyinfoCommand);
	
	CreateTimer(2.0,Timer_UpdateInfo);
}

new bool:ShowMyInfo[MAXPLAYERSCUSTOM];

public Action:SkillCraft_MyinfoCommand(client,args)
{
	decl String:command[32];
	GetCmdArg(0,command,sizeof(command));

	if(ValidPlayer(client))
	{
		if(StrContains(command,"+")>-1)
		{
			new String:buffer[32];

			ShowMyInfo[client]=true;
			new i=client;


			new mastery_cooldown=SC_CooldownRemaining(i,SC_GetSkill(i,mastery));
			new talent_cooldown=SC_CooldownRemaining(i,SC_GetSkill(i,talent)); 
			new ability_cooldown=SC_CooldownRemaining(i,SC_GetSkill(i,ability)); 
			new ultimate_cooldown=SC_CooldownRemaining(i,SC_GetSkill(i,ultimate)); 

			if(TF2_GetPlayerClass(i)!=TFClass_Engineer)
			{
				SC_GetSkillShortname(SC_GetSkill(i,mastery),buffer,sizeof(buffer));
				SetHudTextParams(0.02, 0.08, 0.50, 255, 255, 0, 255);
				if(mastery_cooldown>0)
				{
					ShowSyncHudText(i, HudGoldDiamondMessage1, "M: %s Cooldown: %d",buffer,mastery_cooldown);
				}
				else
				{
					ShowSyncHudText(i, HudGoldDiamondMessage1, "M: %s    ",buffer);
				}

				SC_GetSkillShortname(SC_GetSkill(i,talent),buffer,sizeof(buffer));
				SetHudTextParams(0.02, 0.12, 0.50, 255, 255, 0, 255);
				if(talent_cooldown>0)
				{
					ShowSyncHudText(i, HudGoldDiamondMessage2, "T: %s Cooldown: %d",buffer,talent_cooldown);
				}
				else
				{
					ShowSyncHudText(i, HudGoldDiamondMessage2, "T: %s    ",buffer);
				}

				SC_GetSkillShortname(SC_GetSkill(i,ability),buffer,sizeof(buffer));
				SetHudTextParams(0.02, 0.16, 0.50, 255, 255, 0, 255);
				if(ability_cooldown>0)
				{
					ShowSyncHudText(i, HudGoldDiamondMessage3, "A: %s Cooldown: %d",buffer,ability_cooldown);
				}
				else
				{
					ShowSyncHudText(i, HudGoldDiamondMessage3, "A: %s    ",buffer);
				}

				SC_GetSkillShortname(SC_GetSkill(i,ultimate),buffer,sizeof(buffer));
				SetHudTextParams(0.02, 0.20, 0.50, 255, 255, 0, 255);
				if(ultimate_cooldown>0)
				{
					ShowSyncHudText(i, HudGoldDiamondMessage4, "U: %s Cooldown: %d",buffer,ultimate_cooldown);
				}
				else
				{
					ShowSyncHudText(i, HudGoldDiamondMessage4, "U: %s    ",buffer);
				}
			}
			else
			{
				SC_GetSkillShortname(SC_GetSkill(i,mastery),buffer,sizeof(buffer));
				SetHudTextParams(0.16, 0.08, 0.50, 255, 255, 0, 255);
				if(mastery_cooldown>0)
				{
					ShowSyncHudText(i, HudGoldDiamondMessage1, "M: %s Cooldown: %d",buffer,mastery_cooldown);
				}
				else
				{
					ShowSyncHudText(i, HudGoldDiamondMessage1, "M: %s    ",buffer);
				}

				SC_GetSkillShortname(SC_GetSkill(i,talent),buffer,sizeof(buffer));
				SetHudTextParams(0.16, 0.12, 0.50, 255, 255, 0, 255);
				if(talent_cooldown>0)
				{
					ShowSyncHudText(i, HudGoldDiamondMessage2, "T: %s Cooldown: %d",buffer,talent_cooldown);
				}
				else
				{
					ShowSyncHudText(i, HudGoldDiamondMessage2, "T: %s    ",buffer);
				}

				SC_GetSkillShortname(SC_GetSkill(i,ability),buffer,sizeof(buffer));
				SetHudTextParams(0.16, 0.16, 0.50, 255, 255, 0, 255);
				if(ability_cooldown>0)
				{
					ShowSyncHudText(i, HudGoldDiamondMessage3, "A: %s Cooldown: %d",buffer,ability_cooldown);
				}
				else
				{
					ShowSyncHudText(i, HudGoldDiamondMessage3, "A: %s    ",buffer);
				}

				SC_GetSkillShortname(SC_GetSkill(i,ultimate),buffer,sizeof(buffer));
				SetHudTextParams(0.16, 0.20, 0.50, 255, 255, 0, 255);
				if(ultimate_cooldown>0)
				{
					ShowSyncHudText(i, HudGoldDiamondMessage4, "U: %s Cooldown: %d",buffer,ultimate_cooldown);
				}
				else
				{
					ShowSyncHudText(i, HudGoldDiamondMessage4, "U: %s    ",buffer);
				}
			}
		}
		else
		{
			ShowMyInfo[client]=false;
		}
	}

	return Plugin_Handled;
}



/* ***************************  Timer_UpdateInfo *************************************/
public Action:Timer_UpdateInfo(Handle:timer) 
{
	new String:buffer[32];
	
	for(new i;i<=MaxClients;i++)
	{
		if(ValidPlayer(i) && !IsFakeClient(i) && ( SC_GetPlayerProp(i,iGoldDiamondHud)==1 || ShowMyInfo[i] ))
		{

			new mastery_cooldown=SC_CooldownRemaining(i,SC_GetSkill(i,mastery));
			new talent_cooldown=SC_CooldownRemaining(i,SC_GetSkill(i,talent)); 
			new ability_cooldown=SC_CooldownRemaining(i,SC_GetSkill(i,ability)); 
			new ultimate_cooldown=SC_CooldownRemaining(i,SC_GetSkill(i,ultimate)); 

			if(TF2_GetPlayerClass(i)!=TFClass_Engineer)
			{
				SC_GetSkillShortname(SC_GetSkill(i,mastery),buffer,sizeof(buffer));
				SetHudTextParams(0.02, 0.08, 0.50, 255, 255, 0, 255);
				if(mastery_cooldown>0)
				{
					ShowSyncHudText(i, HudGoldDiamondMessage1, "M: %s Cooldown: %d",buffer,mastery_cooldown);
				}
				else
				{
					ShowSyncHudText(i, HudGoldDiamondMessage1, "M: %s    ",buffer);
				}

				SC_GetSkillShortname(SC_GetSkill(i,talent),buffer,sizeof(buffer));
				SetHudTextParams(0.02, 0.12, 0.50, 255, 255, 0, 255);
				if(talent_cooldown>0)
				{
					ShowSyncHudText(i, HudGoldDiamondMessage2, "T: %s Cooldown: %d",buffer,talent_cooldown);
				}
				else
				{
					ShowSyncHudText(i, HudGoldDiamondMessage2, "T: %s    ",buffer);
				}

				SC_GetSkillShortname(SC_GetSkill(i,ability),buffer,sizeof(buffer));
				SetHudTextParams(0.02, 0.16, 0.50, 255, 255, 0, 255);
				if(ability_cooldown>0)
				{
					ShowSyncHudText(i, HudGoldDiamondMessage3, "A: %s Cooldown: %d",buffer,ability_cooldown);
				}
				else
				{
					ShowSyncHudText(i, HudGoldDiamondMessage3, "A: %s    ",buffer);
				}

				SC_GetSkillShortname(SC_GetSkill(i,ultimate),buffer,sizeof(buffer));
				SetHudTextParams(0.02, 0.20, 0.50, 255, 255, 0, 255);
				if(ultimate_cooldown>0)
				{
					ShowSyncHudText(i, HudGoldDiamondMessage4, "U: %s Cooldown: %d",buffer,ultimate_cooldown);
				}
				else
				{
					ShowSyncHudText(i, HudGoldDiamondMessage4, "U: %s    ",buffer);
				}
			}
			else
			{
				SC_GetSkillShortname(SC_GetSkill(i,mastery),buffer,sizeof(buffer));
				SetHudTextParams(0.16, 0.08, 0.50, 255, 255, 0, 255);
				if(mastery_cooldown>0)
				{
					ShowSyncHudText(i, HudGoldDiamondMessage1, "M: %s Cooldown: %d",buffer,mastery_cooldown);
				}
				else
				{
					ShowSyncHudText(i, HudGoldDiamondMessage1, "M: %s    ",buffer);
				}

				SC_GetSkillShortname(SC_GetSkill(i,talent),buffer,sizeof(buffer));
				SetHudTextParams(0.16, 0.12, 0.50, 255, 255, 0, 255);
				if(talent_cooldown>0)
				{
					ShowSyncHudText(i, HudGoldDiamondMessage2, "T: %s Cooldown: %d",buffer,talent_cooldown);
				}
				else
				{
					ShowSyncHudText(i, HudGoldDiamondMessage2, "T: %s    ",buffer);
				}

				SC_GetSkillShortname(SC_GetSkill(i,ability),buffer,sizeof(buffer));
				SetHudTextParams(0.16, 0.16, 0.50, 255, 255, 0, 255);
				if(ability_cooldown>0)
				{
					ShowSyncHudText(i, HudGoldDiamondMessage3, "A: %s Cooldown: %d",buffer,ability_cooldown);
				}
				else
				{
					ShowSyncHudText(i, HudGoldDiamondMessage3, "A: %s    ",buffer);
				}

				SC_GetSkillShortname(SC_GetSkill(i,ultimate),buffer,sizeof(buffer));
				SetHudTextParams(0.16, 0.20, 0.50, 255, 255, 0, 255);
				if(ultimate_cooldown>0)
				{
					ShowSyncHudText(i, HudGoldDiamondMessage4, "U: %s Cooldown: %d",buffer,ultimate_cooldown);
				}
				else
				{
					ShowSyncHudText(i, HudGoldDiamondMessage4, "U: %s    ",buffer);
				}
			}
		}
	}
	CreateTimer(0.48,Timer_UpdateInfo);
}
