////BUFF SYSTEM

#pragma semicolon 1

#include <sourcemod>
#include "sdkhooks"
#include "SkillCraft_Includes/SkillCraft_Interface"


//for debuff index, see constants, its in an enum
new any:buffdebuff[MAXPLAYERSCUSTOM][SC_Buff][MAXSKILLS+CUSTOMMODIFIERS]; ///a race may only modify a property once

new BuffProperties[SC_Buff][SC_BuffProperties];

new any:BuffCached[MAXPLAYERSCUSTOM][SC_Buff];// instead of looping, we cache everything in the last dimension, see enum SC_BuffCache

public Plugin:myinfo= 
{
	name="SkillCraft Buff System",
	author="SkillCraft Team",
	description="SkillCraft Core Plugins",
	version="1.0",
};



public OnPluginStart()
{
	InitiateBuffPropertiesArray(BuffProperties);
	
	//RegConsoleCmd("bufflist",cmdbufflist);
}

public bool:Init_SC_NativesForwards()
{
	
	CreateNative("SC_SetBuff",Native_SC_SetBuff);//for skills

	CreateNative("SC_ShowBuffs",Native_SC_ShowBuffs);//foritems
	CreateNative("SC_ShowSpeedBuff",Native_SC_ShowSpeedBuff);//foritems
	

	CreateNative("SC_BuffCustomOFFSET",Native_SC_BuffCustomOFFSET);
	
	CreateNative("SC_GetPhysicalArmorMulti",Native_SC_GetPhysicalArmorMulti);
	CreateNative("SC_GetMagicArmorMulti",Native_SC_GetMagicArmorMulti);
	
	
	CreateNative("SC_GetBuff",Native_SC_GetBuff);
	CreateNative("SC_GetBuffSumInt",Native_SC_GetBuffSumInt);
	CreateNative("SC_GetBuffHasTrue",Native_SC_GetBuffHasTrue);
	CreateNative("SC_GetBuffStackedFloat",Native_SC_GetBuffStackedFloat);
	
	CreateNative("SC_GetBuffSumFloat",Native_SC_GetBuffSumFloat);
	CreateNative("SC_GetBuffMinFloat",Native_SC_GetBuffMinFloat);
	CreateNative("SC_GetBuffMaxFloat",Native_SC_GetBuffMaxFloat);
	
	CreateNative("SC_GetBuffMinInt",Native_SC_GetBuffMinInt);
	CreateNative("SC_GetBuffLastValue",Native_SC_GetBuffLastValue);
	
	CreateNative("SC_ResetAllBuffSkill",Native_SC_ResetAllBuffSkill);
	CreateNative("SC_ResetBuffSkill",Native_SC_ResetBuffSkill);
	
	CreateNative("SC_GetBuffLoopLimit",Native_SC_GetBuffLoopLimit);
	return true;
}
SkillsLoaded(){
	return SC_GetSkillsLoaded()+CUSTOMMODIFIERS;
}
public Native_SC_BuffCustomOFFSET(Handle:plugin,numParams)
{
	return SC_GetSkillsLoaded();
}
public Native_SC_ShowBuffs(Handle:plugin,numParams) //buff is from an item
{
	if(numParams==1) //client,skill,buffindex,value
	{
		new client=GetNativeCell(1);
		if(!IsFakeClient(client))
		{
			ShowAttackSpeed(client);
			ShowArmorMagic(client);
			ShowArmorPhysical(client);
			ShowInvisBuff(client);
			ShowRegenBuff(client);
			ShowVampireBuff(client);
			ShowSpeedBuff(client,true);
		}
	}
}
// This is mainly part of the Cyborg Medic Job, as nothing else currently uses this buff information as a native:
public Native_SC_ShowSpeedBuff(Handle:plugin,numParams) //buff is from an item
{
	if(numParams==1) //client,skill,buffindex,value
	{
		new client=GetNativeCell(1);
		ShowSpeedBuff(client,true);
	}
}


