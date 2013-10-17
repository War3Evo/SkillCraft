/**
* File: 
* While we do this, lets document this file. I saw a forum post requesting documentation in this file.
*/


//for all skillcraft, we define MAXPlAYERS as 66
//just so pigs dont fly when you run a 64 slot server with HLTV
#define MAXPLAYERSCUSTOM 34   //+2 of real for normal servers, add +X number of HLTV slots


//dochecking up to <MAXRACES
//limit check up to >=MAXRACES-1

#define MAXSKILLS 200 //20 = [1]-[199]  ///can only hold X-1 races, IE 20 can only hold 19 races, we skip zeroth race!


#define CUSTOMMODIFIERS 3 //how many race indexes extra for modifying buffs without conflicting other races

#define MAXAURAS 100 // [1- ] ignore zeroth index

#define SHORTNAMELEN 16 //item or race shotnames, 15 characters
#define FULLNAMELEN 32 //item or race full names, 31 characters. RUSSIAN and other characters require more than 1 byte to store a displayed character

#define MAXCATS 20 //max race categories

// The enum SC_Var is used with function SC_SetVar and SC_GetVar.
// It is the first parameter, eg: new deathRace = SC_GetVar(DeathRace) <<--no longer exists.. saving just for the example.
enum SC_Var
{
	hDatabase, // Handle to database
	hDatabaseType, // DBI driver, ie sqlite or mysql
	hSaveEnabledCvar, //Handle to sc_savexp
	hSkillLimitEnabledCvar, // sc_skillimit_enable

	hPlayerInfoArgStr, // string argument after player says "playerinfo <arg>" if any
	SkillinfoSkillToShow, // who to show the raceinfo  ....
	EventArg1, //generic sc_event arguments
	EventArg2,
	EventArg3,
	
	SmEvent, ///usual game events from sm hooked events
}

stock String:SC_VarStrings[][32] = {"hDatabase",
								"hDatabaseType",
								"hSaveEnabledCvar",
								"hSkillLimitEnabledCvar",
								"hPlayerInfoArgStr",
								"SkillinfoSkillToShow",
								"EventArg1",
								"EventArg2",
								"EventArg3",
								"SmEvent"};

//These are just used as constants, and enum orders them incrementally
// They are to be used for SC_CreateEvent and On_SC_Event, these constants define the type of the event/
//SC_Events are basically used kind of like Natives and Forwards, without the trouble of creating actual natives/forwards
enum SC_EVENT
{
	ToBeRevived=0,
	DoShowChangeSkillMenu, //2
	DoShowSkillinfoMenu,
	DoShowPlayerinfoMenu,//7 
	DoShowPlayerinfoEntryWithArg,//8
	DoShowParticularSkillInfo, //EventArg1 = raceid//9

	ClearPlayerVariables,//10
	InitPlayerVariables,//11
	
	OnDeathPre, //EventArg1 = attacker.  before w3 actual death forward is called to do some reading ( ie before items are lost)//28
	DoShowMenuMyInfo,//29
	DoShowPlayerInfoTarget, ///EventArg1 = target = the person whos info is shown, client=SHOW TO//30 

	DatabaseConnected,//35
	
	OnBuffChanged, //a buff has changed//37
	OnAuraCalculationFinished, //this is after all the OnSC_PlayerAuraStateChanged have been sent//38
	On_SC_CooldownMGR,
}
enum SC_DENY{
	DN_ShowChangeSkill,
	DN_CanSelectSkill,
	DN_Suicide, //can undead suicide
}
// Constants for an array, which every SC Plugin has. When the variables are ready, they will be forwarded to you.


// The types of immunities you can get/set from.
///corresponds to a buff system immunity
enum SC_Immunity
{
	Immunity_None = 0, //generic zero
	Immunity_Ultimates, // Immune from ultimates
	Immunity_PhysicalDamage, // Immune from health taking
	Immunity_MagicDamage, // Immune from magic based stuff (doesnt not include ultimates)
	Immunity_Items, // Immune from shop items
	Immunity_Skills, // Immune from all skills
	Immunity_Wards, // Immune ward modifiers/damage. skill immunity includes ward immunity
	Immunity_Abilities, // Immune from abilities (not implemented by core)
	Immunity_Poison,
}; // The last of PimpinJuice's sexy syntax

