#pragma dynamic 10000
#pragma semicolon 1
#include <sourcemod>
#include "SkillCraft_Includes/SkillCraft_Interface"
//#include "SkillCraft_Includes/SkillCraft_forwards2"

public Plugin:myinfo = 
{
	name = "SkillCraft - Engine - Skills",
	author = "SkillCraft Team",
	description = "Information about skills"
};

new totalSkillsLoaded=0;  //USE skillid=1;skillid<=SC_GetSkillsLoaded();skillid++ for looping


//SKILLS zeroth skill is NOT  used
new String:skill_Name[MAXSKILLS][32];
new String:skill_Shortname[MAXSKILLS][16];
new String:skill_Description[MAXSKILLS][512];

//used in translations (SkillCraft has no translations file)
//new skill_SkillDescReplaceNum[MAXSKILLS];
//new String:skill_DescReplace[MAXSKILLS][5][64]; ///MAX 5 params for replacement //64 string length

new bool:SkillIsMastery[MAXSKILLS];
new bool:SkillIsTalent[MAXSKILLS];
new bool:SkillIsAbility[MAXSKILLS];
new bool:SkillIsUltimate[MAXSKILLS];

new skillCell[MAXSKILLS][ENUM_SkillObject];

new AccessFlagCvar[MAXSKILLS];
new SkillOrderCvar[MAXSKILLS];
new SkillFlagsCvar[MAXSKILLS];
new RestrictItemsCvar[MAXSKILLS];
new RestrictLimitCvar[MAXSKILLS][2];

// forwards
new Handle:g_On_SC_PluginReadyHandle; //loadin default skills in order
new Handle:g_On_SC_PluginReadyHandle2; 
//new Handle:g_OnWar3PluginReadyHandle3; //other skills backwards compatable
//new Handle:g_OnWar3PluginReadyHandle4;

// El Diablo's Quick Map change
new Handle:hCvarLoadSkillsOnMapStart;
new bool:sc_SkillsLoaded=false;


//SkillCount[skillid]

public OnPluginStart()
{
	PrintToServer("SkillCraft OnPluginStart Engine Skill Creation");
	hCvarLoadSkillsOnMapStart=CreateConVar("sc_Load_skills_every_map","1","0 = Disable | 1 = Enable, May help speed up map changes if disabled.");
	RegAdminCmd("sc_getskilllist",Cmdskilllist,ADMFLAG_KICK);
}