public Native_SC_SetBuff(Handle:plugin,numParams)
{
	if(numParams==4) //client,skill,buffindex,value
	{
		new client=GetNativeCell(1);
		new SC_Buff:buffindex=GetNativeCell(2);
		new skillid=GetNativeCell(3);
		new any:value=GetNativeCell(4);
		SetBuff(client,buffindex,skillid,value); //ofsetted
		/*if(skillid==0){
		new String:buf[64];
		GetPluginFilename(plugin, buf, sizeof(buf));
		ThrowError("warning, war3_setbuff passed zero skillid %s",buf);
		}*/
	}
}
public Native_SC_GetBuff(Handle:plugin,numParams)
{
	
	new client=GetNativeCell(1);
	new SC_Buff:buffindex=GetNativeCell(2);
	new skillid=GetNativeCell(3);
	if(ValidBuff(buffindex)){
		return buffdebuff[client][buffindex][skillid];
	}
	else{
		ThrowError("invalidbuffindex");
	}
	return -1;
}
public Native_SC_GetBuffSumInt(Handle:plugin,numParams)
{
	new client=GetNativeCell(1);
	new SC_Buff:buffindex=GetNativeCell(2);
	return GetBuffSumInt(client,buffindex);
}

//stop complaining that we are returning a float!
public Native_SC_GetPhysicalArmorMulti(Handle:plugin,numParams) {
	return _:PhysicalArmorMulti(GetNativeCell(1));
}

public Native_SC_GetMagicArmorMulti(Handle:plugin,numParams) {
	
	return _:MagicArmorMulti(GetNativeCell(1));
}
public Native_SC_GetBuffLastValue(Handle:plugins,numParams) {
	return GetBuffLastValue(GetNativeCell(1),GetNativeCell(2));
}
public Native_SC_GetBuffHasTrue(Handle:plugin,numParams) {
	//all one true bools are cached
	return _:GetBuffHasOneTrue(GetNativeCell(1),GetNativeCell(2)); //returns bool
}
public Native_SC_GetBuffStackedFloat(Handle:plugin,numParams) {
	
	return _:GetBuffStackedFloat(GetNativeCell(1),GetNativeCell(2)); //returns float usually
}
public Native_SC_GetBuffSumFloat(Handle:plugin,numParams) {
	
	return _:GetBuffSumFloat(GetNativeCell(1),GetNativeCell(2)); 
}
public Native_SC_GetBuffMinFloat(Handle:plugin,numParams) {
	return _:GetBuffMinFloat(GetNativeCell(1),GetNativeCell(2)); 
}
public Native_SC_GetBuffMaxFloat(Handle:plugin,numParams) {
	return _:GetBuffMaxFloat(GetNativeCell(1),GetNativeCell(2)); 
}
public Native_SC_GetBuffMinInt(Handle:plugin,numParams) {
	return GetBuffMinInt(GetNativeCell(1),GetNativeCell(2)); 
}

public Native_SC_ResetAllBuffSkill(Handle:plugin,numParams) {
	new client=GetNativeCell(1);
	new skillid=GetNativeCell(2);
	
	
	for(new buffindex=0;buffindex<MaxBuffLoopLimit;buffindex++)
	{	
		
		ResetBuffParticularSkill(client,SC_Buff:buffindex,skillid);
	}
	//SOME NEEDS TO BE SET AGAIN TO REFRESH
	
}
public Native_SC_ResetBuffSkill(Handle:plugin,numParams) {
	new client=GetNativeCell(1);
	new SC_Buff:buffindex=SC_Buff:GetNativeCell(2);
	new skillid=GetNativeCell(3);
	
	ResetBuffParticularSkill(client,SC_Buff:buffindex,skillid);	
}
public Native_SC_GetBuffLoopLimit(Handle:plugin,numParams) {
	return BuffLoopLimit();
}



/*
public Action:cmdbufflist(client,args){
	
	if(args==1){
		new String:arg[32];
		GetCmdArg(1,arg,sizeof(arg));
		new int=StringToInt(arg);
		new ItemsLoaded = SC_GetItemsLoaded();
		new Skills = SC_GetSkillsLoaded();
		for(new i=1;i<=Skills;i++){
			new String:name[32];
			if(i<=ItemsLoaded){
				SC_GetItemShortname(i,name,sizeof(name));
			}
			else{
				SC_GetSkillShortname(i-ItemsLoaded,name,sizeof(name));
			}
			SC_Log("buff for client %d buffid %d : %d %f skill %s",client,int,buffdebuff[client][SC_Buff:int][i],buffdebuff[client][SC_Buff:int][i],name);
			
		}
	}
}
*/

public OnClientPutInServer(client){
	
	//reset all buffs for each skill and item
	for(new buffindex=0;buffindex<MaxBuffLoopLimit;buffindex++)
	{
		ResetBuff(client,SC_Buff:buffindex);
	}
	
	
	//SDKHook(client, SDKHook_PreThink, OnPreThink);
	//SDKHook(client, SDKHook_PostThinkPost, OnPreThink);
	//SDKHook(client,SDKHook_PostThinkPost,SDK_Forwarded_PostThinkPost);
}

