
#include <sourcemod>


#include "SkillCraft_Includes/SkillCraft_Interface"


public Plugin:myinfo= 
{
	name="SkillCraft - Skill Restrictions",
	author="SkillCraft Team",
	description="SkillCraft Core Plugins",
	version="1.0",
};

public OnPluginStart()
{
}
public On_SC_Denyable(SC_DENY:event,client){
	if(event==DN_CanSelectSkill)
	{
		new skill_selected=SC_GetVar(EventArg1);
		new bool:No_Message=SC_GetVar(EventArg2);
		if(skill_selected<=0)
		{
			ThrowError(" DN_CanSelectSkill CALLED WITH INVALID SKILL [%d]",skill_selected);
			return SC_Deny();
		}
		
		//Check for Skills Developer:
		//El Diablo: Adding myself as a races developer so that I can double check for any errors
		//in the races content of any server.  This allows me to have all races enabled.
		//I do not have any other access other than all races to make sure that
		//all races work correctly with war3source.
		new String:steamid[32];
		GetClientAuthString(client,steamid,sizeof(steamid));
		//if(!StrEqual(steamid,"STEAM_0:1:35173666",false))
		
		new AdminId:admin = GetUserAdmin(client);
		if(!SC_IsDeveloper(client))
		{
			new bool:PassFlagCheck=false;
			//FLAG CHECK
			new String:requiredflagstr[32];
			SC_GetSkillAccessFlagStr(skill_selected,requiredflagstr,sizeof(requiredflagstr));  ///14 = index, see races.inc
			//DP("Skill Access Flag of Selected: %s",requiredflagstr);
			if(!StrEqual(requiredflagstr, "0", false)&&!StrEqual(requiredflagstr, "", false))
			{
			
				//new AdminId:admin = GetUserAdmin(client);
				if(admin == INVALID_ADMIN_ID) //flag is required and this client is not admin
				{
					if(No_Message==false)
					{
						SC_ChatMessage(client,"Restricted Skill. Ask an admin on how to unlock");
						PrintToConsole(client,"No Admin ID found");
					}
					return SC_Deny();
				}
				else
				{
					new AdminFlag:flag;
					if (!FindFlagByChar(requiredflagstr[0], flag)) //this gets the flag class from the string
					{
						if(No_Message==false)
						{
							SC_ChatMessage(client,"ERROR on admin flag check %s",requiredflagstr);
						}
						return SC_Deny();
					}
					else
					{
						if (!GetAdminFlag(admin, flag))
						{
							if(No_Message==false)
							{
								SC_ChatMessage(client,"Restricted job, ask an admin on how to unlock");
								PrintToConsole(client,"Admin ID found, but no required flag");
							}
							return SC_Deny();
						}
					}
				}
				PassFlagCheck=true;
			}
			
			if(admin != INVALID_ADMIN_ID&&!PassFlagCheck)
			{
				PassFlagCheck=true;
			}

			///MAX PER TEAM CHECK
			/*
			if(GetConVarInt(SC_GetVar(hSkillLimitEnabledCvar))>0)
			{
				//if player is already this race, this is not what it does and its up to gameevents to kick the player
				if(SC_GetSkill(client,mastery)!=skill_selected&&GetSkillsOnTeam(skill_selected,GetClientTeam(client))>=SC_GetSkillMaxLimitTeam(skill_selected,GetClientTeam(client))) //already at limit
				{
					//if(!SC_IsDeveloper(client)){
					//	DP("racerestricitons.sp");
					if(No_Message==false)
					{
						SC_ChatMessage(client,"Skill limit for your team has been reached, please select a different race. (MAX %d)",SC_GetSkillMaxLimitTeam(skill_selected,GetClientTeam(client)));
					}
				
					new cvar=SC_GetSkillMaxLimitTeamCvar(skill_selected,GetClientTeam(client));
					new String:cvarstr[64];
					if(cvar>-1)
					{
						SC_GetCvarActualString(cvar,cvarstr,sizeof(cvarstr));
					}
					cvar=SC_FindCvar(cvarstr);
					new String:cvarvalue[64];
					if(cvar>-1)
					{
						SC_GetCvar(cvar,cvarvalue,sizeof(cvarvalue));
					}
				
					//SC_Log("race %d blocked on client %d due to restrictions limit %d  %s %s",skill_selected,client,SC_GetSkillMaxLimitTeam(skill_selected,GetClientTeam(client)),cvarstr,cvarvalue);
					return SC_Deny();
				//}
				
				}
			}*/
		
/*
enum TFClassType
{
	TFClass_Unknown = 0,
	TFClass_Scout,
	TFClass_Sniper,
	TFClass_Soldier,
	TFClass_DemoMan,
	TFClass_Medic,
	TFClass_Heavy,
	TFClass_Pyro,
	TFClass_Spy,
	TFClass_Engineer
};*/
		
			new String:classlist[][32]={"unknown","scout","sniper","soldier","demoman","medic","heavy","pyro","spy","engineer"};
			new class=_:TF2_GetPlayerClass(client);
			new String:classstring[32];
			strcopy(classstring,sizeof(classstring),classlist[class]);

			new cvarid=SC_GetSkillCell(skill_selected,ClassRestrictionCvar);
			//DP("cvar %d %s",cvarid,cvarstring);
			if(SC_FindStringInCvar(cvarid,classstring,2))
			{
				//DP("deny");
				if(No_Message==false)
				{
					SC_ChatMessage(client,"Skill restricted due to class restriction: %s",classstring);
				}
				return SC_Deny();
			}

		//DP("passed");
	
		}
	}
	return false;
}
