# WindShear — the movement workbench (tune the movement by feel)
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
## The movement room with a panel of sliders down the side.
##
## Every knob on the panel is a live movement number. Drag the slider, feel
## the room change, and the controller is running the new number on the very
## next frame. You tune the movement the way you would tune it in a text
## editor: change a number, look at the result, keep it or undo it.
##
## Nothing is written to the repository until somebody bakes a profile into
## the code and the documents. That is a decision and not a side effect, and
## it is why the panel can be reckless and the code cannot.
extends Node3D

## The live override store and the table of knobs.
const Tweak := preload("res://addons/windshear/core/ws_tweak.gd")
## The canonical tuning constants.
const Tuning := preload("res://addons/windshear/core/ws_tuning.gd")
## The measurement room.
const Greybox := preload("res://world/greybox/movement_greybox.tscn")

## Where a profile can be dropped for the repository.
const REPO_PROFILE_PATH := "res://data/tuning_profile.json"

## Set to false to leave the window alone.
##
## The headless test suite does this, because resizing the runner's window
## would disturb the other suites.
@export var adjust_window := true

## How wide the panel is, in pixels.
const PANEL_WIDTH := 430.0
## How tall one slider row is, in pixels.
const ROW_HEIGHT := 24.0
## The font size the panel uses. The game itself runs at 480x270 with tiny
## type, and the workbench is a tool rather than a game screen.
const PANEL_FONT := 13

var _player: Node
var _rig: Node
var _panel: PanelContainer
var _rows := {}
var _status: Label
var _notes: TextEdit


func _ready() -> void:
	_make_the_window_readable()
	_spawn_the_room()
	_build_the_panel()


## Makes the window big enough to read and turns the pixel scaling off.
##
## The game renders at 480x270 on purpose. A panel with twenty-five sliders
## does not fit in that, and a workbench is a tool rather than a game screen.
func _make_the_window_readable() -> void:
	if not adjust_window:
		return
	var window := get_window()
	if window == null:
		return
	window.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	if window.size.x < 1280 or window.size.y < 720:
		window.size = Vector2i(1280, 720)


## Drops the measurement room into the workbench.
##
## The room is in the scene file, so it can be opened and edited like any
## other scene. The script only wires it up, and falls back to instancing the
## greybox if the scene has no room.
func _spawn_the_room() -> void:
	var room: Node = get_node_or_null("Room")
	if room == null:
		room = Greybox.instantiate()
		room.name = "Room"
		add_child(room)
	_player = _find_player(room)
	if _player != null:
		# One dictionary, shared. A slider that moves writes straight into the
		# live simulation, because both sides are looking at the same object.
		_player.set("overrides", WsTweak.overrides)
		_player.call("respawn", Vector3(-24.0, 1.2, 0.0))
		_rig = _player.get_node_or_null("CameraRig")
		if _rig != null:
			# The camera gets the same dictionary, so the camera knobs move
			# the camera on the next frame as well.
			_rig.set("overrides", WsTweak.overrides)


## Finds Lancer anywhere under the room.
func _find_player(node: Node) -> Node:
	if node is CharacterBody3D and node.has_method("respawn"):
		return node
	for child in node.get_children():
		var found := _find_player(child)
		if found != null:
			return found
	return null


## Builds the panel out of the knob table.
##
## The panel is code, not a scene file, because the table is the source of
## truth. Adding a knob is one entry in `ws_tweak.gd` and the panel grows a
## row by itself.
func _build_the_panel() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)

	_panel = PanelContainer.new()
	_panel.name = "WorkbenchPanel"
	_panel.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
	_panel.offset_left = -PANEL_WIDTH
	_panel.offset_right = 0.0
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(_panel)

	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 10)
	_panel.add_child(margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	margin.add_child(column)

	column.add_child(_label("MOVEMENT WORKBENCH", 16))
	column.add_child(_label("drag a slider, the room changes on the next frame", PANEL_FONT))
	column.add_child(HSeparator.new())

	column.add_child(_button_row([
		["reset all", _on_reset_all],
		["save profile", _on_save_profile],
		["load profile", _on_load_profile],
		["copy values", _on_copy_values],
	]))
	column.add_child(_button_row([
		["write to repo", _on_write_to_repo],
	]))

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)

	var knobs := VBoxContainer.new()
	knobs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	knobs.add_theme_constant_override("separation", 2)
	scroll.add_child(knobs)

	for group in Tweak.GROUPS:
		var header := _label(group.to_upper(), PANEL_FONT)
		header.add_theme_color_override("font_color", Color(0.55, 0.78, 1.0))
		knobs.add_child(header)
		for key in Tweak.TUNABLES.keys():
			var entry: Dictionary = Tweak.TUNABLES[key]
			if entry["group"] != group:
				continue
			knobs.add_child(_build_row(key, entry))

	column.add_child(HSeparator.new())
	column.add_child(_label("notes", PANEL_FONT))
	_notes = TextEdit.new()
	_notes.custom_minimum_size = Vector2(0.0, 70.0)
	_notes.placeholder_text = "what changed and why"
	_notes.add_theme_font_size_override("font_size", PANEL_FONT)
	column.add_child(_notes)

	_status = _label("", 11)
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_status)

	_load_saved_profile()
	_refresh_status("ready")


