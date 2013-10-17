#pragma semicolon 1

#include <sourcemod>
#include "SkillCraft_Includes/SkillCraft_Interface"


new Handle:hDB;

//new SC_SQLType:g_SQLType; 

// ConVar definitions
new Handle:m_SaveXPConVar;
new Handle:hSetSkillOnJoinCvar;

new Handle:m_AutosaveTime;
new Handle:hCvarPrintOnSave;

new Handle:g_On_SC_PlayerAuthedHandle;
new desiredMasteryOnJoin[MAXPLAYERSCUSTOM];
new desiredTalentOnJoin[MAXPLAYERSCUSTOM];
new desiredAbilityOnJoin[MAXPLAYERSCUSTOM];
new desiredUltimateOnJoin[MAXPLAYERSCUSTOM];

public Plugin:myinfo= 
{
	name="SkillCraft Engine Database save xp",
	author="SkillCraft Team",
	description="SkillCraft Core Plugins",
	version="1.0",
};


public bool:Init_SC_NativesForwards()
{
	PrintToServer("SC MODE");
	CreateNative("SC_SaveXP" ,Native_SC_SaveXP);
	CreateNative("SC_SaveEnabled" ,Native_SC_SaveEnabled);

	return true;
}

public OnPluginStart()
{
	m_SaveXPConVar=CreateConVar("sc_var_savexp","1");
	SC_SetVar(hSaveEnabledCvar,m_SaveXPConVar);

	hSetSkillOnJoinCvar=CreateConVar("sc_set_skill_on_join","1");

	m_AutosaveTime=CreateConVar("SC_autosavetime","60");
	hCvarPrintOnSave=CreateConVar("SC_print_on_autosave","0","Print a message to chat when xp is auto saved?");
	
	g_On_SC_PlayerAuthedHandle=CreateGlobalForward("On_SC_PlayerAuthed",ET_Ignore,Param_Cell,Param_Cell);

	CreateTimer(GetConVarFloat(m_AutosaveTime),DoAutosave);
}

public Native_SC_SaveXP(Handle:plugin,numParams)
{
	new client=GetNativeCell(1);
	//new skillid=GetNativeCell(2);
//	DP("SAVEXP CALLED");
	//SC_SavePlayerData(client,skillid); //saves main also
	SC_SavePlayerData(client); //saves main also
}
public Native_SC_SaveEnabled(Handle:plugin,numParams)
{
	return GetConVarInt(m_SaveXPConVar);
}





public On_SC_Event(SC_EVENT:event,client){
	if(event==DatabaseConnected)
	{
		PrintToServer("DatabaseSave.sp DatabaseSave executed");
		hDB=SC_GetVar(hDatabase);
		//g_SQLType=SC_GetVar(hDatabaseType);
		Initialize_SQLTable();
	}
	//DP("EVENT %d",event);
}














