
#pragma semicolon 1

#pragma dynamic 10000
#include <sourcemod>
#include "SkillCraft_Includes/SkillCraft_Interface"

//race cat defs
new Handle:hUseCategories,Handle:hCanDrawCat,Handle:hAllowCategoryDefault;
new String:strCategories[MAXCATS][64];
new CatCount;

public Plugin:myinfo= 
{
	name="SkillCraft ChangeSkill Menus",
	author="SkillCraft Team",
	description="SC_Source Core Plugins",
	version="1.0",
};

public OnPluginStart()
{
	hUseCategories = CreateConVar("sc_skillcats","0","If non-zero skill categories will be enabled");
	hAllowCategoryDefault = CreateConVar("sc_allow_default_cats","0","Allow Default categories to show in category menu? (default 0)");
	RegServerCmd("sc_reloadcats", Command_ReloadCats);
}

public bool:Init_SC_NativesForwards()
{
	hCanDrawCat=CreateGlobalForward("On_SC_DrawCategory",ET_Hook,Param_Cell,Param_Cell);
	CreateNative("SC_GetCategoryName",Native_GetCategoryName);
	return true;
}

public Action:Command_ReloadCats(args) {
	PrintToServer("[SkillCraft] forcing skill categories to be refreshed..");
	refreshCategories();
	return Plugin_Handled;
}


public On_SC_Event(SC_EVENT:event,client){
	if(event==DoShowChangeSkillMenu){
		if(ValidPlayer(client) && !SC_Denied(DN_ShowChangeSkill,client)){
			//PrintToServer("Showing the Change Skill Menu!");
			new SKILLTYPE:skilltypechoosen=SC_GetVar(EventArg1);
			SC_ChangeSkillMenu(client,false,skilltypechoosen);
		}
		//else
		//if(ValidPlayer(client))
		//{
			
			//PrintToServer("The client was denied the skill menu!");
		//}
	}
}

public bool:HasCategoryAccess(client,i) {
	/*decl String:buffer[32];
	SC_GetCategoryAccessFlag(i,buffer,sizeof(buffer));
	if(!StrEqual(buffer, "0", false) || StrEqual(buffer, "", false)) {
		return false;
	}
	else {
		new AdminId:admin = GetUserAdmin(client);
		if(admin != INVALID_ADMIN_ID) {
			new AdminFlag:flag;
			if (!FindFlagByChar(buffer[0], flag))
			{
				SC_ChatMessage(client,"%T","ERROR on admin flag check {flag}",client,buffer);
				return false;
			}
			else
			{
				if (!GetAdminFlag(admin, flag)){
					return false;
				}
			}
		}
	}*/
	if(CanDrawCategory(client,i)) {
		return true;
	}
	return false;
}

public OnMapStart(){
	// Delay refresh cats helps prevent stack overflow. - el diablo
	CreateTimer(5.0,refresh_cats,_);
}

/* ****************************** Action:refresh_cats ************************** */

public Action:refresh_cats(Handle:timer)
{
	refreshCategories();
}


new String:dbErrorMsg[100];
public On_SC_GlobalError(String:err[]){
	strcopy(dbErrorMsg,sizeof(dbErrorMsg),err);
}

//This just returns the amount of untouched(=level 0) races in the given category
stock GetNewSkillsInCat(client,String:category[]) {
	new amount=0;
	new skill_list[MAXSKILLS];
	new skilldisplay=SC_GetSkillList(skill_list);
	for(new i=1;i<skilldisplay;i++)
	{
		new String:rcvar[64];
		SC_GetCvar(SC_GetSkillCell(i,SkillCategorieCvar),rcvar,sizeof(rcvar));
		if(strcmp(category, rcvar, false)==0) {
			amount++;
		}
	}
	return amount;
}