//where damage is from   skill or ultimate etc
enum SC_DamageOrigin
{
	SC_DMGORIGIN_UNDEFINED=0,
	SC_DMGORIGIN_SKILL,
	SC_DMGORIGIN_ULTIMATE,
	SC_DMGORIGIN_ITEM,
}

//damage types
enum SC_DamageType
{
	SC_DMGTYPE_TRUEDMG=0,       //normal damage without accout for physical or magic armor
	SC_DMGTYPE_PHYSICAL,
	SC_DMGTYPE_MAGIC,
}

//EXCLUSIVE: buffs that do not stack with itself: gravity, invisblity, however to make them stack use a second property ie gravity2, invisibilty2
//////////////////Generally races use "buffvar" and items that wish to stack uses "varbuff2" and the final value is calculated: best of "buffvar" stacked with best of "buffvar2"
//STACKING: buffs that stack with itself
//EACH BUFF SHOULD HAVE A CONCENSUS ON WHAT TYPE OF VALUE IT USES: bool, int, float
///NOT ALL BUFFS HAVE THE SAME DENIES, some only need skill deny or item deny only



enum SC_BuffProperties
{
	any:DefaultValue=0, //array index 1
	BuffStackCacheType:BuffStackType=1, //array index 1
}

enum BuffStackCacheType
{ //each buff can only have one stacking operation:aa
	DoNotCache=0,
	bHasOneTrue,
	iAbsolute, //sum
	fAbsolute, //sum
	fStacked, /// all float multiplied
	
	fMaximum,
	fMinimum,
	iMinimum,
	iLastValue,
	ERRUNDEFINED=-99,
}


enum SC_Buff
{
	buffdummy=0,
	bBuffDenyAll, //DENY=not allowed to have any buffs, aka "purge"
	
	fLowGravitySkill, //0.4 ish?
	fLowGravityItem, //0.4 ish?
	bLowGravityDenyAll,
	
	fInvisibilitySkill, //0.4 ish?
	fInvisibilityItem, //0.4 ish?
	bInvisibilityDenyAll,
	bInvisibilityDenySkill, //needed for orc
	bDoNotInvisWeapon,
	bInvisWeaponOverride, //set true to use override amount, ONLY 1 RACE SHALL USE THIS AT A TIME PER CLIENT
	iInvisWeaponOverrideAmount, ///amolunt of 0-255 , do not have to set back to 255, just set bInvisWeaponOverride to false
	///11
	
	fMaxSpeed, //for increasing speeds only! MUST BE MORE THAN 1.0
	fMaxSpeed2, //for increasing speeds only!, added onto fMaxSpeed buff, MUST BE MORE THAN 1.0
	
	fSlow, //for decreeasing speeds only! MUST BE LESS THAN 1.0
	fSlow2, //for decreeasing speeds only! MUST BE LESS THAN 1.0. allows a race to have stacking slows
	bSlowImmunity, //immune to slow?
	
	bImmunitySkills, //is immune to skills
	bImmunityUltimates, // is immune to ultimates	
	bImmunityWards, // is immune to wards, skill immunity includes ward immunity
	bImmunityItems, // is immune to items
	bImmunityAbilities, // is immune to abilities
	
	fAttackSpeed, //attack speed multipler!    // does not stack, keeps maximum (used to be fStacked)
	
	bStunned, //cannot shoot, cannot cast, cannot move, basically everything below
	bBashed, //cannot move
	bDisarm,//cannot shoot
	bSilenced,  //cannot cast 
	bHexed,  // no skill proc
	bPerplexed, //cannot use items / proc items
	
	bNoMoveMode,//move type none! overrrides all other movestypes
	bFlyMode,   //fly mode
	bFlyModeDeny,
	bNoClipMode,
	
	fArmorPhysical, // does not stack, keeps maximum (used to be absolute or sum of)
	fArmorMagic, // does not stack, keeps maximum (used to be absolute or sum of)
	
