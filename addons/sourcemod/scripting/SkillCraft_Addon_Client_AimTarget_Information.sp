
#include "SkillCraft_Includes/SkillCraft_Interface"
#include "include/smlib"

new bool:AdminHUD[MAXPLAYERSCUSTOM];

new Handle:ClientNameInfoMessage;
new Handle:AdminInfoMessage1;
new Handle:AdminInfoMessage2;

public Plugin:myinfo=
{
	name="SkillCraft Aim Targeting Addon",
	author="SkillCraft Team",
	description="SkillCraft Client Aim Target Information",
	version="1.0.0.1",
};

public OnPluginStart()
{
	RegAdminCmd("sm_adminhud", Command_AdminHud, ADMFLAG_GENERIC, "sm_adminhud");
	
	ClientNameInfoMessage = CreateHudSynchronizer();
	AdminInfoMessage1 = CreateHudSynchronizer();
	AdminInfoMessage2 = CreateHudSynchronizer();
	
	CreateTimer(0.1,ClientAimTarget,_,TIMER_REPEAT);
}

// Admin Spectate Move Command
public Action:Command_AdminHud(client, args)
{
	//new iLevel=-1;
	
	//if(args==1)
	//{
	//	decl String:arg[65];
	//	GetCmdArg(1, arg, sizeof(arg));
	//	iLevel = StringToInt(arg);
	//}
	
	if(ValidPlayer(client))
	{
		AdminHUD[client]=AdminHUD[client]?false:true;
		SC_ChatMessage(client,"War3 Admin Hud is now %s",AdminHUD[client]?"On":"Off");
	}
}

public Action:ClientAimTarget(Handle:timer,any:userid)
{
	for(new client=1;client<=MaxClients;client++)
	{
		if(ValidPlayer(client))
		{
			//new target=GetClientAimTarget(client,true)
			new target=SC_GetTargetInViewCone(client,10000.0,true, 13.0);
			//GetClientTeam(client)!=GetClientTeam(target) ???
			if(ValidPlayer(target))
			{
				if(!Spying(target))
				{
					//native SC_GetRaceName(raceid,String:retstr[],maxlen);
					decl String:mastery_skillname[32];
					decl String:talent_skillname[32];
					decl String:ability_skillname[32];
					decl String:ultimate_skillname[32];
					new skillid=SC_GetSkill(target,mastery);
					new skillid2=SC_GetSkill(target,talent);
					new skillid3=SC_GetSkill(target,ability);
					new skillid4=SC_GetSkill(target,ultimate);
					SC_GetSkillShortname(skillid,mastery_skillname,63);
					SC_GetSkillShortname(skillid2,talent_skillname,63);
					SC_GetSkillShortname(skillid3,ability_skillname,63);
					SC_GetSkillShortname(skillid4,ultimate_skillname,63);
					//SetHudTextParams(-1.0, 0.14, 0.1, 255, 0, 0, 128,1); //no center full
				
					// I think this is perfect, but players want it darker..
					//SetHudTextParams(-1.0, -1.0, 0.15, 65, 0, 0, 5);
					if(GetClientTeam (target)==2) // red team
					{
						SetHudTextParams(-1.0, 0.20, 0.20, 255, 0, 0, 255);
					}
					else if(GetClientTeam (target)==3)  // blue team
					{
						SetHudTextParams(-1.0, 0.20, 0.20, 0, 0, 255, 255);
					}
					ShowSyncHudText(client, ClientNameInfoMessage, "(%s %s %s %s)",mastery_skillname,talent_skillname,ability_skillname,ultimate_skillname);
				}
			}

			// && GetAdminFlag(GetUserAdmin(client), Admin_Kick) || GetAdminFlag(GetUserAdmin(client), Admin_Root)
			if(AdminHUD[client])
			{
				new ClientX;
				
				if(!ValidPlayer(target,true) && GetClientTeam(client)==1)
				{
					ClientX = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");
					if(ValidPlayer(ClientX))
					{
						target=ClientX;
					}
				}
				
				if(ValidPlayer(target) && !IsFakeClient(target))
				{
					new String:sStatus[64],String:sClientName[128];
					GetClientName(target,sClientName,sizeof(sClientName));
					new clienttime=RoundToCeil(FloatDiv(GetClientTime(target),60.0));
					if(clienttime<0)
					{
						clienttime=0;
					}

					//vip trail is res
					//real vip is with res, admin
					//custom1 is arcitect race
					Format(sStatus,sizeof(sStatus),"%s","N/A");
					if(GetAdminFlag(GetUserAdmin(target), Admin_Reservation))
					{
						Format(sStatus,sizeof(sStatus),"%s","Trial");
					}
					if(GetAdminFlag(GetUserAdmin(target), Admin_Generic))
					{
						Format(sStatus,sizeof(sStatus),"%s","Vip");
					}
					if(GetAdminFlag(GetUserAdmin(target), Admin_Kick))
					{
						Format(sStatus,sizeof(sStatus),"%s","Kick");
					}
					if(GetAdminFlag(GetUserAdmin(target), Admin_Ban))
					{
						Format(sStatus,sizeof(sStatus),"%s-%s",sStatus,"Ban");
					}
					if(!IsPlayerAlive(target))
					{
						Format(sStatus,sizeof(sStatus),"%s %s",sStatus,"DEAD");
					}
					//Format(sStatus,sizeof(sStatus),"%s ",GetClientTime(target));
					SetHudTextParams(-1.0, 0.26, 0.20, 255, 255, 0, 255);
					ShowSyncHudText(client, AdminInfoMessage1, "%s (%s) ping %d",sClientName, sStatus,Client_GetFakePing(target, true));
					SetHudTextParams(-1.0, 0.29, 0.20, 255, 255, 0, 255);
					ShowSyncHudText(client, AdminInfoMessage2, " user id %d time %d min.",GetClientUserId(target),clienttime);
				}
			}
		}
	}
}