## One slider row: the name, the slider, the live value and the documented one.
func _build_row(key: String, entry: Dictionary) -> Control:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0.0, ROW_HEIGHT)
	row.add_theme_constant_override("separation", 6)

	var name_label := _label(String(entry["label"]), PANEL_FONT)
	name_label.custom_minimum_size = Vector2(150.0, 0.0)
	row.add_child(name_label)

	var slider := HSlider.new()
	slider.min_value = float(entry["min"])
	slider.max_value = float(entry["max"])
	slider.step = float(entry["step"])
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slider.value = WsTweak.value(key)
	slider.value_changed.connect(_on_slider_changed.bind(key))
	row.add_child(slider)

	var value_label := _label(_format_value(entry, WsTweak.value(key)), PANEL_FONT)
	value_label.custom_minimum_size = Vector2(92.0, 0.0)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(value_label)

	_rows[key] = {"slider": slider, "label": value_label, "entry": entry}
	return row


## A label with the workbench font size.
func _label(text: String, size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	return label


## A row of buttons.
func _button_row(buttons: Array) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	for entry in buttons:
		var button := Button.new()
		button.text = String(entry[0])
		button.add_theme_font_size_override("font_size", PANEL_FONT)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(entry[1])
		row.add_child(button)
	return row


## Wires the workbench keys.
func _unhandled_input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo():
		return
	if event is InputEventKey:
		var key := event as InputEventKey
		if key.keycode == KEY_F2:
			_panel.visible = not _panel.visible
			get_viewport().gui_release_focus()
			_refresh_status("panel hidden" if not _panel.visible else "panel shown")
		elif key.keycode == KEY_F3:
			_notes.grab_focus()


## A slider moved.
func _on_slider_changed(new_value: float, key: String) -> void:
	WsTweak.set_override(key, new_value)
	var row: Dictionary = _rows[key]
	var entry: Dictionary = row["entry"]
	var label: Label = row["label"]
	label.text = _format_value(entry, new_value)
	_mark_row(key)


## Marks a row that is off its documented value.
func _mark_row(key: String) -> void:
	var row: Dictionary = _rows[key]
	var label: Label = row["label"]
	if WsTweak.is_overridden(key):
		label.add_theme_color_override("font_color", Color(1.0, 0.78, 0.35))
	else:
		label.remove_theme_color_override("font_color")


## Puts every knob back to the documented number.
func _on_reset_all() -> void:
	WsTweak.clear_all()
	for key in _rows.keys():
		var row: Dictionary = _rows[key]
		var slider: HSlider = row["slider"]
		slider.set_value_no_signal(WsTweak.value(key))
		var entry: Dictionary = row["entry"]
		var label: Label = row["label"]
		label.text = _format_value(entry, WsTweak.value(key))
		_mark_row(key)
	_refresh_status("every knob is back to the documented number")


## Saves the profile to the user data folder.
func _on_save_profile() -> void:
	WsTweak.notes = _notes.text
	if WsTweak.save_profile():
		_refresh_status("saved %s" % WsTweak.profile_path())
	else:
		_refresh_status("could not save the profile")


## Loads the profile from the user data folder.
func _on_load_profile() -> void:
	if _load_saved_profile():
		_refresh_status("loaded %s" % WsTweak.profile_path())
	else:
		_refresh_status("there is no saved profile yet")


## Loads the profile and pushes it into the sliders.
func _load_saved_profile() -> bool:
	if not WsTweak.load_profile():
		return false
	for key in _rows.keys():
		var row: Dictionary = _rows[key]
		var slider: HSlider = row["slider"]
		slider.set_value_no_signal(WsTweak.value(key))
		var entry: Dictionary = row["entry"]
		var label: Label = row["label"]
		label.text = _format_value(entry, WsTweak.value(key))
		_mark_row(key)
	_notes.text = WsTweak.notes
	return true


## Puts the profile on the clipboard, so it can be pasted into a message.
func _on_copy_values() -> void:
	WsTweak.notes = _notes.text
	DisplayServer.clipboard_set(WsTweak.profile_text())
	_refresh_status("the values are on the clipboard")


## Writes the profile into the repository, where it can be committed.
##
## This is the handoff. The file is plain JSON, it shows up in a diff, and
## somebody can read it before it turns into a constant.
func _on_write_to_repo() -> void:
	WsTweak.notes = _notes.text
	var file := FileAccess.open(REPO_PROFILE_PATH, FileAccess.WRITE)
	if file == null:
		_refresh_status("could not write %s — is the project folder read-only?" % REPO_PROFILE_PATH)
		return
	file.store_string(WsTweak.profile_text())
	_refresh_status("wrote %s — commit it and ask for it to be baked in" % REPO_PROFILE_PATH)


## Says what is going on.
func _refresh_status(message: String) -> void:
	var count := WsTweak.overrides.size()
	if _status == null:
		return
	_status.text = "%s\n%d override(s) live\nprofile: %s" % [
		message, count, WsTweak.profile_path()
	]


## Formats a number the way the panel shows it.
func _format_value(entry: Dictionary, value: float) -> String:
	if bool(entry["integer"]):
		return "%d" % int(round(value))
	var text := "%.3f" % value
	while text.contains(".") and text.ends_with("0"):
		text = text.substr(0, text.length() - 1)
	if text.ends_with("."):
		text = text.substr(0, text.length() - 1)
	return text