SC_ChangeSkillMenu(client,bool:forceUncategorized=false,SKILLTYPE:skilltypechoosen=didnotfindskill)
{
	if(SC_IsPlayerXPLoaded(client))
	{
		//PrintToServer("Player Database is loaded.. ChangeSkillMenu check");
		//Check for Races Developer:
		//El Diablo: Adding myself as a races developer so that I can double check for any errors
		//in the races content of any server.  This allows me to have all races enabled.
		//I do not have any other access other than all races to make sure that
		//all races work correctly with war3source.
		new String:steamid[32];
		GetClientAuthString(client,steamid,sizeof(steamid));

		decl Handle:crMenu;
		if( IsCategorized() && !forceUncategorized )
		{
			//PrintToServer("IsCategorized() && !forceUncategorized");
			//TODO:
			//- translation support
			crMenu=CreateMenu(SC_CRMenu_SelCat);
			SetMenuExitButton(crMenu,true);
			
			new String:title[400];
			if(strlen(dbErrorMsg)){
				Format(title,sizeof(title),"%s\n \n",dbErrorMsg);
			}
			Format(title,sizeof(title),"%s\n \n[SC] Select a category",title) ;
			SetMenuTitle(crMenu,"%s\n \n",title);
			decl String:strCat[64];
			//Prepend 'All Jobs' entry.
			AddMenuItem(crMenu,"-1","All Skills");
			//At first we gonna add the categories
			for(new i=1;i<CatCount;i++) {
				SC_GetCategory(i,strCat,sizeof(strCat));
				if(StrEqual(strCat,"default") && !GetConVarBool(hAllowCategoryDefault))
					continue;
				if(strlen(strCat)>0) {
					if(HasCategoryAccess(client,i)) {
						new amount=GetNewSkillsInCat(client,strCat);
						if(amount>0) {
							decl String:buffer[64];
							Format(buffer,sizeof(buffer),"%s (%i new skills)",strCat,amount);
						}
						AddMenuItem(crMenu,strCat,strCat);
					}
				}
			}
		}
		else 
		{
			//PrintToServer("showing regular menu w/o categories now:");
			crMenu=CreateMenu(SC_Source_CRMenu_Selected);
			//PrintToServer("crMenu=CreateMenu(SC_Source_CRMenu_Selected);");
			SetMenuExitButton(crMenu,true);
			//PrintToServer("SetMenuExitButton(crMenu,true);");
			new String:title[400], String:rbuf[4];
			if(strlen(dbErrorMsg)){
				Format(title,sizeof(title),"%s\n \n",dbErrorMsg);
			}
			//PrintToServer("error title? %s",title);
			
			if(skilltypechoosen==mastery)
			{
							
				Format(title,sizeof(title),"%s\n \n[SC] Select your mastery skill",title);
				//PrintToServer("title: %s",title);
				SetMenuTitle(crMenu,"%s\n \n",title);
				// Iteriate through the skills and print them out
				new String:rname[64];
				new String:rdisp[128],String:requirement[128];
			
			
				new skill_list[MAXSKILLS];
				new skilldisplay=SC_GetSkillList(skill_list);
				new bool:SteamGroupRequired=false;
				for(new i=0;i<skilldisplay;i++) //notice this starts at zero!
				{
					new	x=skill_list[i];
					
					if(!SC_IsSkillMastery(x))
						continue;

				
					//PrintToServer("new	x=skill_list[i]: %d",x);

					Format(rbuf,sizeof(rbuf),"%d",x); //DATA FOR MENU!
				
					SC_GetSkillName(x,rname,sizeof(rname));
					//PrintToServer("SC GET Skill Name: %s",rname);

					new String:extra[4];
					new String:thetypeofskill[4];
					if(SC_IsSkillMastery(x))
					{
						Format(thetypeofskill,sizeof(thetypeofskill),"[M]");
					}
				
					if(SC_GetSkill(client,mastery)==x)
					{
						Format(extra,sizeof(extra),"<M>");
						
					}
					else if(SC_GetPendingSkill(client,mastery)==x){
						Format(extra,sizeof(extra),"<PM>");
					
					}

					Format(rdisp,sizeof(rdisp),"%s %s %s",extra,rname,thetypeofskill);
					
					new String:requiredflagstr[32];
					SC_GetSkillAccessFlagStr(x,requiredflagstr,sizeof(requiredflagstr));  ///14 = index, see races.inc

					new bool:draw_ITEMDRAW_DEFAULT=false;

					if(!StrEqual(requiredflagstr, "0", false)&&!StrEqual(requiredflagstr, "", false))
					{
						Format(requirement,sizeof(requirement),"(VIP Only)");
						draw_ITEMDRAW_DEFAULT=false;
					}
					else if(!SC_IsInSteamGroup(client)&&SC_SkillHasFlag(x,"steamgroup"))
					{
						Format(requirement,sizeof(requirement),"*SC_Evo Steam Group Required*");

						draw_ITEMDRAW_DEFAULT=false;
	
						SteamGroupRequired=true;
					}
					else
					{
						if(SC_SkillHasFlag(x,"steamgroup"))
						{
							Format(requirement,sizeof(requirement),"(Steam Group)");
						}
						
						draw_ITEMDRAW_DEFAULT=true;
					}
				
					Format(rdisp,sizeof(rdisp),"%s %s",rdisp,requirement);
					strcopy(requirement, sizeof(requirement), "");
				
					new AdminId:admin = GetUserAdmin(client);
					if(admin != INVALID_ADMIN_ID) //flag is required and this client is not admin
					{
						draw_ITEMDRAW_DEFAULT=true;
					}
					if(draw_ITEMDRAW_DEFAULT||SC_IsDeveloper(client))
					{
						AddMenuItem(crMenu,rbuf,rdisp,ITEMDRAW_DEFAULT);
					}
					else
					{
						AddMenuItem(crMenu,rbuf,rdisp,ITEMDRAW_DISABLED);
					}
				}
				if(SteamGroupRequired==true)
				{
					SC_ChatMessage(client,"Steam Group: http://steamcommunity.com/groups/war3evo");
				}
			} // END OF SKILL CHOOSEN
			else if(skilltypechoosen==talent)
			{
							
				Format(title,sizeof(title),"%s\n \n[SC] Select your talent skill",title);
				//PrintToServer("title: %s",title);
				SetMenuTitle(crMenu,"%s\n \n",title);
				// Iteriate through the skills and print them out
				new String:rname[64];
				new String:rdisp[128],String:requirement[128];
			
			
				new skill_list[MAXSKILLS];
				new skilldisplay=SC_GetSkillList(skill_list);
				new bool:SteamGroupRequired=false;
				for(new i=0;i<skilldisplay;i++) //notice this starts at zero!
				{
					new	x=skill_list[i];
				
					if(!SC_IsSkillTalent(x))
						continue;

					//PrintToServer("new	x=skill_list[i]: %d",x);

					Format(rbuf,sizeof(rbuf),"%d",x); //DATA FOR MENU!
				
					SC_GetSkillName(x,rname,sizeof(rname));
					//PrintToServer("SC GET Skill Name: %s",rname);

					new String:extra[4];
					new String:thetypeofskill[4];
					if(SC_IsSkillTalent(x))
					{
						Format(thetypeofskill,sizeof(thetypeofskill),"[T]");
					}
				
					if(SC_GetSkill(client,talent)==x)
					{
						Format(extra,sizeof(extra),"<T>");
						
					}
					else if(SC_GetPendingSkill(client,talent)==x){
						Format(extra,sizeof(extra),"<PT>");
					
					}

					Format(rdisp,sizeof(rdisp),"%s %s %s",extra,rname,thetypeofskill);
					
					new String:requiredflagstr[32];
					SC_GetSkillAccessFlagStr(x,requiredflagstr,sizeof(requiredflagstr));  ///14 = index, see races.inc

					new bool:draw_ITEMDRAW_DEFAULT=false;

					if(!StrEqual(requiredflagstr, "0", false)&&!StrEqual(requiredflagstr, "", false))
					{
						Format(requirement,sizeof(requirement),"(VIP Only)");
						draw_ITEMDRAW_DEFAULT=false;
					}
					else if(!SC_IsInSteamGroup(client)&&SC_SkillHasFlag(x,"steamgroup"))
					{
						Format(requirement,sizeof(requirement),"*SC_Evo Steam Group Required*");

						draw_ITEMDRAW_DEFAULT=false;
	
						SteamGroupRequired=true;
					}
					else
					{
						if(SC_SkillHasFlag(x,"steamgroup"))
						{
							Format(requirement,sizeof(requirement),"(Steam Group)");
						}
						
						draw_ITEMDRAW_DEFAULT=true;
					}
				
					Format(rdisp,sizeof(rdisp),"%s %s",rdisp,requirement);
					strcopy(requirement, sizeof(requirement), "");
				
					new AdminId:admin = GetUserAdmin(client);
					if(admin != INVALID_ADMIN_ID) //flag is required and this client is not admin
					{
						draw_ITEMDRAW_DEFAULT=true;
					}
					if(draw_ITEMDRAW_DEFAULT||SC_IsDeveloper(client))
					{
						AddMenuItem(crMenu,rbuf,rdisp,ITEMDRAW_DEFAULT);
					}
					else
					{
						AddMenuItem(crMenu,rbuf,rdisp,ITEMDRAW_DISABLED);
					}
				}
				if(SteamGroupRequired==true)
				{
					SC_ChatMessage(client,"Steam Group: http://steamcommunity.com/groups/war3evo");
				}
			} // END OF SKILL CHOOSEN
			else if(skilltypechoosen==ability)
			{
				Format(title,sizeof(title),"%s\n \n[SC] Select your ability skill",title);
				//PrintToServer("title: %s",title);
				SetMenuTitle(crMenu,"%s\n \n",title);
				// Iteriate through the skills and print them out
				new String:rname[64];
				new String:rdisp[128],String:requirement[128];
			
			
				new skill_list[MAXSKILLS];
				new skilldisplay=SC_GetSkillList(skill_list);
				new bool:SteamGroupRequired=false;
				for(new i=0;i<skilldisplay;i++) //notice this starts at zero!
				{
					new	x=skill_list[i];
					
					if(!SC_IsSkillAbility(x))
						continue;

				
					//PrintToServer("new	x=skill_list[i]: %d",x);

					Format(rbuf,sizeof(rbuf),"%d",x); //DATA FOR MENU!
				
					SC_GetSkillName(x,rname,sizeof(rname));
					//PrintToServer("SC GET Skill Name: %s",rname);

					new String:extra[4];
					new String:thetypeofskill[4];
					if(SC_IsSkillAbility(x))
					{
						Format(thetypeofskill,sizeof(thetypeofskill),"[A]");
					}
				
					if(SC_GetSkill(client,ability)==x)
					{
						Format(extra,sizeof(extra),"<A>");
						
					}
					else if(SC_GetPendingSkill(client,ability)==x){
						Format(extra,sizeof(extra),"<PA>");
					
					}

					Format(rdisp,sizeof(rdisp),"%s %s %s",extra,rname,thetypeofskill);
					
					new String:requiredflagstr[32];
					SC_GetSkillAccessFlagStr(x,requiredflagstr,sizeof(requiredflagstr));  ///14 = index, see races.inc

					new bool:draw_ITEMDRAW_DEFAULT=false;

					if(!StrEqual(requiredflagstr, "0", false)&&!StrEqual(requiredflagstr, "", false))
					{
						Format(requirement,sizeof(requirement),"(VIP Only)");
						draw_ITEMDRAW_DEFAULT=false;
					}
					else if(!SC_IsInSteamGroup(client)&&SC_SkillHasFlag(x,"steamgroup"))
					{
						Format(requirement,sizeof(requirement),"*SC_Evo Steam Group Required*");

						draw_ITEMDRAW_DEFAULT=false;
	
						SteamGroupRequired=true;
					}
					else
					{
						if(SC_SkillHasFlag(x,"steamgroup"))
						{
							Format(requirement,sizeof(requirement),"(Steam Group)");
						}
						
						draw_ITEMDRAW_DEFAULT=true;
					}
				
					Format(rdisp,sizeof(rdisp),"%s %s",rdisp,requirement);
					strcopy(requirement, sizeof(requirement), "");
				
					new AdminId:admin = GetUserAdmin(client);
					if(admin != INVALID_ADMIN_ID) //flag is required and this client is not admin
					{
						draw_ITEMDRAW_DEFAULT=true;
					}
					if(draw_ITEMDRAW_DEFAULT||SC_IsDeveloper(client))
					{
						AddMenuItem(crMenu,rbuf,rdisp,ITEMDRAW_DEFAULT);
					}
					else
					{
						AddMenuItem(crMenu,rbuf,rdisp,ITEMDRAW_DISABLED);
					}
				}
				if(SteamGroupRequired==true)
				{
					SC_ChatMessage(client,"Steam Group: http://steamcommunity.com/groups/war3evo");
				}
			} // END OF SKILL CHOOSEN
			else if(skilltypechoosen==ultimate)
			{
							
				Format(title,sizeof(title),"%s\n \n[SC] Select your ultimate skill",title);
				//PrintToServer("title: %s",title);
				SetMenuTitle(crMenu,"%s\n \n",title);
				// Iteriate through the skills and print them out
				new String:rname[64];
				new String:rdisp[128],String:requirement[128];
			
			
				new skill_list[MAXSKILLS];
				new skilldisplay=SC_GetSkillList(skill_list);
				new bool:SteamGroupRequired=false;
				for(new i=0;i<skilldisplay;i++) //notice this starts at zero!
				{
					new	x=skill_list[i];
				
					if(!SC_IsSkillUltimate(x))
						continue;

					//PrintToServer("new	x=skill_list[i]: %d",x);

					Format(rbuf,sizeof(rbuf),"%d",x); //DATA FOR MENU!
				
					SC_GetSkillName(x,rname,sizeof(rname));
					//PrintToServer("SC GET Skill Name: %s",rname);

					new String:extra[4];
					new String:thetypeofskill[4];
				
					if(SC_GetSkill(client,ultimate)==x)
					{
						Format(extra,sizeof(extra),"<U>");
						
					}
					else if(SC_GetPendingSkill(client,ultimate)==x){
						Format(extra,sizeof(extra),"<PU>");
					
					}

					Format(rdisp,sizeof(rdisp),"%s %s %s",extra,rname,thetypeofskill);
					
					new String:requiredflagstr[32];
					SC_GetSkillAccessFlagStr(x,requiredflagstr,sizeof(requiredflagstr));  ///14 = index, see races.inc

					new bool:draw_ITEMDRAW_DEFAULT=false;

					if(!StrEqual(requiredflagstr, "0", false)&&!StrEqual(requiredflagstr, "", false))
					{
						Format(requirement,sizeof(requirement),"(VIP Only)");
						draw_ITEMDRAW_DEFAULT=false;
					}
					else if(!SC_IsInSteamGroup(client)&&SC_SkillHasFlag(x,"steamgroup"))
					{
						Format(requirement,sizeof(requirement),"*SC_Evo Steam Group Required*");

						draw_ITEMDRAW_DEFAULT=false;
	
						SteamGroupRequired=true;
					}
					else
					{
						if(SC_SkillHasFlag(x,"steamgroup"))
						{
							Format(requirement,sizeof(requirement),"(Steam Group)");
						}
						
						draw_ITEMDRAW_DEFAULT=true;
					}
				
					Format(rdisp,sizeof(rdisp),"%s %s",rdisp,requirement);
					strcopy(requirement, sizeof(requirement), "");
				
					new AdminId:admin = GetUserAdmin(client);
					if(admin != INVALID_ADMIN_ID) //flag is required and this client is not admin
					{
						draw_ITEMDRAW_DEFAULT=true;
					}
					if(draw_ITEMDRAW_DEFAULT||SC_IsDeveloper(client))
					{
						AddMenuItem(crMenu,rbuf,rdisp,ITEMDRAW_DEFAULT);
					}
					else
					{
						AddMenuItem(crMenu,rbuf,rdisp,ITEMDRAW_DISABLED);
					}
				}
				if(SteamGroupRequired==true)
				{
					SC_ChatMessage(client,"Steam Group: http://steamcommunity.com/groups/war3evo");
				}
			} // END OF SKILL CHOOSEN
			else if(skilltypechoosen==didnotfindskill)
			{
							
				Format(title,sizeof(title),"%s\n \n[SC] Select your desired skill",title);
				//PrintToServer("title: %s",title);
				SetMenuTitle(crMenu,"%s\n \n",title);
				// Iteriate through the skills and print them out
				new String:rname[64];
				new String:rdisp[128],String:requirement[128];
			
			
				new skill_list[MAXSKILLS];
				new skilldisplay=SC_GetSkillList(skill_list);
				new bool:SteamGroupRequired=false;
				for(new i=0;i<skilldisplay;i++) //notice this starts at zero!
				{
					new	x=skill_list[i];
				
					//PrintToServer("new	x=skill_list[i]: %d",x);

					Format(rbuf,sizeof(rbuf),"%d",x); //DATA FOR MENU!
				
					SC_GetSkillName(x,rname,sizeof(rname));
					//PrintToServer("SC GET Skill Name: %s",rname);

					new String:extra[4];
					new String:thetypeofskill[4];

					if(SC_IsSkillMastery(x))
					{
						Format(thetypeofskill,sizeof(thetypeofskill),"[M]");
					}
				
					if(SC_GetSkill(client,mastery)==x)
					{
						Format(extra,sizeof(extra),"<M>");
						
					}
					else if(SC_GetPendingSkill(client,mastery)==x){
						Format(extra,sizeof(extra),"<PM>");
					
					}

					if(SC_IsSkillTalent(x))
					{
						Format(thetypeofskill,sizeof(thetypeofskill),"[T]");
					}
				
					if(SC_GetSkill(client,talent)==x)
					{
						Format(extra,sizeof(extra),"<T>");
						
					}
					else if(SC_GetPendingSkill(client,talent)==x){
						Format(extra,sizeof(extra),"<PT>");
					
					}

					if(SC_IsSkillAbility(x))
					{
						Format(thetypeofskill,sizeof(thetypeofskill),"[A]");
					}
				
					if(SC_GetSkill(client,ability)==x)
					{
						Format(extra,sizeof(extra),"<A>");
						
					}
					else if(SC_GetPendingSkill(client,ability)==x){
						Format(extra,sizeof(extra),"<PA>");
					
					}

					
					if(SC_IsSkillUltimate(x))
					{
						Format(thetypeofskill,sizeof(thetypeofskill),"[U]");
					}
				
					if(SC_GetSkill(client,ultimate)==x)
					{
						Format(extra,sizeof(extra),"<U>");
						
					}
					else if(SC_GetPendingSkill(client,ultimate)==x){
						Format(extra,sizeof(extra),"<PU>");
					
					}

					Format(rdisp,sizeof(rdisp),"%s %s %s",extra,rname,thetypeofskill);
					
					new String:requiredflagstr[32];
					SC_GetSkillAccessFlagStr(x,requiredflagstr,sizeof(requiredflagstr));  ///14 = index, see races.inc

					new bool:draw_ITEMDRAW_DEFAULT=false;

					if(!StrEqual(requiredflagstr, "0", false)&&!StrEqual(requiredflagstr, "", false))
					{
						Format(requirement,sizeof(requirement),"(VIP Only)");
						draw_ITEMDRAW_DEFAULT=false;
					}
					else if(!SC_IsInSteamGroup(client)&&SC_SkillHasFlag(x,"steamgroup"))
					{
						Format(requirement,sizeof(requirement),"*SC_Evo Steam Group Required*");

						draw_ITEMDRAW_DEFAULT=false;
	
						SteamGroupRequired=true;
					}
					else
					{
						if(SC_SkillHasFlag(x,"steamgroup"))
						{
							Format(requirement,sizeof(requirement),"(Steam Group)");
						}
						
						draw_ITEMDRAW_DEFAULT=true;
					}
				
					Format(rdisp,sizeof(rdisp),"%s %s",rdisp,requirement);
					strcopy(requirement, sizeof(requirement), "");
				
					new AdminId:admin = GetUserAdmin(client);
					if(admin != INVALID_ADMIN_ID) //flag is required and this client is not admin
					{
						draw_ITEMDRAW_DEFAULT=true;
					}
					if(draw_ITEMDRAW_DEFAULT||SC_IsDeveloper(client))
					{
						AddMenuItem(crMenu,rbuf,rdisp,ITEMDRAW_DEFAULT);
					}
					else
					{
						AddMenuItem(crMenu,rbuf,rdisp,ITEMDRAW_DISABLED);
					}
				}
				if(SteamGroupRequired==true)
				{
					SC_ChatMessage(client,"Steam Group: http://steamcommunity.com/groups/war3evo");
				}
			} // END OF SKILL CHOOSEN

			//PrintToServer("display menu!");
			DisplayMenu(crMenu,client,MENU_TIME_FOREVER);
		}
	}
	else
	{
		PrintToServer("Skills failed to load!");
		SC_ChatMessage(client,"Skills failed to load! Please reconnect!");
	}
	
}