public bool:Init_SC_NativesForwards()
{
	//g_OnWar3PluginReadyHandle3=CreateGlobalForward("On_SC_PluginReady",ET_Ignore); //unodered rest of the items or races. backwards compatable..
	//g_OnWar3PluginReadyHandle4=CreateGlobalForward("OnWar3PluginRaceId",ET_Ignore,Param_Cell); //Used to send plugin RACE ID before it calls plugin to load itself	
	g_On_SC_PluginReadyHandle=CreateGlobalForward("On_SC_LoadSkillOrdered",ET_Ignore,Param_Cell);//ordered
	g_On_SC_PluginReadyHandle2=CreateGlobalForward("On_SC_LoadSkillOrdered2",ET_Ignore,Param_Cell,Param_Cell);//ordered
 
	//War3Source_InitForwards2();

	// Reloading Races does not seem to work for translated races.
	//CreateNative("SC_RaceOnPluginStart",NSC_RaceOnPluginStart);
	//CreateNative("SC_RaceOnPluginEnd",NSC_RaceOnPluginEnd);
	//CreateNative("SC_IsRaceReloading",NSC_IsRaceReloading);

	CreateNative("SC_CreateNewSkill",Native_SC_CreateNewSkill);
	CreateNative("SC_GetSkillsLoaded",Native_SC_GetSkillsLoaded);

	CreateNative("SC_GetSkillName",Native_SC_GetSkillName);
	CreateNative("SC_GetSkillShortname",Native_SC_GetSkillShortname);
	CreateNative("SC_GetSkillIDByShortname",Native_SC_GetSkillIDByShortname);
	
	CreateNative("SC_GetSkillDesc",Native_SC_GetSkillDesc);

	CreateNative("SC_GetSkillOrder",Native_SC_GetSkillOrder);
	CreateNative("SC_SkillHasFlag",Native_SC_SkillHasFlag);
	
	CreateNative("SC_GetSkillAccessFlagStr",Native_SC_GetSkillAccessFlagStr);
	CreateNative("SC_GetSkillItemRestrictionsStr",Native_SC_GetSkillItemRestrictionsStr);
	CreateNative("SC_GetSkillMaxLimitTeam",Native_SC_GetSkillMaxLimitTeam);
	CreateNative("SC_GetSkillMaxLimitTeamCvar",Native_SC_GetSkillMaxLimitTeamCvar);
	
	CreateNative("SC_GetSkillList",Native_SC_GetSkillList);
	
	CreateNative("SC_GetSkillCell",Native_SC_GetSkillCell);
	CreateNative("SC_SetSkillCell",Native_SC_SetSkillCell);

	CreateNative("SC_GetSkillType",Native_SC_GetSkillSkillType);

	CreateNative("SC_IsSkillMastery",Native_SC_IsSkillMastery);
	CreateNative("SC_IsSkillTalent",Native_SC_IsSkillTalent);
	CreateNative("SC_IsSkillAbility",Native_SC_IsSkillAbility);
	CreateNative("SC_IsSkillUltimate",Native_SC_IsSkillUltimate);
	
	//RegPluginLibrary("SkillClass");

	return true;
}

public OnMapStart()
{
    if(GetConVarBool(hCvarLoadSkillsOnMapStart))
    {
        Load_SC_Skills();
        sc_SkillsLoaded=true;
    } else if(!sc_SkillsLoaded)
    {
        Load_SC_Skills();
        sc_SkillsLoaded=true;
    }
}

Load_SC_Skills()
{	

	PrintToServer("SKILLS LOADING");
	new Float:starttime=GetEngineTime();

	new res;
	//orderd loads
	PrintToServer("Loading regular skills...");
	for(new i;i<=MAXSKILLS*10;i++)
	{
		Call_StartForward(g_On_SC_PluginReadyHandle);
		Call_PushCell(i);
		Call_Finish(res);
		//if(res>-1)
		//{
			//PrintToServer("Skill %d Loaded",i);
		//}
	}
	
	PrintToServer("Loading reloadable skills...");
	for(new i;i<=MAXSKILLS*10;i++)
	{
		Call_StartForward(g_On_SC_PluginReadyHandle2);
		Call_PushCell(i);
		Call_PushCell(-1);  //For future Skille Reloading
		Call_Finish(res);
		//if(res>-1)
		//{
			//PrintToServer("Skill %d Loaded",i);
		//}
	}
	PrintToServer("SKILLS LOADING FINISHED IN %.2f seconds",GetEngineTime()-starttime);	
}


bool:SkillExistsByShortname(String:shortname[]){
	new String:buffer[16];
	
	new SkillsLoaded = SC_GetSkillsLoaded();
	for(new skillid=1;skillid<=SkillsLoaded;skillid++){
		GetSkillShortname(skillid,buffer,sizeof(buffer));
		if(StrEqual(shortname, buffer, false)){
			return true;
		}
	}
	return false;
}

public Native_SC_GetSkillIDByShortname(Handle:plugin,numParams)
{
	new String:short_lookup[16];
	GetNativeString(1,short_lookup,sizeof(short_lookup));
	new SkillsLoaded = SC_GetSkillsLoaded();
	for(new x=1;x<=SkillsLoaded;x++)
	{
		
		new String:short_name[16];
		SC_GetSkillShortname(x,short_name,sizeof(short_name));
		if(StrEqual(short_name,short_lookup,false))
		{
			return x;
		}
	}
	return 0;
}