Initialize_SQLTable()
{
	PrintToServer("[SkillCraft] Initialize_SQLTable");
	if(hDB!=INVALID_HANDLE)
	{
	
		SQL_LockDatabase(hDB); //non threading operations here, done once on plugin load only, not map change
		
		//SkillCraftraces
		/*
		new Handle:query=SQL_Query(hDB,"SELECT * from SkillCraftSkills LIMIT 1");
		if(query!=INVALID_HANDLE) //table exists
		{
			PrintToServer("[SkillCraft] Dropping TABLE SkillCraftSkills and recreating it (normal)") ;
			SQL_FastQueryLogOnError(hDB,"DROP TABLE SkillCraftSkills");
		}
		
		//always create new table
		new String:longquery[4000];
		Format(longquery,sizeof(longquery),"CREATE TABLE SkillCraftSkills (");
		Format(longquery,sizeof(longquery),"%s %s",longquery,"shortname varchar(16) UNIQUE,");
		Format(longquery,sizeof(longquery),"%s %s",longquery,"name  varchar(32)");
		
		for(new i=1;i<3;i++){
			Format(longquery,sizeof(longquery),"%s, skill%d varchar(32)",longquery,i);
			Format(longquery,sizeof(longquery),"%s, skilldesc%d varchar(2000)",longquery,i);
		}
		
		Format(longquery,sizeof(longquery),"%s ) %s",longquery,SC_SQLType:SC_GetVar(hDatabaseType)==SQLType_MySQL?"DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci":"");
	
		SQL_FastQueryLogOnError(hDB,longquery);
		*/
		
		
		
		
		//main table
		new Handle:query=SQL_Query(hDB,"SELECT * from SkillCraft LIMIT 1");
		
		
		if(query==INVALID_HANDLE)
		{   
			new String:createtable[3000];
			Format(createtable,sizeof(createtable),
			"CREATE TABLE SkillCraft (steamid varchar(64) UNIQUE , name varchar(64),   mastery varchar(16),     talent varchar(16),    ability varchar(16),    ultimate varchar(16),  last_seen int) %s",
			SC_SQLType:SC_GetVar(hDatabaseType)==SQLType_MySQL?"DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci":"" );

			if(!SQL_FastQueryLogOnError(hDB,createtable))
			{
				SetFailState("[SkillCraft] ERROR in the creation of the SQL table SkillCraft.");
			}
		}
		else
		{	
			CloseHandle(query);
		}
	
		
		///NEW DATABASE STRUCTURE
		/*
		query=SQL_Query(hDB,"SELECT * from SkillCraft_racedata1 LIMIT 1");
		if(query==INVALID_HANDLE)
		{   
			PrintToServer("[SkillCraft] SkillCraft_racedata1 doesnt exist, creating!!!") ;
			new String:longquery2[4000];
			Format(longquery2,sizeof(longquery2),"CREATE TABLE SkillCraft_racedata1 (steamid varchar(64)  , raceshortname varchar(16),   level int,  xp int  , last_seen int)  %s",SC_SQLType:SC_GetVar(hDatabaseType)==SQLType_MySQL?"DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci":"");
			
			if(!SQL_FastQueryLogOnError(hDB,longquery2)
			||
			!SQL_FastQueryLogOnError(hDB,"CREATE UNIQUE INDEX steamid ON SkillCraft_racedata1 (steamid,raceshortname)")
			)
			{
				SetFailState("[SkillCraft] ERROR in the creation of the SQL table SkillCraft_racedata1");
			}
			query=SQL_Query(hDB,"SELECT * from SkillCraft_racedata1 LIMIT 1"); //get a nother handle for next table check
		}
		
		//do another check for handle, cuz we may have just created database
		if(query==INVALID_HANDLE)
		{
			SetFailState("invalid handle to data, ");
		}
		else
		{	//table exists by now, add skill columns if not exists
			
			new String:columnname[16];
			new dummyfield;
			
			// 3=max skillcount
			for(new i=1;i<3;i++){
				Format(columnname,sizeof(columnname),"skill%d",i);
				
				if(!SQL_FieldNameToNum(query, columnname , dummyfield))
				{
					AddColumn(hDB,columnname,"int","SkillCraft_racedata1");
				}
				
			}
			CloseHandle(query);
		}

		*/
		
		
		
		SQL_UnlockDatabase(hDB);
	}
	else
		PrintToServer("hDB invalid 123");
}


public Action:DoAutosave(Handle:timer,any:data)
{
	if(SC_SaveEnabled())
	{
		for(new x=1;x<=MaxClients;x++)
		{
			if(ValidPlayer(x)&& SC_IsPlayerXPLoaded(x))
			{
				//SC_SavePlayerData(x,SC_GetSkill(x,ability));
				SC_SavePlayerData(x);
			}
		}
		if(GetConVarInt(hCvarPrintOnSave)>0){
			SC_ChatMessage(0,"Saving all player and updating stats");
		}
		
	}
	CreateTimer(GetConVarFloat(m_AutosaveTime),DoAutosave);
}




//SAVING SECTION



//SC_SavePlayerData(client,skillid)
SC_SavePlayerData(client)
{
	if(hDB && !IsFakeClient(client)&&SC_IsPlayerXPLoaded(client))
	{
		//SC_SavePlayerSkill(client,skillid); //only save their current race
		SC_SavePlayerMainData(client);//main data
	}
}
	







//retrieve//retrieve

//retrieve

