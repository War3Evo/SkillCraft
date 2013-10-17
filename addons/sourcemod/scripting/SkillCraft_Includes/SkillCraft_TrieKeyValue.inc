//TKV = trie key value , a abstract data storage, emulates cvars for war3
//Creates internal war3 cvars. returns a id to your cvar, store it!
//cvarid of 0 is null null (filled auto)
//make sure native have binded (on plugin start is fine)
native SC_CreateCvar(String:cvarstr[],String:cvarvalue[],String:cvardesc[],ReplaceCvar=0);
native SC_GetCvar(cvarid,String:returnstr[],maxlen);
native SC_SetCvar(cvarid,String:cvarvalue[]);

//returns -1 if not found, otherwise returns cvar id
native SC_FindCvar(String:cvar[]);
native Handle:SC_CvarList(); //returns a handle arraylist of cvar list (no values, names only. CLOSE THIS!!!

//get cvar value when you have the key
native SC_GetCvarByString(String:cvarstr[],String:returnstr[],maxlen);

//get actual cvar name: undead_blah (the KEY)
native SC_GetCvarActualString(cvarid,String:returnstr[],maxlen);

stock SC_CreateCvarInt(String:cvarstr[],intval,String:cvardesc[]) {
	decl String:str[1024];
	Format(str,sizeof(str),"%d",intval);
	return SC_CreateCvar(cvarstr,str,cvardesc);
}
stock SC_GetCvarInt(cvarid) {
	decl String:ret[1024];
	SC_GetCvar(cvarid, ret, sizeof(ret));
	//PrintToChatAll("%s %d",ret,StringToInt(ret));
	return StringToInt(ret);
}
stock SC_SetCvarInt(cvarid, intval) {
	decl String:str[1024];
	Format(str, sizeof(str), "%d", intval);
	return SC_SetCvar(cvarid, str);
}
stock SC_CreateCvarFloat(String:cvarstr[],intval,String:cvardesc[]) {
	decl String:str[1024];
	Format(str,sizeof(str),"%f",intval);
	SC_CreateCvar(cvarstr,str,cvardesc);
}
stock SC_GetCvarFloat(cvarid) {
	decl String:ret[1024];
	SC_GetCvar(cvarid, ret, sizeof(ret));
	return StringToFloat(ret);
}
stock SC_SetCvarFloat(cvarid, intval) {
	decl String:str[1024];
	Format(str, sizeof(str), "%f", intval);
	SC_SetCvar(cvarid, str);
}

