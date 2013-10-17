/*
File: natives.inc
Description: All the natives that keep us from having to make a C++ extension,
I <3 SourceMod :) 
* 
* natives are initiated and defined
* 
* 
* MUST LIST THE NATIE IN THE SkillCraft_Interface <<- not sure about that.
*/

#pragma semicolon 1

#include <sourcemod>
#include "SkillCraft_Includes/SkillCraft_Interface"

new bool:g_bCanEnumerateMsgType = false;
new UserMsg:g_umsgKeyHintText = INVALID_MESSAGE_ID;
new UserMsg:g_umsgFade = INVALID_MESSAGE_ID;
new UserMsg:g_umsgShake = INVALID_MESSAGE_ID;


public Plugin:myinfo= 
{
	name="SkillCraft Effects Engine",
	author="SkillCraft Team",
	description="SkillCraft Effects Engine",
	version="1.0",
};


public bool:Init_SC_NativesForwards()
{
	///LIST ALL THESE NATIVES IN INTERFACE
	
	CreateNative("SC_GetSC_Version",Native_SC_GetSC_Version);
	//CreateNative("SC_GetSC_Revision",Native_SC_GetSC_Revision);
	
	CreateNative("SC_FlashScreen",Native_SC_FlashScreen);
	CreateNative("SC_ShakeScreen",Native_SC_ShakeScreen);
	
	CreateNative("SC_SpawnPlayer",Native_SC_SpawnPlayer);


	//CreateNative("SC_PrecacheSound",Native_SC_PrecacheSound);

	CreateNative("SC_KeyHintText",Native_SC_KeyHintText);	
	return true;
}

public Native_SC_SpawnPlayer(Handle:plugin,numParams)
{
	new client=GetNativeCell(1);
	new ignore_check=GetNativeCell(2);
	if(ValidPlayer(client,false) && (ignore_check!=0 || !IsPlayerAlive(client)))
	{
		//SC_Respawn(client); //from offsets.inc
		TF2_RespawnPlayer(client);
	}
}


public Native_SC_GetSC_Version(Handle:plugin,numParams){	
	SetNativeString(1,"1.0",GetNativeCell(2));
}

public GetStatsVersion(){
	//return SC_GetStatsVersion();
}

public OnPluginStart()
{
    if(GetFeatureStatus(FeatureType_Native, "GetUserMessageType") == FeatureStatus_Available)
    {
        g_bCanEnumerateMsgType = true;
    }

    // Lookup message id's and cache them.
    g_umsgKeyHintText = GetUserMessageId("KeyHintText");
    if (g_umsgKeyHintText == INVALID_MESSAGE_ID)
    {
        LogError("This game doesn't support KeyHintText!");
    }

    g_umsgFade = GetUserMessageId("Fade");
    if (g_umsgFade == INVALID_MESSAGE_ID)
    {
        LogError("This game doesn't support Fade!");
    }

    g_umsgShake = GetUserMessageId("Shake");
    if (g_umsgShake == INVALID_MESSAGE_ID)
    {
        LogError("This game doesn't support Shake!");
    }
}


public Native_SC_FlashScreen(Handle:plugin,numParams)
{
    new client=GetNativeCell(1);
    new color[4];
    GetNativeArray(2,color,4);
    new Float:holdduration = GetNativeCell(3);
    new Float:fadeduration = GetNativeCell(4);
    new flags = GetNativeCell(5);
    if(ValidPlayer(client,false) && !IsFakeClient(client))
    {
        new Handle:hBf = StartMessageExOne(g_umsgFade,client);
        if(hBf != INVALID_HANDLE)
        {
            if (g_bCanEnumerateMsgType && GetUserMessageType() == UM_Protobuf)
            {
                PbSetInt(hBf, "duration", RoundFloat(255.0*fadeduration));
                PbSetInt(hBf, "hold_time", RoundFloat(255.0*holdduration));
                PbSetInt(hBf, "flags", flags);
                PbSetColor(hBf, "clr", color);
            }
            else
            {
                BfWriteShort(hBf,RoundFloat(255.0*fadeduration));
                BfWriteShort(hBf,RoundFloat(255.0*holdduration)); //holdtime
                BfWriteShort(hBf,flags);
                BfWriteByte(hBf,color[0]);
                BfWriteByte(hBf,color[1]);
                BfWriteByte(hBf,color[2]);
                BfWriteByte(hBf,color[3]);
            }
            EndMessage();
        }
    }
}

public Native_SC_ShakeScreen(Handle:plugin,numParams)
{
    new client = GetNativeCell(1);
    new Float:duration = GetNativeCell(2);
    new Float:magnitude = GetNativeCell(3);
    new Float:noise = GetNativeCell(4);
    if(ValidPlayer(client,false) && !IsFakeClient(client))
    {
        new Handle:hBf = StartMessageExOne(g_umsgShake,client);
        if(hBf != INVALID_HANDLE)
        {
            if (g_bCanEnumerateMsgType && GetUserMessageType() == UM_Protobuf)
            {
                PbSetInt(hBf, "command", 0);
                PbSetFloat(hBf, "local_amplitude", magnitude);
                PbSetFloat(hBf, "frequency", noise);
                PbSetFloat(hBf, "duration", duration);
            }
            else
            {
                BfWriteByte(hBf,0);
                BfWriteFloat(hBf,magnitude);
                BfWriteFloat(hBf,noise);
                BfWriteFloat(hBf,duration);
            }
            EndMessage();
        }
    }
}

public Native_SC_KeyHintText(Handle:plugin,numParams)
{
    new client = GetNativeCell(1);
    new Handle:userMessage = StartMessageExOne(g_umsgKeyHintText, client);
    if(userMessage != INVALID_HANDLE)
    {
        decl String:format[254];
        
        // We don't need to format the string if we just received 2 params.
        if(numParams > 2)
        {
            decl String:buffer[254];

            GetNativeString(2, buffer, sizeof(buffer));
            GetNativeString(3, format, sizeof(buffer));
            
            SetGlobalTransTarget(client);
            FormatNativeString(0, 2, 3, sizeof(format), _, format);
        }
        else
        {
            GetNativeString(2, format, sizeof(format));
        }

        if (g_bCanEnumerateMsgType && GetUserMessageType() == UM_Protobuf)
        {
            PbSetString(userMessage, "hints", format);
        }
        else
        {
            BfWriteByte(userMessage, 1);
            BfWriteString(userMessage, format);
        }
        
        EndMessage();
    }
    return true;
}

stock Handle:StartMessageExOne(UserMsg:msg, client, flags=0)
{
    new players[1];
    players[0] = client;

    return StartMessageEx(msg, players, 1, flags);
}


