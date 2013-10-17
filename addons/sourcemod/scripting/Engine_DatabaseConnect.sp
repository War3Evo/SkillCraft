#pragma semicolon 1

#include <sourcemod>
#include "SkillCraft_Includes/SkillCraft_Interface"


public Plugin:myinfo= 
{
	name="SkillCraft Engine Database Connect",
	author="SkillCraft Team",
	description="SC Core Plugins"
};

new Handle:hDB;
new SC_SQLType:g_SQLType; 


public OnAllPluginsLoaded()
{
	ConnectDB();
}

ConnectDB(){
	PrintToServer("[SC] Connecting to Database");
	new String:sCachedDBIName[256];
	new String:dbErrorMsg[512];
	
	new Handle:keyValue=CreateKeyValues("War3SourceSettings");
	decl String:path[1024];
	BuildPath(Path_SM,path,sizeof(path),"configs/war3source.ini");
	FileToKeyValues(keyValue,path);
	// Load level configuration
	KvRewind(keyValue);
	new String:database_connect[256];
	KvGetString(keyValue,"database",database_connect,sizeof(database_connect),"default");
	decl String:error[256];
	strcopy(sCachedDBIName,256,database_connect);
	
	
	if(StrEqual(database_connect,"",false) || StrEqual(database_connect,"default",false))
	{
		hDB=SQL_DefConnect(error,sizeof(error));	///use default connect, returns a handle...
	}
	else
	{
		hDB=SQL_Connect(database_connect,true,error,sizeof(error));
	}
	if(!hDB)
	{
		LogError("[SkillCraft] ERROR: hDB invalid handle, Check SourceMod database config, could not connect. ");
		Format(dbErrorMsg,sizeof(dbErrorMsg),"ERR: Could not connect to DB. \n%s",error);
		
		LogError("ERRMSG:(%s)",error);
		Create_SC_GlobalError("ERR: Could not connect to Database");
	}
	else
	{
		
		new String:driver_ident[64];
		SQL_ReadDriver(hDB,driver_ident,sizeof(driver_ident));
		if(StrEqual(driver_ident,"mysql",false))
		{
			g_SQLType=SQLType_MySQL;
		}
		else if(StrEqual(driver_ident,"sqlite",false))
		{
			g_SQLType=SQLType_SQLite;
		}
		else
		{
			g_SQLType=SQLType_Unknown;
		}
		PrintToServer("[SkillCraft] SQL connection successful, driver %s",driver_ident);
		SQL_LockDatabase(hDB);
		SQL_FastQuery(hDB, "SET NAMES \"UTF8\""); 
		SQL_UnlockDatabase(hDB);
		SC_SetVar(hDatabase,hDB);
		SC_SetVar(hDatabaseType,g_SQLType);
		SC_CreateEvent(DatabaseConnected,0);
	}
	return true;
}
