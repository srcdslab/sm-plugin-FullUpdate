#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <FullUpdate>

GlobalForward g_hForward_StatusOK;
GlobalForward g_hForward_StatusNotOK;

Handle g_hCBaseClient_UpdateAcknowledgedFramecount;
Handle g_hGetClient;

Address g_pBaseServer;

int g_iLastFullUpdate[MAXPLAYERS + 1] = { 0, ... };

public Plugin myinfo =
{
	name = "FullUpdate",
	author = "BotoX, PŠΣ™ SHUFEN, maxime1907",
	description = "Serverside cl_fullupdate",
	version = FullUpdate_VERSION,
	url = "https://github.com/srcdslab/sm-plugin-FullUpdate"
}

public void OnPluginStart()
{
	GameData hGameData = new GameData("FullUpdate.games");
	if (hGameData == null) {
		SetFailState("Couldn't load FullUpdate.games game config!");
		return;
	}

#if !defined GetClientIClient
	g_pBaseServer = GameConfGetAddress(hGameData, "CBaseServer");
	if(g_pBaseServer == Address_Null)
	{
		delete hGameData;
		SetFailState("Couldn't get BaseServer address!");
		return;
	}

	StartPrepSDKCall(SDKCall_Raw);
	if (!PrepSDKCall_SetFromConf(hGameData, SDKConf_Virtual, "CBaseServer::GetClient"))
	{
		delete hGameData;
		SetFailState("PrepSDKCall_SetFromConf(hGameData, SDKConf_Virtual, \"CBaseServer::GetClient\" failed!");
		return;
	}
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	g_hGetClient = EndPrepSDKCall();
#endif

	// void CBaseClient::UpdateAcknowledgedFramecount()
	StartPrepSDKCall(SDKCall_Raw);
	if(!PrepSDKCall_SetFromConf(hGameData, SDKConf_Virtual, "CBaseClient::UpdateAcknowledgedFramecount"))
	{
		delete hGameData;
		SetFailState("PrepSDKCall_SetFromConf(hGameData, SDKConf_Virtual, \"CBaseClient::UpdateAcknowledgedFramecount\" failed!");
		return;
	}

	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);

	g_hCBaseClient_UpdateAcknowledgedFramecount = EndPrepSDKCall();

	delete hGameData;

	RegConsoleCmd("fullupdate", Command_FullUpdate);
	RegConsoleCmd("sm_fullupdate", Command_FullUpdate);
	AddCommandListener(Command_cl_fullupdate, "cl_fullupdate");
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("ClientFullUpdate", Native_FullUpdate);

	g_hForward_StatusOK = CreateGlobalForward("FullUpdate_OnPluginOK", ET_Ignore);
	g_hForward_StatusNotOK = CreateGlobalForward("FullUpdate_OnPluginNotOK", ET_Ignore);

	RegPluginLibrary("FullUpdate");

	return APLRes_Success;
}

public void OnAllPluginsLoaded()
{
	SendForward_Available();
}

public void OnPluginPauseChange(bool pause)
{
	if (pause)
		SendForward_NotAvailable();
	else
		SendForward_Available();
}

public void OnPluginEnd()
{
	SendForward_NotAvailable();
}

public void OnClientConnected(int client)
{
	g_iLastFullUpdate[client] = 0;
}

bool FullUpdate(int client)
{
	if(g_iLastFullUpdate[client] + 1 > GetTime())
		return false;

	if (IsFakeClient(client))
		return false;

	Address pIClient = GetBaseClient(client);
	if (!pIClient)
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

public Action Command_cl_fullupdate(int client, const char[] command, int args)
{
	Command_FullUpdate(client, -1);
	return Plugin_Handled;
}

public Action Command_FullUpdate(int client, int args)
{
	FullUpdate(client);
	return Plugin_Handled;
}

#if !defined GetClientIClient
stock Address GetClientIClient(int client)
{
	return SDKCall(g_hGetClient, g_pBaseServer, client-1);
}
#endif

stock Address GetBaseClient(int client)
{
	Address pIClientTmp = GetClientIClient(client);
	if(!pIClientTmp)
		return Address_Null;

	// The IClient vtable is +4 from the IGameEventListener2 (CBaseClient) vtable due to multiple inheritance.
	return pIClientTmp - view_as<Address>(4);
}

stock void SendForward_Available()
{
	Call_StartForward(g_hForward_StatusOK);
	Call_Finish();
}

stock void SendForward_NotAvailable()
{
	Call_StartForward(g_hForward_StatusNotOK);
	Call_Finish();
}