public Native_SC_GetSkillAccessFlagStr(Handle:plugin,numParams)
{
	new String:buffer[32];

	new skill_id=GetNativeCell(1);
	SC_GetCvar(AccessFlagCvar[skill_id],buffer,sizeof(buffer));
	SetNativeString(2,buffer,GetNativeCell(3));
	
}
public Native_SC_GetSkillOrder(Handle:plugin,numParams)
{
	new skillid=GetNativeCell(1);
	//DP("getskillorder skill %d cvar %d",skillid,SkillOrderCvar[skillid]);
	return SC_GetCvarInt(SkillOrderCvar[skillid]);
	
}
public Native_SC_SkillHasFlag(Handle:plugin,numParams)
{
	new skill_id=GetNativeCell(1);
	new String:buffer[1000];
	SC_GetCvar(SkillFlagsCvar[skill_id],buffer,sizeof(buffer));
	
	new String:flagsearch[32];
	GetNativeString(2,flagsearch,sizeof(flagsearch));
	return (StrContains(buffer,flagsearch)>-1);
}


/*
public Native_SC_GetSkillList(Handle:plugin,numParams){

	new listcount=0;
	new SkillsLoaded = SC_GetSkillsLoaded();
	new Handle:hdynamicarray=CreateArray(1); //1 cell

	for(new skillid=1;skillid<=SkillsLoaded;skillid++){
		
		if(!SC_SkillHasFlag(skillid,"hidden")){
		//	DP("not hidden %d",skillid);
			PushArrayCell(hdynamicarray, skillid);
			listcount++;
		}
		else{
		//	DP("hidden %d",skillid);
		}
	}
	new skilllist[MAXSKILLS];
	new Handle:result=MergeSort(hdynamicarray); //closes hdynamicarray
	for(new i=0;i<listcount;i++){
		skilllist[i]=GetArrayCell(result, i);
	}
	printArray("",result); 
	PrintToServer("result array size %d/%d", GetArraySize(result),SC_GetSkillsLoaded());
	CloseHandle(result);

	SetNativeArray(1, skilllist, MAXSKILLS);
	return listcount;
}
*/

public Native_SC_GetSkillList(Handle:plugin,numParams){
	new listcount=0;
	new SkillsLoaded = SC_GetSkillsLoaded();
	new Handle:skillsAvailable = CreateArray(1); //1 cell
	
	for(new skillid = 1; skillid <= SkillsLoaded; skillid++){
		
		if(!SC_SkillHasFlag(skillid,"hidden"))
		{
			PushArrayCell(skillsAvailable, skillid);
			listcount++;
		}
	}
	new skilllist[MAXSKILLS];
	SortADTArrayCustom(skillsAvailable, SortSkillsBySkillOrder,skillsAvailable);
	for(new i = 0; i < listcount; i++)
	{
		skilllist[i] = GetArrayCell(skillsAvailable, i);
	}
	CloseHandle(skillsAvailable);
	
	SetNativeArray(1, skilllist, MAXSKILLS);
	return listcount;
}

public Native_SC_GetSkillItemRestrictionsStr(Handle:plugin,numParams)
{

	new skill_id=GetNativeCell(1);
	new String:buffer[64];
	SC_GetCvar(RestrictItemsCvar[skill_id],buffer,sizeof(buffer));
	SetNativeString(2,buffer,GetNativeCell(3));
}

