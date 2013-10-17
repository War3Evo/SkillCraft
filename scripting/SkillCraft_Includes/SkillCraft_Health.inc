/**
 * heals with the limit of (skillcraft ) max hp
 * @noreturn
 */
stock SC_HealToMaxHP(client, addhp)
{
	new maxhp=SC_GetMaxHP(client);
	new currenthp=GetClientHealth(client);
	if(currenthp<maxhp){ ///do not make hp lower
		new newhp=GetClientHealth(client)+addhp;
		if (newhp>maxhp){
			newhp=maxhp;
		}
		nsEntity_SetHealth(client,newhp);
	}
	return 0;
}

/**
 * heals with the limit of your specified HP
 * @noreturn
 */
stock SC_HealToHP(client, addhp, maximumHP) {
	new currenthp = GetClientHealth(client);
	new newhp = currenthp + addhp;
	if (newhp > maximumHP) {
		newhp = maximumHP;
	}

	SetEntityHealth(client, newhp);
	// below creates a hud above health plus on user screen
	// quite annoying, so temporary removed
	//if (currenthp < newhp)
	//{
		//SC_TFHealingEvent(client, newhp - currenthp);
	//}
}

/**
 * heals to max hp * 1.5 buff in tf2
 * no extra hp in other games 
 * @noreturn
 */
stock SC_HealToBuffHP(client, addhp)
{
	new maxhp=RoundFloat(float(SC_GetMaxHP(client))*1.5);
	new currenthp=GetClientHealth(client);
	if(currenthp<maxhp){ ///do not make hp lower
		new newhp=GetClientHealth(client)+addhp;
		if (newhp>maxhp){
			newhp=maxhp;
		}
		nsEntity_SetHealth(client,newhp);
	}
}

/** 
 * direcly decreases the player's hp by X amount (Not via damage)
 * this health removal is "non lethal"
 */
stock SC_DecreaseHP(client, decrease)
{
	new client = GetNativeCell(1);
	new dechp = GetNativeCell(2);
	new newhp=GetClientHealth(client)-dechp;
	if(newhp<1){
		newhp=1;
	}
	nsEntity_SetHealth(client,newhp);
}

// This one is actually used by HealToMaxHP, HealToBuffHP aswell as DecreaseHP
stock nsEntity_SetHealth(entity, health) {
	//new currenthp = GetEntProp(entity, Prop_Data, "m_iHealth");
	SetEntProp(entity, Prop_Data, "m_iHealth", health);
	ChangeEdictState(entity, 0);
	// below creates a hud above health plus on user screen
	// quite annoying, so temporary removed
	//if (currenthp < newhp)
	//{
		//SC_TFHealingEvent(client, newhp - currenthp);
	//}
}

/** 
 * Creates a event to show a player in the HUD how much HP he has healed
 */
stock SC_TFHealingEvent(client, amount_healed)
{
    if (!ValidPlayer(client, true) || IsFakeClient(client))
    {
        return;
    }
    
    new Handle:event = CreateEvent("player_healonhit");
    SetEventInt(event, "entindex", client);
    SetEventInt(event, "amount", amount_healed);
    FireEvent(event);
}
