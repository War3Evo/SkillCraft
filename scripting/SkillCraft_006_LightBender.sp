#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdktools_stocks>
#include <sdktools_functions>

#include "SkillCraft_Includes/SkillCraft_Interface"

new SKILL_RED, SKILL_GREEN, SKILL_BLUE, SKILL_YELLOW, ULT_DISCO;

new ClientTarget[64];

const Maximum_Players_array=100;

new HaloSprite, BeamSprite;

public Plugin:myinfo = 
{
	name = "Skills from Light Bender",
	author = "SkillCraft Team",
	description = "Skills from the Light Bender race for War3Source.",
	version = "1.0.0.0",
	url = ""
};

public OnMapStart()
{
	HaloSprite = PrecacheModel( "materials/sprites/halo01.vmt" );
	BeamSprite = PrecacheModel( "materials/sprites/laser.vmt" );
}

public On_SC_LoadSkillOrdered(num)
{
	if(num==80)
	{
		SKILL_RED = SC_CreateNewSkill( "Red Laser: Burn", "Red.Laser", "Burn your targets", talent );
	}
	if(num==81)
	{
		SKILL_GREEN = SC_CreateNewSkill( "Green Laser: Hex", "Green.Laser",
		"Hex your Targets for 1.0 second (1.25 second cooldown)\nHexing makes players skills not work.", talent);
	}
	if(num==82)
	{
		SKILL_BLUE = SC_CreateNewSkill( "Blue Laser: Freeze", "Blue.Laser", "Freeze your Targets for 0.75 seconds (10 second cooldown)", talent);
	}
	if(num==83)
	{
		SKILL_YELLOW = SC_CreateNewSkill( "Yellow Laser: ", "Yellow.Laser",
		"Silence your Targets for 1.0 second (1.25 second cooldown)\nSilence makes players unable to cast spells.", talent );
	}
	if(num==84)
	{
		ULT_DISCO = SC_CreateNewSkill( "Teleport to random ally", "Teleport.Rand", "Teleport a random ally!", ultimate );
	}
}

public On_SC_TalentSkillChanged(client, oldskill, newskill)
{
	if(oldskill==SKILL_GREEN)
	{
		SC_SetBuff( client, bHexed, SKILL_GREEN, false );
	}
	else if(oldskill==SKILL_BLUE)
	{
		SC_SetBuff( client, bNoMoveMode, SKILL_BLUE, false );
	}
	else if(oldskill==SKILL_YELLOW)
	{
		SC_SetBuff( client, bSilenced, SKILL_YELLOW, false );
	}
}


public OnWar3EventDeath( victim, attacker )
{
	if(SC_GetBuff( victim, bHexed, SKILL_GREEN )==true)
		SC_SetBuff( victim, bHexed, SKILL_GREEN, false );
	
	if(SC_GetBuff( victim, bNoMoveMode, SKILL_BLUE )==true)
		SC_SetBuff( victim, bNoMoveMode, SKILL_BLUE, false );

	if(SC_GetBuff( victim, bSilenced, SKILL_YELLOW )==true)
		SC_SetBuff( victim, bSilenced, SKILL_YELLOW, false );
}