public SC_CRMenu_SelCat(Handle:menu,MenuAction:action,client,selection)
{
	switch(action) {
	case MenuAction_Select:
		{
			if(ValidPlayer(client))
			{
				new String:sItem[64],String:title[512],String:rbuf[4],String:rname[64],String:rdisp[128],String:requirement[128];
				GetMenuItem(menu, selection, sItem, sizeof(sItem));
				if( StringToInt(sItem) == -1 ) {
					SC_ChangeSkillMenu(client,true);
					return;
				}

				new Handle:crMenu=CreateMenu(SC_Source_CRMenu_Selected);
				SetMenuExitButton(crMenu,true);
				Format(title,sizeof(title),"[SC] Select your desired skill");
				SetMenuTitle(crMenu,"%s\nCategory: %s\n",title,sItem);
				// Iteriate through the races and print them out				
				new skill_list[MAXSKILLS];
				new skilldisplay=SC_GetSkillList(skill_list);
				new bool:SteamGroupRequired=false;
				AddMenuItem(crMenu,"-1","[Return to Categories]");
				for(new i=0;i<skilldisplay;i++)
				{
					new	x=skill_list[i],String:rcvar[64];
					SC_GetCvar(SC_GetSkillCell(x,SkillCategorieCvar),rcvar,sizeof(rcvar));
					if(strcmp(sItem, rcvar, false)==0) {
						IntToString(x,rbuf,sizeof(rbuf)); //menudata as string
						SC_GetSkillName(x,rname,sizeof(rname));
						decl String:extra[3],yourteam,otherteam;
						for(new y=1;y<=MaxClients;y++)
						{
							
							if(ValidPlayer(y,false))
							{
								if(SC_GetSkill(y,mastery)==x)
								{
									if(GetClientTeam(client)==GetClientTeam(y))
									{
										++yourteam;
									}
									else
									{
										++otherteam;
									}
								}
								else if(SC_GetSkill(y,talent)==x)
								{
									if(GetClientTeam(client)==GetClientTeam(y))
									{
										++yourteam;
									}
									else
									{
										++otherteam;
									}
								}
								else if(SC_GetSkill(y,ability)==x)
								{
									if(GetClientTeam(client)==GetClientTeam(y))
									{
										++yourteam;
									}
									else
									{
										++otherteam;
									}
								}
								else if(SC_GetSkill(y,ultimate)==x)
								{
									if(GetClientTeam(client)==GetClientTeam(y))
									{	
										++yourteam;
									}
									else
									{
										++otherteam;
									}
								}						
							}
						}
						strcopy(extra, sizeof(extra), "");
						
						if(SC_GetSkill(client,mastery)==x)
						{

							Format(extra,sizeof(extra),"<M>");
						}
						else if(SC_GetPendingSkill(client,mastery)==x){
							Format(extra,sizeof(extra),"<PM>");
					
						}
						if(SC_GetSkill(client,talent)==x)
						{
							Format(extra,sizeof(extra),"<T>");
					
						}
						else if(SC_GetPendingSkill(client,talent)==x){
							Format(extra,sizeof(extra),"<PT>");
					
						}
						if(SC_GetSkill(client,ability)==x)
						{
							Format(extra,sizeof(extra),"<A>");
					
						}
						else if(SC_GetPendingSkill(client,ability)==x){
							Format(extra,sizeof(extra),"<PA>");
					
						}
						if(SC_GetSkill(client,ultimate)==x)
						{
							Format(extra,sizeof(extra),"<U>");
					
						}
						else if(SC_GetPendingSkill(client,ultimate)==x){
							Format(extra,sizeof(extra),"<PU>");
					
						}

						Format(rdisp,sizeof(rdisp),"%s %s",extra,rname);

						new String:requiredflagstr[32];
						SC_GetSkillAccessFlagStr(x,requiredflagstr,sizeof(requiredflagstr));  ///14 = index, see races.inc

						new bool:draw_ITEMDRAW_DEFAULT=false;

						if(!StrEqual(requiredflagstr, "0", false)&&!StrEqual(requiredflagstr, "", false))
						{
							//Format(rdisp,sizeof(rdisp),"%s (VIP Only)",rdisp);
							Format(requirement,sizeof(requirement),"(VIP Only)");
							draw_ITEMDRAW_DEFAULT=false;
						}
						else if(!SC_IsInSteamGroup(client)&&SC_SkillHasFlag(x,"steamgroup"))
						{
							//Format(rdisp,sizeof(rdisp),"%s *SC_Evo Steam Group Required*",rdisp);
							Format(requirement,sizeof(requirement),"*SC Steam Group Required*");

							draw_ITEMDRAW_DEFAULT=false;
							//AddMenuItem(crMenu,rbuf,rdisp,ITEMDRAW_DISABLED);

							SteamGroupRequired=true;
			
							//SC_ChatMessage(client,"Job %s requires you join our Steam Group:\nhttp://steamcommunity.com/groups/war3evo",rname);
							//SC_ChatMessage("Sometimes we lose connection to the steam group, so please be patient.");
						}
						else
						{
							// MIN LEVEL REQUIREMENT
							
							//AddMenuItem(crMenu,rbuf,rdisp,(minlevel<=SC_GetTotalLevels(client)||StrEqual(steamid,"STEAM_0:1:35173666",false)?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
							if(SC_SkillHasFlag(x,"steamgroup"))
							{
								// Lets not fill up the display, this would tell them the race is a steam group race
							
								Format(requirement,sizeof(requirement),"(Steam Group)");
							
							}
							
							draw_ITEMDRAW_DEFAULT=true;
							//AddMenuItem(crMenu,rbuf,rdisp,minlevel<=SC_GetTotalLevels(client)?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
						}

						// Display only one requirement
						Format(rdisp,sizeof(rdisp),"%s %s",rdisp,requirement);
						// Erase requirement
						strcopy(requirement, sizeof(requirement), "");

						// If client is admin, all races are availible.
						new AdminId:admin = GetUserAdmin(client);
						if(admin != INVALID_ADMIN_ID) //flag is required and this client is not admin
						{
							draw_ITEMDRAW_DEFAULT=true;
							//AddMenuItem(crMenu,rbuf,rdisp,ITEMDRAW_DEFAULT);
						}

						// draw menu item
						if(draw_ITEMDRAW_DEFAULT||SC_IsDeveloper(client))
						{
							AddMenuItem(crMenu,rbuf,rdisp,ITEMDRAW_DEFAULT);
						}
						else
						{
							AddMenuItem(crMenu,rbuf,rdisp,ITEMDRAW_DISABLED);
						}
				
					}
					if(SteamGroupRequired==true)
					{
						SC_ChatMessage(client,"Steam Group: http://steamcommunity.com/groups/war3evo");
					}
				}
				DisplayMenu(crMenu,client,MENU_TIME_FOREVER);
			}
		}
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
	}
}


