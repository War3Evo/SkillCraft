///check race limit and force re-choose race
CheckRaceTeamLimit(skillid,team){

	new Float:youngest=-1.0;
	new target=0;
	for(new i=1;i<=MaxClients;i++){
	    if(ValidPlayer(i))
		{
			if(SC_GetRace(i)==skillid&&!SC_IsDeveloper(i))
			{
				if(GetClientTeam(i)==team)
				{
					if(SC_GetPlayerProp(i,LastChangeTeamTime)>youngest){
						target=i;
						youngest=SC_GetPlayerProp(i,LastChangeTeamTime);
					}
				}
			}
		}
	}
	if(target>0){
		SC_SetSkill(target,0);
		new String:racename[64];
		SC_GetRaceName(skillid,racename,sizeof(racename));
		SC_ChatMessage(target,"%T","{race} race team limit has reached (MAX {amount}), please select a different job",target,racename,SC_GetSkillMaxLimitTeam(skillid,team));
		PrintToConsole(target,"Your job has been set via raceutils.inc");
		new cvar=SC_GetSkillMaxLimitTeamCvar(skillid,team);
		new String:cvarstr[64];
		if(cvar>-1){
			SC_GetCvarActualString(cvar,cvarstr,sizeof(cvarstr));
		}
		cvar=SC_FindCvar(cvarstr);
		new String:cvarvalue[64];
		if(cvar>-1){
			SC_GetCvar(cvar,cvarvalue,sizeof(cvarvalue));
		}
		
		SC_Log("job %s blocked on client %d due to restrictions limit %d (CheckRaceTeamLimit)  %s %s",skillname,target,SC_GetSkillMaxLimitTeam(skillid,team),cvarstr,cvarvalue);
		
		SC_CreateEvent(DoShowChangeSkillMenu,target);
	}
	
}

/*
HasRaceAccess(client,Handle:hRace)
{
	new String:flag_str[8];
	new Handle:cvarCheck=GetArrayCell(hRace,14);
	GetConVarString(cvarCheck,flag_str,8);
	new first_char=_:flag_str[0];
	if(StrEqual(flag_str,"0",false) || first_char<(_:'a') || first_char>(_:'z'))
		return true; // no valid cvar value, give them access
	new AdminFlag:flag_check;
	if(!FindFlagByChar(first_char,flag_check))
		return true; // bad flag provided
	new AdminId:admin = GetUserAdmin(client);
	if((admin!=INVALID_ADMIN_ID)&&(GetAdminFlag(admin,flag_check,Access_Effective)==true))
		return true; // user has flag
		
	
	
	//return IsDeveloper(client); // must not have proper flag if it got all the way down here.
	return false;
}
*/