public Native_SC_GetSkillMaxLimitTeam(Handle:plugin,numParams)
{
	new skill_id=GetNativeCell(1);
	if(skill_id>0){
		
		new team=GetNativeCell(2);
		if(team==TEAM_T||team==TEAM_RED){
			return SC_GetCvarInt(RestrictLimitCvar[skill_id][0]);
		}
		if(team==TEAM_CT||team==TEAM_BLUE){
			return SC_GetCvarInt(RestrictLimitCvar[skill_id][1]);
		}
	}
	return 99;
}
public Native_SC_GetSkillMaxLimitTeamCvar(Handle:plugin,numParams)
{
	new skill_id=GetNativeCell(1);
	if(skill_id>0){
		
		new team=GetNativeCell(2);
		if(team==TEAM_T||team==TEAM_RED){
			return RestrictLimitCvar[skill_id][0];
		}
		if(team==TEAM_CT||team==TEAM_BLUE){
			return RestrictLimitCvar[skill_id][1];
		}
	}
	return -1;
}
public Native_SC_SetSkillCell(Handle:plugin,numParams){
	return skillCell[GetNativeCell(1)][GetNativeCell(2)]=GetNativeCell(3);
}
public Native_SC_GetSkillCell(Handle:plugin,numParams){
	return skillCell[GetNativeCell(1)][GetNativeCell(2)];
}


GetSkillName(skillid,String:retstr[],maxlen){
	new num=strcopy(retstr, maxlen, skill_Name[skillid]);
	return num;
}
GetSkillShortname(skillid,String:retstr[],maxlen){
	new num=strcopy(retstr, maxlen, skill_Shortname[skillid]);
	return num;
}

GetSkillDesc(skillid,String:retstr[],maxlen){
	new num=strcopy(retstr, maxlen, skill_Description[skillid]);
	return num;
}

public Native_SC_GetSkillName(Handle:plugin,numParams)
{
	new skill=GetNativeCell(1);
	new bufsize=GetNativeCell(2);
	if(skill>-1 && skill<=SC_GetSkillsLoaded()) //allow "No Skill"
	{
		new String:skill_name[32];
		GetSkillName(skill,skill_name,sizeof(skill_name));
		SetNativeString(2,skill_name,bufsize);
	}
}
public Native_SC_GetSkillShortname(Handle:plugin,numParams)
{
	new skill=GetNativeCell(1);
	new bufsize=GetNativeCell(2);
	if(skill>=1 && skill<=SC_GetSkillsLoaded())
	{
		new String:skill_shortname[16];
		GetSkillShortname(skill,skill_shortname,sizeof(skill_shortname));
		SetNativeString(2,skill_shortname,bufsize);
	}
}
public Native_SC_GetSkillDesc(Handle:plugin,numParams)
{
	new skill_id=GetNativeCell(1);
	new maxlen=GetNativeCell(3);
	
	new String:longbuf[1000];
	GetSkillDesc(skill_id,longbuf,sizeof(longbuf));
	SetNativeString(2,longbuf,maxlen);
}

public Native_SC_GetSkillsLoaded(Handle:plugin,numParams){
	return totalSkillsLoaded;
}
IsSkillMastery(skillid){
	return SkillIsMastery[skillid];
}
IsSkillTalent(skillid){
	return SkillIsTalent[skillid];
}
IsSkillAbility(skillid){
	return SkillIsAbility[skillid];
}
IsSkillUltimate(skillid){
	return SkillIsUltimate[skillid];
}



public Native_SC_IsSkillMastery(Handle:plugin,numParams)
{
	return IsSkillMastery(GetNativeCell(1));
}

public Native_SC_IsSkillTalent(Handle:plugin,numParams)
{
	return IsSkillTalent(GetNativeCell(1));
}

public Native_SC_IsSkillAbility(Handle:plugin,numParams)
{
	return IsSkillAbility(GetNativeCell(1));
}

public Native_SC_IsSkillUltimate(Handle:plugin,numParams)
{
	return IsSkillUltimate(GetNativeCell(1));
}
public Native_SC_GetSkillSkillType(Handle:plugin,numParams)
{
	new skillid=GetNativeCell(1);
	if(IsSkillMastery(skillid))
		return _:mastery;
	
	if(IsSkillTalent(skillid))
		return _:talent;
	
	if(IsSkillAbility(skillid))
		return _:ability;
	
	if(IsSkillUltimate(skillid))
		return _:ultimate;	
		
	return _:didnotfindskill;
}






