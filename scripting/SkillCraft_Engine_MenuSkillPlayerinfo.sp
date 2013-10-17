#pragma semicolon 1

//#pragma tabsize 0     // doesn't mess with how you format your lines
#include <sourcemod>
#include "SkillCraft_Includes/SkillCraft_Interface"


public Plugin:myinfo= 
{
	name="SkillCraft Menus playerinfo",
	author="SkillCraft Team",
	description="SkillCraft Core Plugins",
	version="1.0",
};

new skillinfoshowskillnumber[MAXPLAYERSCUSTOM];

//new Handle:ShowOtherPlayerItemsCvar;
//new Handle:ShowTargetSelfPlayerItemsCvar;

public OnPluginStart()
{
	//CreateConVar("war3evo_MenuRacePlayerInfo",PLUGIN_VERSION,"War3evo Menu Core",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	// No Spendskill level restrictions on non-ultimates (Requires mapchange)
	
	//ShowOtherPlayerItemsCvar=CreateConVar("war3_show_playerinfo_other_player_items","1","0 disables showing other players items using playerinfo. [default 1]");
	
	//war3_show_playerinfo_targetself_items 0
	
	//ShowTargetSelfPlayerItemsCvar=CreateConVar("war3_show_playerinfo_targetself_items","1","0 disables showing targeting yourself items using playerinfo. [default 1]");

}			//SC_playertargetItemMenu

public On_SC_Event(SC_EVENT:event,client){
	if(event==DoShowSkillinfoMenu){
		ShowSkillinfoMenu(client);
	}
	
	if(event==DoShowPlayerinfoMenu){
		SC_PlayerInfoMenu(client,"");
	}
	
	if(event==DoShowPlayerinfoEntryWithArg){
		PlayerInfoMenuEntry(client);
	}
	if(event==DoShowParticularSkillInfo){
		new skillid = SC_GetVar(SkillinfoSkillToShow);
		if(ValidSkill(skillid)) {
			SC_ShowParticularSkillInfoMenu(client,skillid);
		}
	}
	if(event==DoShowPlayerInfoTarget){
		new target = SC_GetVar(EventArg1);
		if(ValidPlayer(target,false)) {
			SC_playertargetMenu(client,target) ;
		}
	}
}



