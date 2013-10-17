
#pragma semicolon 1
#include <sourcemod>
#include "SkillCraft_Includes/SkillCraft_Interface"


new Handle:hSC_Log;
new Handle:hSC_LogError;
new Handle:hSC_LogNotError;
new Handle:hGlobalErrorFwd;
public Plugin:myinfo= 
{
	name="Engine Log Error",
	author="SkillCraft Team",
	description="SkillCraft Core Plugins",
	version="1.0",
};

public APLRes:SC_AskPluginLoad2Custom(Handle:myself,bool:late,String:error[],err_max)
{

	new String:path_log[1024];
	BuildPath(Path_SM,path_log,sizeof(path_log),"logs/war3sourcelog.txt");
	new Handle:hFile=OpenFile(path_log,"a+");
	if(hFile)
	{
		CloseHandle(hFile);
		// using this file for war3bug, why delete it on restart???
		//DeleteFile(path_log);
		
	}

	hSC_Log=OpenFile(path_log,"a+");
	
	BuildPath(Path_SM,path_log,sizeof(path_log),"logs/war3sourceerrorlog.txt");
	hSC_LogError=OpenFile(path_log,"a+");
	
	
	
	
	BuildPath(Path_SM,path_log,sizeof(path_log),"logs/war3sourcenoterrorlog.txt");
	hFile=OpenFile(path_log,"a+");
	if(hFile)
	{
		CloseHandle(hFile);
		DeleteFile(path_log);
	}
	hSC_LogNotError=OpenFile(path_log,"a+");
	
	return APLRes_Success;
}

public OnPluginStart()
{
}

public bool:Init_SC_NativesForwards()
{
	
	CreateNative("SC_Log",Native_SC_Log);
	CreateNative("SC_LogError",Native_SC_LogError);
	CreateNative("SC_LogNotError",Native_SC_LogNotError);

	CreateNative("Create_SC_GlobalError",Native_Create_SC_GlobalError);
	hGlobalErrorFwd=CreateGlobalForward("On_SC_GlobalError",ET_Ignore,Param_String);
	
	return true;
}


public Native_SC_Log(Handle:plugin,numParams)//{const String:fmt[],any:...)
{
	
	decl String:outstr[1000];
	
	FormatNativeString(0, 
                          1, 
                          2, 
                          sizeof(outstr),
						  _,
						  outstr);
	decl String:date[32];
	FormatTime(date, sizeof(date), "%c");					  					  
	Format(outstr,sizeof(outstr),"%s %s",date,outstr);
	
	PrintToServer("%s",outstr);
	WriteFileLine(hSC_Log,outstr);
	FlushFile(hSC_Log);
}
public Native_SC_LogError(Handle:plugin,numParams)//{const String:fmt[],any:...)
{
	
	decl String:outstr[1000];
	
	FormatNativeString(0, 
                          1, 
                          2, 
                          sizeof(outstr),
						  _,
						  outstr);
	decl String:date[32];
	FormatTime(date, sizeof(date), "%c");					  					  
	Format(outstr,sizeof(outstr),"%s %s",date,outstr);
	
	PrintToServer("%s",outstr);
	WriteFileLine(hSC_LogError,outstr);
	FlushFile(hSC_LogError);
}
public Native_SC_LogNotError(Handle:plugin,numParams)//{const String:fmt[],any:...)
{
	
	decl String:outstr[1000];
	
	FormatNativeString(0, 
                          1, 
                          2, 
                          sizeof(outstr),
						  _,
						  outstr);
	decl String:date[32];
	FormatTime(date, sizeof(date), "%c");					  					  
	Format(outstr,sizeof(outstr),"%s %s",date,outstr);
	
	PrintToServer("%s",outstr);
	WriteFileLine(hSC_LogNotError,outstr);
	FlushFile(hSC_LogNotError);
}
public Native_Create_SC_GlobalError(Handle:plugin,numParams){
	decl String:outstr[1000];
	
	FormatNativeString(0, 
		      1, 
		      2, 
		      sizeof(outstr),
			_,
			outstr);
			
	Call_StartForward(hGlobalErrorFwd);
	Call_PushString(outstr);
	Call_Finish(dummy);

}