//retrieve
//retrieve
public OnClientPutInServer(client)
{
	//DP("PUTIN");
	//DP("PUTINSC_");
	SC_SetPlayerProp(client,xpLoaded,false); //set race 0 may trigger unwanted behavior, block it first
	SC_SetPlayerProp(client,bPutInServer,true); //stateful entry
	SC_CreateEvent(InitPlayerVariables,client);
	SC_SetPlayerProp(client,xpLoaded,false);

//		SC_CreateEvent(ClearPlayerVariables,client); 


	if(IsFakeClient(client)){
		SC_SetPlayerProp(client,xpLoaded,true);
	}
	else
	{
		if(SC_SaveEnabled())
		{
			SC_ChatMessage(client,"Loading player data...");
			SkillCraft_LoadPlayerData(client);
		}
		else{
			DoForwardOn_SC_PlayerAuthed(client);
		}
		if(!SC_SaveEnabled() || hDB==INVALID_HANDLE)
			SC_SetPlayerProp(client,xpLoaded,true); // if db failed , or no save xp
	}
}
public OnClientDisconnect(client)
{
	if(SC_GetPlayerProp(client,bPutInServer)){ //he must have joined (not just connected) server already
		if(SC_SaveEnabled() && SC_IsPlayerXPLoaded(client)){
			//SC_SavePlayerData(client,SC_GetSkill(client,mastery));
			SC_SavePlayerData(client);
		}

		SC_CreateEvent(ClearPlayerVariables,client);
		SC_SetPlayerProp(client,bPutInServer,false);
		desiredMasteryOnJoin[client]=0;
		desiredTalentOnJoin[client]=0;
		desiredAbilityOnJoin[client]=0;
		desiredUltimateOnJoin[client]=0;
	}
}

//SELECT STATEMENTS HERE
SkillCraft_LoadPlayerData(client) //SkillCraft calls this
{
		//DP("LOAD");
	//need space for steam id
	decl String:steamid[64];
	
	if(hDB && /*!IsFakeClient(client) && */GetClientAuthString(client,steamid,sizeof(steamid))) // no bots and steamid
	{
		
		new String:longquery[4000];
		//Prepare select query for main data
		Format(longquery,sizeof(longquery),"SELECT mastery,talent,ability,ultimate FROM SkillCraft WHERE steamid='%s'",steamid);
		//Pass off to threaded call back at normal prority
		SQL_TQuery(hDB,T_CallbackSelectPDataMain,longquery,client);
		
		PrintToConsole(client,"[SkillCraft] skills retrieval query: sending MAIN and load all skills request! Time: %d",GetGameTime());
		SC_SetPlayerProp(client,sqlStartLoadXPTime,GetGameTime());
		
		//Lets get race data too
		
		//Format(longquery,sizeof(longquery),"SELECT * FROM SkillCraft_racedata1 WHERE steamid='%s'",steamid);
		//SQL_TQuery(hDB,T_CallbackSelectPDataRace,longquery,client);
		
	}
}

