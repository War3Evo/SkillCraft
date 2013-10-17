//#pragma dynamic 10000

#pragma semicolon 1

#include <sourcemod>
#include "SkillCraft_Includes/SkillCraft_Interface"


new Handle:g_SC_GlobalEventFH; 
new Handle:g_hfwddenyable; 
//new dummyreturn;
new bool:notdenied=true;
new SC_VarArr[SC_Var];

public Plugin:myinfo= 
{
	name="SkillCraft Events",
	author="SkillCraft Team",
	description="SkillCraft Core Plugins",
	version="1.0",
};



//public OnPluginStart()
//{
//}

public bool:Init_SC_NativesForwards()
{
	CreateNative("SC_CreateEvent",Native_SC_CreateEvent);//foritems
	
	CreateNative("SC_Denied",Native_SC_Denied);
	CreateNative("SC_Deny",Native_SC_Deny);
	
	CreateNative("SC_GetVar",Native_SC_GetVar);
	CreateNative("SC_SetVar",Native_SC_SetVar);
	
	g_SC_GlobalEventFH=CreateGlobalForward("On_SC_Event",ET_Ignore,Param_Cell,Param_Cell);
	g_hfwddenyable=CreateGlobalForward("On_SC_Denyable",ET_Ignore,Param_Cell,Param_Cell);
	return true;
}

public Native_SC_GetVar(Handle:plugin,numParams){
	return _:SC_VarArr[SC_Var:GetNativeCell(1)];
}
public Native_SC_SetVar(Handle:plugin,numParams){
	SC_VarArr[SC_Var:GetNativeCell(1)]=GetNativeCell(2);
}

public Native_SC_CreateEvent(Handle:plugin,numParams)
{
	//new event=GetNativeCell(1);
	//new client=GetNativeCell(2);
	DoFwd_SC_Event(SC_EVENT:GetNativeCell(1),GetNativeCell(2));
}

DoFwd_SC_Event(SC_EVENT:event,client){
	Call_StartForward(g_SC_GlobalEventFH);
	Call_PushCell(event);
	Call_PushCell(client);
	Call_Finish();
}

public Native_SC_Denied(Handle:plugin,numParams){
	notdenied=true;
	Call_StartForward(g_hfwddenyable);
	Call_PushCell(GetNativeCell(1)); //event,/
	Call_PushCell(GetNativeCell(2));	//client
	Call_Finish(notdenied);
	return notdenied;
}
public Native_SC_Deny(Handle:plugin,numParams){
	notdenied=false;
}

//public On_SC_War3Event(W3EVENT:event,client){
//	if(event==DoShowHelpMenu){
		//War3Source_War3Help(client);
	//}
//}
//public OnW3Denyable(W3DENY:event,client){
	//if(event==ChangeRace){
//		W3Deny();
//		DP("blocked chancerace %d",client);
		//War3Source_War3Help(client);
//	}
//}
