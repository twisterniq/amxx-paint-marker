/*
 * Official resource topic: https://dev-cs.ru/resources/1005/
 */

#include <amxmodx>
#include <paint_marker>

#pragma semicolon 1

public stock const PluginName[] = "Paint Marker: Default Access";
public stock const PluginVersion[] = "1.0.1";
public stock const PluginAuthor[] = "twisterniq";
public stock const PluginURL[] = "https://github.com/twisterniq/amxx-paint-marker";
public stock const PluginDescription[] = "Allows to use the marker by default if player has flag access";

new const CONFIG_NAME[] = "paint_marker_default_access";

// If you have Admin Loader by neugomon installed on your server, uncomment this.
// You can also uncomment this if in your Admin Loader there is a "client_admin"
// forward.
//#define ADMIN_LOADER

#if defined ADMIN_LOADER
	#define client_putinserver client_admin
#endif

new g_iDefaultAccess = ADMIN_BAN;

public plugin_init()
{
#if AMXX_VERSION_NUM == 190
	register_plugin(
		.plugin_name = PluginName,
		.version = PluginVersion,
		.author = PluginAuthor);
#endif

	register_dictionary("paint_marker_default_access.txt");

	new pCvar = create_cvar(
		.name = "paint_marker_default_access",
		.string = "d",
		.flags = FCVAR_NONE,
		.description = fmt("%L", LANG_SERVER, "PAINT_MARKER_DEFAULT_ACCESS_CVAR"));
	set_pcvar_string(pCvar, "");
	hook_cvar_change(pCvar, "@OnDefaultAccessChange");

	AutoExecConfig(true, CONFIG_NAME);

	new szPath[PLATFORM_MAX_PATH];
	get_localinfo("amxx_configsdir", szPath, charsmax(szPath));
	server_cmd("exec %s/plugins/%s.cfg", szPath, CONFIG_NAME);
	server_exec();
}

public client_putinserver(id)
{
    if(g_iDefaultAccess > 0 && get_user_flags(id) & g_iDefaultAccess)
        paint_marker_set_user_access(id, true);
#if defined ADMIN_LOADER
    else
        paint_marker_set_user_access(id, false);
#endif
}

@OnDefaultAccessChange(const iHandle, const szOldValue[], const szNewValue[])
{
	g_iDefaultAccess = read_flags(szNewValue);
}