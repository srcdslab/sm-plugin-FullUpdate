#if defined _FullUpdate_Included
	#endinput
#endif
#define _FullUpdate_Included

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
