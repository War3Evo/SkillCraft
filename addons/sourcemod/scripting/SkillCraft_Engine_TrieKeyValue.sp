
#pragma dynamic 10000
#pragma semicolon 1
#include <sourcemod>
#include "SkillCraft_Includes/SkillCraft_Interface"

new Handle:Cvartrie;
new Handle:Cvararraylist; //cvar
new Handle:Cvararraylist2; //cvar definition
public Plugin:myinfo= 
{
	name="SkillCraft Engine Trie Key Value",
	author="SkillCraft Team",
	description="SkillCraft Core Plugins",
	version="1.0",
};



public OnPluginStart()
{
	RegConsoleCmd("sc",cmdSC,"SkillCraft internal variables and commands");
}

public bool:Init_SC_NativesForwards()
{
	Cvartrie=CreateTrie();
	Cvararraylist=CreateArray(ByteCountToCells(64));  //cvar
	Cvararraylist2=CreateArray(ByteCountToCells(1024)); //cvar desc
	PushArrayString(Cvararraylist, "ZEROTH CVAR, INVALID CVARID PASSED");
	PushArrayString(Cvararraylist2, "ZEROTH CVAR, INVALID CVARID PASSED");
	CreateNative("SC_CreateCvar",Native_SC_CreateCvar);
	CreateNative("SC_GetCvar",Native_SC_GetCvar);
	CreateNative("SC_SetCvar",Native_SC_SetCvar);
	CreateNative("SC_FindCvar",Native_SC_FindCvar);
	//CreateNative("SC_RemoveCvar",Native_SC_RemoveCvar);
	
	CreateNative("SC_CvarList",Native_SC_CvarList);
	CreateNative("SC_GetCvarByString",Native_SC_GetCvarByString);
	
	CreateNative("SC_GetCvarActualString",Native_SC_GetCvarActualString);
	return true;
}
public Native_SC_CreateCvar(Handle:plugin,numParams){
	new String:cvar[64];
	new String:value[1024];
	new String:desc[1024];
	GetNativeString(1,cvar,sizeof(cvar));
	GetNativeString(2,value,sizeof(value));
	GetNativeString(3,desc,sizeof(desc));

	//new bool:ReplaceCvars=War3_IsRaceReloading();
	new bool:ReplaceCvars=GetNativeCell(4)>=1?true:false;
	
	//PrintToServer("SC_ Cvar %s %s ReplaceCvars: %s",cvar,desc,ReplaceCvars?"true":"false");
		
	if(!SetTrieString(Cvartrie,cvar,value,ReplaceCvars)){
		ThrowError("SC_ Cvar %s %s already created, or creation failed",cvar,desc);
		
	}
	PushArrayString(Cvararraylist, cvar);
	PushArrayString(Cvararraylist2, desc);
	
	return GetArraySize(Cvararraylist)-1;
}

public Native_SC_GetCvar(Handle:plugin,numParams){
	new cvarid=GetNativeCell(1);
	new String:cvarstr[64];
	GetArrayString(Cvararraylist, cvarid,cvarstr,sizeof(cvarstr));
	
	
	new String:outstr[1024];
	if(!GetTrieString(Cvartrie, cvarstr, outstr, sizeof(outstr))){
		ThrowError("Could not GET Cvar: cvarid %d",cvarid);
	}
	//PrintToServer("%s %d",outstr,cvarid);
	SetNativeString(2,outstr,GetNativeCell(3));
	
}
public Native_SC_SetCvar(Handle:plugin,numParams){
	new cvarid=GetNativeCell(1);
	new String:cvarstr[64];
	GetArrayString(Cvararraylist, cvarid,cvarstr,sizeof(cvarstr));
	
	new String:setvalue[1024];
	GetNativeString(2,setvalue,sizeof(setvalue));
	
	new String:outstr[32];
	if(!GetTrieString(Cvartrie, cvarstr, outstr, sizeof(outstr))){
		ThrowError("Could not FIND Cvar");
	}
	else if(!SetTrieString(Cvartrie, cvarstr, setvalue)){
		ThrowError("Could not SET Cvar");
	}
}

public Native_SC_FindCvar(Handle:plugin,numParams){
	decl String:cvarstr[64];
	GetNativeString(1,cvarstr,sizeof(cvarstr));
	return FindStringInArray(Cvararraylist, cvarstr);
}
/*
  Need to do: add way to to remove arrays from code
  so we can force a restart without having to restart the server.

public Native_SC_RemoveCvar(Handle:plugin,numParams){

	decl String:cvarstr[64];
	GetNativeString(1,cvarstr,sizeof(cvarstr));
	return FindStringInArray(Cvararraylist, cvarstr);
}
*/
public Native_SC_CvarList(Handle:plugin,numParams){
	
	return _:CloneHandle(Cvararraylist);
}