//Float:GetOldSpeedFloat(client,SC_Buff:buffindex,skillindex)
//{
	//return Float:buffdebuff[client][buffindex][skillindex];
//}
//new Float:OldSpeedBuffValue[MAXPLAYERSCUSTOM];
new OldSpeedBuffValue2[MAXPLAYERSCUSTOM];
new bool:TimerSpeedBuff[MAXPLAYERSCUSTOM];
new any:Oldbuffdebuff[MAXPLAYERSCUSTOM][SC_Buff][MAXSKILLS+CUSTOMMODIFIERS];

SetBuff(client,SC_Buff:buffindex,skillindex,value)
{
	//PrintToServer("client %d buffindex %d skill %d value: %d %f",client,buffindex,skillindex,value,value);
	//new any:oldvalue=buffdebuff[client][buffindex][skillindex];
	
	// later add a PREBUFF EVENT
	//new Float:OldSpeed = GetOldSpeedFloat(client,buffindex,skillindex); 
	
	buffdebuff[client][buffindex][skillindex]=value;
	
	// later add a AFTER BUFF EVENT
	
	if(buffindex==fMaxSpeed||buffindex==fMaxSpeed2||buffindex==fSlow||buffindex==fSlow2||buffindex==bStunned||buffindex==bBashed){
		SC_ReapplySpeed(client); 
	}
	DoCalculateBuffCache(client,buffindex,skillindex);
	
	
	SC_SetVar(EventArg1,buffindex); //generic war3event arguments
	SC_SetVar(EventArg2,skillindex); 
	SC_SetVar(EventArg3,value); 
	//SC_CreateEvent(SC_EVENT:OnBuffChanged,client);		
	SC_CreateEvent(OnBuffChanged,client);		
	
	if(ValidPlayer(client) && IsFakeClient(client))
		return;

	//new Float:NewSpeed = Float:value;
	if(value==Oldbuffdebuff[client][buffindex][skillindex])
		return;
		
	// Tell client what's going on
	if(buffindex==fMaxSpeed||buffindex==fSlow||buffindex==fMaxSpeed2||buffindex==fSlow2)
	{
		//SC_ChatMessage(client,"Buff value old %f new %f",OldSpeedBuffValue[client],NewSpeed);
		//if(value==Oldbuffdebuff[client][buffindex][skillindex] && TimerSpeedBuff[client]==true)
			//return;
		if(TimerSpeedBuff[client]==true)
			return;
		TimerSpeedBuff[client]=true;
		if(ValidPlayer(client) && SC_GetPlayerProp(client,iBuffChatInfo2)==1)
		{
			CreateTimer(0.2,SpeedBuffTimer,GetClientUserId(client));
		}
		//OldSpeedBuffValue[client]=Float:value;
		Oldbuffdebuff[client][buffindex][skillindex]=value;
		return;
	}
	
	// Tell client what's going on
	if(buffindex==fInvisibilitySkill||buffindex==fInvisibilityItem)
	{
		if(ValidPlayer(client) && SC_GetPlayerProp(client,iBuffChatInfo2)==1)
		{
			CreateTimer(0.2,InvisibilityTimer,GetClientUserId(client));
		}		
		Oldbuffdebuff[client][buffindex][skillindex]=value;
		return;
	}
	
	// Tell client what's going on
	if(buffindex==fArmorPhysical)
	{
		if(ValidPlayer(client) && SC_GetPlayerProp(client,iBuffChatInfo2)==1)
		{
			//SC_ChatMessage(client,"Buff value old %f\ncached %f\nnew %f",Float:Oldbuffdebuff[client][buffindex][skillindex],Float:BuffCached[client][buffindex],Float:value);
			CreateTimer(0.2,PhysicalArmorSpeedTimer,GetClientUserId(client));
		}
		Oldbuffdebuff[client][buffindex][skillindex]=value;
		return;
	}
	
	// Tell client what's going on
	if(buffindex==fArmorMagic)
	{
		if(ValidPlayer(client) && SC_GetPlayerProp(client,iBuffChatInfo2)==1)
		{
			//SC_ChatMessage(client,"Buff value old %f\ncached %f\nnew %f",Float:Oldbuffdebuff[client][buffindex][skillindex],Float:BuffCached[client][buffindex],Float:value);
			CreateTimer(0.2,MagicalArmorSpeedTimer,GetClientUserId(client));
		}
		Oldbuffdebuff[client][buffindex][skillindex]=value;
		return;
	}
	
	// Tell client what's going on
	if(buffindex==fAttackSpeed)
	{
		if(ValidPlayer(client) && SC_GetPlayerProp(client,iBuffChatInfo2)==1)
		{
			//SC_ChatMessage(client,"Buff value old %f\ncached %f\nnew %f",Float:Oldbuffdebuff[client][buffindex][skillindex],Float:BuffCached[client][buffindex],Float:value);
			CreateTimer(0.2,AttackSpeedTimer,GetClientUserId(client));
		}
		Oldbuffdebuff[client][buffindex][skillindex]=value;
		return;
	}

	if(buffindex==fHPRegen)
	{
		if(ValidPlayer(client) && SC_GetPlayerProp(client,iBuffChatInfo2)==1)
		{
			//SC_ChatMessage(client,"Buff value old %f\ncached %f\nnew %f",Float:Oldbuffdebuff[client][buffindex][skillindex],Float:BuffCached[client][buffindex],Float:value);
			CreateTimer(0.2,RegenSpeedTimer,GetClientUserId(client));
		}
		Oldbuffdebuff[client][buffindex][skillindex]=value;
		return;
	}
	
	if(buffindex==fVampirePercent)
	{
		if(ValidPlayer(client) && SC_GetPlayerProp(client,iBuffChatInfo2)==1)
		{
			//SC_ChatMessage(client,"Buff value old %f\ncached %f\nnew %f",Float:Oldbuffdebuff[client][buffindex][skillindex],Float:BuffCached[client][buffindex],Float:value);
			CreateTimer(0.2,VampireTimer,GetClientUserId(client));
		}
		Oldbuffdebuff[client][buffindex][skillindex]=value;
		return;
	}
}

