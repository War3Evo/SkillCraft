//Cooldown manager
//keeps track of all cooldowns

//Delay Tracker:
//setting an object's state to false for X seconds, manually retrieve the state




#include <sourcemod>
#include "SkillCraft_Includes/SkillCraft_Interface"




new bool:CooldownOnSpawn[MAXSKILLS];
new bool:CooldownSpawnPrintOnExpire[MAXSKILLS];
new Float:CooldownOnSpawnDuration[MAXSKILLS];

new String:ultimateReadySound[256]; //="war3source/ult_ready.mp3";
new String:abilityReadySound[256]; //="war3source/ability_refresh.mp3";

new Handle:g_CooldownExpiredForwardHandle;


new CooldownPointer[MAXPLAYERSCUSTOM][MAXSKILLS];

enum CooldownClass
{
	Float:cexpiretime,
	cclient,
	cskill,
	bool:cexpireonspawn,
	bool:cprintmsgonexpire,
	cnext,
}

#define MAXCOOLDOWNS 64*2
new Cooldown[MAXCOOLDOWNS][CooldownClass];








#define MAXTHREADS 2000
new Float:expireTime[MAXTHREADS];
new threadsLoaded;


public Plugin:myinfo= 
{
	name="SkillCraft Engine Cooldown Manager",
	author="SkillCraft Team",
	description="SkillCraft Core Plugins",
	version="1.0",
};


public OnPluginStart()
{
	CreateTimer(0.1,DeciSecondTimer,_,TIMER_REPEAT);

}
public OnMapStart()
{
	strcopy(ultimateReadySound,sizeof(ultimateReadySound),"war3source/ult_ready.mp3");
	strcopy(abilityReadySound,sizeof(abilityReadySound),"war3source/ability_refresh.mp3");
	SC_PrecacheSound("UI/hint.wav");

	for(new i=0;i<MAXTHREADS;i++){
		expireTime[i]=0.0;
	}
	
	SC_PrecacheSound(abilityReadySound);
	SC_PrecacheSound(ultimateReadySound);


	ClearAllCooldowns();
}

public bool:Init_SC_NativesForwards()
{
	
	///LIST ALL THESE NATIVES IN INTERFACE
	CreateNative("SC_CooldownMGR",Native_SC_CooldownMGR);
	CreateNative("SC_CooldownRemaining",Native_SC_Cooldown_Remaining_Time);
	CreateNative("SC_CooldownReset",Native_SC_CooldownReset);
	CreateNative("SC_SkillNotInCooldown",Native_SC_Skill_Not_In_Cooldown);
	CreateNative("SC_PrintSkillIsNotReady",Native_SC_PrintSkillINR);
	
	
	CreateNative("SC_RegisterDelayTracker",Native_SC_RegisterDelayTracker);
	CreateNative("SC_TrackDelay",Native_SC_TrackDelay);
	CreateNative("SC_TrackDelayExpired",Native_SC_TrackDelayExpired);
	
	CreateNative("SC_SkillCooldownOnSpawn",Native_SC_SkillCooldownOnSpawn);
	g_CooldownExpiredForwardHandle=CreateGlobalForward("SC_OnCooldownSetup",ET_Ignore,Param_Cell,Param_Cell,Param_Cell);
	
	return true;
}


public Native_SC_RegisterDelayTracker(Handle:plugin,numParams)
{
	if(threadsLoaded<MAXTHREADS){
		return threadsLoaded++;
	}
	LogError("[SC_S Engine 1] DELAY TRACKER MAXTHREADS LIMIT REACHED! return -1");
	return -1;
}
public Native_SC_TrackDelay(Handle:plugin,numParams)
{
	new index=GetNativeCell(1);
	new Float:delay=GetNativeCell(2);
	expireTime[index]=GetEngineTime()+delay;
}
public Native_SC_TrackDelayExpired(Handle:plugin,numParams)
{
	return GetEngineTime()>expireTime[GetNativeCell(1)];
}
	
