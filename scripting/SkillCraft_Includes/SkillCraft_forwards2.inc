
new Handle:g_OnWar3PluginReadyHandle2;

///END forwards


bool:War3Source_InitForwards2()
{
	g_OnWar3PluginReadyHandle2=CreateGlobalForward("OnWar3LoadRaceOrItemOrdered2",ET_Ignore,Param_Cell,Param_Cell,Param_String);//ordered
	return true;
}
