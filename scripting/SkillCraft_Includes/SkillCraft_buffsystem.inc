////BUFF SYSTEM
////BUFF SYSTEM
////BUFF SYSTEM
////BUFF SYSTEM
////BUFF SYSTEM
////BUFF SYSTEM


/*
 * set a buff, identified as coming from a race
 * value can be int float bool, but has to be consistant, agreed upon by war3 main plugin
 * 
 */
native SC_SetBuff(client,SC_Buff:buffindex,skillid,any:value);

/*
 * set a buff, identified as coming from a item
 * 
 */
native SC_BuffCustomOFFSET(); //get offset for custom buff modifier indexes. use SC_SetBuffItem(client,buffindex,SC_BuffCustomOFFSET() + NUMBER,value) (YES, ITEM)
//not implemented
//simple buff application which the plugin does internal tracking so you don't have to
//given a race, buffindex, and its value, applies that buff for a certain duration then calls buffReset 
//@allowReapplyToExtendDuration if true, means a new call to the same race-buff combination will renew its duration, otherwise it will be blocked and the existing duration is kept
native SC_ApplyBuffSimple(client,SC_Buff:buffindex,skillid,any:appliedBuffValue,Float:duration,bool:allowReapplyToExtendDuration=true);

///RESETS a particular buff from your race on this client
native SC_ResetBuffSkill(client,SC_Buff:buffindex,skillid);

///RESETS ALL BUFFS PERTAINGIN TO THIS CLIENT AND SKILL, basically fully getting rid if all buffs attatched to this player from your race
native SC_ResetAllBuffSkill(client, skillid);

//set player shell glowish color (blood mage, shadow hunter), highest override priority takes effect, all integers
stock SC_SetPlayerColor(client, skillid, r, g, b, a = 255,
		overridepriority = GLOW_DEFAULT) {
	SC_SetBuff(client, iGlowRed, skillid, r);
	SC_SetBuff(client, iGlowGreen, skillid, g);
	SC_SetBuff(client, iGlowBlue, skillid, b);
	SC_SetBuff(client, iGlowAlpha, skillid, a);
	SC_SetBuff(client, iGlowPriority, skillid, overridepriority);
	SC_SetBuff(client, fGlowSetTime, skillid, GetGameTime());
}
stock SC_ResetPlayerColor(client, skillid) {
	SC_SetPlayerColor(client, skillid, 255, 255, 255, _, 0);
}

//getting buffs
native SC_GetBuffLoopLimit(); //buff loop size , skill count + others, loop from 0 to <this return value
native any:SC_GetBuff(client,SC_Buff:buffindex,SkillID);
native bool:SC_GetBuffHasTrue(client,SC_Buff:buffindex); //does this buff have one true (activated?)
native SC_GetBuffSumInt(client,SC_Buff:buffindex);
native Float:SC_GetBuffStackedFloat(client,SC_Buff:buffindex); //get buff stacked value of an buff, use appropriately
native Float:SC_GetBuffSumFloat(client,SC_Buff:buffindex);
native Float:SC_GetBuffMinFloat(client,SC_Buff:buffindex);
native Float:SC_GetBuffMaxFloat(client,SC_Buff:buffindex);
native SC_GetBuffLastValue(client,SC_Buff:buffindex);
native SC_GetBuffMinInt(client,SC_Buff:buffindex);

//calculate player speed next frame
native SC_ReapplySpeed(client);
native SC_GetSpeedMulti(client); //get the effective speed multipler for TF

//statuses
stock bool:Stunned(client) {
	return SC_GetBuffHasTrue(client,bStunned);
}

stock bool:Silenced(client,printSilenced=true) {
	new bool:silenced=(SC_GetBuffHasTrue(client,bSilenced)||Stunned(client));
	if(silenced&&printSilenced) {
		if(IsPlayerAlive(client)) {
			if(Stunned(client))
			{
				PrintHintText(client,"You are stunned");
			}
			else
			{
				PrintHintText(client,"You are silenced");
			}
		}
		if(Stunned(client))
		{
			PrintToConsole(client,"You are stunned, cannot activate skill");
		}
		else
		{
			PrintToConsole(client,"You are silenced, cannot activate skill");
		}
	}
	return silenced;
}

stock bool:Hexed(client,printmsg=true) {
	new bool:status=(SC_GetBuffHasTrue(client,bHexed)||SC_GetBuffHasTrue(client,bStunned));
	if(status&&printmsg) {

		if(Stunned(client))
		{
			PrintToConsole(client,"You are stunned, cannot proc skill");
		}
		else
		{
			PrintToConsole(client,"You are hexed, cannot proc skill");
		}
	}
	return status;
}

stock bool:Perplexed(client,printmsg=true) {
	new bool:perplexed=(SC_GetBuffHasTrue(client,bPerplexed)||SC_GetBuffHasTrue(client,bStunned));
	if(perplexed&&printmsg) {

		if(Stunned(client))
		{
			PrintToConsole(client,"You are stunned, cannot activate item");
		}
		else
		{
			PrintToConsole(client,"You are perplexed, cannot activate item");
		}
	}
	return perplexed;
}

stock bool:SC_HasImmunity(client,SC_Immunity:immunityindex) {
										 //Immunity_Ability
	//add magic immunity etc later
	if(immunityindex==Immunity_Abilities) {
		return SC_GetBuffHasTrue(client,bImmunityAbilities);
	}
	if(immunityindex==Immunity_Items) {
		return SC_GetBuffHasTrue(client,bImmunityItems);
	}
	if(immunityindex==Immunity_Skills) {
		return SC_GetBuffHasTrue(client,bImmunitySkills);
	}
	if(immunityindex==Immunity_Ultimates) {
		return SC_GetBuffHasTrue(client,bImmunityUltimates);
	}
	if(immunityindex==Immunity_Wards) {
		//return SC_GetBuffHasTrue(client,bImmunityWards)||SC_GetBuffHasTrue(client,bImmunitySkills);
		return SC_GetBuffHasTrue(client,bImmunityWards);
	}
	if(immunityindex==Immunity_Poison) {
		return SC_GetBuffHasTrue(client,bImmunityPoison);
	}

	return false;

}

stock bool:IsSkillImmune(client) {
	return SC_GetBuffHasTrue(client,bImmunitySkills);
}

stock bool:IsUltImmune(client) {
	return SC_GetBuffHasTrue(client,bImmunityUltimates);
}