	//DO NOT USE GLOW FOR INVIS
	iGlowRed, //glowing the player 0-255
	iGlowGreen,
	iGlowBlue,
	iGlowAlpha, //careful this is like invisiblity
	iGlowPriority, //highest priority takes effect
	fGlowSetTime, //time is recorded, those with same prioirty will compete via time. not something u set
	
	
	fHPRegen, ///float sum! NO NEGATIVES! MINIM regin rate is 0.5 / second ( 1 hp per 2 seconds)
	fHPDecay, //float sum, NO NEGATIVES, postive means lose this much HP / second, same requirements as fHPRegen
	fHPRegenDeny, //set true to deny hp regen
	iAdditionalMaxHealth,   ///increase / decrease in maxhp
	
	//44
	// DODGE MELEE ONLY
	fDodgeChance, //Registers a chance to dodge, (Note: 0.7 would equal a 70% chance to dodge)
	bDodgeMode, //Set 0 for Pre, 1 for post (quick regen)
	
	fVampirePercent, //Sets a % of damage done to give back as health
	fVampirePercentNoBuff, // Same as fVampirePercent, but doesn't overheal
	fMeleeVampirePercent, // Sets a % of damage done to give back as health when the damage was caused by melee
	fMeleeVampirePercentNoBuff, // Same as fMeleeVampirePercent, but doesn't overheal
	
	fBashChance, //Registers a chance to bash, (Note: 0.7 would equal a 70% chance to bash)
	iBashDamage, //Does a certain amount of damage when you bash an enemy (more similar to warcraft 3's bash, default 0)
	fBashDuration, //Sets the duration of bash's stun
	
	fCritChance, //Registers a chance to crit, (Note: 0.7 would equal a 70% chance to crit)
	iCritMode, //Default 0 (all damage qualifies for crit) 1 (bullet damage crit) 2 (grenade damage crit) 3 (melee damage crit) 4 (melee and bullet crit) 5 (melee and grenade crit) 6 (bullet and grenade crit)
	fCritModifier, //Sets the critical strike modifer, default 1.0
	
	iDamageMode, //Default 0 (all damage qualifies for damage increase) 1 (bullet damage damage increase) 2 (grenade damage damage increase) 3 (melee damage damage increase) 4 (melee and bullet damage increase) 5 (melee and grenade damage increase) 6 (bullet and grenade damage increase)

	iDamageBonus, //Gives a direct increase to damage done
	fDamageModifier, //Gives a % increase to damage done

	iAdditionalMaxHealthNoHPChange,   ///increase / decrease in maxhp. NO AUTOMATIC HP CHANGE WHEN BUFF IS CHANGED

	bImmunityPoison,   // immunity to poisons

	// DODGE RANGED ONLY
	fDodgeChanceRanged, //Registers a chance to dodge ranged attacks, (Note: 0.7 would equal a 30% chance to dodge)
	
	MaxBuffLoopLimitTemp, //this is a variable that is for loops, this number is automatically generated from the enum.
}
stock MaxBuffLoopLimit=_:MaxBuffLoopLimitTemp;


