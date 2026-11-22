# WindShear — main menu
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
## The first screen. It is deliberately plain: the milestone that ships this
## is the movement prototype, and the menu exists to get the player into the
## greybox as fast as possible.
##
## The art direction of this project is hand-made — the icon and the layout
## here are placeholders that the author replaces by hand.
extends Control

## The movement greybox, loaded when a run starts.
const GreyboxScene := preload("res://world/greybox/movement_greybox.tscn")
## The PSX helper, which owns the shader globals.
const Psx := preload("res://addons/windshear/render/ws_psx.gd")

@onready var _new_run_button: Button = $Buttons/NewRun
@onready var _settings_button: Button = $Buttons/Settings
@onready var _quit_button: Button = $Buttons/Quit
@onready var _settings_panel: PanelContainer = $SettingsPanel
@onready var _settings_backdrop: ColorRect = $SettingsBackdrop
@onready var _settings_close_button: Button = $SettingsPanel/Margin/Column/Close
@onready var _sensitivity_slider: HSlider = $SettingsPanel/Margin/Column/SensitivityRow/Sensitivity
@onready var _sensitivity_value: Label = $SettingsPanel/Margin/Column/SensitivityRow/SensitivityValue
@onready var _fov_slider: HSlider = $SettingsPanel/Margin/Column/FovRow/Fov
@onready var _fov_value: Label = $SettingsPanel/Margin/Column/FovRow/FovValue
@onready var _invert_check: CheckButton = $SettingsPanel/Margin/Column/InvertRow/Invert
@onready var _psx_slider: HSlider = $SettingsPanel/Margin/Column/PsxRow/Psx
@onready var _psx_value: Label = $SettingsPanel/Margin/Column/PsxRow/PsxValue
@onready var _affine_check: CheckButton = $SettingsPanel/Margin/Column/AffineRow/Affine


func _ready() -> void:
	_new_run_button.pressed.connect(_on_new_run)
	_settings_button.pressed.connect(_on_settings)
	_quit_button.pressed.connect(_on_quit)
	_settings_close_button.pressed.connect(_on_settings_close)
	_sensitivity_slider.value_changed.connect(_on_sensitivity_changed)
	_fov_slider.value_changed.connect(_on_fov_changed)
	_invert_check.toggled.connect(_on_invert_toggled)
	_psx_slider.value_changed.connect(_on_psx_changed)
	_affine_check.toggled.connect(_on_affine_toggled)

	_settings_panel.visible = false
	_settings_backdrop.visible = false
	_sensitivity_slider.value = WsGame.mouse_sensitivity
	_fov_slider.value = WsGame.fov
	_invert_check.button_pressed = WsGame.invert_y
	_psx_slider.value = int(round(WsGame.psx_amount * 100.0))
	_affine_check.button_pressed = WsGame.psx_affine
	_refresh_value_labels()

	_new_run_button.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and _settings_panel.visible:
		_on_settings_close()


## Starts a run in the movement greybox.
func _on_new_run() -> void:
	WsGame.start_run("0.01")
	get_tree().change_scene_to_packed(GreyboxScene)


## Opens the settings panel.
func _on_settings() -> void:
	_settings_panel.visible = true
	_settings_backdrop.visible = true
	_sensitivity_slider.grab_focus()


## Closes the settings panel.
func _on_settings_close() -> void:
	_settings_panel.visible = false
	_settings_backdrop.visible = false
	WsGame.save_settings()
	_settings_button.grab_focus()


## Leaves the game.
func _on_quit() -> void:
	WsGame.save_settings()
	get_tree().quit()


func _on_sensitivity_changed(value: float) -> void:
	WsGame.mouse_sensitivity = value
	_refresh_value_labels()


func _on_fov_changed(value: float) -> void:
	WsGame.fov = value
	_refresh_value_labels()


func _on_invert_toggled(value: bool) -> void:
	WsGame.invert_y = value


## The PSX amount slider, which runs from 0 to 100 percent.
func _on_psx_changed(value: float) -> void:
	WsGame.psx_amount = value / 100.0
	Psx.set_amount(WsGame.psx_amount)
	_refresh_value_labels()


## The affine texture switch.
func _on_affine_toggled(value: bool) -> void:
	WsGame.psx_affine = value
	Psx.set_affine(value)


func _refresh_value_labels() -> void:
	_sensitivity_value.text = "%.4f" % WsGame.mouse_sensitivity
	_fov_value.text = "%d" % int(WsGame.fov)
	_psx_value.text = "%d%%" % int(round(WsGame.psx_amount * 100.0))