public T_CallbackSelectPDataMain(Handle:owner,Handle:hndl,const String:error[],any:client)
{
	SQLCheckForErrors(hndl,error,"T_CallbackSelectPDataMain");
	
	if(!ValidPlayer(client))
	{
		//PrintToConsole(client,"[SkillCraft] T_CallbackSelectPDataMain !ValidPlayer(%d)",client);
		return;
	}
	
	if(hndl==INVALID_HANDLE)
	{
		//Well the database is fucked up
		//TODO: add retry for select query
		LogError("[SkillCraft] ERROR: SELECT player data failed! Check DATABASE settings!");
		//Don't hang up the process for now
	}
	
	else
	{
		if(SQL_GetRowCount(hndl) == 1) 
		{
			SQL_Rewind(hndl);
			
			if(!SQL_FetchRow(hndl))
			{
				//This would be pretty fucked to occur here
				LogError("[SkillCraft] Unexpected error loading player data, could not FETCH row. Check DATABASE settings!");
				return;
			}
			else{
				//Get the gold from the query
				//new cred=SC_SQLPlayerInt(hndl,"gold");
				//Set the gold for player
				//SC_SetGold(client,cred);
				//PrintToConsole(client,"[SkillCraft] Setting Gold %d",cred);
				
				//new diamonds=SC_SQLPlayerInt(hndl,"diamonds");
				//Set the gold for player
				//SC_SetDiamonds(client,diamonds);
				//PrintToConsole(client,"[SkillCraft] Setting Diamonds %d",diamonds);
				
				//new platinum=SC_SQLPlayerInt(hndl,"platinum");
				//SC_SetPlatinum(client,platinum);
				//PrintToConsole(client,"[SkillCraft] Setting Platinum %d",platinum);
				
				//new levelbankamount=SC_SQLPlayerInt(hndl,"levelbankV2");
				
				//if(SC_GetLevelBank(client)>levelbankamount){ //whichever is higher
					//levelbankamount=SC_GetLevelBank(client); 
				//}
				//SC_SetLevelBank(client,levelbankamount);
				//PrintToConsole(client,"[SkillCraft] Setting levelbank %d",levelbankamount);
				
				
				
				//Get the short race string
				new String:current_mastery[16],String:current_talent[16],String:current_ability[16],String:current_ultimate[16];
				if(!SC_SQLPlayerString(hndl,"mastery",current_mastery,sizeof(current_mastery)))
				{
					LogError("[SkillCraft] Unexpected error loading player skill mastery. Check DATABASE settings!");
					return;
				}
				if(!SC_SQLPlayerString(hndl,"talent",current_talent,sizeof(current_talent)))
				{
					LogError("[SkillCraft] Unexpected error loading player skill mastery. Check DATABASE settings!");
					return;
				}
				if(!SC_SQLPlayerString(hndl,"ability",current_ability,sizeof(current_ability)))
				{
					LogError("[SkillCraft] Unexpected error loading player skill mastery. Check DATABASE settings!");
					return;
				}
				if(!SC_SQLPlayerString(hndl,"ultimate",current_ultimate,sizeof(current_ultimate)))
				{
					LogError("[SkillCraft] Unexpected error loading player skill mastery. Check DATABASE settings!");
					return;
				}
				PrintToConsole(client,"[SkillCraft] mastery skill %s",current_mastery);
				PrintToConsole(client,"[SkillCraft] talent skill %s",current_talent);
				PrintToConsole(client,"[SkillCraft] ability skill %s",current_ability);
				PrintToConsole(client,"[SkillCraft] ultimate skill %s",current_ultimate);
				
				new masteryFound=0,talentFound=0,abilityFound=0,ultimateFound=0; // worst case senario set player to race 0 <<-- changed to 1 so that they must have a race
				if(GetConVarInt(hSetSkillOnJoinCvar)>0)
				{
					//Scan all the races
					new SkillsLoaded = SC_GetSkillsLoaded();
					if(SkillsLoaded>0)
					{
						masteryFound=1;  //Change default to 1 since skills do exist
						talentFound=1;
						abilityFound=1;
						ultimateFound=1;
					}
					for(new x=1;x<=SkillsLoaded;x++)
					{
						new String:short[16];
						SC_GetSkillShortname(x,short,sizeof(short));
						
						//compare their short names to the one loaded
						if(StrEqual(current_mastery,short,false))
						{
							masteryFound=x;
							//break;
						}
					}
					for(new x=1;x<=SkillsLoaded;x++)
					{
						new String:short[16];
						SC_GetSkillShortname(x,short,sizeof(short));
						
						//compare their short names to the one loaded
						if(StrEqual(current_talent,short,false))
						{
							talentFound=x;
							//break;
						}
					}
					for(new x=1;x<=SkillsLoaded;x++)
					{
						new String:short[16];
						SC_GetSkillShortname(x,short,sizeof(short));
						
						//compare their short names to the one loaded
						if(StrEqual(current_ability,short,false))
						{
							abilityFound=x;
							//break;
						}
					}
					for(new x=1;x<=SkillsLoaded;x++)
					{
						new String:short[16];
						SC_GetSkillShortname(x,short,sizeof(short));
						
						//compare their short names to the one loaded
						if(StrEqual(current_ultimate,short,false))
						{
							ultimateFound=x;
							//break;
						}
					}
					desiredMasteryOnJoin[client]=masteryFound;
					desiredTalentOnJoin[client]=talentFound;
					desiredAbilityOnJoin[client]=abilityFound;
					desiredUltimateOnJoin[client]=ultimateFound;
					
					SC_SetPlayerProp(client,xpLoaded,true);
					PrintToConsole(client,"[SkillCraft] RETRIEVED IN %f seconds",GetGameTime()-Float:SC_GetPlayerProp(client,sqlStartLoadXPTime)) ;
					DoForwardOn_SC_PlayerAuthed(client);

					if(desiredMasteryOnJoin[client]>0 && CanSelectSkill(client,desiredMasteryOnJoin[client])){
						//SC_SetPlayerProp(client,SkillSetByAdmin,false);
						SC_SetSkill(client,desiredMasteryOnJoin[client]);
					}
					if(desiredTalentOnJoin[client]>0 && CanSelectSkill(client,desiredTalentOnJoin[client])){
						//SC_SetPlayerProp(client,RaceSetByAdmin,false);
						SC_SetSkill(client,desiredTalentOnJoin[client]);
					}
					if(desiredAbilityOnJoin[client]>0 && CanSelectSkill(client,desiredAbilityOnJoin[client])){
						//SC_SetPlayerProp(client,RaceSetByAdmin,false);
						SC_SetSkill(client,desiredAbilityOnJoin[client]);
					}
					if(desiredUltimateOnJoin[client]>0 && CanSelectSkill(client,desiredUltimateOnJoin[client])){
						//SC_SetPlayerProp(client,RaceSetByAdmin,false);
						SC_SetSkill(client,desiredUltimateOnJoin[client]);
					}

				}
			}
		}
		else if(SQL_GetRowCount(hndl) == 0) //he or she doesnt exist
		{
			///////////////////////////////////////////
			///////////////////////////////////////////
			///////////////////////////////////////////
			/////////IN THIS AREA IS///////////////////
			/////////WHERE THE NEW PLAYER DATA/////////
			/////////IS CREATED!///////////////////////
			///////////////////////////////////////////
			/////////CREATE A WAR3 EVENT///////////////
			///////////////////////////////////////////

			//Not in database so add
			decl String:steamid[64];
			decl String:name[64];
			//get their name and steamid
			if(GetClientAuthString(client,steamid,sizeof(steamid)) && GetClientName(client,name,sizeof(name))) // steamid
			{
				ReplaceString(name,sizeof(name), "'","", true);//REMOVE IT//double escape because \\ turns into -> \  after the %s insert into sql statement

				new String:szSafeName[(sizeof(name)*2)-1];
				SQL_EscapeString( hDB, name, szSafeName, sizeof(szSafeName));

				// Get data from the player vector I guess this allows the player to play before the queries are
				// done but it is probably zero all the time
				
				new String:short_name_mastery[16],String:short_name_talent[16],String:short_name_ability[16],String:short_name_ultimate[16];
				SC_GetSkillShortname(SC_GetSkill(client,mastery),short_name_mastery,sizeof(short_name_mastery));
				SC_GetSkillShortname(SC_GetSkill(client,talent),short_name_talent,sizeof(short_name_talent));
				SC_GetSkillShortname(SC_GetSkill(client,ability),short_name_ability,sizeof(short_name_ability));
				SC_GetSkillShortname(SC_GetSkill(client,ultimate),short_name_ultimate,sizeof(short_name_ultimate));
				
				new String:longquery[4000];
				// Main table query
				Format(longquery,sizeof(longquery),"INSERT INTO SkillCraft (steamid,name,mastery,talent,ability,ultimate) VALUES ('%s','%s','%s','%s','%s','%s')",steamid,szSafeName,short_name_mastery,short_name_talent,short_name_ability,short_name_ultimate);
				new Handle:querytrie=CreateTrie();
				SetTrieString(querytrie,"query",longquery);
				SQL_TQuery(hDB,T_CallbackInsertPDataMain,longquery,querytrie);

				// Set New Player Job
				//SC_SetRace(client,1);

				//new String:requiredflagstr[32];
				
				//new skillsloaded = SC_GetSkillsLoaded();
				
				// New Skills
				//new newskill = GetRandomInt(1, racesloaded);
				
				// SETTING 1ST SKILL AS BEGINNER SKILL?  redo later
				SC_SetSkill(client,1);
				SC_SetSkill(client,1);
				SC_SetSkill(client,1);
				SC_SetSkill(client,1);

				//SC_SetSkill(client,GetRandomInt(1, skillsloaded));
				//SC_SetSkill(client,GetRandomInt(1, skillsloaded));
				//SC_SetSkill(client,GetRandomInt(1, skillsloaded));
				//SC_SetSkill(client,GetRandomInt(1, skillsloaded));
				
				//new countit=0;
				//SC_GetSkillAccessFlagStr(newrace,requiredflagstr,sizeof(requiredflagstr));
				
				//while ((SC_RaceHasFlag(newrace, "hidden")||SC_RaceHasFlag(newrace, "steamgroup"))&&(!StrEqual(requiredflagstr, "0", false)||!StrEqual(requiredflagstr, "", false)))
				//SC_GetRaceShortname(newrace,short_name,sizeof(short_name));
				//while(StrContains("warden, undead, mage, nightelf, crypt, bh, naix, succubus, chronos, luna, lightbender,",short_name) == -1)//
				//{
					//PrintToServer("%s",short_name);
					//countit++;
					//newrace = GetRandomInt(1, racesloaded);
					//SC_GetRaceShortname(newrace,short_name,sizeof(short_name));
					//SC_GetRaceAccessFlagStr(newrace,requiredflagstr,sizeof(requiredflagstr));
					//if(countit>22)
					//{
						//newrace=1;
						//requiredflagstr="0";
						//break;
					//}
				//}
				
				//SC_SetRace(client,newrace);
				//SC_SetGold(client,180);
				
				//new SetRaceLevel = 10;
				//if(SC_GetRaceMaxLevel(newrace)<10)
				//	SetRaceLevel = SC_GetRaceMaxLevel(newrace);
				//SC_SetLevel(client, newrace, SetRaceLevel);
				
				SC_SetPlayerProp(client,xpLoaded,true);
				PrintToConsole(client,"[SkillCraft] RETRIEVED IN %f seconds",GetGameTime()-Float:SC_GetPlayerProp(client,sqlStartLoadXPTime)) ;
				DoForwardOn_SC_PlayerAuthed(client);
			}
			
			
		}
		else if(SQL_GetRowCount(hndl) >1)
		{
			// this is a WTF moment here
			//should probably purge these records and get the player to rejoin but I'm lazy
			//and don't want to write that
			LogError("[SkillCraft] Returned more than 1 record, primary or UNIQUE keys are screwed (main, rows: %d)",SQL_GetRowCount(hndl));
		}
	}
}