ShowInvisBuff(client)
{
	if(ValidPlayer(client))
	{
		new Float:currentAttribute=FloatAdd(Float:BuffCached[client][fInvisibilitySkill],Float:BuffCached[client][fInvisibilityItem]);
		if(currentAttribute>1.0)
			currentAttribute=FloatSub(currentAttribute,1.0);
		else
			currentAttribute=FloatSub(1.0,currentAttribute);
		currentAttribute=currentAttribute*100.0;
		new percentage=RoundToFloor(currentAttribute);
		if(currentAttribute>0.0 && currentAttribute<100.0)
			SC_ChatMessage(client,"You are now {green}%i{default} percent visibile.",percentage);
		else //if(currentAttribute==0.0)
			SC_ChatMessage(client,"You are now {green}100{default} percent visibile.");
	}
}
ShowArmorPhysical(client)
{
	if(ValidPlayer(client))
	{
		new Float:currentAttribute=Float:BuffCached[client][fArmorPhysical];
		new percentage=RoundToFloor(FloatMul(PhysicalArmorMulti(client),100.0));
		percentage=100-percentage;
		if(currentAttribute>0.0)
			SC_ChatMessage(client,"You now have {green}%i{default} percent physical armor damage reduction.",percentage);
		else if(currentAttribute==0.0)
			SC_ChatMessage(client,"You now have {green}0{default} percent physical armor damage reduction.");
	}
}
ShowArmorMagic(client)
{
	if(ValidPlayer(client))
	{
		new Float:currentAttribute=Float:BuffCached[client][fArmorMagic];
		new percentage=RoundToFloor(FloatMul(MagicArmorMulti(client),100.0));
		percentage=100-percentage;
		if(currentAttribute>0.0)
			SC_ChatMessage(client,"You now have {green}%i{default} percent magical armor damage reduction.",percentage);
		else if(currentAttribute==0.0)
			SC_ChatMessage(client,"You now have {green}0{default} percent magical armor damage reduction.");
	}
}
ShowAttackSpeed(client)
{
	if(ValidPlayer(client))
	{
		new Float:currentAttribute=Float:BuffCached[client][fAttackSpeed];
		if(currentAttribute>1.0)
			currentAttribute=FloatSub(currentAttribute,1.0);
		else
			currentAttribute=FloatSub(1.0,currentAttribute);
		currentAttribute=currentAttribute*100.0;
		new percentage=RoundToFloor(currentAttribute);
		if(currentAttribute!=1.0)
			SC_ChatMessage(client,"You now have {green}%i{default} percent attack speed buff.",percentage);
		else if(currentAttribute==1.0)
			SC_ChatMessage(client,"You now have {green}0{default} percent attack speed buff.");
	}
}
ShowVampireBuff(client)
{
	if(ValidPlayer(client))
	{
		new Float:currentAttribute=Float:BuffCached[client][fVampirePercent];
		if(currentAttribute>1.0)
			currentAttribute=FloatSub(currentAttribute,1.0);
		else
			currentAttribute=FloatSub(1.0,currentAttribute);
		currentAttribute=currentAttribute*100.0;
		new percentage=RoundToFloor(FloatSub(100.0,currentAttribute));
		if(currentAttribute>0.0)
			SC_ChatMessage(client,"You now gain {green}%i{default} percent damage as health.",percentage);
		else if(currentAttribute==0.0)
			SC_ChatMessage(client,"You now gain {green}0{default} percent damage as health.");
	}
}
ShowRegenBuff(client)
{
	if(ValidPlayer(client))
	{
		new Float:currentAttribute=Float:BuffCached[client][fHPRegen];
		new percentage=RoundToFloor(currentAttribute);
		if(currentAttribute>0.0)
			SC_ChatMessage(client,"You now gain {green}%i{default} hit points per second.",percentage);
		else if(currentAttribute==0.0)
			SC_ChatMessage(client,"You now gain {green}0{default} hit points per second.");
	}
}
ShowSpeedBuff(client,bool:bypass=false)
{
	if(ValidPlayer(client))
	{
		new Float:currentmaxspeed=GetEntDataFloat(client,FindSendPropOffs("CTFPlayer","m_flMaxspeed"));
		new Float:NEWcurrentmaxspeed=FloatDiv(currentmaxspeed,TF2_GetClassSpeed(TF2_GetPlayerClass(client)));
		if(NEWcurrentmaxspeed>1.0)
			NEWcurrentmaxspeed=FloatSub(NEWcurrentmaxspeed,1.0);
		else
			NEWcurrentmaxspeed=FloatSub(1.0,NEWcurrentmaxspeed);
		NEWcurrentmaxspeed=NEWcurrentmaxspeed*100.0;
		new percentage=RoundToFloor(NEWcurrentmaxspeed);
		if(OldSpeedBuffValue2[client]!=percentage||bypass)
		{
			if(currentmaxspeed>TF2_GetClassSpeed(TF2_GetPlayerClass(client)))
				SC_ChatMessage(client,"You move at {green}%i{default} percent {green}faster{default} than normal.",percentage);
			else if(currentmaxspeed<TF2_GetClassSpeed(TF2_GetPlayerClass(client)))
				SC_ChatMessage(client,"You move at {green}%i{default} percent {green}slower{default} than normal.",percentage);
			else if(currentmaxspeed==TF2_GetClassSpeed(TF2_GetPlayerClass(client)))
				SC_ChatMessage(client,"You move at {green}normal{default} speed.",percentage);
		}
		OldSpeedBuffValue2[client]=percentage;
	}
}