public Native_SC_SkillCooldownOnSpawn(Handle:plugin,numParams)
{
	new skillid=GetNativeCell(1);
	new Float:cooldowntime=GetNativeCell(2);
	new bool:print=GetNativeCell(3);
	CooldownOnSpawn[skillid]=true;
	CooldownSpawnPrintOnExpire[skillid]=print;
	CooldownOnSpawnDuration[skillid]=cooldowntime;
}

	
	
	
	
	
	
	

	
	
	
	

	
	
	
public Native_SC_CooldownMGR(Handle:plugin,numParams)
{
	
		new client = GetNativeCell(1);
		new Float:cooldownTime= GetNativeCell(2);
		new skillid = GetNativeCell(3);
		new bool:resetOnSpawn = GetNativeCell(4);
		new bool:printMsgOnExpireByTime = GetNativeCell(5);
		
		SC_SetVar(EventArg1,cooldownTime); //float
		SC_CreateEvent(On_SC_CooldownMGR,client); //fire event
		
		cooldownTime=Float:SC_GetVar(EventArg1);

		Internal_CreateCooldown(client,cooldownTime,skillid,resetOnSpawn,printMsgOnExpireByTime);
	
}
public Native_SC_Cooldown_Remaining_Time(Handle:plugin,numParams)
{
	if(numParams==2){
		new client = GetNativeCell(1);
		new skillid = GetNativeCell(2);
		
		new index=GetCooldownIndexByCRS(client,skillid);
		if(index>0){
			return RoundToCeil(Cooldown[index][cexpiretime]-GetEngineTime());
		}
		return _:0.0;
	}
	return -1;
}
public Native_SC_CooldownReset(Handle:plugin,numParams)
{
	if(numParams==2){
		new client = GetNativeCell(1);
		new skillid = GetNativeCell(2);
		CooldownResetByCRS(client,skillid);
	}
	return -1;
}
public Native_SC_Skill_Not_In_Cooldown(Handle:plugin,numParams) // skill available
{
	if(numParams>=2){
		new client = GetNativeCell(1);
		new skillid = GetNativeCell(2);
		new bool:printTextIfNotReady=false;
		if(numParams>2){
			printTextIfNotReady=GetNativeCell(3);
		}
		new bool:result= InternalIsSkillNotInCooldown(client,skillid);
		if(result==false&&printTextIfNotReady){
			Internal_PrintSkillNotAvailable(GetCooldownIndexByCRS(client,skillid));
			Internal_PrintSkillNotAvailable(GetCooldownIndexByCRS(client,skillid));
		}
		return result;
	}
	return -1;
}
public Native_SC_PrintSkillINR(Handle:plugin,numParams)
{
	if(numParams==2){
		new client = GetNativeCell(1);
		new skillid = GetNativeCell(2);
		
		
		Internal_PrintSkillNotAvailable(GetCooldownIndexByCRS(client,skillid)); //cooldown inc
	}
	return -1;
}
	
	
	
// not used?
//public OnClientPutInServer(client){
	
//}
		
ClearAllCooldowns()
{

			///we just dump the entire linked list
	for(new i=0;i<MAXCOOLDOWNS;i++){
		//we need to "unenable" aka free each cooldown
		Cooldown[i][cexpiretime]=0.0;
		
	}
	Cooldown[0][cnext]=0;
	
	
	for(new i=1;i<=MaxClients;i++)
	{
		for(new skillid=0;skillid< MAXSKILLS;skillid++)
		{
			CooldownPointer[i][skillid]=0;
		}
	}
}