//create an buffpropertiesarray[SC_Buff][SC_BuffProperties]; (separate from the array that stores every client's buffs)
//we fill the array with its properties
stock InitiateBuffPropertiesArray(buffpropertiesarray[SC_Buff][SC_BuffProperties])
{
	
	for(new i=0;i<MaxBuffLoopLimit;i++)
	{
		buffpropertiesarray[SC_Buff:i][DefaultValue]=-99;
		buffpropertiesarray[SC_Buff:i][BuffStackType]=ERRUNDEFINED;
	}
	
	buffpropertiesarray[buffdummy][DefaultValue]=false;
	buffpropertiesarray[buffdummy][BuffStackType]=bHasOneTrue;
	
	buffpropertiesarray[bBuffDenyAll][DefaultValue]=false;
	buffpropertiesarray[bBuffDenyAll][BuffStackType]=bHasOneTrue;
	
	buffpropertiesarray[fLowGravitySkill][DefaultValue]=1.0;
	buffpropertiesarray[fLowGravitySkill][BuffStackType]=fMinimum;
	
	buffpropertiesarray[fLowGravityItem][DefaultValue]=1.0;
	buffpropertiesarray[fLowGravityItem][BuffStackType]=fMinimum;
	
	buffpropertiesarray[ bLowGravityDenyAll ][DefaultValue]=false;
	buffpropertiesarray[ bLowGravityDenyAll ][BuffStackType]=bHasOneTrue;
	
	buffpropertiesarray[ fInvisibilitySkill ][DefaultValue]=1.0;
	buffpropertiesarray[ fInvisibilitySkill ][BuffStackType]=fMinimum;
	
	buffpropertiesarray[ fInvisibilityItem ][DefaultValue]=1.0;
	buffpropertiesarray[ fInvisibilityItem ][BuffStackType]=fMinimum;
	
	buffpropertiesarray[ bInvisibilityDenyAll ][DefaultValue]=false;
	buffpropertiesarray[ bInvisibilityDenyAll ][BuffStackType]=bHasOneTrue;
	
	buffpropertiesarray[ bInvisibilityDenySkill ][DefaultValue]=false;
	buffpropertiesarray[ bInvisibilityDenySkill ][BuffStackType]=bHasOneTrue;
		
	buffpropertiesarray[ bDoNotInvisWeapon ][DefaultValue]=false;
	buffpropertiesarray[ bDoNotInvisWeapon ][BuffStackType]=bHasOneTrue;	
	
	buffpropertiesarray[ bInvisWeaponOverride ][DefaultValue]=false;
	buffpropertiesarray[ bInvisWeaponOverride ][BuffStackType]=bHasOneTrue;	
	
	buffpropertiesarray[ iInvisWeaponOverrideAmount ][DefaultValue]=255;
	buffpropertiesarray[ iInvisWeaponOverrideAmount ][BuffStackType]=iMinimum;	
	
	buffpropertiesarray[ fMaxSpeed ][DefaultValue]=1.0;
	buffpropertiesarray[ fMaxSpeed ][BuffStackType]=fMaximum;
	
	buffpropertiesarray[ fMaxSpeed2 ][DefaultValue]=1.0;
	buffpropertiesarray[ fMaxSpeed2 ][BuffStackType]=fMaximum;
	
	
	buffpropertiesarray[ fSlow ][DefaultValue]=1.0;
	buffpropertiesarray[ fSlow ][BuffStackType]=fStacked;	
	
	buffpropertiesarray[ fSlow2 ][DefaultValue]=1.0;
	buffpropertiesarray[ fSlow2 ][BuffStackType]=fStacked;
	
	buffpropertiesarray[ bSlowImmunity ][DefaultValue]=false;
	buffpropertiesarray[ bSlowImmunity ][BuffStackType]=bHasOneTrue;
	
//	buffpropertiesarray[ fIncomingDamage ][DefaultValue]=1.0;
//	buffpropertiesarray[ fIncomingDamage ][BuffStackType]=fStacked;
	
	buffpropertiesarray[ bImmunitySkills ][DefaultValue]=false;
	buffpropertiesarray[ bImmunitySkills ][BuffStackType]=bHasOneTrue;	
	
	buffpropertiesarray[ bImmunityWards ][DefaultValue]=false;
	buffpropertiesarray[ bImmunityWards ][BuffStackType]=bHasOneTrue;	
	
	buffpropertiesarray[ bImmunityUltimates ][DefaultValue]=false;
	buffpropertiesarray[ bImmunityUltimates ][BuffStackType]=bHasOneTrue;

	buffpropertiesarray[ bImmunityItems ][DefaultValue]=false;
	buffpropertiesarray[ bImmunityItems ][BuffStackType]=bHasOneTrue;

	buffpropertiesarray[ bImmunityAbilities ][DefaultValue]=false;
	buffpropertiesarray[ bImmunityAbilities ][BuffStackType]=bHasOneTrue;

	buffpropertiesarray[ fAttackSpeed ][DefaultValue]=1.0;
	buffpropertiesarray[ fAttackSpeed ][BuffStackType]=fMaximum;
	
	buffpropertiesarray[ bStunned ][DefaultValue]=false;
	buffpropertiesarray[ bStunned ][BuffStackType]=bHasOneTrue;	
	
	buffpropertiesarray[ bBashed ][DefaultValue]=false;
	buffpropertiesarray[ bBashed ][BuffStackType]=bHasOneTrue;	
	
	buffpropertiesarray[ bDisarm ][DefaultValue]=false;
	buffpropertiesarray[ bDisarm ][BuffStackType]=bHasOneTrue;	
	
	buffpropertiesarray[ bSilenced ][DefaultValue]=false;
	buffpropertiesarray[ bSilenced ][BuffStackType]=bHasOneTrue;	
	
	buffpropertiesarray[ bPerplexed ][DefaultValue]=false;
	buffpropertiesarray[ bPerplexed ][BuffStackType]=bHasOneTrue;	
		
	buffpropertiesarray[ bHexed ][DefaultValue]=false;
	buffpropertiesarray[ bHexed ][BuffStackType]=bHasOneTrue;
		
	buffpropertiesarray[ bNoMoveMode ][DefaultValue]=false;
	buffpropertiesarray[ bNoMoveMode ][BuffStackType]=bHasOneTrue;	
	
	buffpropertiesarray[ bFlyMode ][DefaultValue]=false;
	buffpropertiesarray[ bFlyMode ][BuffStackType]=bHasOneTrue;	
	
	buffpropertiesarray[ bFlyModeDeny ][DefaultValue]=false;
	buffpropertiesarray[ bFlyModeDeny ][BuffStackType]=bHasOneTrue;	
	
	
	buffpropertiesarray[ bNoClipMode ][DefaultValue]=false;
	buffpropertiesarray[ bNoClipMode ][BuffStackType]=bHasOneTrue;	
	
	
	buffpropertiesarray[ fArmorPhysical ][DefaultValue]=0;
	buffpropertiesarray[ fArmorPhysical ][BuffStackType]=fMaximum;	
	
	buffpropertiesarray[ fArmorMagic ][DefaultValue]=0;
	buffpropertiesarray[ fArmorMagic ][BuffStackType]=fMaximum;	
	
	buffpropertiesarray[ iGlowRed ][DefaultValue]=255;
	buffpropertiesarray[ iGlowRed ][BuffStackType]=DoNotCache;
	
	buffpropertiesarray[ iGlowGreen ][DefaultValue]=255;
	buffpropertiesarray[ iGlowGreen ][BuffStackType]=DoNotCache;
	
	buffpropertiesarray[ iGlowBlue ][DefaultValue]=255;
	buffpropertiesarray[ iGlowBlue ][BuffStackType]=DoNotCache;
	
	buffpropertiesarray[ iGlowAlpha ][DefaultValue]=255;
	buffpropertiesarray[ iGlowAlpha ][BuffStackType]=DoNotCache;	
	
	buffpropertiesarray[ iGlowPriority ][DefaultValue]=0;
	buffpropertiesarray[ iGlowPriority ][BuffStackType]=DoNotCache;	
	
	buffpropertiesarray[ fGlowSetTime ][DefaultValue]=0;
	buffpropertiesarray[ fGlowSetTime ][BuffStackType]=DoNotCache;	
	
	
	
	buffpropertiesarray[ fHPRegen][DefaultValue]=0.0;
	buffpropertiesarray[ fHPRegen][BuffStackType]=fAbsolute;	
	
	buffpropertiesarray[ fHPDecay][DefaultValue]=0.0;
	buffpropertiesarray[ fHPDecay][BuffStackType]=fAbsolute;	
	
	buffpropertiesarray[ fHPRegenDeny][DefaultValue]=false;
	buffpropertiesarray[ fHPRegenDeny][BuffStackType]=bHasOneTrue;	
	
	buffpropertiesarray[ iAdditionalMaxHealth ][DefaultValue]=0;
	buffpropertiesarray[ iAdditionalMaxHealth ][BuffStackType]=iAbsolute;
	
	buffpropertiesarray[ fDodgeChance ][DefaultValue]=0.0;
	buffpropertiesarray[ fDodgeChance ][BuffStackType]=fAbsolute;
	
	buffpropertiesarray[ bDodgeMode	  ][DefaultValue]=0;
	buffpropertiesarray[ bDodgeMode   ][BuffStackType]=bHasOneTrue;
	
	buffpropertiesarray[ fVampirePercent][DefaultValue]=0.0;
	buffpropertiesarray[ fVampirePercent][BuffStackType]=fAbsolute;
	
	buffpropertiesarray[ fVampirePercentNoBuff][DefaultValue]=0.0;
	buffpropertiesarray[ fVampirePercentNoBuff][BuffStackType]=fAbsolute;
	
	buffpropertiesarray[ fMeleeVampirePercent][DefaultValue]=0.0;
	buffpropertiesarray[ fMeleeVampirePercent][BuffStackType]=fAbsolute;	
	
	buffpropertiesarray[ fMeleeVampirePercentNoBuff][DefaultValue]=0.0;
	buffpropertiesarray[ fMeleeVampirePercentNoBuff][BuffStackType]=fAbsolute;	
	
	buffpropertiesarray[ fBashChance ][DefaultValue]=0.0;
	buffpropertiesarray[ fBashChance ][BuffStackType]=fAbsolute;
	
	buffpropertiesarray[ iBashDamage ][DefaultValue]=0;
	buffpropertiesarray[ iBashDamage ][BuffStackType]=iAbsolute;
	
	buffpropertiesarray[ fBashDuration ][DefaultValue]=0.0;
	buffpropertiesarray[ fBashDuration ][BuffStackType]=fAbsolute;
	
	buffpropertiesarray[ fCritChance ][DefaultValue]=0.0;
	buffpropertiesarray[ fCritChance ][BuffStackType]=fAbsolute;
	
	buffpropertiesarray[ iCritMode ][DefaultValue]=-1;
	buffpropertiesarray[ iCritMode ][BuffStackType]=iLastValue;
	
	buffpropertiesarray[ fCritModifier ][DefaultValue]=0.0;
	buffpropertiesarray[ fCritModifier ][BuffStackType]=fAbsolute;
	
	buffpropertiesarray[ iDamageBonus ][DefaultValue]=0;
	buffpropertiesarray[ iDamageBonus ][BuffStackType]=iAbsolute;
	
	buffpropertiesarray[ fDamageModifier ][DefaultValue]=0.0;
	buffpropertiesarray[ fDamageModifier ][BuffStackType]=fAbsolute;
	
	buffpropertiesarray[ iDamageMode ][DefaultValue]=-1;
	buffpropertiesarray[ iDamageMode ][BuffStackType]=iLastValue;
	
	buffpropertiesarray[ iAdditionalMaxHealthNoHPChange ][DefaultValue]=0;
	buffpropertiesarray[ iAdditionalMaxHealthNoHPChange ][BuffStackType]=iAbsolute;
	
	buffpropertiesarray[ bImmunityPoison ][DefaultValue]=false;
	buffpropertiesarray[ bImmunityPoison ][BuffStackType]=bHasOneTrue;
	
	buffpropertiesarray[ fDodgeChanceRanged ][DefaultValue]=0.0;
	buffpropertiesarray[ fDodgeChanceRanged ][BuffStackType]=fAbsolute;

	
	//check that all indexes have been set
	for(new i=0;i<MaxBuffLoopLimit;i++)
	{
		if(buffpropertiesarray[SC_Buff:i][DefaultValue]==-99)
		{
			SetFailState("Buff index %d [DefaultValue] was not set properly!",i);
		}
		if(buffpropertiesarray[SC_Buff:i][BuffStackType]==ERRUNDEFINED)
		{
			SetFailState("Buff index %d [BuffStackType] was not set properly!",i);
		}
	}
	
}