//we just tried inserting main data
public T_CallbackInsertPDataMain(Handle:owner,Handle:query,const String:error[],any:querytrie)
{
	SQLCheckForErrors(query,error,"T_CallbackInsertPDataMain",querytrie);
}






/*
///callback retrieved individual race xp!!!!!
public T_CallbackSelectPDataRace(Handle:owner,Handle:hndl,const String:error[],any:client)
{
	SQLCheckForErrors(hndl,error,"T_CallbackSelectPDataRace");
	
	if(!ValidPlayer(client))
		return;
	
	
	
	if(hndl!=INVALID_HANDLE)
	{
		new retrievals;
		new usefulretrievals;
		new bool:raceloaded[MAXSKILLS];
		while(SQL_MoreRows(hndl))
		{
			if(SQL_FetchRow(hndl)){ //SQLITE doesnt properly detect ending
				// Load up the data from a successful query
				// level,xp,skill1,skill2,skill3,ultimate
				
				new String:skillshortname[16];
				SC_SQLPlayerString(hndl,"mastery",skillshortname,sizeof(raceshortname));
				new skillid=SC_GetSkillIDByShortname(raceshortname);
				if(skillid>0) //this race was loaded in war3
				{
					
					raceloaded[raceid]=true;
					new level=SC_SQLPlayerInt(hndl,"level");
					
					// REMOVED.. causes races of different levels not to save the highest level
					//if(level>SC_GetRaceMaxLevel(raceid)){
						//level=SC_GetRaceMaxLevel(raceid);
					//}
					
					SC_SetLevel(client,raceid,level);
					new pxp=SC_SQLPlayerInt(hndl,"xp");
					SC_SetXP(client,raceid,pxp);
					
					
					new String:printstr[500];
					Format(printstr,sizeof(printstr),"[_SC_Evo] XP Ret: Job %s Level %d XP %d Time %f...",raceshortname,level,pxp,GetGameTime());
					
					
					
					new String:column[32];
					new skilllevel;
					new RacesSkillCount = SC_GetRaceSkillCount(raceid);
					for(new skillid=1;skillid<=RacesSkillCount;skillid++){
						Format(column,sizeof(column),"skill%d",skillid);
						skilllevel=SC_SQLPlayerInt(hndl,column);
						//Prevent Future Problems when we remove skill levels from certain races
						new SkillMaxLevel=SC_GetRaceSkillMaxLevel(raceid,skillid);
						if(skilllevel>SkillMaxLevel)
						{
							skilllevel=SkillMaxLevel;
						}
						SC_SetSkillLevelINTERNAL(client,raceid,skillid,skilllevel);
						
						Format(printstr,sizeof(printstr),"%s skill%d=%d",printstr,skillid,skilllevel);
					}

					usefulretrievals++;
				}
				retrievals++;
			}
		} 
		if(retrievals>0){
			PrintToConsole(client,"[SkillCraft] Successfully retrieved data jobs, total of %d jobs were returned, %d are running on this server",retrievals,usefulretrievals);
		}
		else if(retrievals==0&&SC_GetRacesLoaded()>0){     //no xp record
			
			SC_CreateEvent(PlayerIsNewToServer,client);
		}
		new inserts;
		new RacesLoaded = SC_GetRacesLoaded()
		for(new raceid=1;raceid<=RacesLoaded;raceid++)
		{
			
			if(raceloaded[raceid]==false){
				
				
				//no record make one
				decl String:steamid[64];
				decl String:name[64];
				if(GetClientAuthString(client,steamid,sizeof(steamid)) && GetClientName(client,name,sizeof(name)) ) {
					// don't even use name... why have it?

					//ReplaceString(name,sizeof(name), "'","", true);//REMOVE IT //double escape because \\ turns into -> \  after the %s insert into sql statement
					
					//new String:szSafeName[(sizeof(name)*2)-1];
					//SQL_EscapeString( hDB, name, szSafeName, sizeof(szSafeName));

					new String:longquery[4000];
					new String:short[16];
					SC_GetRaceShortname(raceid,short,sizeof(short));
					
					new last_seen=GetTime();
					Format(longquery,sizeof(longquery),"INSERT INTO SkillCraft_racedata1 (steamid,raceshortname,level,xp,last_seen) VALUES ('%s','%s','%d','%d','%d')",steamid,short,SC_GetLevelEx(client,raceid,true),SC_GetXP(client,raceid),last_seen);
					
					SQL_TQuery(hDB,T_CallbackInsertPDataRace,longquery,client);
					inserts++;
				}
			}
			
		}
		if(inserts>0){
			
			PrintToConsole(client,"[SkillCraft] Inserting fresh level xp data for %d jobs",inserts);
		}

		
		SC_SetPlayerProp(client,xpLoaded,true);
		//SC_ChatMessage(client,"Successfully retrieved save data");
		PrintToConsole(client,"[SkillCraft] RETRIEVED IN %f seconds",GetGameTime()-Float:SC_GetPlayerProp(client,sqlStartLoadXPTime)) ;
		DoForwardOn_SC_PlayerAuthed(client);
		
		if(SC_GetRace(client)<=0 && desiredRaceOnJoin[client]>0){
		
			if(CanSelectRace(client,desiredRaceOnJoin[client])){
				SC_SetPlayerProp(client,RaceSetByAdmin,false);
				SC_SetRace(client,desiredRaceOnJoin[client]);
			}
			else{
				SC_CreateEvent(DoShowChangeSkillMenu,client);
			}
		//PrintToServer("shoudl set race? %d client %d",raceDesiredOnJoin,client);
			new bool:doset=true;
			if(GetConVarInt(SC_GetVar(hRaceLimitEnabledCvar))>0){
				if(!CanSelectRace(client,desiredRaceOnJoin[client])){
					doset=false;
				}
				else if(GetRacesOnTeam(desiredRaceOnJoin[client],GetClientTeam(client))>=SC_GetRaceMaxLimitTeam(desiredRaceOnJoin[client],GetClientTeam(client)))
				{
					doset=false;
					SC_ChatMessage(client,"%T","Race limit for your team has been reached, please select a different race. (MAX {amount})",client,SC_GetRaceMaxLimitTeam(desiredRaceOnJoin[client],GetClientTeam(client)));
					SC_Log("race %d blocked on client %d due to restrictions limit %d (set race on join)",desiredRaceOnJoin[client],client,SC_GetRaceMaxLimitTeam(desiredRaceOnJoin[client],GetClientTeam(client)));
					SC_CreateEvent(DoShowChangeSkillMenu,client);
					
				}
				
			}
			if(doset){ ///player race was set on join, 
				SC_SetPlayerProp(client,RaceSetByAdmin,false);
				SC_SetRace(client,desiredRaceOnJoin[client]);
			}
			//else{  ///player race NOT was set on join, show menu
			//	SC_CreateEvent(DoShowChangeRaceMenu,client);
			//}
		}
		// After Race is setup in database.
		//SC_SetPlayerProp(client,dbRaceSelected,true);
	}
}


public T_CallbackInsertPDataRace(Handle:owner,Handle:query,const String:error[],any:data)
{
	SQLCheckForErrors(query,error,"T_CallbackInsertPDataRace");
}
*/