//public OnWar3EventPostHurt( victim, attacker, damage )
public On_SC_TakeDmgAll(victim,attacker,Float:damage)
{
	if(!SC_IsOwnerSentry(attacker) && SC_GetDamageIsBullet() && ValidPlayer( victim, true ) && ValidPlayer( attacker, true ) && GetClientTeam( victim ) != GetClientTeam( attacker ) )
	{
		if( !SC_HasImmunity(victim,Immunity_Skills) )
		{
			if( SC_HasSkill( attacker,SKILL_RED ) && !Hexed( attacker, false ) && GetRandomFloat( 0.0, 1.0 ) <= 0.25 && !SC_HasImmunity(victim,Immunity_Skills) )
			{
				IgniteEntity( victim, 1.0 );
				//IgniteEntity( victim, 5.0 );
	
				//CPrintToChat( victim, "{red}Red Laser{default} :  Burn" );
				//CPrintToChat( attacker, "{red}Red Laser{default} :  Burn" );
	
				new Float:StartPos[3];
				new Float:EndPos[3];
	
				GetClientAbsOrigin( victim, StartPos );
	
				GetClientAbsOrigin( victim, EndPos );
	
				EndPos[0] += GetRandomFloat( -100.0, 100.0 );
				EndPos[1] += GetRandomFloat( -100.0, 100.0 );
				EndPos[2] += GetRandomFloat( -100.0, 100.0 );

				TE_SetupBeamPoints( StartPos, EndPos, BeamSprite, HaloSprite, 0, 1, 4.0, 20.0, 2.0, 0, 0.0, { 255, 11, 15, 255 }, 1 );
				TE_SendToAll();
	
				GetClientAbsOrigin( victim, EndPos );
	
				EndPos[0] += GetRandomFloat( -100.0, 100.0 );
				EndPos[1] += GetRandomFloat( -100.0, 100.0 );
				EndPos[2] += GetRandomFloat( -100.0, 100.0 );
	
				TE_SetupBeamPoints( StartPos, EndPos, BeamSprite, HaloSprite, 0, 1, 4.0, 20.0, 2.0, 0, 0.0, { 255, 11, 15, 255 }, 1 );
				TE_SendToAll();
	
				GetClientAbsOrigin( victim, EndPos );
	
				EndPos[0] += GetRandomFloat( -100.0, 100.0 );
				EndPos[1] += GetRandomFloat( -100.0, 100.0 );
				EndPos[2] += GetRandomFloat( -100.0, 100.0 );
	
				TE_SetupBeamPoints( StartPos, EndPos, BeamSprite, HaloSprite, 0, 1, 4.0, 20.0, 2.0, 0, 0.0, { 255, 11, 15, 255 }, 1 );
				TE_SendToAll();
			}
			
			if( SC_HasSkill( attacker,SKILL_GREEN ) && !Hexed( attacker, false ) && GetRandomFloat( 0.0, 1.0 ) <= 0.25 && !SC_HasImmunity(victim,Immunity_Skills) && SC_SkillNotInCooldown(attacker, SKILL_GREEN, true))
			{
				//SC_ShakeScreen( victim );
				SC_SetBuff( victim, bHexed, SKILL_GREEN, true );
				CreateTimer( 1.0, StopHex, victim );
				SC_CooldownMGR( attacker, 1.25, SKILL_GREEN, true, true);
	
				//CPrintToChat( victim, "{green}Green Laser{default} :  Hex" );
				//CPrintToChat( attacker, "{green}Green Laser{default} :  Hex" );
	
				new Float:StartPos[3];
				new Float:EndPos[3];
	
				GetClientAbsOrigin( victim, StartPos );
	
				GetClientAbsOrigin( victim, EndPos );
	
				EndPos[0] += GetRandomFloat( -100.0, 100.0 );
				EndPos[1] += GetRandomFloat( -100.0, 100.0 );
				EndPos[2] += GetRandomFloat( -100.0, 100.0 );

				TE_SetupBeamPoints( StartPos, EndPos, BeamSprite, HaloSprite, 0, 1, 4.0, 20.0, 2.0, 0, 0.0, { 11, 255, 15, 255 }, 1 );
				TE_SendToAll();
	
				GetClientAbsOrigin( victim, EndPos );
	
				EndPos[0] += GetRandomFloat( -100.0, 100.0 );
				EndPos[1] += GetRandomFloat( -100.0, 100.0 );
				EndPos[2] += GetRandomFloat( -100.0, 100.0 );
	
				TE_SetupBeamPoints( StartPos, EndPos, BeamSprite, HaloSprite, 0, 1, 4.0, 20.0, 2.0, 0, 0.0, { 11, 255, 15, 255 }, 1 );
				TE_SendToAll();
	
				GetClientAbsOrigin( victim, EndPos );
	
				EndPos[0] += GetRandomFloat( -100.0, 100.0 );
				EndPos[1] += GetRandomFloat( -100.0, 100.0 );
				EndPos[2] += GetRandomFloat( -100.0, 100.0 );

				TE_SetupBeamPoints( StartPos, EndPos, BeamSprite, HaloSprite, 0, 1, 4.0, 20.0, 2.0, 0, 0.0, { 11, 255, 15, 255 }, 1 );
				TE_SendToAll();
			}
			
			if( SC_HasSkill( attacker,SKILL_BLUE ) && !Hexed( attacker, false ) && GetRandomFloat( 0.0, 1.0 ) <= 0.25 && !SC_HasImmunity(victim,Immunity_Skills) && SC_SkillNotInCooldown(attacker, SKILL_BLUE, true)) 
			{
				SC_SetBuff( victim, bNoMoveMode, SKILL_BLUE, true );
				//CreateTimer( 3.0, StopFreeze, victim );
				CreateTimer( 0.75, StopFreeze, victim );
				SC_CooldownMGR( attacker, 10.0, SKILL_BLUE, true, true);
	
				//CPrintToChat( victim, "{blue}Blue Laser{default} :  Freeze" );
				//CPrintToChat( attacker, "{blue}Blue Laser{default} :  Freeze" );
	
				new Float:StartPos[3];
				new Float:EndPos[3];
	
				GetClientAbsOrigin( victim, StartPos );
				GetClientAbsOrigin( victim, EndPos );
	
				EndPos[0] += GetRandomFloat( -100.0, 100.0 );
				EndPos[1] += GetRandomFloat( -100.0, 100.0 );
				EndPos[2] += GetRandomFloat( -100.0, 100.0 );

				TE_SetupBeamPoints( StartPos, EndPos, BeamSprite, HaloSprite, 0, 1, 4.0, 20.0, 2.0, 0, 0.0, { 15, 11, 255, 255 }, 1 );
				TE_SendToAll();
	
				GetClientAbsOrigin( victim, EndPos );
	
				EndPos[0] += GetRandomFloat( -100.0, 100.0 );
				EndPos[1] += GetRandomFloat( -100.0, 100.0 );
				EndPos[2] += GetRandomFloat( -100.0, 100.0 );
	
				TE_SetupBeamPoints( StartPos, EndPos, BeamSprite, HaloSprite, 0, 1, 4.0, 20.0, 2.0, 0, 0.0, { 15, 11, 255, 255 }, 1 );
				TE_SendToAll();
	
				GetClientAbsOrigin( victim, EndPos );
	
				EndPos[0] += GetRandomFloat( -100.0, 100.0 );
				EndPos[1] += GetRandomFloat( -100.0, 100.0 );
				EndPos[2] += GetRandomFloat( -100.0, 100.0 );
	
				TE_SetupBeamPoints( StartPos, EndPos, BeamSprite, HaloSprite, 0, 1, 4.0, 20.0, 2.0, 0, 0.0, { 15, 11, 255, 255 }, 1 );
				TE_SendToAll();
			}

			if( SC_HasSkill( attacker,SKILL_YELLOW ) && !Hexed( attacker, false ) && GetRandomFloat( 0.0, 1.0 ) <= 0.25 && !SC_HasImmunity(victim,Immunity_Skills) && SC_SkillNotInCooldown(attacker, SKILL_YELLOW, true)) 
			{
				SC_SetBuff( victim, bSilenced, SKILL_YELLOW, true );
				//CreateTimer( 3.0, StopFreeze, victim );
				CreateTimer( 1.0, StopSilence, victim );
				SC_CooldownMGR( attacker, 1.25, SKILL_YELLOW, true, true);
	
				//CPrintToChat( victim, "{blue}Blue Laser{default} :  Freeze" );
				//CPrintToChat( attacker, "{blue}Blue Laser{default} :  Freeze" );
	
				new Float:StartPos[3];
				new Float:EndPos[3];
	
				GetClientAbsOrigin( victim, StartPos );
				GetClientAbsOrigin( victim, EndPos );
	
				EndPos[0] += GetRandomFloat( -100.0, 100.0 );
				EndPos[1] += GetRandomFloat( -100.0, 100.0 );
				EndPos[2] += GetRandomFloat( -100.0, 100.0 );

				TE_SetupBeamPoints( StartPos, EndPos, BeamSprite, HaloSprite, 0, 1, 4.0, 20.0, 2.0, 0, 0.0, { 255, 255, 25, 255 }, 1 );
				TE_SendToAll();
	
				GetClientAbsOrigin( victim, EndPos );
	
				EndPos[0] += GetRandomFloat( -100.0, 100.0 );
				EndPos[1] += GetRandomFloat( -100.0, 100.0 );
				EndPos[2] += GetRandomFloat( -100.0, 100.0 );
	
				TE_SetupBeamPoints( StartPos, EndPos, BeamSprite, HaloSprite, 0, 1, 4.0, 20.0, 2.0, 0, 0.0, { 255, 255, 25, 255 }, 1 );
				TE_SendToAll();
	
				GetClientAbsOrigin( victim, EndPos );
	
				EndPos[0] += GetRandomFloat( -100.0, 100.0 );
				EndPos[1] += GetRandomFloat( -100.0, 100.0 );
				EndPos[2] += GetRandomFloat( -100.0, 100.0 );
	
				TE_SetupBeamPoints( StartPos, EndPos, BeamSprite, HaloSprite, 0, 1, 4.0, 20.0, 2.0, 0, 0.0, { 255, 255, 25, 255 }, 1 );
				TE_SendToAll();
			}
		}
	}
}