public SC_Source_CRMenu_Selected(Handle:menu,MenuAction:action,client,selection)
{
	if(action==MenuAction_Select)
	{
		if(ValidPlayer(client))
		{
			//new menuselectindex=selection+1;
			//if(racechosen>0&&racechosen<=SC_GetRacesLoaded())
			
			decl String:SelectionInfo[4];
			decl String:SelectionDispText[256];
			
			new SelectionStyle;
			GetMenuItem(menu,selection,SelectionInfo,sizeof(SelectionInfo),SelectionStyle, SelectionDispText,sizeof(SelectionDispText));
			new skill_selected=StringToInt(SelectionInfo);
			
			if(skill_selected==-1) {
				SC_ChangeSkillMenu(client); //user came from the categorized cr menu and clicked the back button
				return;
			}

			new bool:allowChooseSkill=bool:CanSelectSkill(client,skill_selected); //this is the deny system SC_Denyable			
			if(allowChooseSkill==false){
				SC_ChangeSkillMenu(client);//derpy hooves
			}
			
			
		/* MOVED TO RESTRICT ENGINE
			if(allowChooseRace){
				// Minimum level?
				
				new total_level=0;
				new RacesLoaded = SC_GetRacesLoaded();
				for(new x=1;x<=RacesLoaded;x++)
				{
					total_level+=SC_GetLevel(client,x);
				}
				new min_level=SC_GetRaceMinLevelRequired(race_selected);
				if(min_level<0) min_level=0;
				
				if(min_level!=0&&min_level>total_level&&!SC_IsDeveloper(client))
				{
					SC_ChatMessage(client,"%T","You need {amount} more total levels to use this race",GetTrans(),min_level-total_level);
					SC_Source_ChangeRaceMenu(client);
					allowChooseRace=false;
				}
			}
				*/
				
			// GetUserFlagBits(client)&ADMFLAG_ROOT??
			
			
			
			
			///MOVED TO RESTRICT ENGINE
			/*
			new String:requiredflagstr[32];
			
			SC_GetRaceAccessFlagStr(race_selected,requiredflagstr,sizeof(requiredflagstr));  ///14 = index, see races.inc
			
			if(allowChooseRace&&!StrEqual(requiredflagstr, "0", false)&&!StrEqual(requiredflagstr, "", false)&&!SC_IsDeveloper(client)){
				
				new AdminId:admin = GetUserAdmin(client);
				if(admin == INVALID_ADMIN_ID) //flag is required and this client is not admin
				{
					allowChooseRace=false;
					SC_ChatMessage(client,"%T","Restricted Race. Ask an admin on how to unlock",GetTrans());
					PrintToConsole(client,"%T","No Admin ID found",client);
					SC_Source_ChangeRaceMenu(client);
					
				}
				else{
					decl AdminFlag:flag;
					if (!FindFlagByChar(requiredflagstr[0], flag)) //this gets the flag class from the string
					{
						SC_ChatMessage(client,"%T","ERROR on admin flag check {flag}",client,requiredflagstr);
						allowChooseRace=false;
					}
					else
					{
						if (!GetAdminFlag(admin, flag)){
							allowChooseRace=false;
							SC_ChatMessage(client,"%T","Restricted race, ask an admin on how to unlock",GetTrans());
							PrintToConsole(client,"%T","Admin ID found, but no required flag",client);
							SC_Source_ChangeRaceMenu(client);
						}
					}
				}
			}
			
			*/
			
		
			
				//PrintToChatAll("1");
			decl String:buf[192];
			SC_GetSkillName(skill_selected,buf,sizeof(buf));
			if(allowChooseSkill&&(skill_selected==SC_GetSkill(client,mastery)||skill_selected==SC_GetSkill(client,talent)||
			skill_selected==SC_GetSkill(client,ability)||skill_selected==SC_GetSkill(client,ultimate))/*&&(   SC_GetPendingRace(client)<1||SC_GetPendingRace(client)==SC_GetRace(client)    ) */){ //has no other pending race, cuz user might wana switch back
				
				SC_ChatMessage(client,"You already have this skill: %s",buf);
				//if(SC_GetPendingRace(client)){
				
				//SC_SetPendingSkill(client,-1);
					
				//}
				allowChooseSkill=false;
				
			}
		
				
				
				
				
			
			if(allowChooseSkill)
			{
				SC_SetPlayerProp(client,SkillChosenTime,GetGameTime());
				SC_SetPlayerProp(client,SkillSetByAdmin,false);
			
				//has race, set pending, 
				if(SC_GetSkill(client,SC_GetSkillType(skill_selected))>0&&IsPlayerAlive(client)&&!SC_IsDeveloper(client)) //developer direct set (for testing purposes)
				{
					SC_SetPendingSkill(client,SC_GetSkillType(skill_selected),skill_selected);
					SC_ChatMessage(client,"Your skill will be set to %s after death or spawn.",buf);
				}
				//HAS NO RACE, CHANGE NOW
				else //schedule the race change
				{
					SC_SetPendingSkill(client,SC_GetSkillType(skill_selected),-1);
					SC_SetSkill(client,skill_selected);
					
					//PrintToChatAll("2");
					//print is in setrace
					SC_ChatMessage(client,"Your skill is now %s",buf);
					
					//SC_DoLevelCheck(client);
				}
			}
		}
//	}
	}
	if(action==MenuAction_End)
	{
		CloseHandle(menu);
	}
}

