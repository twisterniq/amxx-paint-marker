/*
 * Official resource topic: https://dev-cs.ru/resources/634/
 *
 * Credits to stupok69 for original plugin Magic Marker v3.1:
 *
*/

#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <reapi>
#include <xs>

#pragma semicolon 1

public stock const PluginName[] = "Paint Marker";
public stock const PluginVersion[] = "2.0.0";
public stock const PluginAuthor[] = "twisterniq";
public stock const PluginURL[] = "https://github.com/twisterniq/amxx-paint-marker";
public stock const PluginDescription[] = "Adds the ability to paint. It has API";

// Time for think, the more time the more you can paint but the less smooth it will be displayed
const Float:THINK_TIME = 0.1;

#define CHECK_NATIVE_PLAYER(%0,%1) \
    if (!(1 <= %0 <= MaxClients)) \
	{ \
        abort(AMX_ERR_NATIVE, "Player out of range (%d)", %0); \
		return %1; \
    }

new bool:g_bAlive[MAX_PLAYERS + 1];
new bool:g_bIsPainting[MAX_PLAYERS + 1], bool:g_bIsHoldingPaint[MAX_PLAYERS + 1];
new bool:g_bCanUseMarker[MAX_PLAYERS + 1];
new Float:g_iOriginPaint[MAX_PLAYERS + 1][3];
new g_pSpriteLightning;
new g_iLifeTime;

public plugin_init()
{
#if AMXX_VERSION_NUM == 190
	register_plugin(
		.plugin_name = PluginName,
		.version = PluginVersion,
		.author = PluginAuthor);
#endif

	register_dictionary("paint_marker.txt");

	register_clcmd("+paint", "@func_PaintEnable");
	register_clcmd("-paint", "@func_PaintDisable");

	RegisterHookChain(RG_CSGameRules_PlayerSpawn, "@OnPlayerSpawn_Post", true);
	RegisterHookChain(RG_CBasePlayer_Killed, "@OnPlayerKilled_Post", true);

	bind_pcvar_num(create_cvar(
		.name = "paint_marker_life_time",
		.string = "25",
		.flags = FCVAR_NONE,
		.description = fmt("%L", LANG_SERVER, "PAINT_MARKER_CVAR_LIFE_TIME"),
		.has_min = true,
		.min_val = 1.0,
		.has_max = true,
		.max_val = 25.0), g_iLifeTime);

	AutoExecConfig(true, "paint_marker");

	new iEnt = rg_create_entity("info_target", true);

	if(iEnt)
	{
		SetThink(iEnt, "@think_Paint");
		set_entvar(iEnt, var_nextthink, get_gametime() + THINK_TIME);
	}
}

public plugin_precache()
{
	g_pSpriteLightning = precache_model("sprites/lgtning.spr");
}

public client_disconnected(id)
{
	g_bIsPainting[id] = false;
	g_bAlive[id] = false;
	g_bCanUseMarker[id] = false;
}

@OnPlayerSpawn_Post(const id)
{
	if(is_user_alive(id))
	{
		g_bAlive[id] = true;
		g_bIsPainting[id] = false;
	}
}

@OnPlayerKilled_Post(const iVictim)
{
	g_bAlive[iVictim] = false;
	g_bIsPainting[iVictim] = false;
}

@func_PaintEnable(const id)
{
	if(!g_bAlive[id])
	{
		return PLUGIN_HANDLED;
	}

	if(!g_bCanUseMarker[id])
	{
		client_print_color(id, print_team_red, "%l", "PAINT_MARKER_ERROR_ACCESS");
		return PLUGIN_HANDLED;
	}

	g_bIsPainting[id] = true;
	return PLUGIN_HANDLED;
}

@func_PaintDisable(const id)
{
	g_bIsPainting[id] = false;
	return PLUGIN_HANDLED;
}