//simulates race object
enum ENUM_SkillObject{ //CELLS ONLY, NO STRINGS
	ClassRestrictionCvar, //for TF
	SkillCategorieCvar,
	SkillExtends,
}


// SC Glow constants
enum  
{
	GLOW_NONE=0,
	GLOW_BASE=1, //if ur race needs a glow
	GLOW_BASE2, //temporary glow of ur race over ur orignal glow? like mole u can add a glow for another priority
	GLOW_DEFAULT,
	GLOW_SKILL, //if skill activates on u  or others
	GLOW_ULTIMATE, //if ultimate actiavates on u or others
	GLOW_OVERRIDE=255, //override all glow
}


enum SC_ItemProp 
{
	ITEM_USED_ON_BUY=0,
	ITEM_SELFSTACK,
}

enum SC_SQLType
{
	SQLType_Unknown = 0,
	SQLType_MySQL,
	SQLType_SQLite,
}

// Ward targeting affinities
enum SC_WardAffinity
{
	ENEMIES,
	ALLIES,
	ALL,
	SELF_ONLY
}

enum SC_HintPriority{
	HINT_NORMAL, //things that are attached from non hint engine hints
	HINT_SKILL_STATUS, //"TELEPORTED!"
	HINT_DMG_DEALT,
	HINT_DMG_RCVD,
	HINT_COOLDOWN_NOTREADY,
	HINT_COOLDOWN_EXPIRED,
	HINT_COOLDOWN_COUNTDOWN,
	HINT_LOWEST,
	