public On_SC_AnySkillChanged(client, oldskill, newskill)
{
	if(ValidPlayer(client) && !IsFakeClient(client) && SC_GetPlayerProp(client,iBuffChatInfo)==1)
	{
		//CreateTimer(7.0,DisplayBuffsTimer,GetClientUserId(client));
		DisplayBuffsTimer(GetClientUserId(client));
	}
}


//public Action:DisplayBuffsTimer(Handle:timer,any:userid)
DisplayBuffsTimer(any:userid)
{
	new client=GetClientOfUserId(userid);
	if(ValidPlayer(client))
	{
		SC_ChatMessage(client,"{lightgreen}Your new Buffs{default}:");
		SC_ShowBuffs(client);
	}
}

public Action:InvisibilityTimer(Handle:timer,any:userid)
{
	new client=GetClientOfUserId(userid);
	if(ValidPlayer(client))
	{
		ShowInvisBuff(client);
	}
}


public Action:RegenSpeedTimer(Handle:timer,any:userid)
{
	new client=GetClientOfUserId(userid);
	if(ValidPlayer(client))
	{
		ShowRegenBuff(client);
	}
}

public Action:VampireTimer(Handle:timer,any:userid)
{
	new client=GetClientOfUserId(userid);
	if(ValidPlayer(client))
	{
		ShowVampireBuff(client);
	}
}


public Action:PhysicalArmorSpeedTimer(Handle:timer,any:userid)
{
	new client=GetClientOfUserId(userid);
	if(ValidPlayer(client))
	{
		ShowArmorPhysical(client);
	}
}