CreateNewSkill(String:variable_skill_longname[],String:variable_skill_shortname[],String:variable_skill_description[],SKILLTYPE:typeofskill)
{

	if(SkillExistsByShortname(variable_skill_shortname)){
		new oldskillid=SC_GetSkillIDByShortname(variable_skill_shortname);
		PrintToServer("Skill already exists: %s, returning old skillid %d",variable_skill_shortname,oldskillid);
		return oldskillid;
	}
	
	if(totalSkillsLoaded+1==MAXSKILLS){ //make sure we didnt reach our race capacity limit
		LogError("MAX SKILLS REACHED, CANNOT REGISTER %s %s",variable_skill_longname,variable_skill_shortname);
		return 0;
	}
	
	//first skill registering, fill in the  zeroth race along
	if(totalSkillsLoaded==0){
		Format(skill_Name[0],31,"NO SKILL DEFINED %d",0);
		Format(skill_Shortname[0],15,"NO SKILL DEFINED %d",0);
		Format(skill_Description[0],511,"NO SKILL DESCRIPTION DEFINED %d",0);
	}

	totalSkillsLoaded++;
	new tskillid=totalSkillsLoaded;
	
	//make all skills zero so we can easily debug
	Format(skill_Name[tskillid],31,"NO SKILL DEFINED %d",0);
	Format(skill_Shortname[tskillid],15,"NO SKILL DEFINED %d",0);
	Format(skill_Description[tskillid],511,"NO SKILL DESCRIPTION DEFINED %d",0);
	
	strcopy(skill_Name[tskillid], 31, variable_skill_longname);
	strcopy(skill_Shortname[tskillid], 15, variable_skill_shortname);
	strcopy(skill_Description[tskillid], 511, variable_skill_description);
	PrintToServer("Create New Skill - Skill id: %d",tskillid);
	
	PrintToServer("Create New Skill long name  : %s",variable_skill_longname);
	PrintToServer("Create New Skill short name : %s",variable_skill_shortname);
	PrintToServer("Create New Skill description: %s",variable_skill_description);
	
	// DEFINES TYPE OF SKILL
	
	// CREATE NEW SKILL CVAR INFO
	new String:cvarstr[64];

	switch(typeofskill)
	{
		
		case mastery:
		{
			SkillIsMastery[tskillid]=true;
			
			//PrintToServer("Create New Skill - %s is Mastery",variable_skill_shortname);
		}
		case talent:
		{
			SkillIsTalent[tskillid]=true;

			//PrintToServer("Create New Skill - %s is Talent",variable_skill_shortname);
		}
		case ability:
		{
			SkillIsAbility[tskillid]=true;

			//PrintToServer("Create New Skill - %s is Ability",variable_skill_shortname);
		}
		case ultimate:
		{
			SkillIsUltimate[tskillid]=true;

			//PrintToServer("Create New Skill - %s is Ultimate",variable_skill_shortname);
		}
	}

	//We remove all dependencys(atm there aren't any but we need to call this to apply our default value)
	PrintToServer("Need to add Skill Dependency stuff sometime");
	PrintToServer("SC_RemoveDependency temporary commented out within Skill Creation.sp");
	//SC_RemoveDependency(tskillid);
	

	Format(cvarstr,sizeof(cvarstr),"%s_accessflag",variable_skill_shortname);
	AccessFlagCvar[tskillid]=SC_CreateCvar(cvarstr,"0","Admin access flag required for skill",false);

	Format(cvarstr,sizeof(cvarstr),"%s_skillorder",variable_skill_shortname);
	new String:buf[16];
	Format(buf,sizeof(buf),"%d",tskillid*100);
	SkillOrderCvar[tskillid]=SC_CreateCvar(cvarstr,buf,"This skill's Skill Order on changeskill menu",false);

	Format(cvarstr,sizeof(cvarstr),"%s_flags",variable_skill_shortname);
	SkillFlagsCvar[tskillid]=SC_CreateCvar(cvarstr,"","This skill's flags, ie 'hidden,etc",false);

	Format(cvarstr,sizeof(cvarstr),"%s_team%d_limit",variable_skill_shortname,1);
	RestrictLimitCvar[tskillid][0]=SC_CreateCvar(cvarstr,"99","How many people can play this skill on team 1 (RED/T)",false);
	Format(cvarstr,sizeof(cvarstr),"%s_team%d_limit",variable_skill_shortname,2);
	RestrictLimitCvar[tskillid][1]=SC_CreateCvar(cvarstr,"99","How many people can play this skill on team 2 (BLU/CT)",false);

	new temp;
	Format(cvarstr,sizeof(cvarstr),"%s_restrictclass",variable_skill_shortname);
	temp=SC_CreateCvar(cvarstr,"","Which classes are not allowed to play this skill? Separate by comma. MAXIMUM OF 2!! list: scout,sniper,soldier,demoman,medic,heavy,pyro,spy,engineer",false);
	SC_SetSkillCell(tskillid,ClassRestrictionCvar,temp);
			
	Format(cvarstr,sizeof(cvarstr),"%s_category",variable_skill_shortname);
	SC_SetSkillCell(tskillid,SkillCategorieCvar,SC_CreateCvar(cvarstr,"default","Determines in which Category the skill should be displayed(if cats are active)",false));

	return tskillid; //this will be the new skill's id / index
}

