#if defined _FullUpdate_Included
	#endinput
#endif
#define _FullUpdate_Included

#define FullUpdate_V_MAJOR   "1"
#define FullUpdate_V_MINOR   "3"
#define FullUpdate_V_PATCH   "2"

#define FullUpdate_VERSION   FullUpdate_V_MAJOR..."."...FullUpdate_V_MINOR..."."...FullUpdate_V_PATCH

/**
 * Forces a full update (cl_fullupdate) for a client.
 *
 * @param client    Client index
 * @return          True if update was successful, false otherwise
 * @error          Invalid client index, client not in game, or client is fake
 */
native bool ClientFullUpdate(int client);

public SharedPlugin __pl_FullUpdate =
{
	name = "FullUpdate",
	file = "FullUpdate.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public __pl_FullUpdate_SetNTVOptional()
{
	MarkNativeAsOptional("ClientFullUpdate");
}
#endif
