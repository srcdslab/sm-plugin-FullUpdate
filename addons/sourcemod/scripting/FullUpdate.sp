#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <FullUpdate>

Handle g_hCBaseClient_UpdateAcknowledgedFramecount;
Handle g_hCBaseClient_OnRequestFullUpdate;

Address m_nDeltaTick;
Address m_nForceWaitForTick;

int g_iLastFullUpdate[MAXPLAYERS + 1] = { 0, ... };

public Plugin myinfo =
{
	name = "FullUpdate",
	author = "BotoX, PŠΣ™ SHUFEN, maxime1907",
	description = "Serverside cl_fullupdate",
	version = "1.2"
}

public void OnPluginStart()
{
	GameData hGameData = new GameData("FullUpdate.games");
	if (hGameData == null) {
		SetFailState("Couldn't load FullUpdate.games game config!");
		return;
	}

	if (GetEngineVersion() != Engine_CSGO)
	{
		// void CBaseClient::UpdateAcknowledgedFramecount()
		StartPrepSDKCall(SDKCall_Raw);

		if(!PrepSDKCall_SetFromConf(hGameData, SDKConf_Virtual, "CBaseClient::UpdateAcknowledgedFramecount"))
		{
			CloseHandle(hGameData);
			SetFailState("PrepSDKCall_SetFromConf(hGameData, SDKConf_Virtual, \"CBaseClient::UpdateAcknowledgedFramecount\" failed!");
			return;
		}
		CloseHandle(hGameData);

		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);

		g_hCBaseClient_UpdateAcknowledgedFramecount = EndPrepSDKCall();
	}
	else
	{
		// void CBaseClient::OnRequestFullUpdate(char const *pchReason)
		StartPrepSDKCall(SDKCall_Raw);
		if (!PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CBaseClient::OnRequestFullUpdate")) {
			delete hGameData;
			SetFailState("PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, \"CBaseClient::OnRequestFullUpdate\") failed!");
			return;
		}
		PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
		g_hCBaseClient_OnRequestFullUpdate = EndPrepSDKCall();

		int offset = hGameData.GetOffset("m_nDeltaTick");
		if (offset == -1) {
			delete hGameData;
			SetFailState("Cannot get offset CBaseClient->m_nDeltaTick");
			return;
		}
		m_nDeltaTick = view_as<Address>(offset);

		offset = hGameData.GetOffset("m_nForceWaitForTick");
		if (offset == -1) {
			delete hGameData;
			SetFailState("Cannot get offset CBaseClient->m_nForceWaitForTick");
			return;
		}
		m_nForceWaitForTick = view_as<Address>(offset);
	}

	delete hGameData;

	RegConsoleCmd("sm_fullupdate", Command_FullUpdate);
	AddCommandListener(Command_cl_fullupdate, "cl_fullupdate");
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

	if (IsFakeClient(client))
		return false;

	if (GetEngineVersion() != Engine_CSGO)
	{
		Address pIClient = GetBaseClient(client);
		if (!pIClient)
			return false;

		SDKCall(g_hCBaseClient_UpdateAcknowledgedFramecount, pIClient, -1);
	}
	else
	{
		Address pIClient = GetBaseClient(client);
		if (!pIClient)
			return false;

		int iDeltaTick = LoadFromAddress(pIClient + m_nDeltaTick, NumberType_Int32);
		int iForceWaitForTick = LoadFromAddress(pIClient + m_nForceWaitForTick, NumberType_Int32);

		if (iForceWaitForTick > 0) {
			return false;
		}
		else {
			if (iDeltaTick == -1)
				return false;

			char sReason[128];
			FormatEx(sReason, sizeof(sReason), "%N called this function by 'sm_fullupdate' command", client);

			SDKCall(g_hCBaseClient_OnRequestFullUpdate, pIClient, sReason);
		}

		// get acknowledged client frame
		StoreToAddress(pIClient + m_nDeltaTick, -1, NumberType_Int32);
	}

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

stock Address GetBaseClient(int client)
{
	Address pIClientTmp = GetClientIClient(client);
	if(!pIClientTmp)
		return Address_Null;

	// The IClient vtable is +4 from the IGameEventListener2 (CBaseClient) vtable due to multiple inheritance.
	return pIClientTmp - view_as<Address>(4);
}
