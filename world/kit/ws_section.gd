# WindShear — the root of a section scene
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
## The root of a section: the scene the game loads and the thing the
## designer edits.
##
## The root carries the id of the section and, if it wants to repeat them,
## the name, the difficulty and the par time the campaign index already
## says. The exporter checks the two against each other, so a section that
## drifts away from the index is a problem and not a surprise.
##
## The export button is in the Inspector. The designer presses it and the
## section data is written next to the scene.
@tool
extends Node3D
class_name WSSection

## The exporter.
const Exporter := preload("res://addons/level_tools/ws_section_exporter.gd")

## The id of the section, for example "P1.01". Leave it empty to take the
## id from the campaign index.
@export var section_id := ""

## The name the menus show. Leave it empty to take it from the index.
@export var display_name := ""

## How hard the section is, from one to ten. Zero means take it from the
## index.
@export_range(0, 10, 1) var difficulty := 0

## The par time in frames at sixty a second. Zero means take it from the
## index.
@export var par_time_frames := 0

## Writes the section data.
##
## The button is in the Inspector of the section root.
@export_tool_button("export section data", "Save") var export_button: Callable = export_data


## Writes the data for this section.
##
## The game does not read that file. The game loads this scene. The file is
## the mirror the tests compare against, so a section that was changed and
## not exported fails the build.
func export_data() -> void:
	var path := scene_file_path
	if path.is_empty():
		push_warning("save the section scene before exporting it")
		return

	var exporter := Exporter.new()
	if not exporter.write(path):
		for problem in exporter.problems:
			push_warning(problem)
		return
	print("wrote %s" % Exporter.output_path(path))
