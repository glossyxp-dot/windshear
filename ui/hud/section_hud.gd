# WindShear — the objective HUD
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
## The screen furniture of a section: what it is called, what the player has
## to do in it, and how long it has taken.
##
## The look is the theme's, not this file's. A label here asks the theme for
## a style and nothing else, so changing the look means changing one file.
extends Control

## What the HUD says when the designer has not written an objective.
const DEFAULT_OBJECTIVE := "REACH THE EXIT"

@onready var _section_label: Label = $Section
@onready var _objective_label: Label = $Objective
@onready var _timer_label: Label = $Timer
@onready var _banner_label: Label = $Banner


## Puts the section name and the objective on the screen.
##
## The name is the one the campaign index carries, so the HUD and the menu
## call the section the same thing.
func set_section(section_id: String, display_name: String, objective: String) -> void:
	if display_name.is_empty():
		_section_label.text = section_id
	else:
		_section_label.text = "%s   %s" % [section_id, display_name.to_upper()]
	set_objective(objective)


## Puts the objective on the screen.
##
## An empty objective means the section has nothing special to ask for, and
## the player is told to get to the end.
func set_objective(objective: String) -> void:
	var text := objective.strip_edges()
	if text.is_empty():
		text = DEFAULT_OBJECTIVE
	_objective_label.text = text.to_upper()


## Puts the section clock on the screen.
func set_time(seconds: float) -> void:
	_timer_label.text = _clock(seconds)


## Shows a message in the middle of the screen.
func show_banner(text: String) -> void:
	_banner_label.text = text
	_banner_label.visible = true


## Takes the message away.
func hide_banner() -> void:
	_banner_label.text = ""
	_banner_label.visible = false


## The text of the clock, in minutes and hundredths of a second.
func _clock(seconds: float) -> String:
	var minutes := int(seconds) / 60
	var rest := seconds - float(minutes * 60)
	return "%d:%05.2f" % [minutes, rest]