public Action:MagicalArmorSpeedTimer(Handle:timer,any:userid)
{
	new client=GetClientOfUserId(userid);
	if(ValidPlayer(client))
	{
		ShowArmorMagic(client);
	}
}

public Action:AttackSpeedTimer(Handle:timer,any:userid)
{
	new client=GetClientOfUserId(userid);
	if(ValidPlayer(client))
	{
		ShowAttackSpeed(client);
	}
}

public Action:SpeedBuffTimer(Handle:timer,any:userid)
{
	new client=GetClientOfUserId(userid);
	if(ValidPlayer(client))
	{
		ShowSpeedBuff(client);
	}
	TimerSpeedBuff[client]=false;
}

//public On_SC_Event(SC_EVENT:event,client){
//	if(event==OnBuffChanged)
//	{
//		if(SC_GetVar(EventArg1)==iAdditionalMaxHealth&&ValidPlayer(client,true)){
//			if(mytimer2[client]==INVALID_HANDLE){	
//				mytimer2[client]=CreateTimer(0.1,CheckHPBuffChange,client);
//			}
//		}
//		//DP("EVENT OnBuffChanged",event);
//	}
//	//DP("EVENT %d",event);
//}
/*
GetBuff(client,SC_Buff:buffindex,skillindex){
return buffdebuff[client][buffindex][skillindex];
}*/
///REMOVE SINGLE BUFF FROM ALL SKILLS
ResetBuff(client,SC_Buff:buffindex){
	
	if(ValidBuff(buffindex))
	{
		new loop = SkillsLoaded();
		for(new i=0;i<=loop;i++) //reset starts at 0
		{
			buffdebuff[client][buffindex][i]=BuffDefault(buffindex);
			
			DoCalculateBuffCache(client,buffindex,i);
		}
		SC_ReapplySpeed(client);
		
	}
}
//RESET SINGLE BUFF OF SINGLE SKILL
ResetBuffParticularSkill(client,SC_Buff:buffindex,particularraceitemindex){
	if(ValidBuff(buffindex))
	{
		buffdebuff[client][buffindex][particularraceitemindex]=BuffDefault(buffindex);
		
		DoCalculateBuffCache(client,buffindex,particularraceitemindex);
		SC_ReapplySpeed(client);
	}
}

DoCalculateBuffCache(client,SC_Buff:buffindex,particularraceitemindex){
	///after we set it, we do an entire calculation to cache its value ( on selected buffs , mainly bools we test for HasTrue )
	switch(BuffCacheType(buffindex)){
		case DoNotCache: {}
		case bHasOneTrue: BuffCached[client][buffindex]=CalcBuffHasOneTrue(client,buffindex);
		case iAbsolute: BuffCached[client][buffindex]=CalcBuffSumInt(client,buffindex);
		case fAbsolute: BuffCached[client][buffindex]=CalcBuffSumFloat(client,buffindex);
		case fStacked: BuffCached[client][buffindex]=CalcBuffStackedFloat(client,buffindex);
		case fMaximum: BuffCached[client][buffindex]=CalcBuffMax(client,buffindex);
		case fMinimum: BuffCached[client][buffindex]=CalcBuffMin(client,buffindex);
		case iMinimum: BuffCached[client][buffindex]=CalcBuffMinInt(client,buffindex);
		case iLastValue: BuffCached[client][buffindex]=CalcBuffRecentValue(client,buffindex,particularraceitemindex);
	}
}


any:BuffDefault(SC_Buff:buffindex){
	return BuffProperties[buffindex][DefaultValue];
}
BuffStackCacheType:BuffCacheType(SC_Buff:buffindex){
	return BuffProperties[buffindex][BuffStackType];
}