	HINT_SIZE, //do not use this as priority
}
enum SC_HintPriorityMultiType{
	HINT_TYPE_SINGLE=0,	//show single, overrides old
	HINT_TYPE_ALL,		//show all of them
	HINT_TYPE_QUEUE,	//queue each one
}
//functio to retreve these constants
stock any:SC_GetHintPriorityType(SC_HintPriority:priority){
	switch(priority){
		case HINT_NORMAL:  return HINT_TYPE_ALL;
		case HINT_SKILL_STATUS: return HINT_TYPE_ALL;
		case HINT_DMG_DEALT: return HINT_TYPE_ALL;
		case HINT_DMG_RCVD: return HINT_TYPE_ALL;
		case HINT_COOLDOWN_NOTREADY: return HINT_TYPE_SINGLE;
		case HINT_COOLDOWN_EXPIRED:  return HINT_TYPE_ALL;
		case HINT_COOLDOWN_COUNTDOWN:  return HINT_TYPE_SINGLE;
		case HINT_LOWEST:  return HINT_TYPE_ALL;
	}
	return -1;
}

// The following are color presets for the SC_FlashScreen function
#define RGBA_COLOR_RED		{255,0,0,4}
#define RGBA_COLOR_GREEN	{0,255,0,3}
#define RGBA_COLOR_BLUE		{0,0,255,3}
#define RGBA_COLOR_YELLOW	{255,255,0,3}
#define RGBA_COLOR_ORANGE	{255,69,0,3}
#define RGBA_COLOR_PURPLE	{128,0,128,3}
#define RGBA_COLOR_CYAN		{255,0,255,3}
#define RGBA_COLOR_WHITE	{255,255,255,3}
#define RGBA_COLOR_BLACK	{0,0,0,3}
#define RGBA_COLOR_GREY		{128,128,128,3}
#define RGBA_COLOR_PINK		{255,20,147,3}
#define RGBA_COLOR_MAROON	{128,0,0,3}
#define RGBA_COLOR_SKYBLUE	{135,206,25,3}
#define RGBA_COLOR_GOLD		{255,215,0,3}
#define RGBA_COLOR_BROWN	{139,69,19,3}
#define RGBA_COLOR_VIOLET	{238,130,238,3}