public Native_SC_CreateNewSkill(Handle:plugin,numParams)
{
	
	
	new String:name[64],String:shortname[16],String:skilldesc[512];
	GetNativeString(1,name,sizeof(name));
	GetNativeString(2,shortname,sizeof(shortname));
	GetNativeString(3,skilldesc,sizeof(skilldesc));
	new SKILLTYPE:typeofskill=SKILLTYPE:GetNativeCell(4);

	//native SC_CreateNewRace(String:skill_longname[],String:skill_shortname[],String:skill_description[],typeofskill);	
	return CreateNewSkill(name,shortname,skilldesc,SKILLTYPE:typeofskill);

}

/*
Handle:MergeSort(Handle:array){
	
	new len=GetArraySize(array);
	if(len==1){
		return array;
	}
	new cut=len/2;
	
	new Handle:smallerarrayleft=CreateArray(1,cut);
	new Handle:smallerarrayright=CreateArray(1,len-cut);
	
	for(new i=0;i<cut;i++){
		SetArrayCell(smallerarrayleft, i, GetArrayCell(array, i));
	
	}
	for(new i=cut;i<len;i++){
		SetArrayCell(smallerarrayright, i-cut, GetArrayCell(array, i ));
	
	}
	CloseHandle(array);
	
	
	new Handle:leftresult=	MergeSort(smallerarrayleft);
	new Handle:rightresult=	MergeSort(smallerarrayright);
	
	new Handle:resultarray=CreateArray(1,0);
	new index=0;
	while(GetArraySize(leftresult)>0&&GetArraySize(rightresult)>0){
		new leftval=SC_GetSkillOrder( GetArrayCell(leftresult, 0));
		new rightval=SC_GetSkillOrder( GetArrayCell(rightresult, 0));
		//PrintToServer("left %d vs right %d",leftval,rightval);
		
		if(leftval<=rightval){
			PushArrayCell(resultarray,-1); //add index 
			SetArrayCell(resultarray, index, GetArrayCell(leftresult, 0));
		
			RemoveFromArray(leftresult, 0);
			
			//printArray("took left" ,resultarray);
		}
		else{
			PushArrayCell(resultarray,-1); //add index 
			SetArrayCell(resultarray, index, GetArrayCell(rightresult, 0));
		
			RemoveFromArray(rightresult, 0);
			//printArray("took right" ,resultarray);
		}
		index++;
	}
	
	new bool:closeleft,bool:closeright;
	if(GetArraySize(leftresult)>0){ 
		resultarray=append(resultarray,leftresult);
		closeright=true;
	}
	else if(GetArraySize(rightresult)>0){ 
		resultarray=append(resultarray,rightresult);
		closeleft=true;
	}
	
	
	if(closeleft){
		CloseHandle(leftresult);
	}
	if(closeright){
		CloseHandle(rightresult);
	}

	return resultarray;
	
}
Handle:append(Handle:leftarr,Handle:rightarr){
	new leftindex=GetArraySize(leftarr);
	new rigthlen=GetArraySize(rightarr);
	
	for(new i=0;i<rigthlen;i++){
		//append right
		PushArrayCell(leftarr,-1); //add index to left
		SetArrayCell(leftarr, leftindex, GetArrayCell(rightarr, 0));
	
		RemoveFromArray(rightarr, 0);
		leftindex++;
	}
	CloseHandle(rightarr);
	//printArray("appended" ,leftarr);
	return leftarr;
}
stock printArray(String:prepend[]="",Handle:arr){
	new len=GetArraySize(arr);
	new String:print[100];
	Format(print,sizeof(print),"%s {",prepend);
	for(new i=0;i<len;i++){
		Format(print,sizeof(print),"%s %d",print,GetArrayCell(arr,i));
	}
	Format(print,sizeof(print),"%s}",print);
	PrintToServer(print);
}

stock SkillNameSearch(String:changeraceArg[64])
{
		new String:sSkillName[64];
		new SkillsLoaded=War3_SC_GetSkillsLoaded();
		new skill_id=0;
		//full name
		for(skill_id=1;skill_id<=SkillsLoaded;skill_id++)
		{
			War3_GetSkillName(skill_id,sSkillName,sizeof(sSkillName));
			if(StrContains(sSkillName,changeraceArg,false)>-1){
				return skill_id;
			}
		}
		//shortname // checks inside of for() for raceFound==
		for(skill_id=1;skill_id<=SkillsLoaded;skill_id++)
		{
			War3_GetSkillShortname(skill_id,sSkillName,sizeof(sSkillName));
			if(StrContains(sSkillName,changeraceArg,false)>-1){
				return skill_id;
			}
		}
		return -1;
}
*/