////loop through the value of all items and races contributing values
stock any:CalcBuffMax(client,SC_Buff:buffindex)
{
	if(ValidBuff(buffindex))
	{
		new any:value=buffdebuff[client][buffindex][0];
		new loop = SkillsLoaded();
		for(new i=1;i<=loop;i++)
		{
			new any:value2=buffdebuff[client][buffindex][i];
			//PrintToChatAll("%f",value2);
			if(value2>value){
				value=value2;
			}
		}
		return value;
	}
	LogError("invalid buff index");
	return -1;
}
stock any:CalcBuffMin(client,SC_Buff:buffindex)
{
	if(ValidBuff(buffindex))
	{
		new any:value=buffdebuff[client][buffindex][0];
		new loop = SkillsLoaded();
		for(new i=1;i<=loop;i++)
		{
			new any:value2=buffdebuff[client][buffindex][i];
			if(value2<value){
				value=value2;
			}
		}
		return value;
	}
	LogError("invalid buff index");
	return -1;
}
CalcBuffMinInt(client,SC_Buff:buffindex)
{ 	
	if(ValidBuff(buffindex))
	{
		new value=buffdebuff[client][buffindex][0];
		new loop = SkillsLoaded();
		for(new i=1;i<=loop;i++)
		{
			new value2=buffdebuff[client][buffindex][i];
			if(value2<value){
				value=value2;
			}
		}
		return value;
	}
	LogError("invalid buff index");
	return -1;
}
stock bool:CalcBuffHasOneTrue(client,SC_Buff:buffindex)
{
	if(ValidBuff(buffindex))
	{
		new loop = SkillsLoaded();
		for(new i=1;i<=loop;i++)
		{
			if(buffdebuff[client][buffindex][i])
			{
				//PrintToChat(client,"hasonetrue: true: buffindex = %d itter %d",buffindex,i);
				return true;
			}
		}
		return false;
		
	}
	LogError("invalid buff index");
	return false;
}


//multiplied all the values together , only for floats
stock Float:CalcBuffStackedFloat(client,SC_Buff:buffindex)
{
	if(ValidBuff(buffindex))
	{
		new Float:value=buffdebuff[client][buffindex][0];
		new loop = SkillsLoaded();
		for(new i=1;i<=loop;i++)
		{
			value=FloatMul(value,buffdebuff[client][buffindex][i]);
		}
		return value;
	}
	LogError("invalid buff index");
	return -1.0;
}


///all values added!
stock CalcBuffSumInt(client,SC_Buff:buffindex)
{
	if(ValidBuff(buffindex))
	{
		new any:value=0;
		//this one starts from zero
		new loop = SkillsLoaded();
		for(new i=1;i<=loop;i++)
		{
			
			value=value+buffdebuff[client][buffindex][i];
			
		}
		return value;
		
	}
	LogError("invalid buff index");
	return -1;
}

///all values added!
stock CalcBuffSumFloat(client,SC_Buff:buffindex)
{
	if(ValidBuff(buffindex))
	{
		new any:value=0;
		//this one starts from zero
		new loop = SkillsLoaded();
		for(new i=1;i<=loop;i++)
		{
			
			value=Float:value+Float:(buffdebuff[client][buffindex][i]);
			
		}
		return value;
		
	}
	LogError("invalid buff index");
	return -1;
}

//Returns the most recent value set by any race
stock CalcBuffRecentValue(client,SC_Buff:buffindex,race)
{
	if(ValidBuff(buffindex))
	{
		new value = buffdebuff[client][buffindex][race];
		if(value!=-1)	
		{
			return value;
		} else {
			return BuffCached[client][buffindex];
		}
	}
	LogError("invalid buff index");
	return -1;
}