public Action:StopSilence( Handle:timer, any:client )
{
	if( ValidPlayer( client ) )
	{
		SC_SetBuff( client, bSilenced, SKILL_YELLOW, false );
	}
}

public Action:StopFreeze( Handle:timer, any:client )
{
	if( ValidPlayer( client ) )
	{
		SC_SetBuff( client, bNoMoveMode, SKILL_BLUE, false );
	}
}

public Action:StopHex( Handle:timer, any:client )
{
	if( ValidPlayer( client ) )
	{
		SC_SetBuff( client, bHexed, SKILL_GREEN, false );
	}
}

public OnUltimateCommand(client,bool:pressed,bool:bypass)
{
	if( SC_HasSkill(client,ULT_DISCO) && pressed && ValidPlayer( client, true ) )
	{
		if(!SC_HasImmunity(ClientTarget[client],Immunity_Ultimates))
		if( SC_SkillNotInCooldown( client, ULT_DISCO, true ) )
		{
			Disco( client );
		}
		else
		{
			PrintHintText( client, "Ultimate is on cooldown" );
		}
	}
}

stock Disco( client )
{
	// changing so that the client goes to a random ally player
	if( GetClientTeam( client ) == TEAM_T )
		ClientTarget[client] = SC_LightBender_GetRandomPlayer( "#t", true, true );
	if( GetClientTeam( client ) == TEAM_CT )
		ClientTarget[client] = SC_LightBender_GetRandomPlayer( "#ct", true, true );

	if( ClientTarget[client] == 0 || ClientTarget[client] == client )
	{
		PrintHintText( client, "No Target Found" );
	}
	else
	{
		//GetClientAbsOrigin( ClientTarget[client], ClientPos[client] );
		CreateTimer( 3.0, Teleport, client );

		new String:NameAttacker[64];
		GetClientName( client, NameAttacker, 64 );
		
		new String:NameVictim[64];
		GetClientName( ClientTarget[client], NameVictim, 64 );
		
		PrintToChat( ClientTarget[client], "\x05: \x4%s \x03will teleport to you and to aid you in your \x04fight \x03in \x043 \x03seconds", NameAttacker );
		PrintToChat( client, "\x05: \x03You will teleport to \x04%s \x03and aid him/her in thier \x04fight \x03in \x043 \x03seconds", NameVictim );
		
		SC_CooldownMGR( client, 20.0, ULT_DISCO, true, true);
	}
}

