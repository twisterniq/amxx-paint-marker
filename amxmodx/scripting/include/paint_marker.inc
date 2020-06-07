#if defined _paint_marker_included
	#endinput
#endif
#define _paint_marker_included

#pragma reqlib paint_marker

/**
 * Sets the ability for player to use the marker.
 *
 * @param id        Client index
 * @param access    true to allow using the marker, false otherwise
 *
 * @return          true on success, false otherwise
 * @error           If the index is not within the range of 1 to MaxClients,
 *                  an error will be thrown.
 */
native bool:paint_marker_set_user_access(const id, bool:access);

/**
 * Returns if player has access to use the marker.
 *
 * @param id        Client index
 *
 * @return          true if player has access to use it, false otherwise
 * @error           If the index is not within the range of 1 to MaxClients,
 *                  an error will be thrown.
 */
native bool:paint_marker_has_user_access(const id);