////////getting cached values!
stock GetBuffLastValue(client,SC_Buff:buffindex)
{
	if(ValidBuff(buffindex))
	{	
		if(BuffCacheType(buffindex)!=iLastValue){
			ThrowError("Tried to get cached value when buff index (%d) should not cache this type (%d)",buffindex,BuffCacheType(buffindex));
		}
		return BuffCached[client][buffindex];
		
	}
	LogError("invalid buff index");
	return false;
}
stock bool:GetBuffHasOneTrue(client,SC_Buff:buffindex)
{
	if(ValidBuff(buffindex))
	{	
		if(BuffCacheType(buffindex)!=bHasOneTrue){
			ThrowError("Tried to get cached value when buff index (%d) should not cache this type (%d)",buffindex,BuffCacheType(buffindex));
		}
		return BuffCached[client][buffindex];
		
	}
	LogError("invalid buff index");
	return false;
}
stock Float:GetBuffStackedFloat(client,SC_Buff:buffindex)
{
	if(ValidBuff(buffindex))
	{	
		if(BuffCacheType(buffindex)!=fStacked){
			ThrowError("Tried to get cached value when buff index (%d) should not cache this type (%d)",buffindex,BuffCacheType(buffindex));
		}
		return BuffCached[client][buffindex];
		
	}
	LogError("invalid buff index");
	return 0.0;
}
stock GetBuffSumInt(client,SC_Buff:buffindex)
{
	if(ValidBuff(buffindex))
	{	
		if(BuffCacheType(buffindex)!=iAbsolute){
			ThrowError("Tried to get cached value when buff index (%d) should not cache this type (%d)",buffindex,BuffCacheType(buffindex));
		}
		return BuffCached[client][buffindex];
		
	}
	LogError("invalid buff index");
	return false;
}
stock Float:GetBuffSumFloat(client,SC_Buff:buffindex)
{
	if(ValidBuff(buffindex))
	{	
		if(BuffCacheType(buffindex)!=fAbsolute){
			ThrowError("Tried to get cached value when buff index (%d) should not cache this type (%d)",buffindex,BuffCacheType(buffindex));
		}
		if (ValidPlayer(client)) {
			return Float:BuffCached[client][buffindex];
		}
		else {
			return 0.0;
		}
		
	}
	LogError("invalid buff index");
	return 0.0;
}
stock Float:GetBuffMaxFloat(client,SC_Buff:buffindex)
{
	if(ValidBuff(buffindex))
	{	
		if(BuffCacheType(buffindex)!=fMaximum){
			ThrowError("Tried to get cached value when buff index (%d) should not cache this type (%d)",buffindex,BuffCacheType(buffindex));
		}
		return BuffCached[client][buffindex];
		
	}
	LogError("invalid buff index");
	return 0.0;
}
stock Float:GetBuffMinFloat(client,SC_Buff:buffindex)
{
	if(ValidBuff(buffindex))
	{	
		if(BuffCacheType(buffindex)!=fMinimum){
			ThrowError("Tried to get cached value when buff index (%d) should not cache this type (%d)",buffindex,BuffCacheType(buffindex));
		}
		return BuffCached[client][buffindex];
		
	}
	LogError("invalid buff index");
	return 0.0;
}
GetBuffMinInt(client,SC_Buff:buffindex)
{
	if(ValidBuff(buffindex))
	{	
		if(BuffCacheType(buffindex)!=iMinimum){
			ThrowError("Tried to get cached value when buff index (%d) should not cache this type (%d)",buffindex,BuffCacheType(buffindex));
		}
		return BuffCached[client][buffindex];
		
	}
	LogError("invalid buff index");
	return 0;
}











Float:PhysicalArmorMulti(client){
	new Float:armor=Float:GetBuffMaxFloat(client,fArmorPhysical);
	
	if(armor<0.0){
		armor=armor*-1.0;
		return ((armor*0.06)/(1.0+armor*0.06))+1.0;
	}
	
	return (1.0-(armor*0.06)/(1.0+armor*0.06));
}
Float:MagicArmorMulti(client){
	
	new Float:armor=Float:GetBuffMaxFloat(client,fArmorMagic);
	//PrintToServer("armor=%f",armor);
	if(armor<0.0){
		armor=armor*-1.0;
		return ((armor*0.06)/(1.0+armor*0.06))+1.0;
	}
	
	return (1.0-(armor*0.06)/(1.0+armor*0.06));
}



stock GetEntityAlpha(index)
{
	return GetEntData(index,m_OffsetClrRender+3,1);
}

stock GetPlayerR(index)
{
	return GetEntData(index,m_OffsetClrRender,1);
}

stock GetPlayerG(index)
{
	return GetEntData(index,m_OffsetClrRender+1,1);
}

stock GetPlayerB(index)
{
	return GetEntData(index,m_OffsetClrRender+2,1);
}

stock SetPlayerRGB(index,r,g,b)
{
	SetEntityRenderMode(index,RENDER_TRANSCOLOR);
	SetEntityRenderColor(index,r,g,b,GetEntityAlpha(index));	
}

// FX Distort == 14
// Render TransAdd == 5
stock SetEntityAlpha(index,alpha)
{	
	//if(FindSendPropOffs(index,"m_nRenderFX")>-1&&FindSendPropOffs(index,"m_nRenderMode")>-1){
	new String:class[32];
	GetEntityNetClass(index, class, sizeof(class) );
	//PrintToServer("%s",class);
	if(FindSendPropOffs(class,"m_nRenderFX")>-1){
		SetEntityRenderMode(index,RENDER_TRANSCOLOR);
		SetEntityRenderColor(index,GetPlayerR(index),GetPlayerG(index),GetPlayerB(index),alpha);
	}
	//else{
	//	SC_Log("deny render fx %d",index);
	//}
	//}	
}

stock GetWeaponAlpha(client)
{
	new wep=SC_GetCurrentWeaponEnt(client);
	if(wep>MaxClients && IsValidEdict(wep))
	{
		return GetEntityAlpha(wep);
	}
	return 255;
}


//use 0 < limit
stock BuffLoopLimit(){
	return SC_GetSkillsLoaded()+1;
}