public Action:Cmdskilllist(client,args){
	new SkillsLoaded = SC_GetSkillsLoaded();
	PrintToServer("SkillsLoaded: %d",SkillsLoaded);
	new String:LongSkillName[64];
	for(new x=1;x<=SkillsLoaded;x++)
	{
		SC_GetSkillName(x,LongSkillName,64);
		SC_ChatMessage(client,"SkillCraft List [Debug]: %s Skill ID: %i",LongSkillName,x);
		PrintToServer("SkillCraft List [Debug]: %s Skill ID: %i",LongSkillName,x);
	}
	return Plugin_Handled;
}

//return -1 if race1 < race2 race1 earlier on list
//return 1 if race1 > race2 race1 later on the list
//higher order means later in the menu
public SortSkillsBySkillOrder(index1, index2, Handle:skills, Handle:hndl_optional)
{
    //BLAME: Necavi / glider
    //callback passes indexes, not races dude!
    new skill1=GetArrayCell(skills,index1);
    new skill2=GetArrayCell(skills,index2);
    
    if(skill1 > 0 && skill2 > 0 )
    {
        //race order is the cvar <race>_raceorder
        new order1 = SC_GetSkillOrder(skill1);
        new order2 = SC_GetSkillOrder(skill2);
        if(order1 < order2)
        {
            return -1;
        }
        else if(order2 < order1)
        {
            return 1;
        }
    }
    return 0; //tie
}
