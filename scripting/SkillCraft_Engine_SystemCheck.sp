#pragma semicolon 1

#include <sourcemod>
#include "sdkhooks"
#include "SkillCraft_Includes/SkillCraft_Interface"


#define COREPLUGINSNUM 9
new String:coreplugins[COREPLUGINSNUM][]={
"SkillCraft",
"SkillCraft_Engine_CooldownMgr",
"SkillCraft_Engine_PlayerTrace",
"SkillCraft_Engine_PlayerCollision",
"SkillCraft_Engine_Weapon",
"SkillCraft_Engine_Buff",
"SkillCraft_Engine_DamageSystem",
"SkillCraft_Engine_CooldownMgr",
"Engine_Hint"
};


new Handle:g_SC_FailedFH;


public Plugin:myinfo= 
{
	name="SkillCraft Engine System Check",
	author="SkillCraft Team",
	description="SkillCraft Source Core Plugins",
	version="1.0",
};



public OnPluginStart()
{
	CreateTimer(2.0,TwoSecondTimer,_,TIMER_REPEAT);
	CreateTimer(0.1,TwoSecondTimer);
	DoNatives();
}
public bool:Init_SC_NativesForwards(){
	CreateNative("SC_Failed",Native_SC_Failed);
	g_SC_FailedFH=CreateGlobalForward("SC_FailedSignal",ET_Ignore,Param_String); 
	return true;
}
public Native_SC_Failed(Handle:plugin,numParams)
{
	new String:str[2000];
	GetNativeString(1,str,2000);
	DoFwd_SC_Failed(str);
}

DoFwd_SC_Failed(String:str[]){
	Call_StartForward(g_SC_FailedFH);
	Call_PushString(str);
	new dummyret;
	Call_Finish(dummyret);
}

public Action:TwoSecondTimer(Handle:h,any:a){

	for(new i=0;i<COREPLUGINSNUM;i++){
		new Handle:plug=FindPluginByFileCustom(coreplugins[i]);
		if(plug==INVALID_HANDLE){
			LogError("Could not find plugin (handle): %s",coreplugins[i]);
		}
		else{
			new PluginStatus:stat=GetPluginStatus(plug);
			if(stat!=Plugin_Running&&stat!=Plugin_Loaded){
				new String:reason[3000];
				Format(reason,sizeof(reason),"%s failed",coreplugins[i]);
				SC_Failed(reason);
			}
		}	
	}
}


stock Handle:FindPluginByFileCustom(const String:filename[])
{
	decl String:buffer[256];
	
	new Handle:iter = GetPluginIterator();
	new Handle:pl;
	
	while (MorePlugins(iter))
	{
		pl = ReadPlugin(iter);
		
		GetPluginFilename(pl, buffer, sizeof(buffer));
		if (StrContains(buffer,filename,false)>-1) //not case sensitive
		{
			CloseHandle(iter);
			return pl;
		}
	}
	
	CloseHandle(iter);
	
	return INVALID_HANDLE;
}

DoNatives(){

	decl String:path[1024];
	BuildPath(Path_SM,path,sizeof(path),"configs/natives.txt");
	new Handle:file;
	file=OpenFile(path, "r");
	
	
	//new line=0;
	if(file){
		BuildPath(Path_SM,path,sizeof(path),"configs/nativeout.txt");
		new Handle:file2=OpenFile(path,"w+");
		
		
		new String:linestr[1000];
		new String:nativename[100];
		new temp;
		new result;
		while(ReadFileLine(file, linestr, sizeof(linestr)))
		{
			//PrintToServer("LINE:%s",linestr);
			
			temp=StrContains(linestr,"native ",true);
			new nativestrlen=strlen("native ");
			
			if(temp>-1 &&temp<20){ ///20 is arbitrary, makes sure it captures native in front, not a native in teh back somewhere
				result=temp+nativestrlen;
				PrintToServer("native ' at %d",result);
				temp=StrContains(linestr[result],":",true);
				if(temp>-1){
					new temp2=StrContains(linestr[result],"(",true);
					if(temp2>temp){
						result+=(temp+1);
						//PrintToServer("%s",linestr[result]);
					}
				}
				
				new result2=StrContains(linestr[result],"(",true);
				if(result2>-1){
					strcopy(nativename, result2+1, linestr[result]);
				
					//PrintToServer("CreateNative('%s %d \n\n\n\n",nativename,result2);
					WriteFileLine(file2,"MarkNativeAsOptional(\"%s\");",nativename);
					FlushFile(file2);
				}
			}
		}	
	}
}

