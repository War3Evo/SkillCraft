/////FORWARD HANDLES (FH)

new Handle:g_OnUltimateCommandHandle;
new Handle:g_OnAbilityCommandHandle;

///END forwards


public bool:Init_SC_NativesForwards()
{
	g_OnUltimateCommandHandle=CreateGlobalForward("OnUltimateCommand",ET_Ignore,Param_Cell,Param_Cell,Param_Cell,Param_Cell);
	g_OnAbilityCommandHandle=CreateGlobalForward("OnAbilityCommand",ET_Ignore,Param_Cell,Param_Cell,Param_Cell,Param_Cell);

	return true;
}


