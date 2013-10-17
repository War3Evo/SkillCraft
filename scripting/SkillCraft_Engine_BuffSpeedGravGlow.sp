 	

////BUFF SYSTEM




#pragma semicolon 1

#include <sourcemod>
#include "sdkhooks"
#include "SkillCraft_Includes/SkillCraft_Interface"


new m_OffsetSpeed=-1;
new m_OffsetClrRender=-1;

new reapplyspeed[MAXPLAYERSCUSTOM];
new bool:invisWeaponAttachments[MAXPLAYERSCUSTOM];
new bool:bDeniedInvis[MAXPLAYERSCUSTOM];

new Float:gspeedmulti[MAXPLAYERSCUSTOM];

new Float:speedBefore[MAXPLAYERSCUSTOM];
new Float:speedWeSet[MAXPLAYERSCUSTOM];

public Plugin:myinfo= 
{
	name="SkillCraft Buff Speed",
	author="SkillCraft Team",
	description="SkillCraft Core Plugins",
	version="1.0",
};

public OnPluginStart()
{
	CreateTimer(0.1,DeciSecondTimer,_,TIMER_REPEAT);
	
}

public bool:Init_SC_NativesForwards()
{

	CreateNative("SC_ReapplySpeed",Native_SC_ReapplySpeed);//for skills
	m_OffsetSpeed=FindSendPropOffs("CTFPlayer","m_flMaxspeed");
	if(m_OffsetSpeed==-1)
	{
		PrintToServer("[SkillCraft] Error finding speed offset.");
	}
	
	m_OffsetClrRender=FindSendPropOffs("CBaseAnimating","m_clrRender");
	if(m_OffsetClrRender==-1)
	{
		PrintToServer("[SkillCraft] Error finding render color offset.");
	}
	
	CreateNative("SC_IsBuffInvised",Native_SC_IsBuffInvised);
	CreateNative("SC_GetSpeedMulti",Native_SC_GetSpeedMulti);
	return true;
}

public Native_SC_ReapplySpeed(Handle:plugin,numParams)
{	
	new client=GetNativeCell(1);
	reapplyspeed[client]++;
}
public Native_SC_IsBuffInvised(Handle:plugin,numParams)
{	
	new client=GetNativeCell(1);
	return GetEntityAlpha(client)<50;
}
public Native_SC_GetSpeedMulti(Handle:plugin,numParams)
{	
	new client=GetNativeCell(1);
	if(ValidPlayer(client,true)){
		new Float:multi=1.0;
		if(TF2_IsPlayerInCondition(client,TFCond_SpeedBuffAlly)){
			multi=1.35;
		}
		return  _:(gspeedmulti[client]*multi +0.001); //rounding error
	}
	return _:1.0;
}



