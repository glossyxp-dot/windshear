// WindShear — the PSX surface shader (vertex, texture, colour and dither)
// SPDX-License-Identifier: GPL-2.0-or-later
//
// The PSX look is four separate artefacts of the 1990s that happen to sit
// together:
//
//   1. the framebuffer was small, so the rasteriser rounded every vertex to
//      the nearest pixel of a 320x240 or 480x270 buffer and the geometry
//      wobbled as it moved;
//   2. textures were mapped affinely — the UVs of a triangle were
//      interpolated in screen space instead of in perspective — so flat
//      surfaces visibly swam;
//   3. the colour buffer was 15 bits, five bits per channel, so gradients
//      banded;
//   4. the banding was hidden with an ordered dither pattern.
//
// Each is a separate knob here. The global `psx_amount` uniform is the master
// dial between "none of it" and "all of it". The player picks that number in
// the settings panel.
//
// Use this as the base of a hand-made material: set `albedo_color`, drop in an
// `albedo_texture` if you need one, and leave the PSX knobs alone unless you
// have a reason to move them.

shader_type spatial;
render_mode cull_back, diffuse_burley, specular_disabled;

// The master dial. 0.0 gives a clean modern surface; 1.0 gives the full look.
// It is global, so one settings slider reaches every material in the game
// without changing a material resource.
global uniform float psx_amount;

// The master switch for swimming textures. This one is global too, so the
// player can turn warping off everywhere. It starts off because warped
// textures are hard to read.
global uniform float psx_affine;

uniform vec4 albedo_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform sampler2D albedo_texture : source_color, filter_nearest, repeat_enable;
uniform bool use_albedo_texture = false;
uniform vec4 emission_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float emission_energy = 0.0;

// --- the PSX knobs --------------------------------------------------------

// How hard the vertices snap to the internal resolution grid.
uniform float vertex_snap : hint_range(0.0, 1.0) = 1.0;
// How much of the texture swims because the UVs are interpolated affinely.
uniform float affine_warp : hint_range(0.0, 1.0) = 1.0;
// How strong the ordered dither pattern is.
uniform float dither_strength : hint_range(0.0, 1.0) = 1.0;
// Bits per colour channel. The PlayStation had five.
uniform float color_depth : hint_range(2.0, 8.0) = 5.0;
// The resolution the vertices snap to. This is the internal buffer size.
uniform vec2 psx_grid = vec2(480.0, 270.0);

varying vec2 v_affine_uv;
varying float v_clip_w;

// The two smallest ordered dither matrices share one bit trick.
//
// bayer2 gives the 2x2 matrix, bayer4 the 4x4 one. Neither needs a lookup
// texture, so the shader stays self-contained: no extra texture, no extra
// VRAM, nothing to load.
float bayer2(vec2 a) {
	a = floor(a);
	return fract(dot(a, vec2(0.5, a.y * 0.75)));
}

float bayer4(vec2 p) {
	return bayer2(0.5 * p) * 0.25 + bayer2(p);
}

void vertex() {
	vec4 view_position = MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
	vec4 clip = PROJECTION_MATRIX * view_position;

	// The affine trick gives the fragment stage UVs that have already been
	// multiplied by clip-space w. The hardware interpolates them with
	// perspective correction. Dividing them by the interpolated w again
	// cancels that correction, leaving the straight screen-space interpolation
	// the PlayStation used. The texture swims.
	v_clip_w = clip.w;
	v_affine_uv = UV * clip.w;

	// Vertex snapping rounds the clip-space position to the nearest pixel of
	// the internal buffer. The wobble is the whole reason the era looks the
	// way it does.
	float snap = clamp(psx_amount * vertex_snap, 0.0, 1.0);
	vec2 ndc = clip.xy / max(clip.w, 0.0001);
	vec2 pixel = (ndc * 0.5 + 0.5) * psx_grid;
	vec2 snapped = (floor(pixel + 0.5) / psx_grid) * 2.0 - 1.0;
	clip.xy = mix(ndc, snapped, snap) * clip.w;

	POSITION = clip;
}

void fragment() {
	float amount = clamp(psx_amount, 0.0, 1.0);

	// Pick between the perspective-correct UVs and the affine ones.
	// `affine_warp` is the per-material knob. It is an art decision: some
	// surfaces should swim and others should not. `psx_affine` is the player's
	// master switch. Both have to be on before anything warps.
	vec2 uv = UV;
	float warp = clamp(amount * affine_warp * psx_affine, 0.0, 1.0);
	if (warp > 0.0) {
		vec2 affine = v_affine_uv / max(v_clip_w, 0.0001);
		uv = mix(uv, affine, warp);
	}

	vec4 sampled = vec4(1.0);
	if (use_albedo_texture) {
		sampled = texture(albedo_texture, uv);
	}

	ALBEDO = albedo_color.rgb * sampled.rgb;
	ROUGHNESS = 1.0;
	METALLIC = 0.0;
	SPECULAR = 0.0;
	EMISSION = emission_color.rgb * emission_energy;

	// The dither and the colour depth. The threshold is centred on zero, so
	// dither_strength 0.0 changes nothing at all.
	float dither = clamp(amount * dither_strength, 0.0, 1.0);
	if (dither > 0.0) {
		float threshold = (bayer4(mod(floor(FRAGCOORD.xy), 4.0)) - 0.5) * dither;
		float levels = color_depth;
		ALBEDO = clamp(floor((ALBEDO + threshold / levels) * levels) / levels,
				vec3(0.0), vec3(1.0));
		EMISSION = clamp(floor((EMISSION + threshold / levels) * levels) / levels,
				vec3(0.0), vec3(64.0));
	}
}