ShowSkillinfoMenu(client){
	new Handle:hMenu=CreateMenu(SC_skillinfoSelected);
	SetMenuExitButton(hMenu,true);
	SetMenuTitle(hMenu,"\n ","[SkillCraft] Select a skill for more info");
	// Iteriate through the races and print them out
	
	decl String:rbuf[4];
	decl String:rskillname[64];
	decl String:rdisp[128];
	
	new skill_list[MAXSKILLS];
	new skilldisplay=SC_GetSkillList(skill_list);
	//if(GetConVarInt(SC_GetVar(hSortByMinLevelCvar))<1){
	//	for(new x=0;x<SC_GetRacesLoaded();x++){//notice this starts at zero!
	//		racelist[x]=x+1;
	//	}
	//}
	
	
		
	
	for(new i=0;i<skilldisplay;i++) //notice this starts at zero!
	{
		new	skillid=skill_list[i];
	
		Format(rbuf,sizeof(rbuf),"%d",skillid); //DATA FOR MENU!
		SC_GetSkillName(skillid,rskillname,sizeof(rskillname));
		
		
		
		new yourteam,otherteam;
		for(new y=1;y<=MaxClients;y++)
		{
			
			if(ValidPlayer(y,false))
			{
				if(SC_GetSkill(y,mastery)==skillid)
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
				else if(SC_GetSkill(y,talent)==skillid)
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
				else if(SC_GetSkill(y,ability)==skillid)
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
				else if(SC_GetSkill(y,ultimate)==skillid)
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
		
		new String:extra[4];
		if(SC_GetSkill(client,mastery)==skillid)
		{
			Format(extra,sizeof(extra),"<M>");
					
		}
		else if(SC_GetPendingSkill(client,mastery)==skillid){
			Format(extra,sizeof(extra),"<PM>");
					
		}
		if(SC_GetSkill(client,talent)==skillid)
		{
			Format(extra,sizeof(extra),"<T>");
		
		}
		else if(SC_GetPendingSkill(client,talent)==skillid){
			Format(extra,sizeof(extra),"<PT>");
			
		}
		if(SC_GetSkill(client,ability)==skillid)
		{
			Format(extra,sizeof(extra),"<A>");
			
		}
		else if(SC_GetPendingSkill(client,ability)==skillid){
			Format(extra,sizeof(extra),"<PA>");
			
		}
		if(SC_GetSkill(client,ultimate)==skillid)
		{
			Format(extra,sizeof(extra),"<U>");
					
		}
		else if(SC_GetPendingSkill(client,ultimate)==skillid){
			Format(extra,sizeof(extra),"<PU>");
					
		}
		
		Format(rdisp,sizeof(rdisp),"%s %s (Your Team:%d The Other:%d)",extra,rskillname,yourteam,otherteam);
		AddMenuItem(hMenu,rbuf,rdisp);
	}
	DisplayMenu(hMenu,client,MENU_TIME_FOREVER);
}


public SC_skillinfoSelected(Handle:menu,MenuAction:action,client,selection)
{
	if(action==MenuAction_Select)
	{
		if(ValidPlayer(client))
		{
			
			decl String:SelectionInfo[4];
			decl String:SelectionDispText[256];
			
			new SelectionStyle;
			GetMenuItem(menu,selection,SelectionInfo,sizeof(SelectionInfo),SelectionStyle, SelectionDispText,sizeof(SelectionDispText));
			new skill_selected=StringToInt(SelectionInfo);
			
			skillinfoshowskillnumber[client]=-1;
			SC_ShowParticularSkillInfoMenu(client,skill_selected);
		}
	}
	if(action==MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public SC_ShowParticularSkillInfoMenu(client,skillid){
	new Handle:hMenu=CreateMenu(SC_particularraceinfoSelected);
	SetMenuExitButton(hMenu,true);
	SetMenuExitBackButton(hMenu,false);
	
	new String:skilldesc[1000];
	new String:skillname[64];
	//new String:longbuf[7000];


	
	new String:selectioninfo[32];
	
	
	SetMenuTitle(hMenu,"\n \n[SkillCraft] Skill information");
		
	decl String:str[1000];
	
	new bool:hasskill=false;
	
	if(SC_HasSkill(client,skillid))
	{
		hasskill=true;
	}
	
	if(hasskill)
	{
		new masterynum = SC_GetSkill(client,mastery);
		new talentnum = SC_GetSkill(client,talent);
		new abilitynum = SC_GetSkill(client,ability);
		new ultimatenum = SC_GetSkill(client,ultimate);
	
	
		// MASTERY
	
		SC_GetSkillName(masterynum,skillname,sizeof(skillname));
	
		Format(str,sizeof(str),"Mastery: %s",skillname);
	
		Format(selectioninfo,sizeof(selectioninfo),"%d,skill,%d",skillid,masterynum);
	
		if(skillinfoshowskillnumber[client]==masterynum){
			SC_GetSkillDesc(masterynum,skilldesc,sizeof(skilldesc)) ;
			//AddMenuItem(hMenu,selectioninfo,skilldesc,ITEMDRAW_RAWLINE); //,ITEMDRAW_DISABLED|ITEMDRAW_RAWLINE
	
			Format(str,sizeof(str),"%s \n%s \n",str,skilldesc);
			//Format(longbuf,sizeof(longbuf),"%s\n%s%s  (Level %d/%d)\n%s\n ",longbuf,,skillname,level,,skilldesc);
		}
	
		AddMenuItem(hMenu,selectioninfo,str);
	
	
		// TALENT
	
		SC_GetSkillName(talentnum,skillname,sizeof(skillname));
	
		Format(str,sizeof(str),"Talent: %s",skillname);
	
		Format(selectioninfo,sizeof(selectioninfo),"%d,skill,%d",skillid,talentnum);
	
		if(skillinfoshowskillnumber[client]==talentnum){
			SC_GetSkillDesc(talentnum,skilldesc,sizeof(skilldesc)) ;
			//AddMenuItem(hMenu,selectioninfo,skilldesc,ITEMDRAW_RAWLINE); //,ITEMDRAW_DISABLED|ITEMDRAW_RAWLINE
	
			Format(str,sizeof(str),"%s \n%s \n",str,skilldesc);
			//Format(longbuf,sizeof(longbuf),"%s\n%s%s  (Level %d/%d)\n%s\n ",longbuf,,skillname,level,,skilldesc);
		}
	
		AddMenuItem(hMenu,selectioninfo,str);
	

		// ABILITY
	
		SC_GetSkillName(abilitynum,skillname,sizeof(skillname));
	
		Format(str,sizeof(str),"Ability: %s",skillname);
	
		Format(selectioninfo,sizeof(selectioninfo),"%d,skill,%d",skillid,abilitynum);
	
		if(skillinfoshowskillnumber[client]==abilitynum){
			SC_GetSkillDesc(abilitynum,skilldesc,sizeof(skilldesc)) ;
			//AddMenuItem(hMenu,selectioninfo,skilldesc,ITEMDRAW_RAWLINE); //,ITEMDRAW_DISABLED|ITEMDRAW_RAWLINE
	
			Format(str,sizeof(str),"%s \n%s \n",str,skilldesc);
			//Format(longbuf,sizeof(longbuf),"%s\n%s%s  (Level %d/%d)\n%s\n ",longbuf,,skillname,level,,skilldesc);
		}
	
		AddMenuItem(hMenu,selectioninfo,str);

	
		// ULTIMATE
	
		SC_GetSkillName(ultimatenum,skillname,sizeof(skillname));
	
		Format(str,sizeof(str),"Ultimate: %s",skillname);
	
		Format(selectioninfo,sizeof(selectioninfo),"%d,skill,%d",skillid,ultimatenum);
	
		if(skillinfoshowskillnumber[client]==ultimatenum){
			SC_GetSkillDesc(ultimatenum,skilldesc,sizeof(skilldesc)) ;
			//AddMenuItem(hMenu,selectioninfo,skilldesc,ITEMDRAW_RAWLINE); //,ITEMDRAW_DISABLED|ITEMDRAW_RAWLINE
	
			Format(str,sizeof(str),"%s \n%s \n",str,skilldesc);
			//Format(longbuf,sizeof(longbuf),"%s\n%s%s  (Level %d/%d)\n%s\n ",longbuf,,skillname,level,,skilldesc);
		}
	
		AddMenuItem(hMenu,selectioninfo,str);

		// SHOW OPTION TO SHOW ALL SKILLS
	
		Format(str,sizeof(str),"Show all availible skills");
	
		Format(selectioninfo,sizeof(selectioninfo),"%d,allskills,%d",skillid,skillid);
	
		AddMenuItem(hMenu,selectioninfo,str);
	}
	else
	{
		//new skillnumid = SC_GetSkill(client,SC_GetSkillType(skillid));
		new skillnumid = skillid;
		
		SC_GetSkillName(skillnumid,skillname,sizeof(skillname));
		
		if(SC_IsSkillMastery(skillnumid))
			Format(str,sizeof(str),"Mastery: %s",skillname);
		if(SC_IsSkillTalent(skillnumid))
			Format(str,sizeof(str),"Talent: %s",skillname);
		if(SC_IsSkillAbility(skillnumid))
			Format(str,sizeof(str),"Ability: %s",skillname);
		if(SC_IsSkillUltimate(skillnumid))
			Format(str,sizeof(str),"Ultimate: %s",skillname);
	
		Format(selectioninfo,sizeof(selectioninfo),"%d,allskills,%d",skillid,skillnumid);
	
		SC_GetSkillDesc(skillnumid,skilldesc,sizeof(skilldesc)) ;

		Format(str,sizeof(str),"%s \n%s \n",str,skilldesc);
	
		AddMenuItem(hMenu,selectioninfo,str);

		// possible spacer:
		//strcopy(str,sizeof(str)," ");
		//Format(selectioninfo,sizeof(selectioninfo),"%d,allskills,%d",skillid,-4);
		
		//AddMenuItem(hMenu,selectioninfo,str,ITEMDRAW_RAWLINE);
		Format(str,sizeof(str),"Set this Skill");
		Format(selectioninfo,sizeof(selectioninfo),"%d,setskill,%d",skillid,-3);
		AddMenuItem(hMenu,selectioninfo,str);
		
		Format(str,sizeof(str),"Back");
		Format(selectioninfo,sizeof(selectioninfo),"%d,allskills,%d",skillid,-4);
		AddMenuItem(hMenu,selectioninfo,str);
	}

	DisplayMenu(hMenu,client,MENU_TIME_FOREVER);
}














public SC_particularraceinfoSelected(Handle:menu,MenuAction:action,client,selection)
{
	if(action==MenuAction_Select)
	{
		if(ValidPlayer(client))
		{
			
			new String:exploded[3][32];
			
			decl String:SelectionInfo[32];
			decl String:SelectionDispText[256];
			new SelectionStyle;
			GetMenuItem(menu,selection,SelectionInfo,sizeof(SelectionInfo),SelectionStyle, SelectionDispText,sizeof(SelectionDispText));
			
			ExplodeString(SelectionInfo, ",", exploded, 3, 32);
			new skillid=StringToInt(exploded[0]);
			
			if(StrEqual(exploded[1],"skill")){
				new skillnum=StringToInt(exploded[2]);
				if(skillinfoshowskillnumber[client]==selection){
					skillinfoshowskillnumber[client]=-1;
				}
				else{
					skillinfoshowskillnumber[client]=skillnum;
				}
				SC_ShowParticularSkillInfoMenu(client,skillid);
		
			}
			else if(StrEqual(exploded[1],"changeskill")){
				new skillidnum=StringToInt(exploded[2]);
				decl String:buf[192];
				SC_GetSkillName(skillidnum,buf,sizeof(buf));

				SC_SetPendingSkill(client,SC_GetSkillType(skillidnum),skillidnum);

				//ForcePlayerSuicide(client);
				SC_ChatMessage(client,"You will have skill %s after death or spawn",buf);
			}
			else if(StrEqual(exploded[1],"allskills")){
				ShowSkillinfoMenu(client);
				new listnum=StringToInt(exploded[2]);

				if(listnum==-4){
					ShowSkillinfoMenu(client);
				}
			}
			else if(StrEqual(exploded[1],"setskill")){
				ShowSkillinfoMenu(client);
				new listnum=StringToInt(exploded[2]);
				
				if(listnum==-3){
					new bool:allowChooseSkill=bool:CanSelectSkill(client,skillid); //this is the deny system SC_Denyable			
					if(allowChooseSkill==false){
						ShowSkillinfoMenu(client);//derpy hooves
					}
					decl String:buf[192];
					SC_GetSkillName(skillid,buf,sizeof(buf));
					if(allowChooseSkill&&(skillid==SC_GetSkill(client,mastery)||skillid==SC_GetSkill(client,talent)||
					skillid==SC_GetSkill(client,ability)||skillid==SC_GetSkill(client,ultimate))/*&&(   SC_GetPendingRace(client)<1||SC_GetPendingRace(client)==SC_GetRace(client)    ) */){ //has no other pending race, cuz user might wana switch back
				
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
						if(SC_GetSkill(client,SC_GetSkillType(skillid))>0&&IsPlayerAlive(client)&&!SC_IsDeveloper(client)) //developer direct set (for testing purposes)
						{
							SC_SetPendingSkill(client,SC_GetSkillType(skillid),skillid);
							SC_ChatMessage(client,"Your skill will be set to %s after death or spawn.",buf);
						}
						//HAS NO SKILL, CHANGE NOW
						else //schedule the race change
						{
							SC_SetPendingSkill(client,SC_GetSkillType(skillid),-1);
							SC_SetSkill(client,skillid);
					
							//PrintToChatAll("2");
							//print is in setrace
							SC_ChatMessage(client,"Your skill is now %s",buf);
					
							//SC_DoLevelCheck(client);
						}
					}
				}
			}
			
		}
	}
	//if(action==MenuAction_Cancel)
	//{
		//if(selection==MenuCancel_ExitBack)
		//{
			//ShowMenuSkillinfo(client);
		//}
	//}
	if(action==MenuAction_End)
	{
		CloseHandle(menu);
	}
}












/*
SC_playersWhoAreThisRaceMenu(client,skillid){
	new Handle:hMenu=CreateMenu(SC_playersWhoAreThisRaceSel);
	SetMenuExitButton(hMenu,true);
	
	new String:racename[64];
	SC_GetRaceName(skillid,racename,sizeof(racename));
	
	SetMenuTitle(hMenu,"%T\n \n","[War3Evo] People who are job: {racename}",client,racename);
	
	decl String:playername[64];
	decl String:war3playerbuf[4];
	
	for(new x=1;x<=MaxClients;x++)
	{
		if(ValidPlayer(x)&&SC_GetRace(x)==skillid){
			
			Format(war3playerbuf,sizeof(war3playerbuf),"%d",x);  //target index
			GetClientName(x,playername,sizeof(playername));
			decl String:menuitemstr[100];
			decl String:teamname[10];
			GetShortTeamName( GetClientTeam(x),teamname,sizeof(teamname));
			Format(menuitemstr,sizeof(menuitemstr),"%T","{player} (Level {amount}) [{team}]",client,playername,SC_GetLevel(x,skillid),teamname);
			AddMenuItem(hMenu,war3playerbuf,menuitemstr);
		}
	}
	DisplayMenu(hMenu,client,MENU_TIME_FOREVER);
	
}
public SC_playersWhoAreThisRaceSel(Handle:menu,MenuAction:action,client,selection)
{
	if(action==MenuAction_Select)
	{
		
		decl String:SelectionInfo[4];
		decl String:SelectionDispText[256];
		new SelectionStyle;
		GetMenuItem(menu,selection,SelectionInfo,sizeof(SelectionInfo),SelectionStyle, SelectionDispText,sizeof(SelectionDispText));
		new target=StringToInt(SelectionInfo);
		if(ValidPlayer(target))
			SC_playertargetMenu(client,target);
		else
			SC_ChatMessage(client,"%T","Player has left the server",client);
	
	}
	if(action==MenuAction_End)
	{
		CloseHandle(menu);
	}
}
*/





PlayerInfoMenuEntry(client){
	new String:arg[32];
	new Handle:dataarray=SC_GetVar(hPlayerInfoArgStr); //should always be created, upper plugin closes handle
	GetArrayString(dataarray,0,arg,sizeof(arg));
	SC_PlayerInfoMenu(client,arg);
}


SC_PlayerInfoMenu(client,String:arg[]){
	//PrintToChatAll("%s",arg);
	if(strlen(arg)>10){   //has argument (space after)
		new String:arg2[32];
		Format(arg2,sizeof(arg2),"%s",arg[11]);
		//PrintToChatAll("%s",arg2);
		
		
		new found=0;
		new targetlist[MAXPLAYERSCUSTOM];
		new String:name[32];
		for(new i=1;i<=MaxClients;i++){
			if(ValidPlayer(i)){
				GetClientName(i,name,sizeof(name));
				if(StrContains(name,arg2,false)>-1){
					targetlist[found++]=i;
				}
			}
		}
		if(found==0){
			//SC_ChatMessage(client,"%T","!playerinfo <optional name>: No target found",client);
		}
		else if(found>1){
			//SC_ChatMessage(client,"%T","!playerinfo <optional name>: More than one target found",client);
			//redundant code..maybe we should optmize?
			new Handle:hMenu=CreateMenu(SC_playerinfoSelected1);
			SetMenuExitButton(hMenu,true);
			SetMenuTitle(hMenu,"\n [SkillCraft] Select a player to view its information");
			// Iteriate through the players and print them out
			decl String:playername[32];
			decl String:scplayerbuf[4];
			decl String:racename[64];
			decl String:menuitem[100] ;
			for(new i=0;i<found;i++)
			{
				new clientindex=targetlist[i];
				Format(scplayerbuf,sizeof(scplayerbuf),"%d",clientindex);  //target index
				GetClientName(clientindex,playername,sizeof(playername));

				// Replace No Race w/ No Job
				if(StrEqual("No Race",racename,true))
					strcopy(racename, sizeof(racename), "No Skill");

				Format(menuitem,sizeof(menuitem),"%s",playername);

				AddMenuItem(hMenu,scplayerbuf,menuitem);
				
			}
			DisplayMenu(hMenu,client,MENU_TIME_FOREVER);
			 
		}
		else {
				SC_playertargetMenu(client,targetlist[0]);
		}
	}
	else
	{
		
		new Handle:hMenu=CreateMenu(SC_playerinfoSelected1);
		SetMenuExitButton(hMenu,true);
		SetMenuTitle(hMenu,"\n [SkillCraft] Select a player to view its information");
		// Iteriate through the players and print them out
		decl String:playername[32];
		decl String:scplayerbuf[4];
		decl String:menuitem[100] ;
		for(new x=1;x<=MaxClients;x++)
		{
			if(ValidPlayer(x)){
				
				Format(scplayerbuf,sizeof(scplayerbuf),"%d",x);  //target index
				GetClientName(x,playername,sizeof(playername));

				Format(menuitem,sizeof(menuitem),"%s",playername);

				AddMenuItem(hMenu,scplayerbuf,menuitem);
			}
		}
		DisplayMenu(hMenu,client,MENU_TIME_FOREVER);
	}
}

public SC_playerinfoSelected1(Handle:menu,MenuAction:action,client,selection)
{
	if(action==MenuAction_Select)
	{
		decl String:SelectionInfo[4];
		decl String:SelectionDispText[256];
		new SelectionStyle;
		GetMenuItem(menu,selection,SelectionInfo,sizeof(SelectionInfo),SelectionStyle, SelectionDispText,sizeof(SelectionDispText));
		new target=StringToInt(SelectionInfo);
		if(ValidPlayer(target))
			SC_playertargetMenu(client,target);
		else
			SC_ChatMessage(client,"%T","Player has left the server",client);
	}
	if(action==MenuAction_End)
	{
		CloseHandle(menu);
	}
}

// ***********************************************************************************************
// ***********************************************************************************************
// ***********************************************************************************************
// ***************************************************************************************************************
// ***********************************************************************************************
// ***********************************************************************************************
// ***********************************************************************************************
// ***************************************************************************************************************
// ***********************************************************************************************
// ***********************************************************************************************
// ***********************************************************************************************
// ***************************************************************************************************************

SC_playertargetMenu(client,target) {
	new Handle:hMenu=CreateMenu(SC_playertargetMenuSelected);
	SetMenuExitButton(hMenu,true);

	new String:targetname[32];
	GetClientName(target,targetname,sizeof(targetname));
	
	new String:skillname[64];
	
	//new skillid=SC_GetRace(target);
	new String:title[3000];

	Format(title,sizeof(title),"\n \n","[SC] Information for %s",targetname);
	
	Format(title,sizeof(title),"%s\n",title);
	
	new skillid=SC_GetSkill(target,mastery);
	SC_GetSkillName(skillid,skillname,sizeof(skillname));
	Format(title,sizeof(title),"%s\n Mastery: %s",title,skillname);

	skillid=SC_GetSkill(target,talent);
	SC_GetSkillName(skillid,skillname,sizeof(skillname));
	Format(title,sizeof(title),"%s\n Talent: %s",title,skillname);

	skillid=SC_GetSkill(target,ability);
	SC_GetSkillName(skillid,skillname,sizeof(skillname));
	Format(title,sizeof(title),"%s\n Ability: %s",title,skillname);

	skillid=SC_GetSkill(target,ultimate);
	SC_GetSkillName(skillid,skillname,sizeof(skillname));
	Format(title,sizeof(title),"%s\n Ultimate: %s",title,skillname);

	new Float:armorred=(1.0-SC_GetPhysicalArmorMulti(target))*100;
	Format(title,sizeof(title),"%s\n \n Physical Armor: %.2f (%s%.2f%%)",title,SC_GetBuffMaxFloat(target,fArmorPhysical),armorred<0.0?"+":"-",armorred<0.0?armorred*-1.0:armorred);
	
	armorred=(1.0-SC_GetMagicArmorMulti(target))*100;
	Format(title,sizeof(title),"%s\n Magic Armor: %.2f (%s%.2f%%)",title,SC_GetBuffMaxFloat(target,fArmorMagic),armorred<0.0?"+":"-",armorred<0.0?armorred*-1.0:armorred);
	
	Format(title,sizeof(title),"%s\n \n",title);
	
	
	SetMenuTitle(hMenu,"%s",title);
	// Iteriate through the races and print them out
	
	
	
	
	new String:buf[3];
	
	IntToString(target,buf,sizeof(buf));
	new String:str[100];
	Format(str,sizeof(str),"Refresh");
	AddMenuItem(hMenu,buf,str);
	
	new String:selectionDisplayBuff[16];
	new String:selectioninfo[32];
	Format(selectionDisplayBuff,sizeof(selectionDisplayBuff),"Copy Skills");
	Format(selectioninfo,sizeof(selectioninfo),"%d,copy,%d",GetClientUserId(client),GetClientUserId(target));
	if(client!=target)
	{
		AddMenuItem(hMenu,selectioninfo,selectionDisplayBuff); 
	}
	else
	{
		AddMenuItem(hMenu,selectioninfo,selectionDisplayBuff,ITEMDRAW_DISABLED);
	}
	Format(selectionDisplayBuff,sizeof(selectionDisplayBuff),"Playerinfo Menu");
	Format(selectioninfo,sizeof(selectioninfo),"%d,back,%d",GetClientUserId(client),GetClientUserId(target));
	AddMenuItem(hMenu,selectioninfo,selectionDisplayBuff); 
	//Format(selectionDisplayBuff,sizeof(selectionDisplayBuff),"Beta Testing");
	//AddMenuItem(hMenu,buf,selectionDisplayBuff); 
	
	//Format(selectionDisplayBuff,sizeof(selectionDisplayBuff),"Spectate Player");
	//AddMenuItem(hMenu,buf,selectionDisplayBuff); 
	
	DisplayMenu(hMenu,client,MENU_TIME_FOREVER);
}

/*
SC_playertargetItemMenu(client,target) {

		new Handle:hMenu=CreateMenu(SC_playertargetItemMenuSelected2);
		SetMenuExitButton(hMenu,true);

		new String:title[3000];

		// Items info
		//if(client==target)
		//{
		Format(title,sizeof(title),"%s\n \n%T\n",title,"Items:",client);

		Format(title,sizeof(title),"%s\n \n",title);

		new String:itemname[64];
		new moleitemid=SC_GetItemIdByShortname("mole");
		new ItemsLoaded = SC_GetItemsLoaded();
		for(new itemid=1;itemid<=ItemsLoaded;itemid++)
		{
			if(SC_GetOwnsItem(target,itemid)&&itemid!=moleitemid)
			{
				SC_GetItemName(itemid,itemname,sizeof(itemname));
				Format(title,sizeof(title),"%s\n%s",title,itemname);
			}
		}
		Format(title,sizeof(title),"%s\n \n",title);

		new Items2Loaded = SC_GetItems2Loaded();
		for(new itemid=1;itemid<=Items2Loaded;itemid++)
		{
			if(SC_GetOwnsItem2(target,itemid)&&itemid!=moleitemid)
			{
				SC_GetItem2Name(itemid,itemname,sizeof(itemname));
				Format(title,sizeof(title),"%s\n%s",title,itemname);
			}
		}
	//}

		Format(title,sizeof(title),"%s\n \n",title);

		SetMenuTitle(hMenu,"%s",title);

		new String:buf[3];

		IntToString(target,buf,sizeof(buf));
		new String:str[100];
		Format(str,sizeof(str),"%T","Refresh",client);
		AddMenuItem(hMenu,buf,str);

		DisplayMenu(hMenu,client,MENU_TIME_FOREVER);
}


public SC_playertargetItemMenuSelected2(Handle:menu,MenuAction:action,client,selection)
	if(action==MenuAction_Select)
	{
		decl String:SelectionInfo[4];
		decl String:SelectionDispText[256];
		new SelectionStyle;
		GetMenuItem(menu,selection,SelectionInfo,sizeof(SelectionInfo),SelectionStyle, SelectionDispText,sizeof(SelectionDispText));
		new target=StringToInt(SelectionInfo);
		if(!ValidPlayer(target)){
			SC_ChatMessage(client,"%T","Player has left the server",client);
		}
		else
		{
			if(selection==0){
				SC_playertargetItemMenu(client,target);
			}
		}
		if(action==MenuAction_End)
		{
			CloseHandle(menu);
		}
}*/



// ***********************************************************************************************
// ***********************************************************************************************
// ***********************************************************************************************
// ***************************************************************************************************************
// ***********************************************************************************************
// ***********************************************************************************************
// ***********************************************************************************************
// ***************************************************************************************************************
// ***********************************************************************************************
// ***********************************************************************************************
// ***********************************************************************************************
// ***************************************************************************************************************

public SC_playertargetMenuSelected(Handle:menu,MenuAction:action,client,selection)
{
	if(action==MenuAction_Select)
	{
		if(ValidPlayer(client))
		{
			new String:exploded[3][32];
			
			decl String:SelectionInfo[32];
			decl String:SelectionDispText[256];
			new SelectionStyle;
			GetMenuItem(menu,selection,SelectionInfo,sizeof(SelectionInfo),SelectionStyle, SelectionDispText,sizeof(SelectionDispText));
			
			ExplodeString(SelectionInfo, ",", exploded, 3, 32);
			//new clientuserid=StringToInt(exploded[0]);
			
			if(StrEqual(exploded[1],"back")){
				//new clientuserid=StringToInt(exploded[0]);
				//new targetuserid=StringToInt(exploded[2]);
				SC_PlayerInfoMenu(client,"");
			}
			else if(StrEqual(exploded[1],"copy")){
				new clientuserid=StringToInt(exploded[0]);
				new targetuserid=StringToInt(exploded[2]);
				new copyfrom=GetClientOfUserId(targetuserid);
				new copyto=GetClientOfUserId(clientuserid);
				if(ValidPlayer(copyfrom)&&ValidPlayer(copyto))
				{
					new copyfrom_mastery=SC_GetSkill(copyfrom,mastery);
					new copyfrom_talent=SC_GetSkill(copyfrom,talent);
					new copyfrom_ability=SC_GetSkill(copyfrom,ability);
					new copyfrom_ultimate=SC_GetSkill(copyfrom,ultimate);
					
					decl String:buf[192];
					new bool:allowChooseSkill=bool:CanSelectSkill(client,copyfrom_mastery); //this is the deny system SC_Denyable
					if(allowChooseSkill==false){
						SC_ChatMessage(copyto,"You can not copy this mastery skill.");
					}
					else
					{
						//copy mastery
						SC_GetSkillName(copyfrom_mastery,buf,sizeof(buf));
						
						if(IsPlayerAlive(client)&&!SC_IsDeveloper(client)) //developer direct set (for testing purposes)
						{
							SC_SetPendingSkill(client,SC_GetSkillType(copyfrom_mastery),copyfrom_mastery);
							SC_ChatMessage(client,"Your skill will be set to %s after death or spawn.",buf);
						}
						//HAS NO SKILL, CHANGE NOW
						else //schedule the race change
						{
							SC_SetPendingSkill(client,SC_GetSkillType(copyfrom_mastery),-1);
							SC_SetSkill(client,copyfrom_mastery);
					
							SC_ChatMessage(client,"Your skill is now %s",buf);
					
							//SC_DoLevelCheck(client);
						}
					}
					allowChooseSkill=bool:CanSelectSkill(client,SC_GetSkill(copyfrom,talent)); //this is the deny system SC_Denyable
					if(allowChooseSkill==false){
						SC_ChatMessage(copyto,"You can not copy this talent skill.");
					}
					else
					{
						//copy talent
						SC_GetSkillName(copyfrom_talent,buf,sizeof(buf));
						
						if(IsPlayerAlive(client)&&!SC_IsDeveloper(client)) //developer direct set (for testing purposes)
						{
							SC_SetPendingSkill(client,SC_GetSkillType(copyfrom_talent),copyfrom_talent);
							SC_ChatMessage(client,"Your skill will be set to %s after death or spawn.",buf);
						}
						//HAS NO SKILL, CHANGE NOW
						else //schedule the race change
						{
							SC_SetPendingSkill(client,SC_GetSkillType(copyfrom_talent),-1);
							SC_SetSkill(client,copyfrom_talent);
					
							SC_ChatMessage(client,"Your skill is now %s",buf);
					
							//SC_DoLevelCheck(client);
						}
					}
					allowChooseSkill=bool:CanSelectSkill(client,SC_GetSkill(copyfrom,ability)); //this is the deny system SC_Denyable			
					if(allowChooseSkill==false){
						SC_ChatMessage(copyto,"You can not copy this ability skill.");
					}
					else
					{
						//copy ability
						SC_GetSkillName(copyfrom_ability,buf,sizeof(buf));
						
						if(IsPlayerAlive(client)&&!SC_IsDeveloper(client)) //developer direct set (for testing purposes)
						{
							SC_SetPendingSkill(client,SC_GetSkillType(copyfrom_ability),copyfrom_ability);
							SC_ChatMessage(client,"Your skill will be set to %s after death or spawn.",buf);
						}
						//HAS NO SKILL, CHANGE NOW
						else //schedule the race change
						{
							SC_SetPendingSkill(client,SC_GetSkillType(copyfrom_ability),-1);
							SC_SetSkill(client,copyfrom_ability);
					
							SC_ChatMessage(client,"Your skill is now %s",buf);
					
							//SC_DoLevelCheck(client);
						}
					}
					allowChooseSkill=bool:CanSelectSkill(client,SC_GetSkill(copyfrom,ultimate)); //this is the deny system SC_Denyable			
					if(allowChooseSkill==false){
						SC_ChatMessage(copyto,"You can not copy this ultimate skill.");
					}
					else
					{
						//copy ultimate
						SC_GetSkillName(copyfrom_ultimate,buf,sizeof(buf));
						
						if(IsPlayerAlive(client)&&!SC_IsDeveloper(client)) //developer direct set (for testing purposes)
						{
							SC_SetPendingSkill(client,SC_GetSkillType(copyfrom_ultimate),copyfrom_ultimate);
							SC_ChatMessage(client,"Your skill will be set to %s after death or spawn.",buf);
						}
						//HAS NO SKILL, CHANGE NOW
						else //schedule the race change
						{
							SC_SetPendingSkill(client,SC_GetSkillType(copyfrom_ultimate),-1);
							SC_SetSkill(client,copyfrom_ultimate);
					
							SC_ChatMessage(client,"Your skill is now %s",buf);
					
							//SC_DoLevelCheck(client);
						}
					}
				}
				else
				{
					if(ValidPlayer(copyto))
						SC_ChatMessage(client,"Player has left the server, unable to copy.");
				}
		
			}
		}
		else
		{
			SC_ChatMessage(client,"Player has left the server");
		}
	}
	if(action==MenuAction_End)
	{
		CloseHandle(menu);
	}
}


