#include <sourcemod>
#include "SkillCraft_Includes/SkillCraft_Interface"

public Plugin:myinfo = 
{
		name = "SkillCraft - SkillCraft Extended - Vampirism",
		author = "SkillCraft Team",
		description="SkillCraft vampirism skill"
};

new Handle:h_ForwardOn_SC_VampirismPost = INVALID_HANDLE;

public OnPluginStart()
{
		//LoadTranslations("w3s.race.undead.phrases");
}

public bool:Init_SC_NativesForwards()
{
		h_ForwardOn_SC_VampirismPost = CreateGlobalForward("On_SC_VampirismPost", ET_Hook, Param_Cell, Param_Cell, Param_Cell);

		return true;
}

LeechHP(victim, attacker, damage, Float:percentage, bool:bBuff)
{
		new leechhealth = RoundToFloor(damage * percentage);
		if(leechhealth > 40)
		{
				leechhealth = 40;
		}

		new iOldHP = GetClientHealth(attacker);
		
		bBuff ? SC_HealToBuffHP(attacker, leechhealth) : SC_HealToMaxHP(attacker, leechhealth);
		
		new iNewHP = GetClientHealth(attacker);
		
		if (iOldHP != iNewHP)
		{
				new iHealthLeeched = iNewHP - iOldHP;
				// from war3source 2.0:
				//SC_VampirismEffect(victim, attacker, iHealthLeeched);
				SC_FlashScreen(attacker,RGBA_COLOR_GREEN);
				
				Call_StartForward(h_ForwardOn_SC_VampirismPost);
				Call_PushCell(victim);
				Call_PushCell(attacker);
				Call_PushCell(iHealthLeeched);
				Call_Finish();
		}
}

public On_SC_EventPostHurt(victim,attacker,damage,const String:weapon[32],bool:isWarcraft)
{
		if(!isWarcraft && ValidPlayer(victim) && ValidPlayer(attacker, true) && attacker != victim && GetClientTeam(victim) != GetClientTeam(attacker))
		{
				new Float:fVampirePercentage = SC_GetBuffSumFloat(attacker, fVampirePercent);
				new Float:fVampirePercentageNoBuff = SC_GetBuffSumFloat(attacker, fVampirePercentNoBuff);

				if(!SC_HasImmunity(victim, Immunity_Skills) && !Hexed(attacker))
				{
						// This one runs first
						if(fVampirePercentageNoBuff > 0.0)
						{
								LeechHP(victim, attacker, damage, fVampirePercentageNoBuff, false);
						}

						if(fVampirePercentage > 0.0)
						{
								LeechHP(victim, attacker, damage, fVampirePercentage, true);
						}
				}
		}
}

// PostHurt does not have the inflictor
public OnSC_TakeDmgBullet(victim, attacker, Float:damage)
{
		if(SC_GetDamageIsBullet() && ValidPlayer(victim) && ValidPlayer(attacker, true) && attacker != victim && GetClientTeam(victim) != GetClientTeam(attacker))
		{
				new Float:fVampirePercentage = 0.0;
				new Float:fVampireNoBuffPercentage = 0.0;

				new inflictor = SC_GetDamageInflictor();
				if (attacker == inflictor || !IsValidEntity(inflictor))
				{
						new String:weapon[64];
						GetClientWeapon(attacker, weapon, sizeof(weapon));

						if (SC_IsDamageFromMelee(weapon))
						{
								fVampirePercentage += SC_GetBuffSumFloat(attacker, fMeleeVampirePercent);
								fVampireNoBuffPercentage += SC_GetBuffSumFloat(attacker, fMeleeVampirePercentNoBuff);
						}
				}

				if(!SC_HasImmunity(victim, Immunity_Skills) && !Hexed(attacker))
				{
						// This one runs first
						if(fVampireNoBuffPercentage > 0.0)
						{
								LeechHP(victim, attacker, RoundToFloor(damage), fVampireNoBuffPercentage, false);
						}

						if(fVampirePercentage > 0.0)
						{
								LeechHP(victim, attacker, RoundToFloor(damage), fVampirePercentage, true);
						}
				}
		}
}
