#define crosshair_visible IniParams[0].x
#define hud_w1_tolerance IniParams[0].y
#define cursor_showing IniParams[7].y
#define texture_filter IniParams[1].y
#define pda_preset IniParams[1].z

#define crosshair_texture 2
#define screen_depth_texture 3

#include "crosshair.hlsl"

void handle_in_world_hud(inout float4 pos)
{
	float4 s = StereoParams.Load(0);

	// Tablet, in-world WARNING display or some other in-world HUD
	// Stupidly (and probably because of VR), this game projects a lot of
	// HUD in world, then projects them back to screen space, so this
	// matches more than you would expect. This affects the main menu and
	// the popup box that appears when mousing over the icons at the bottom
	// of the screen in the PDA, and the icons in the fabricator.

	// Because of this double-projection the W==1 driver heuristic doesn't
	// work due to floating point error, so we increase the tolerance
	// ourselves to return things to screen depth.
	if (pos.w != 1 && distance(pos.w, 1) < hud_w1_tolerance)
		pos.x -= s.x * (pos.w - s.y);
}

void handle_hud(inout float4 pos, bool allow_crosshair_adjust = true)
{
	float4 s = StereoParams.Load(0);

#ifdef UNITY_PER_DRAW
	if (!all(UNITY_PER_DRAW.unity_ObjectToWorld._m30_m31_m32_m33 == float4(0, 0, 1, 1))) {
		handle_in_world_hud(pos);
		return;
	}
#endif

	// Return all HUD items to screen depth:
	if (pos.w != 1)
		pos.x -= s.x * (pos.w - s.y);

	// If the cursor is visible we are in a menu, keep it simple and leave
	// the whole HUD at screen depth so the mouse cursor lines up:
	if (cursor_showing)
		return;

	// Blacklist inventory circles at bottom of screen, since they overlap
	// with the mask. The actual icons are on a separate shader that does
	// not allow_crosshair_adjust to keep them at screen depth - if we
	// later need that shader auto-adjusted, we will need to change this to
	// a Y > -0.84 threshold check instead.
	if (texture_filter == screen_depth_texture)
		return;

	if (texture_filter == crosshair_texture && !crosshair_visible) {
		pos = 0;
		return;
	}

	// Otherwise, adjust to crosshair depth if allowed for this shader:
	if (allow_crosshair_adjust)
		pos.x += adjust_from_depth_buffer(0, 0);
}