Internal_CreateCooldown(client,Float:cooldownTime,skillid,bool:resetOnSpawn,bool:printMsgOnExpireByTime){

	new indextouse=-1;
	new bool:createlinks=true;
	if(CooldownPointer[client][skillid]>0){ //already has a cooldown
		indextouse=CooldownPointer[client][skillid];
		createlinks=false;
	}
	else{
		for(new i=1;i<MAXCOOLDOWNS;i++){
			if(Cooldown[i][cexpiretime]<1.0){ //consider this one empty
				indextouse=i;
				break;
				
			}
		}
	}
	/**********************
	 * this isliked a linked list
	 */	 	
	if(indextouse==-1){
		LogError("ERROR, UNABLE TO CREATE COOLDOWN");
	}
	else{
		if(createlinks){ //if u create links again and u are already link from the prevous person, u will infinite loop
		
			Cooldown[indextouse][cnext]=Cooldown[indextouse-1][cnext]; //this next is the previous guy's next
			Cooldown[indextouse-1][cnext]=indextouse; //previous guy points to you
		}
		
		Cooldown[indextouse][cexpiretime]=GetEngineTime()+cooldownTime;
		Cooldown[indextouse][cclient]=client;
		Cooldown[indextouse][cskill]=skillid;
		Cooldown[indextouse][cexpireonspawn]=resetOnSpawn;
		Cooldown[indextouse][cprintmsgonexpire]=printMsgOnExpireByTime;

		CooldownPointer[client][skillid]=indextouse;
	}
}
public Action:DeciSecondTimer(Handle:h,any:data){
	
	CheckCooldownsForExpired(false);
}
CheckCooldownsForExpired(bool:expirespawn,clientthatspawned=0)
{
	
	new Float:currenttime=GetEngineTime();
	new tempnext;
	new skippedfrom;
	
	new Handle:arraylist[MAXPLAYERSCUSTOM]; //hint messages will be attached to an arraylist
	
	for(new i=0;i<MAXCOOLDOWNS;i++){
		if(Cooldown[i][cexpiretime]>1.0) //enabled
		{
			new bool:expired;
			new bool:bytime;
			if(currenttime>Cooldown[i][cexpiretime]){
				expired=true;
				bytime=true;
			}
			else if(expirespawn&&Cooldown[i][cclient]==clientthatspawned&&Cooldown[i][cexpireonspawn]){
				expired=true;
			}
			
			
			if(expired)
			{
				//PrintToChatAll("EXPIRED");
				CooldownExpired(i, bytime);
				Cooldown[i][cexpiretime]=0.0;
				
				if(i>0){ //not front do some pointer changes, shouldnt be front anyway
					Cooldown[skippedfrom][cnext]=Cooldown[i][cnext];
					//PrintToChatAll("changing next at %d to %d",skippedfrom,Cooldown[i][cnext]);
					
					
				}
				
				//PrintToChatAll("CD expired %d %d %d",Cooldown[i][cclient],Cooldown[i][crace],Cooldown[i][cskill]);
				
				i=skippedfrom;
			}
			else{
				new client=Cooldown[i][cclient];
				//new skillid=Cooldown[i][cskill];
				new timeremaining=RoundToCeil(Cooldown[i][cexpiretime]-GetEngineTime());
				if(SC_GetSkill(client,mastery)==Cooldown[i][cskill] && timeremaining<=5 && Cooldown[i][cprintmsgonexpire]==true){
					
					if(arraylist[client]==INVALID_HANDLE){
						arraylist[client]=CreateArray(ByteCountToCells(128));
					}
					new String:str[128];
					new String:skillname[32];
					SC_GetSkillName(Cooldown[i][cskill],skillname,sizeof(skillname));
					Format(str,sizeof(str),"%s%s: %d",GetArraySize(arraylist[client])>0?"\n":"",skillname,timeremaining);
					PushArrayString(arraylist[client],str);
				}
				if(SC_GetSkill(client,talent)==Cooldown[i][cskill] && timeremaining<=5 && Cooldown[i][cprintmsgonexpire]==true){
					
					if(arraylist[client]==INVALID_HANDLE){
						arraylist[client]=CreateArray(ByteCountToCells(128));
					}
					new String:str[128];
					new String:skillname[64];
					SC_GetSkillName(Cooldown[i][cskill],skillname,sizeof(skillname));
					Format(str,sizeof(str),"%s%s: %d",GetArraySize(arraylist[client])>0?"\n":"",skillname,timeremaining);
					PushArrayString(arraylist[client],str);
				}
				if(SC_GetSkill(client,ability)==Cooldown[i][cskill] && timeremaining<=5 && Cooldown[i][cprintmsgonexpire]==true){
					
					if(arraylist[client]==INVALID_HANDLE){
						arraylist[client]=CreateArray(ByteCountToCells(128));
					}
					new String:str[128];
					new String:skillname[64];
					SC_GetSkillName(Cooldown[i][cskill],skillname,sizeof(skillname));
					Format(str,sizeof(str),"%s%s: %d",GetArraySize(arraylist[client])>0?"\n":"",skillname,timeremaining);
					PushArrayString(arraylist[client],str);
				}
				if(SC_GetSkill(client,ultimate)==Cooldown[i][cskill] && timeremaining<=5 && Cooldown[i][cprintmsgonexpire]==true){
					
					if(arraylist[client]==INVALID_HANDLE){
						arraylist[client]=CreateArray(ByteCountToCells(128));
					}
					new String:str[128];
					new String:skillname[64];
					SC_GetSkillName(Cooldown[i][cskill],skillname,sizeof(skillname));
					Format(str,sizeof(str),"%s%s: %d",GetArraySize(arraylist[client])>0?"\n":"",skillname,timeremaining);
					PushArrayString(arraylist[client],str);
				}
			}
		}
		tempnext=Cooldown[i][cnext];
	
		if(tempnext==0){
			//PrintToChatAll("DeciSecondTimer break because next is zero at index %d",i);
			break;
		}	
		skippedfrom=i;
		i=tempnext-1; //i will increment, decremet it first here
	}
	static bool:cleared[MAXPLAYERSCUSTOM];
	for(new client=1;client<=MaxClients;client++){
	
		if(arraylist[client]){
			new Handle:array=arraylist[client];
			new String:str[128];
			new String:newstr[128];
			new size=GetArraySize(array);
			for(new i=0;i<size;i++){
				GetArrayString(array,i,newstr,sizeof(newstr));
				StrCat(str,sizeof(str),newstr);
			}
			SC_Hint(client,HINT_COOLDOWN_COUNTDOWN,4.0,str);
			CloseHandle(arraylist[client]);
			arraylist[client]=INVALID_HANDLE;
			cleared[client]=false;
		}
		else{
			if(cleared[client]==false){
				cleared[client]=true;
				SC_Hint(client,HINT_COOLDOWN_COUNTDOWN,0.0,"");//CLEAR IT , so we dont have "ready" and "cooldown" of same skill at same time
			}
		}
	}
}


