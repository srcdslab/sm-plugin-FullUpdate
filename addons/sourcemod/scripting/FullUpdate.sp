#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <FullUpdate>

Handle g_hCBaseClient_UpdateAcknowledgedFramecount;
int g_iLastFullUpdate[MAXPLAYERS + 1] = { 0, ... };

public Plugin myinfo =
{
	name = "FullUpdate",
	author = "BotoX",
	description = "Serverside cl_fullupdate",
	version = "1.0"
}

public void OnPluginStart()
{
	Handle hGameConf = LoadGameConfigFile("FullUpdate.games");
	if(hGameConf == INVALID_HANDLE)
	{
		SetFailState("Couldn't load FullUpdate.games game config!");
		return;
	}

	// void CBaseClient::UpdateAcknowledgedFramecount()
	StartPrepSDKCall(SDKCall_Raw);

	if(!PrepSDKCall_SetFromConf(hGameConf, SDKConf_Virtual, "CBaseClient::UpdateAcknowledgedFramecount"))
	{
		CloseHandle(hGameConf);
		SetFailState("PrepSDKCall_SetFromConf(hGameConf, SDKConf_Virtual, \"CBaseClient::UpdateAcknowledgedFramecount\" failed!");
		return;
	}
	CloseHandle(hGameConf);

	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);

	g_hCBaseClient_UpdateAcknowledgedFramecount = EndPrepSDKCall();

	RegConsoleCmd("sm_fullupdate", Command_FullUpdate);
	RegConsoleCmd("cl_fullupdate", Command_FullUpdate);
	RegConsoleCmd("fullupdate", Command_FullUpdate);
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("ClientFullUpdate", Native_FullUpdate);
	RegPluginLibrary("FullUpdate");

	return APLRes_Success;
}

public void OnClientConnected(int client)
{
	g_iLastFullUpdate[client] = 0;
}

bool FullUpdate(int client)
{
	if(g_iLastFullUpdate[client] + 1 > GetTime())
		return false;

	// The IClient vtable is +4 from the IGameEventListener2 (CBaseClient) vtable due to multiple inheritance.
	Address pIClientTmp = GetClientIClient(client);
	Address pIClient = pIClientTmp - view_as<Address>(4);
	if(!pIClientTmp || !pIClient)
		return false;

	SDKCall(g_hCBaseClient_UpdateAcknowledgedFramecount, pIClient, -1);

	g_iLastFullUpdate[client] = GetTime();
	return true;
}

public int Native_FullUpdate(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);

	if(client > MaxClients || client <= 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Client is not valid.");
		return 0;
	}

	if(!IsClientInGame(client))
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Client is not in-game.");
		return 0;
	}

	if(IsFakeClient(client))
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Client is fake-client.");
		return 0;
	}

	return FullUpdate(client);
}

public Action Command_FullUpdate(int client, int args)
{
	FullUpdate(client);
	return Plugin_Handled;
}
