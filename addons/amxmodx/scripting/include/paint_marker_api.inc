#if defined _paint_marker_api_included
	#endinput
#endif
#define _paint_marker_api_included

/**
 * Manages the mode of player's marker, i.e., enables or disables it.
 *
 * @param id		Client index
 * @param enable	true if marker needs to be enabled, false otherwise
 *
 * @noreturn
 */
native paint_marker_user_manage(id, bool:enable);

/**
 * Checks if the player has access to paint.
 *
 * @param id		Client index
 *
 * @return			true if the player can use hook, false otherwise
 */
native bool:paint_marker_has_user(id);