///SAVE
///SAVE
///SAVE
///SAVE
///SAVE
///SAVE
///SAVE
///SAVE
///SAVE









//saveing section
//save a skill using new db style
/*
SC_SavePlayerSkill(client,skillid)
{
	//DP("save");
	if(hDB && SC_SaveEnabled() && SC_GetPlayerProp(client,xpLoaded)&&skillid>0)
	{
		//DP("save2");
		//PrintToServer("race %d client %d",race,client);
		decl String:steamid[64];
	
		if(GetClientAuthString(client,steamid,sizeof(steamid)))
		{
		

			//DP("%d,%d,",level,xp);
			new String:skill_shortname[16];
			SC_GetSkillShortname(skillid,skill_shortname,sizeof(skill_shortname));
			
			
			new String:longquery[4000];
			Format(longquery,sizeof(longquery),"UPDATE SkillCraft_racedata1 SET skillshortname='%s'",skill_shortname);
			
			new last_seen=GetTime();
			Format(longquery,sizeof(longquery),"%s , last_seen='%d' WHERE steamid='%s'",longquery,last_seen,steamid);
			
			new String:skillname[64];
			SC_GetSkillName(skillid,skillname,sizeof(skillname));
			PrintToConsole(client,"[SkillCraft] Saving Skill %s",skillname);
			
			//XP safety?
			//	new level=SC_GetLevel(client,x);
			//	if(level<SC_GetRaceMaxLevel(x)){
			//		Format(longquery,sizeof(longquery),"%s AND level<='%d'",query_buffer,templevel); //only level restrict if not max, iif max or over do not restrict
			//	}
			
			new Handle:querytrie=CreateTrie();
			SetTrieString(querytrie,"query",longquery);
			SQL_TQuery(hDB,T_CallbackSavePlayerRace,longquery,querytrie);
			//DP("%s",longquery);
			//ThrowError("END SAVE");
		}
	}
}
public T_CallbackSavePlayerRace(Handle:owner,Handle:hndl,const String:error[],any:trie)
{
	SQLCheckForErrors(hndl,error,"T_CallbackSavePlayerRace",trie);
}
*/


