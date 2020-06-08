/*
 * Official resource topic: https://dev-cs.ru/resources/1004/
 */

#include <amxmodx>
#include <amxmisc>
#include <paint_marker>

#pragma semicolon 1

public stock const PluginName[] = "Paint Marker: Menu Access";
public stock const PluginVersion[] = "1.0.1";
public stock const PluginAuthor[] = "twisterniq";
public stock const PluginURL[] = "https://github.com/twisterniq/amxx-paint-marker";
public stock const PluginDescription[] = "Adds the ability to set access for player in menu";

// Players per page in menu. It cannot be more than 8.
const PLAYERS_PER_PAGE = 8;

new g_iMenuPlayers[MAX_PLAYERS + 1][MAX_PLAYERS], g_iMenuPosition[MAX_PLAYERS + 1];
new g_iMenuAccess = ADMIN_IMMUNITY;

public plugin_init()
{
#if AMXX_VERSION_NUM == 190
	register_plugin(
		.plugin_name = PluginName,
		.version = PluginVersion,
		.author = PluginAuthor);
#endif

	register_dictionary("paint_marker_menu_access.txt");

	new szCmd[][] = { "paintmenu", "/paintmenu", "!paintmenu", ".paintmenu" };
	register_clcmd_list(szCmd, "@func_PaintMarkerCmd");

	register_menu("func_PaintMarkerMenu", 1023, "@func_PaintMarkerMenu_Handler");

	new pCvar = create_cvar(
		.name = "paint_marker_menu_access",
		.string = "a",
		.flags = FCVAR_NONE,
		.description = fmt("%L", LANG_SERVER, "PAINT_MARKER_MENU_ACCESS_CVAR"));
	set_pcvar_string(pCvar, "");
	hook_cvar_change(pCvar, "@OnMenuAccessChange");

	AutoExecConfig(true, "paint_marker_menu_access");
}

@func_PaintMarkerCmd(const id)
{
	if(g_iMenuAccess > 0 && !(get_user_flags(id) & g_iMenuAccess))
	{
		return PLUGIN_HANDLED;
	}

	func_PaintMarkerMenu(id, 0);
	return PLUGIN_HANDLED;
}

func_PaintMarkerMenu(const id, iPage)
{
	if(iPage < 0)
	{
		return PLUGIN_HANDLED;
	}

	new iPlayerCount;

	for(new i = 1; i <= MaxClients; i++)
	{
		if(!is_user_alive(i))
		{
			continue;
		}

		g_iMenuPlayers[id][iPlayerCount++] = i;
	}

	SetGlobalTransTarget(id);

	new i = min(iPage * PLAYERS_PER_PAGE, iPlayerCount);
	new iStart = i - (i % PLAYERS_PER_PAGE);
	new iEnd = min(iStart + PLAYERS_PER_PAGE, iPlayerCount);
	g_iMenuPosition[id] = iPage = iStart / PLAYERS_PER_PAGE;

	new szMenu[MAX_MENU_LENGTH], iMenuItem, iKeys = (MENU_KEY_0);
	new iPagesNum = (iPlayerCount / PLAYERS_PER_PAGE + ((iPlayerCount % PLAYERS_PER_PAGE) ? 1 : 0));
	new iLen = formatex(szMenu, charsmax(szMenu), "\y%l \d\R%d/%d^n^n", "PAINT_MARKER_MENU_ACCESS_TITLE", iPage + 1, iPagesNum);

	for(new a = iStart, iPlayer; a < iEnd; ++a)
	{
		iPlayer = g_iMenuPlayers[id][a];

		iKeys |= (1<<iMenuItem);
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\y%d. \w%n %l^n", ++iMenuItem, iPlayer,
			paint_marker_has_user_access(iPlayer) ? "PAINT_MARKER_MENU_ACCESS_HAS" : "PAINT_MARKER_MENU_ACCESS_EMPTY");
	}

	if(iEnd != iPlayerCount)
	{
		formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\y9. \w%l^n\y0. \w%l", "PAINT_MARKER_MENU_ACCESS_NEXT",
			iPage ? "PAINT_MARKER_MENU_ACCESS_BACK" : "PAINT_MARKER_MENU_ACCESS_EXIT");
		iKeys |= (MENU_KEY_9);
	}
	else
	{
		formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\y0. \w%l", iPage ? "PAINT_MARKER_MENU_ACCESS_BACK" : "PAINT_MARKER_MENU_ACCESS_EXIT");
	}

	show_menu(id, iKeys, szMenu, -1, "func_PaintMarkerMenu");
	return PLUGIN_HANDLED;
}

@func_PaintMarkerMenu_Handler(const id, iKey)
{
	switch(iKey)
	{
		case 8:
		{
			func_PaintMarkerMenu(id, ++g_iMenuPosition[id]);
		}
		case 9:
		{
			func_PaintMarkerMenu(id, --g_iMenuPosition[id]);
		}
		default:
		{
			new iTarget = g_iMenuPlayers[id][(g_iMenuPosition[id] * PLAYERS_PER_PAGE) + iKey];

			if(!is_user_connected(iTarget))
			{
				client_print_color(id, print_team_red, "%l", "PAINT_MARKER_MENU_ACCESS_ERROR");
				func_PaintMarkerMenu(id, g_iMenuPosition[id]);

				return PLUGIN_HANDLED;
			}

			new bool:bHasMarker = paint_marker_has_user_access(iTarget);
			paint_marker_set_user_access(iTarget, !bHasMarker);
			client_print_color(id, iTarget, "%l", bHasMarker ? "PAINT_MARKER_MENU_ACCESS_OFF" : "PAINT_MARKER_MENU_ACCESS_ON", iTarget);

			func_PaintMarkerMenu(id, g_iMenuPosition[id]);
		}
	}

	return PLUGIN_HANDLED;
}

@OnMenuAccessChange(const iHandle, const szOldValue[], const szNewValue[])
{
	g_iMenuAccess = read_flags(szNewValue);
}

// thx wopox1337 (https://dev-cs.ru/threads/222/page-7#post-76442)
stock register_clcmd_list(const cmd_list[][], const function[], flags = -1, const info[] = "", FlagManager = -1, bool:info_ml = false, const size = sizeof(cmd_list))
{
#pragma unused info
#pragma unused FlagManager
#pragma unused info_ml

    for (new i; i < size; i++)
	{
        register_clcmd(cmd_list[i], function, flags, info, FlagManager, info_ml);
    }
}