public Action:Teleport( Handle:timer, any:client )
{
	if( ValidPlayer( ClientTarget[client], true ) )
	{
		new Float:ang[3];
		new Float:ClientPos[3];
		GetClientAbsOrigin( ClientTarget[client], ClientPos );
		GetClientEyeAngles( ClientTarget[client], ang);
		//ClientPos[1] -= 50;
		// lightbender teleports to his allly
		TeleportEntity( client, ClientPos, ang, NULL_VECTOR );
	}
	else
	{
		SC_CooldownReset(client, ULT_DISCO);
		PrintHintText( client, "Your Target Died!" );
	}
}

public SC_LightBender_GetRandomPlayer( const String:type[], bool:check_alive, bool:check_immunity )
{
	new targettable[MaxClients];
	new target = 0;
	new bool:all;
	new x = 0;
	new team;
	if( StrEqual( type, "#t" ) )
	{
		team = TEAM_T;
		all = false;
	}
	else if( StrEqual( type, "#ct" ) )
	{
		team = TEAM_CT;
		all = false;
	}
	else if( StrEqual( type, "#a" ) )
	{
		team = 0;
		all = true;
	}
	for( new i = 1; i <= MaxClients; i++ )
	{
		if( i > 0 && i <= MaxClients && IsClientConnected( i ) && IsClientInGame( i ) )
		{
			if( check_alive && !IsPlayerAlive( i ) )
	continue;
			if( check_immunity && SC_HasImmunity( i, Immunity_Ultimates ) )
	continue;
			if( !all && GetClientTeam( i ) != team )
	continue;
			targettable[x] = i;
			x++;
		}
	}
	for( new y = 0; y <= x; y++ )
	{
		if( target == 0 )
		{
			target = targettable[GetRandomInt( 0, x - 1 )];
		}
		else if( target != 0 && target > 0 )
		{
			return target;
		}
	}
	return 0;
}