SC_SavePlayerMainData(client){
	if(hDB &&SC_IsPlayerXPLoaded(client))
	{
		//PrintToServer("client %d mainxp",client);
		decl String:steamid[64];
		decl String:name[64];
		if(GetClientAuthString(client,steamid,sizeof(steamid)) && GetClientName(client,name,sizeof(name)))
		{
			ReplaceString(name,sizeof(name), "'","", true);//REMOVE IT //double escape because \\ turns into -> \  after the %s insert into sql statement

			new String:szSafeName[(sizeof(name)*2)-1];
			SQL_EscapeString( hDB, name, szSafeName, sizeof(szSafeName));

				
			new String:longquery[4000];
				
			new last_seen=GetTime();
			
			new String:shortname_mastery[16];
			SC_GetSkillShortname(SC_GetSkill(client,mastery),shortname_mastery,sizeof(shortname_mastery));
			new String:shortname_talent[16];
			SC_GetSkillShortname(SC_GetSkill(client,talent),shortname_talent,sizeof(shortname_talent));
			new String:shortname_ability[16];
			SC_GetSkillShortname(SC_GetSkill(client,ability),shortname_ability,sizeof(shortname_ability));
			new String:shortname_ultimate[16];
			SC_GetSkillShortname(SC_GetSkill(client,ultimate),shortname_ultimate,sizeof(shortname_ultimate));
			Format(longquery,sizeof(longquery),"UPDATE SkillCraft SET name='%s',mastery='%s',talent='%s',ability='%s',ultimate='%s',last_seen='%d' WHERE steamid = '%s'",szSafeName,shortname_mastery,shortname_talent,shortname_ability,shortname_ultimate,last_seen,steamid);
			new Handle:querytrie=CreateTrie();
			SetTrieString(querytrie,"query",longquery);
			SQL_TQuery(hDB,T_CallbackUpdatePDataMain,longquery,querytrie);
		}
	}
}

//we just tried inserting main data
public T_CallbackUpdatePDataMain(Handle:owner,Handle:query,const String:error[],any:trie)
{
	SQLCheckForErrors(query,error,"T_CallbackUpdatePDataMain",trie);
}

DoForwardOn_SC_PlayerAuthed(client){
	Call_StartForward(g_On_SC_PlayerAuthedHandle);
	Call_PushCell(client);
	Call_Finish(dummy);
}