public Action:DeciSecondTimer(Handle:timer)
{

		// Boy, this is going to be fun.
		for(new client=1;client<=MaxClients;client++)
		{
			if(ValidPlayer(client,true))
			{
				
		
				//PrintToChatAll("sdf %d",client);
				new Float:gravity=1.0; //default
				if(!SC_GetBuffHasTrue(client,bLowGravityDenyAll)&&!SC_GetBuffHasTrue(client,bBuffDenyAll)) //can we change gravity?
				{
					//if(!SC_GetBuffHasTrue(client,bLowGravityDenySkill)){
					new Float:gravity1=SC_GetBuffMinFloat(client,fLowGravitySkill);
					//}
					//if(!SC_GetBuffHasTrue(client,bLowGravityDenyItem)){
					new Float:gravity2=SC_GetBuffMinFloat(client,fLowGravityItem);
					
					gravity=gravity1<gravity2?gravity1:gravity2;
					//}
					//gravity=; //replace
					//PrintToChat(client,"mingrav=%f",gravity);
				}
				///now lets set the grav
				if(GetEntityGravity(client)!=gravity){ ///gravity offset is somewhoe different for each person? this offset is got on PutInServer
					SetEntityGravity(client,gravity);
				}
				
				
				
				
				///GLOW
				new r=255,g=255,b=255,alpha=255;
			//	new bool:skipinvis=false;
				
				new bestindex=-1;
				new highestvalue=0;
				new Float:settime=0.0;
				
				new limit=SC_GetSkillsLoaded();
				for(new i=0;i<=limit;i++){
					if(SC_GetBuff(client,iGlowPriority,i)>highestvalue){
						highestvalue=SC_GetBuff(client,iGlowPriority,i);
						bestindex=i;
						settime=Float:SC_GetBuff(client,fGlowSetTime,i);
					}
					else if(SC_GetBuff(client,iGlowPriority,i)==highestvalue&&highestvalue>0){ //equal priority
						if(SC_GetBuff(client,fGlowSetTime,i)>settime){ //only if this one set it sooner
							highestvalue=SC_GetBuff(client,iGlowPriority,i);
							bestindex=i;
							settime=Float:SC_GetBuff(client,fGlowSetTime,i);
						}
					}
				}
				if(bestindex>-1){
					r=SC_GetBuff(client,iGlowRed,bestindex);
					g=SC_GetBuff(client,iGlowGreen,bestindex);
					b=SC_GetBuff(client,iGlowBlue,bestindex);
					alpha=SC_GetBuff(client,iGlowAlpha,bestindex);
				//	skipinvis=true;
				}
				
				new bool:set=false;
				if(GetPlayerR(client)!=r)
					set=true;
				if(GetPlayerG(client)!=g)
					set=true;
				if(GetPlayerB(client)!=b)
					set=true;
				//alpha set is after invis block, not here
				if(set){
					//	PrintToChatAll("%d %d %d %d",r,g,b,alpha);
					SetPlayerRGB(client,r,g,b);
					
					
				}
				
				
				
				
				
				///invisbility!
				//PrintToChatAll("SC_GetBuffMinFloat(client,fInvisibility) %f %f %f ",SC_GetBuffMinFloat(client,fInvisibility),float(alpha),float(alpha)*SC_GetBuffMinFloat(client,fInvisibility));
				
				
			
				new Float:falpha=1.0;
				if(!SC_GetBuffHasTrue(client,bInvisibilityDenySkill))
				{
					falpha=FloatMul(falpha,SC_GetBuffMinFloat(client,fInvisibilitySkill));
					
				}
				//if(!SC_GetBuffHasTrue(client,bInvisibilityDenySkillbInvisibl  ///we dont have an item deny yet
				new Float:itemalpha=SC_GetBuffMinFloat(client,fInvisibilityItem);
				if(falpha!=1.0){
					//PrintToChatAll("has skill invis");
					//has skill, reduce stack
					itemalpha=Pow(itemalpha,0.75);
				}
				falpha=FloatMul(falpha,itemalpha);
				
				//PrintToChatAll("%f",SC_GetBuffMinFloat(client,fInvisibilityItem));
				
				new alpha2=RoundFloat(       FloatMul(255.0,falpha)  ); 
				//PrintToChatAll("alpha2 = %d",alpha2);
				if(alpha2>=0&&alpha2<=255){
					alpha=alpha2;
				}
				else{
					LogError("alpha playertracking out of bounds 0 - 255");
				}
				if(SC_GetBuffHasTrue(client,bInvisibilityDenyAll)||SC_GetBuffHasTrue(client,bBuffDenyAll) ){
					if( /*bDeniedInvis[client]==false &&*/ alpha<222) ///buff is not denied
					{
						bDeniedInvis[client]=true;
						SC_Hint(client,HINT_NORMAL,4.0,"Cannot Invis. Being revealed");
						
					}
					alpha=255;
				}
				else{
					bDeniedInvis[client]=false;
				}
				static skipcheckingwearables[MAXPLAYERSCUSTOM];
				//PrintToChatAll("%d",alpha);
				if(GetEntityAlpha(client)!=alpha){
					SetEntityAlpha(client,alpha);
					skipcheckingwearables[client]=0;
					
				}
				
				if(skipcheckingwearables[client]<=0){
					new ent=-1;
					//DP("check");
					while ((ent = FindEntityByClassname(ent, "tf_wearable")) != -1){
						if(GetEntPropEnt(ent,Prop_Send, "m_hOwnerEntity")==client){
							if(GetEntityAlpha(ent)!=alpha){
								SetEntityAlpha(ent,alpha);
						//		DP("alpha on %d wearable",ent);
							}
						}
					//	DP("wearable was owned by %d",GetEntPropEnt(ent,Prop_Send, "m_hOwnerEntity"));
					}
					while ((ent = FindEntityByClassname(ent, "tf_wearable_demoshield")) != -1){
						if(GetEntPropEnt(ent,Prop_Send, "m_hOwnerEntity")==client){
							if(GetEntityAlpha(ent)!=alpha){
								SetEntityAlpha(ent,alpha);
						//		DP("alpha on %d wearable",ent);
							}
						}
					//	DP("wearable was owned by %d",GetEntPropEnt(ent,Prop_Send, "m_hOwnerEntity"));
					}
					
					for(new i=0;i<10;i++){
						if(-1!=GetPlayerWeaponSlot(client, i)){
							new went=GetPlayerWeaponSlot(client, i);
							//DP("weapon slot %d ent %d",i,went);
							if(GetEntityAlpha(went)!=alpha){
								SetEntityAlpha(went,alpha);
								
							}
						}
					}
					skipcheckingwearables[client]=10;
				}
				else{
					skipcheckingwearables[client]--;
				}
			
					
				invisWeaponAttachments[client]=alpha<200?true:false;
				
					
					
					
				new wpn=SC_GetCurrentWeaponEnt(client);
				if(wpn>0){
					new alphaw=alpha;
					if(SC_GetBuffHasTrue(client,bInvisWeaponOverride)){
						
						new buffloop = SC_GetBuffLoopLimit();
						for(new i=0;i<=buffloop;i++){
							//Old War3Evo...something about isitem?:
							//if(SC_GetBuff(client,bInvisWeaponOverride,i,true)){
							if(SC_GetBuff(client,bInvisWeaponOverride,i)){
								alphaw=SC_GetBuffMinInt(client,iInvisWeaponOverrideAmount);
							}
						}
						
					}
					if(!SC_GetBuffHasTrue(client,bDoNotInvisWeapon)){
						if(GetEntityAlpha(wpn)!=alphaw){
							SetEntityAlpha(wpn,alphaw);
							
						}
						
					}
					
				}
			
				///NEED 4 SPEED!
				///SPEED IS IN PLAYER FRAME	
			}
		}
	
}