//category stocks
//Checks if a category exist
stock bool:SC_IsCategory(const String:cat_name[]) {
	for(new i=0;i<CatCount;i++) {
		if(strcmp(strCategories[i], cat_name, false)==0) {
			return true; //cat exist
		}
	}
	return false;//no cat founded that is named X
}
//Removes all categories
stock SC_ClearCategory() {
	for(new i=0;i<CatCount;i++) {
		strcopy(strCategories[i],64,"");
	}
	CatCount = 0;
}

//Adds a new Category and returns true on success
stock bool:SC_AddCategory(const String:cat_name[]) {
	if(CatCount<MAXCATS) {
		strcopy(strCategories[CatCount],64,cat_name);
		/*if(bCreateSC_Cvar) {
			//Add a w3cvar for this cat
			decl String:buffer[FACTION_LENGTH],w3cvar;
			strcopy(buffer,sizeof(buffer),cat_name);
			ReplaceString(buffer,sizeof(buffer), " ", "_", false);
			Format(buffer,sizeof(buffer),"\"accessflag_%s\"",buffer);
			w3cvar = SC_FindCvar(buffer);
			if(w3cvar==-1)
				w3cvar = SC_CreateCvar(buffer,"0","Admin flag required to access this category");
			}
			iCategories[CatCount]=w3cvar;
		}*/
		CatCount++;
		return true;
	}
	SC_Log("Too much categories!!! (%i/%i) - failed to add new category",CatCount,MAXCATS);
	return false;
}
//Returns a Category Name thing
stock SC_GetCategory(iIndex,String:cat_name[],max_size) {
	decl String:buffer[32];
	strcopy(buffer,sizeof(buffer),strCategories[iIndex]);
	ReplaceString(buffer,sizeof(buffer), "_", " ", false);
	strcopy(cat_name,max_size,buffer);
}
//Refreshes Categories
refreshCategories() {
	SC_ClearCategory();
	//zeroth cat will not be drawn = perfect hidden cat ;D
	SC_AddCategory("hidden");
	decl String:rcvar[64];
	decl skill_list[MAXSKILLS];
	//Loop tru all _avaible_ skills
	new skilldisplay=SC_GetSkillList(skill_list);
	for(new i=0;i<skilldisplay;i++)
	{
		new x=skill_list[i];
		SC_GetCvar(SC_GetSkillCell(x,SkillCategorieCvar),rcvar,sizeof(rcvar));
		//To avoid multiple-same-named-categories we need to check if the category allready exist
		if(!SC_IsCategory(rcvar)) {
			//Add a new category
			SC_AddCategory(rcvar);
		}
	}
}
bool:IsCategorized() {
	return GetConVarBool(hUseCategories);
}
//Calls the forward
bool:CanDrawCategory(iClient,iCategoryIndex) {
	decl value;
	Call_StartForward(hCanDrawCat);
	Call_PushCell(iClient);
	Call_PushCell(iCategoryIndex);
	Call_Finish(value);
	if (value == 3 || value == 4)
		return false;
	return true;
}
public _:Native_GetCategoryName(Handle:plugin,numParams)
{
	SetNativeString(2, strCategories[GetNativeCell(1)], GetNativeCell(3), false);
}