@think_Paint(const iEnt)
{
	static iPlayers[MAX_PLAYERS], iPlayerCount;
	get_players_ex(iPlayers, iPlayerCount, GetPlayers_ExcludeDead);

	for(new i, iPlayer; i < iPlayerCount; i++)
	{
		iPlayer = iPlayers[i];

		if(!g_bIsPainting[iPlayer] || func_IsAimingAtSky(iPlayer))
		{
			g_bIsHoldingPaint[iPlayer] = false;
			continue;
		}

		static Float:flOrigin[3], Float:flDistance;
		flOrigin = g_iOriginPaint[iPlayer];

		if(!g_bIsHoldingPaint[iPlayer])
		{
			func_GetAimOrigin(iPlayer, g_iOriginPaint[iPlayer]);
			func_MoveTowardClient(iPlayer, g_iOriginPaint[iPlayer]);
			g_bIsHoldingPaint[iPlayer] = true;

			continue;
		}

		func_GetAimOrigin(iPlayer, g_iOriginPaint[iPlayer]);
		func_MoveTowardClient(iPlayer, g_iOriginPaint[iPlayer]);

		flDistance = get_distance_f(g_iOriginPaint[iPlayer], flOrigin);

		if(flDistance > 2.0)
		{
			func_StartPainting(g_iOriginPaint[iPlayer], flOrigin);
		}
	}

	set_entvar(iEnt, var_nextthink, get_gametime() + THINK_TIME);
}

func_StartPainting(Float:flOrigin1[3], Float:flOrigin2[3])
{
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	{
		write_byte(TE_BEAMPOINTS);
		write_coord_f(flOrigin1[0]);		// startposition x
		write_coord_f(flOrigin1[1]);		// startposition y
		write_coord_f(flOrigin1[2]);		// startposition z
		write_coord_f(flOrigin2[0]);		// endposition x
		write_coord_f(flOrigin2[1]);		// endposition y
		write_coord_f(flOrigin2[2]);		// endposition z
		write_short(g_pSpriteLightning);	// sprite index
		write_byte(0);						// starting frame
		write_byte(10);						// frame rate in 0.1's
		write_byte(g_iLifeTime * 10);		// life in 0.1's
		write_byte(50);						// line width in 0.1's
		write_byte(0);						// noise aimplitude in 0.01's
		write_byte(random_num(0, 255));		// red
		write_byte(random_num(0, 255));		// green
		write_byte(random_num(0, 255));		// blue
		write_byte(255);					// brightness
		write_byte(0);						// scroll speed in 0.1's
	}
	message_end();
}

stock func_GetAimOrigin(const id, Float:flOrigin[3])
{
	static Float:flStart[3], Float:flViewOfs[3];
	get_entvar(id, var_origin, flStart);
	get_entvar(id, var_view_ofs, flViewOfs);
	xs_vec_add(flStart, flViewOfs, flStart);

	static Float:flDest[3];
	get_entvar(id, var_v_angle, flDest);
	engfunc(EngFunc_MakeVectors, flDest);
	global_get(glb_v_forward, flDest);
	xs_vec_mul_scalar(flDest, 9999.0, flDest);
	xs_vec_add(flStart, flDest, flDest);

	engfunc(EngFunc_TraceLine, flStart, flDest, 0, id, 0);
	get_tr2(0, TR_vecEndPos, flOrigin);
}

stock func_MoveTowardClient(const id, Float:flOrigin[3])
{
	static Float:flPlayerOrigin[3];

	get_entvar(id, var_origin, flPlayerOrigin);

	flOrigin[0] += (flPlayerOrigin[0] > flOrigin[0]) ? 1.0 : -1.0;
	flOrigin[1] += (flPlayerOrigin[1] > flOrigin[1]) ? 1.0 : -1.0;
	flOrigin[2] += (flPlayerOrigin[2] > flOrigin[2]) ? 1.0 : -1.0;
}

bool:func_IsAimingAtSky(const id)
{
	new Float:flOrigin[3];
	func_GetAimOrigin(id, flOrigin);
	return (engfunc(EngFunc_PointContents, flOrigin) == CONTENTS_SKY);
}

/****************************************************************************************
****************************************************************************************/

public plugin_natives()
{
	register_library("paint_marker");

	register_native("paint_marker_set_user_access",	"@Native_SetUserAccess");
	register_native("paint_marker_has_user_access",	"@Native_HasUserAccess");
}

@Native_SetUserAccess(const iPlugin, const iParams)
{
	enum { arg_player = 1, arg_access };

	new iPlayer = get_param(arg_player);

	CHECK_NATIVE_PLAYER(iPlayer, false)

	g_bCanUseMarker[iPlayer] = bool:get_param(arg_access);

	if(!g_bCanUseMarker[iPlayer])
	{
		g_bIsPainting[iPlayer] = false;
	}

	return true;
}

bool:@Native_HasUserAccess(const iPlugin, const iParams)
{
	enum { arg_player = 1 };

	new iPlayer = get_param(arg_player);

	CHECK_NATIVE_PLAYER(iPlayer, false)

	return g_bCanUseMarker[iPlayer];
}