public OnGameFrame()
{
	for(new client=1;client<=MaxClients;client++)
	{
		if(ValidPlayer(client,true))//&&!bIgnoreTrackGF[client])
		{
			new Float:currentmaxspeed=GetEntDataFloat(client,m_OffsetSpeed);
			//DP("speed %f, speedbefore %f , we set %f",currentmaxspeed,speedBefore[client],speedWeSet[client]);
			if(currentmaxspeed!=speedWeSet[client]) ///SO DID engien set a new speed? copy that!! //TFIsDefaultMaxSpeed(client,currentmaxspeed)){ //ONLY IF NOT SET YET
			{
				//DP("detected newspeed %f was %f",currentmaxspeed,speedWeSet[client]);
				speedBefore[client]=currentmaxspeed;
				reapplyspeed[client]++;
			}

				//PrintToChat(client,"speed %f %s",currentmaxspeed, TFIsDefaultMaxSpeed(client,currentmaxspeed)?"T":"F");
			if(reapplyspeed[client]>0)
			{
				//	DP("reapply");
				reapplyspeed[client]=0;
				///player frame tracking, if client speed is not what we set, we reapply speed
					//PrintToChatAll("1");

				//	if(true||	speedBefore[client]>3.0){ //reapply speed, using previous cached base speed, make sure the cache isnt' zero lol
				new Float:speedmulti=1.0;
					//DP("before");
				//new Float:speedadd=1.0;
				if(!SC_GetBuffHasTrue(client,bBuffDenyAll)){
					speedmulti=SC_GetBuffMaxFloat(client,fMaxSpeed)+SC_GetBuffMaxFloat(client,fMaxSpeed2)-1.0;
					}
				if(SC_GetBuffHasTrue(client,bStunned)||SC_GetBuffHasTrue(client,bBashed)){
				//DP("stunned or bashed");
					speedmulti=0.0;
				}
				if(!SC_GetBuffHasTrue(client,bSlowImmunity)){
					speedmulti=FloatMul(speedmulti,SC_GetBuffStackedFloat(client,fSlow));
					speedmulti=FloatMul(speedmulti,SC_GetBuffStackedFloat(client,fSlow2));
				}
				//PrintToConsole(client,"speedmulti should be 1.0 %f %f",speedmulti,speedadd);
				gspeedmulti[client]=speedmulti;
				new Float:newmaxspeed=FloatMul(speedBefore[client],speedmulti);
				if(newmaxspeed<0.1){
					newmaxspeed=0.1;
				}
				speedWeSet[client]=newmaxspeed;
				SetEntDataFloat(client,m_OffsetSpeed,newmaxspeed,true);
					//DP("%f",newmaxspeed);
				//	}
			}
//				}

			new MoveType:currentmovetype=GetEntityMoveType(client);
			new MoveType:shouldmoveas=MOVETYPE_WALK;
			if(SC_GetBuffHasTrue(client,bNoMoveMode)){
				shouldmoveas=MOVETYPE_NONE;
			}
			if(SC_GetBuffHasTrue(client,bNoClipMode)){
				shouldmoveas=MOVETYPE_NOCLIP;
			}
			else if(SC_GetBuffHasTrue(client,bFlyMode)&&!SC_GetBuffHasTrue(client,bFlyModeDeny)){
				shouldmoveas=MOVETYPE_FLY;
			}

			if(currentmovetype!=shouldmoveas){
				SetEntityMoveType(client,shouldmoveas);
			}
			//PrintToChatAll("end");
		}
	}
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if(ValidPlayer(client,true)){ //block attack
		if(SC_GetBuffHasTrue(client,bStunned)||SC_GetBuffHasTrue(client,bDisarm)){
			if((buttons & IN_ATTACK) || (buttons & IN_ATTACK2))
			{
				buttons &= ~IN_ATTACK;
				buttons &= ~IN_ATTACK2;
			}
		}
	}
	return Plugin_Continue;
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