public Native_SC_GetCvarByString(Handle:plugin,numParams){
	decl String:cvarstr[64];
	GetNativeString(1,cvarstr,sizeof(cvarstr));
	
	new String:outstr[1024];
	if(!GetTrieString(Cvartrie, cvarstr, outstr, sizeof(outstr))){
		ThrowError("Could not GET Cvar %s, not in Trie, not registered?",cvarstr);
	}
	//PrintToServer("%s %d",outstr,cvarid);
	SetNativeString(2,outstr,GetNativeCell(3));
	
}
public Native_SC_GetCvarActualString(Handle:plugin,numParams){
	new String:ret[64];
	GetArrayString(Cvararraylist,GetNativeCell(1),ret,sizeof(ret));
	SetNativeString(2,ret,GetNativeCell(3));
}




public Action:cmdSC(client,args){
	if(client!=0&&!HasSMAccess(client,ADMFLAG_ROOT)){
		ReplyToCommand(client,"No Access. This is not a command for players. say war3menu for the main menu");
	}
	else{	
		
		new bool:pass=false;
		if(args>=1){
	
			new String:arg1[64];
			GetCmdArg(1,arg1,sizeof(arg1));
			
			if(StrEqual(arg1,"cvarlist")){
				PrintCvars(client,args>1,2);
				pass=true;
			}
			
			if (!pass&&args==2){
				SetCvar(client);
				pass=true;
			}
			if (!pass&&args==1){
				PrintCvars(client,true,1);
				pass=true;
			}
		}
		
		if(!pass){
			new String:arg0[32];
			new String:arg[32];
			GetCmdArg(0,arg0,sizeof(arg0));
			GetCmdArgString(arg, sizeof(arg));
			ReplyToCommand(client,"-----------------------------------");
			ReplyToCommand(client,"war3 <arg> ...  Unknown CMD: %s %s Args: %d",arg0,arg,args);
			ReplyToCommand(client,"    Available commands:");
			ReplyToCommand(client,"war3 cvarlist <optional prefix filter>");
			ReplyToCommand(client,"war3 <cvar> <value>");
			ReplyToCommand(client,"    Use double quotes when needed");
			ReplyToCommand(client,"-----------------------------------");
		}
	}
}
PrintCvars(client,bool:hasfilter,filterarg){

	new limit=GetArraySize(Cvararraylist);
	
	if(!hasfilter){
		ReplyToCommand(client,"LISTING ALL WAR3 INTERNAL CVARS" );
		for(new i;i<limit;i++){
			decl String:out1[32];
			decl String:out11[32];
			decl String:out2[1024];
			GetArrayString(Cvararraylist,i,out1,sizeof(out1)); //cvar
			GetTrieString(Cvartrie,out1,out11,sizeof(out11)); //value
			Format(out1,sizeof(out1),"%s \"%s\" ",out1,out11);
			//ReplyToCommand(client,"%s",out);
			if(strlen(out1)<32){
				StrCat(out1,32,"                                ");
			}
			
			GetArrayString(Cvararraylist2,i,out2,sizeof(out2)); //desc
			ReplyToCommand(client,"%s%s",out1,out2);
		}
	}
	else{
		
		new String:arg2[32];
		GetCmdArg(filterarg,arg2,sizeof(arg2));	
		ReplyToCommand(client,"LISTING ALL WAR3 INTERNAL CVARS THAT BEGINS WITH '%s'" ,arg2);
		
		for(new i;i<limit;i++){
			decl String:out1[32];
			decl String:out11[32];
			decl String:out2[1024];
			GetArrayString(Cvararraylist,i,out1,sizeof(out1)); //cvar
			
			if(StrContains(out1,arg2,false)==0){
				GetTrieString(Cvartrie,out1,out11,sizeof(out11)); //value
				Format(out1,sizeof(out1),"%s \"%s\" ",out1,out11);
				//ReplyToCommand(client,"%s",out);
				if(strlen(out1)<32){
					StrCat(out1,32,"                                ");
				}
				
				GetArrayString(Cvararraylist2,i,out2,sizeof(out2)); //desc
				ReplyToCommand(client,"%s%s",out1,out2);
			}
		}
	}
}

SetCvar(client){
	new String:arg1[64];
	GetCmdArg(1,arg1,sizeof(arg1));
	
	new cvar=SC_FindCvar(arg1);
	if(cvar==-1){
		ReplyToCommand(client,"SC_CVAR \"%s\" not found, please fix/clean up your config",arg1);
		SC_Log("SC_CVAR (internal)  \"%s\" not found, please fix/clean up your config",arg1);
		return;
	}
	
	new String:arg2[1024];
	GetCmdArg(2,arg2,sizeof(arg2));
	
	SC_SetCvar(cvar,arg2);
	
	new String:out[1024];
	SC_GetCvar(cvar,out,sizeof(out));
	ReplyToCommand(client,"SC_CVAR %s is now \"%s\"",arg1,out);
	
	
	return;
}