CooldownResetByCRS(client,skillid){
	if(CooldownPointer[client][skillid]>0){
		Cooldown[CooldownPointer[client][skillid]][cexpiretime]=GetEngineTime(); ///lol
	}
}
CooldownExpired(i,bool:expiredByTimer)
{	
	new client=Cooldown[i][cclient]
	new skillid=Cooldown[i][cskill];
	CooldownPointer[client][skillid]=-1;

	if(expiredByTimer){
		if(ValidPlayer(client,true)&&Cooldown[i][cprintmsgonexpire]){ //if still the same race and alive
			new String:skillname[64];
			SC_GetSkillName(skillid,skillname,sizeof(skillname));
			//{ultimate} is just an argument, we fill it in with skillname
			new String:str[128];
			Format(str,sizeof(str),"%s Is Ready",skillname); //ultimate
			SC_Hint(client,HINT_COOLDOWN_EXPIRED,4.0,str);
			SC_Hint(client,HINT_COOLDOWN_NOTREADY,0.0,""); //if something is ready, force erase the not ready
		
			EmitSoundToAll( SC_IsSkillUltimate(skillid)?ultimateReadySound:abilityReadySound , client);
		}
	}

	Call_StartForward(g_CooldownExpiredForwardHandle);
	Call_PushCell(client);
	Call_PushCell(skillid);
	Call_PushCell(expiredByTimer);
	new result;
	Call_Finish(result); //this will be returned to ?
	
	//DP("expired");
}


public bool:InternalIsSkillNotInCooldown(client,skillid){
	new index=GetCooldownIndexByCRS(client,skillid);
	if(index>0){
		return false; //has record = in cooldown
	}
	return true; //no cooldown record
}
GetCooldownIndexByCRS(client,skillid){
	
	return CooldownPointer[client][skillid];

}

public Internal_PrintSkillNotAvailable(cooldownindex){
	new client=Cooldown[cooldownindex][cclient];
	new skill=Cooldown[cooldownindex][cskill];
	if(ValidPlayer(client,true)){
		new String:skillname[64];
		SC_GetSkillName(skill,skillname,sizeof(skillname));
		//DP("%s Is Not Ready. %d Seconds Remaining",skillname,SC_CooldownRemaining(client,skill));
		SC_Hint(client,HINT_COOLDOWN_NOTREADY,2.5,"%s Is Not Ready. %d Seconds Remaining",skillname,SC_CooldownRemaining(client,skill));

	}
}

public On_SC_EventSpawn(client){
	

	CheckCooldownsForExpired(true,client)
	new mastery_skillid=SC_GetSkill(client,mastery);
	new talent_skillid=SC_GetSkill(client,talent);
	new ability_skillid=SC_GetSkill(client,ability);
	new ultimate_skillid=SC_GetSkill(client,ultimate);
	if(CooldownOnSpawn[mastery_skillid]){ //only his race
		Internal_CreateCooldown(client,CooldownOnSpawnDuration[mastery_skillid],mastery_skillid,false,CooldownSpawnPrintOnExpire[mastery_skillid]);
	}
	if(CooldownOnSpawn[talent_skillid]){ //only his race
		Internal_CreateCooldown(client,CooldownOnSpawnDuration[talent_skillid],mastery_skillid,false,CooldownSpawnPrintOnExpire[talent_skillid]);
	}
	if(CooldownOnSpawn[ability_skillid]){ //only his race
		Internal_CreateCooldown(client,CooldownOnSpawnDuration[ability_skillid],ability_skillid,false,CooldownSpawnPrintOnExpire[ability_skillid]);
	}
	if(CooldownOnSpawn[ultimate_skillid]){ //only his race
		Internal_CreateCooldown(client,CooldownOnSpawnDuration[ultimate_skillid],mastery_skillid,false,CooldownSpawnPrintOnExpire[ultimate_skillid]);
	}
}