// The following are from the SourceSDK, used for the optional flags field of SC_FlashScreen
#define FFADE_IN			0x0001		// Just here so we don't pass 0 into the function, YOUR SCREEN DECAYS AND YOU SEE CLEARLY SLOWLY
#define FFADE_OUT			0x0002		// Fade out (not in)
#define FFADE_MODULATE		0x0004		// Modulate (don't blend)
#define FFADE_STAYOUT		0x0008		// ignores the duration, stays faded out until new ScreenFade message received
#define FFADE_PURGE			0x0010		// Purges all other fades, replacing them with this one

// Team ID's for the Valve specific game
//0 == unassigned
// 1 == spectator
#define  TEAM_T 2
#define  TEAM_CT 3
#define  TEAM_RED 2
#define  TEAM_BLUE 3

// Modeltypes used by the Model Engine  // not implemented anywhere.. good for reference
//#define MDLTYPE_VIEWMODEL 0
//#define MDLTYPE_WORLDMODEL 1


enum ItemClassString
{
	unknown = TFClass_Unknown,
	scout = TFClass_Scout,
	sniper = TFClass_Sniper,
	soldier = TFClass_Soldier,
	demoman = TFClass_DemoMan,
	medic = TFClass_Medic,
	heavy = TFClass_Heavy,
	pyro = TFClass_Pyro,
	spy = TFClass_Spy,
	engineer = TFClass_Engineer
}
//#define MDLTYPE_GRENADE 2 //thrown grenades  // not implemented anywhere.. good for reference

enum SKILLTYPE
{
	mastery=0,
	talent,
	ability,
	ultimate,
	didnotfindskill
}
