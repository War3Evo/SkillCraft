/**
 * Called when a cooldown expires (timed, death, or spawn)
 */
forward OnCooldownExpired(client,skillID,skillNum,bool:expiredByTime);

//when player spawns, fires only in war3 mode
forward On_SC_EventSpawn(client);

//when player dies, fires only in war3 mode
//Distance in feet
//forward OnWar3EventDeath(victim, attacker, distance, attacker_hpleft, String:weapon[32]);
forward On_SC_EventDeath(victim, attacker, distance, attacker_hpleft);

//very generic damage event
//derrived from the game engine's posthurt event
//FRIENDLY FIRE IS NOT FILTERED
forward On_SC_EventPostHurt(victim,attacker,dmgamount,const String:weapon[32],bool:isWarcraft);

//Fired after a player dodges, useful primarily for attaching effects
forward On_SC_DodgePost(victim, attacker);

//Fired before a player dodges, you can edit the dodge chance here
forward On_SC_DodgePre(victim,attacker,Float:chance);

//Fired every time a ward is created
forward OnWardCreated(wardindex, behaviorID);

//Fired every time a ward "pulses"
forward OnWardPulse(wardindex, behaviorID);

//Fired every time a ward "pulses" when a valid target is in range
forward OnWardTrigger(wardindex, victim, owner, behaviorID);

//Fired every time a ward is removed
forward OnWardExpire(wardindex, owner, behaviorID);


/**
 * Called to send id back to plugin if it changes (usually called on a plugin reload)
 */
//forward On_SC_PluginSkillId(String:plugin_shortname[16],reload_skillid);

/**
 * Gets called when after PutInServer, xp retrievcal has started, initial variables may have been set
 * @param client: The client's index.
 */
forward OnSCPlayerAuthed(client);


/**
 * Gets called when someone changes their skill.
 * @param client: The client's index.
 * @param newskill: The player's new skill.
 */
//client is not check if valid or not, still forwarded if client is not present, so you can disable buffs etc
forward On_SC_AnySkillChanged(client, oldskill, newskill);

/**
 * Gets called when someone changes their skill.
 * @param client: The client's index.
 * @param newskill: The player's new skill.
 */
//client is not check if valid or not, still forwarded if client is not present, so you can disable buffs etc
forward On_SC_MasterySkillChanged(client, oldskill, newskill);

/**
 * Gets called when someone changes their skill.
 * @param client: The client's index.
 * @param newskill: The player's new skill.
 */
//client is not check if valid or not, still forwarded if client is not present, so you can disable buffs etc
forward On_SC_TalentSkillChanged(client, oldskill, newskill);

/**
 * Gets called when someone changes their skill.
 * @param client: The client's index.
 * @param newskill: The player's new skill.
 */
//client is not check if valid or not, still forwarded if client is not present, so you can disable buffs etc
forward On_SC_AbilitySkillChanged(client, oldskill, newskill);

/**
 * Gets called when someone changes their skill.
 * @param client: The client's index.
 * @param newskill: The player's new skill.
 */
//client is not check if valid or not, still forwarded if client is not present, so you can disable buffs etc
forward On_SC_UltimateSkillChanged(client, oldskill, newskill);

/**
 * Gets called when the +ultimate or -ultimate command is called, IT ISNT ALWAYS FOR YOUR SKILL, YOU NEED TO CHECK!!!
 * @param client: The client's index.
 * @param skill: The skill for which it was called.
 * @param pressed: If true, +ultimate, false, -ultimate.
 * Isn't always for you, check SC_GetSkill(client,ultimate)==yourultimate
 */
forward OnUltimateCommand(client,bool:pressed,bool:bypass);

/**
 * Gets called when the +ability# or -ability# command is called.
 * If its +ability or -ability (without a number), 0 is passed to ability. 
 * Isn't always for you, check SC_GetSkill(client,ability)==yourability
 * @param client: The client's index.
 * @param ability: The ability number.
 * @param pressed: If true, +ability#, false, -ability#.
 * @param bypass: If true, a separate part of the program is requesting to bypass your skill restrictions to use the ability.
 */
forward OnAbilityCommand(client,abilitybutton,bool:pressed,bool:bypass);


/**
 * Called when a an entity takes damage, requires SDK Hooks until SM natively supports this.
 * @param victim: Victim entity.
 * @param attacker: Attacker entity.
 * @param damage: How much damage is done.
 * @noreturn
 * 
 * order of execution is
 * damageallpre
 * bulletpre (if bullet)
 * damageall
 * bullet  (if bullet)       
 */
//FF triggers this function!!! even though it didnt damage any teammate
//THIS is a theoretical damage given by the engine, if u want real damage dealt use the hurt-event 
//use natives to retrieve inflictor and game damagetype
//becareful when using this, u should only use this to reduce incoming damage. if you want to return damge, only use on bullet (first trigger damage)(below) or check IsBullet
//you may set damage mod percent HERE  
//you may NOT DAMAGE IN HERE  
forward OnW3TakeDmgAllPre(victim,attacker,Float:damage);
//bullet only 
forward OnW3TakeDmgBulletPre(victim,attacker,Float:damage);

//you may NOT set damage mod percent HERE   
//you may DAMAGE in here, however damage will be engine theoretical damage, not actual damage dealt 
forward OnW3TakeDmgAll(victim,attacker,Float:damage);
// BULLET GAME DAMAGE ONLY or Warcraft damage that is allowed to be retriggered (allow more item and skill modifiers), (FILTERED)
//you may NOT set damage mod percent HERE 
//you may DAMAGE in here
forward OnW3TakeDmgBullet(victim,attacker,Float:damage);

//when a weapon fires, via weapon_fire or TF2 Calc critical (which crits must be on)
forward OnWeaponFired(victim,attacker,Float:damage);

/*create an error displayed in various places at runtime*/
native Create_SC_GlobalError(String:str[]);
