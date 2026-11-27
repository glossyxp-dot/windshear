# WindShear — global game state and settings (the WsGame autoload)
# Copyright (C) 2026 the WindShear contributors
#
# This program is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 2 of the License, or (at your
# option) any later version.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program.  If not, see <https://www.gnu.org/licenses/>.
##
## The autoload singleton. A few values have to survive a scene change: the
## current mode, the run clock, and the player's settings.
##
## There is no `class_name` on this file. The autoload singleton is registered
## as `WsGame`; a global class with the same name would shadow it.
extends Node

## The modes the game can be in.
enum Mode {
	BOOT,    ## Starting up.
	MENU,    ## Main menu.
	PLAYING, ## A run is live.
	PAUSED,  ## A run is live but frozen.
}

## Emitted when [member mode] changes.
signal mode_changed(mode: Mode)
## Emitted when a run starts.
signal run_started(section_id: String)
## Emitted when a run ends (finished or abandoned).
signal run_finished()

## Where the settings file lives.
const SETTINGS_PATH := "user://settings.cfg"
## Where personal bests live.
const SPLITS_PATH := "user://splits.json"
## The PSX helper, which owns the shader globals.
const Psx := preload("res://addons/windshear/render/ws_psx.gd")

## Current mode of the game.
var mode: Mode = Mode.BOOT
## Frames elapsed in the current run (60 per second).
var run_frames := 0
## Section identifier for the current run, e.g. "P1.01".
var current_section := ""
## Seconds elapsed in the current run.
var run_seconds := 0.0
## Whether the last run reached the end of the campaign.
##
## The menu says so when the player comes back from a finished run.
var run_complete := false

## Mouse look sensitivity, radians per pixel.
var mouse_sensitivity := 0.0022
## Controller look sensitivity, radians per second.
var controller_sensitivity := 3.0
## Vertical field of view in degrees.
var fov := 72.0
## Invert the vertical look axis.
var invert_y := false
## Assist preset: "off", "standard" or "relaxed".
var assist_preset := "standard"
## Master volume, 0.0 – 1.0.
var master_volume := 0.8
## How much PSX the picture gets, 0.0 – 1.0.
##
## 0.0 is a clean modern surface, 1.0 is the full 1995 look. The player
## picks this in the settings panel; it drives a global shader uniform, so
## it reaches every material in the game at once.
var psx_amount := Psx.DEFAULT_AMOUNT
## Whether the textures swim (affine mapping). Off by default.
var psx_affine := Psx.DEFAULT_AFFINE


func _ready() -> void:
	load_settings()
	mode = Mode.MENU
	mode_changed.emit(mode)


func _physics_process(delta: float) -> void:
	if mode == Mode.PLAYING:
		run_frames += 1
		run_seconds += delta


## Puts the game into [param new_mode] and notifies listeners.
func set_mode(new_mode: Mode) -> void:
	if mode == new_mode:
		return
	mode = new_mode
	mode_changed.emit(mode)


## Starts a fresh run in [param section_id].
func start_run(section_id: String) -> void:
	run_frames = 0
	run_seconds = 0.0
	current_section = section_id
	run_complete = false
	set_mode(Mode.PLAYING)
	run_started.emit(section_id)


## Ends the current run.
func finish_run() -> void:
	set_mode(Mode.MENU)
	run_finished.emit()


## Ends the current run because the campaign was finished.
func finish_campaign() -> void:
	run_complete = true
	finish_run()


## Returns a seeded generator for [param section_id].
##
## The seed is an FNV-1a hash of the section id, so it does not depend on the
## engine's string hashing and stays identical across builds and platforms.
## Section-scoped randomness goes through this generator. The global random
## number functions would break replay determinism.
func rng_for_section(section_id: String) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = section_seed(section_id)
	return rng


## The deterministic seed used by [method rng_for_section].
func section_seed(section_id: String) -> int:
	var hash_value := 2166136261
	for i in section_id.length():
		hash_value = (hash_value ^ section_id.unicode_at(i)) * 16777619
		hash_value = hash_value & 0x7FFFFFFF
	return hash_value


## Reads the player's settings from disk. Missing keys keep their defaults.
func load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		_apply_psx()
		return
	mouse_sensitivity = float(config.get_value("look", "mouse_sensitivity", mouse_sensitivity))
	controller_sensitivity = float(config.get_value("look", "controller_sensitivity", controller_sensitivity))
	fov = float(config.get_value("look", "fov", fov))
	invert_y = bool(config.get_value("look", "invert_y", invert_y))
	assist_preset = String(config.get_value("accessibility", "assist_preset", assist_preset))
	master_volume = float(config.get_value("audio", "master_volume", master_volume))
	var psx := Psx.read_config(config)
	psx_amount = float(psx["amount"])
	psx_affine = bool(psx["affine"])
	_apply_psx()


## Writes the player's settings to disk.
func save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("look", "mouse_sensitivity", mouse_sensitivity)
	config.set_value("look", "controller_sensitivity", controller_sensitivity)
	config.set_value("look", "fov", fov)
	config.set_value("look", "invert_y", invert_y)
	config.set_value("accessibility", "assist_preset", assist_preset)
	config.set_value("audio", "master_volume", master_volume)
	Psx.write_config(config, psx_amount, psx_affine)
	config.save(SETTINGS_PATH)


## Pushes the PSX settings to the renderer.
##
## The renderer cannot be read back in a headless run, so the numbers that
## matter are kept here and mirrored into `WsPsx`, which owns the globals.
func _apply_psx() -> void:
	Psx.set_amount(psx_amount)
	Psx.set_affine(psx_affine)
