

#include <sourcemod>
#include "SkillCraft_Includes/SkillCraft_Interface"

new g_offsCollisionGroup;
public Plugin:myinfo= 
{
	name="SkillCraft Engine Player Collisions",
	author="SkillCraft Team",
	description="War3Source Core Plugins",
	version="1.0",
};





public OnPluginStart()
{
	g_offsCollisionGroup = FindSendPropOffs("CBaseEntity", "m_CollisionGroup");
}

public bool:Init_SC_NativesForwards()
{
	return true;
}

stock SetCollidable(client,bool:collidable){
	SetEntData(entity, g_offsCollisionGroup, collidable?5:2, 4, true);
}
