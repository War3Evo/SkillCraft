/*
public Action:Check_Bot_ClassName_Timer(Handle:timer, any:userid)
{
	new client=GetClientOfUserId(userid);
	new String:aName[64];
	GetClientName(client, aName, sizeof(aName));

	new motherbot=SC_GetRaceIDByShortname("motherbot");
	new race=SC_GetRace(client);

	//DP("timer checker for bots");

	if(StrEqual(aName, "Sentry Buster",true))
	{
		race = SC_GetRaceIDByShortname("motherbot");
		SC_SetRace(client,race);
		SC_SetLevel(client,race,SC_GetRaceMaxLevel(race));
		for(new i=1;i<=SC_GetRaceSkillCount(race);i++)
		{
			SC_SetSkillLevelINTERNAL(client,race,i,SC_GetRaceSkillMaxLevel(race,i));
		}
		SC_DoLevelCheck(client);
	}
	else if(race==0)
	{
		// if you have no player races, this may cause a loop:
		while (SC_RaceHasFlag(race, "nobots")&&(race!=motherbot))
			race = GetRandomInt(1, SC_GetRacesLoaded());
		SC_SetRace(client,race);
		SC_SetLevel(client,race,SC_GetRaceMaxLevel(race));
		for(new i=1;i<=SC_GetRaceSkillCount(race);i++)
		{
			SC_SetSkillLevelINTERNAL(client,race,i,SC_GetRaceSkillMaxLevel(race,i));
		}
		SC_DoLevelCheck(client);
	}
} */



