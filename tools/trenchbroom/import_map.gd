# WindShear — turns a TrenchBroom map into a WindShear section
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
## Reads a map made in TrenchBroom and writes the section it describes.
##
## [codeblock]
## godot --headless --path . --script res://tools/trenchbroom/import_map.gd -- --map maps/P1_02.map --section P1.02
## godot --headless --path . --script res://tools/trenchbroom/import_map.gd -- --template P1.02 --out maps/P1_02.map
## [/codeblock]
##
## The map is the base of the section. The textures are not in the map and
## are not the job of this converter; they are made in Godot.
##
## The section is only written when there is no scene there yet. The
## `--overwrite` flag says to write it anyway, and the designer has to ask
## for it.
extends SceneTree

## The importer.
const Importer := preload("res://tools/trenchbroom/ws_map_importer.gd")
## The starter map.
const Template := preload("res://tools/trenchbroom/ws_map_template.gd")


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var arguments := OS.get_cmdline_user_args()

	var map_path := _value_of(arguments, "--map")
	var section_id := _value_of(arguments, "--section")
	var template_id := _value_of(arguments, "--template")
	var out_path := _value_of(arguments, "--out")
	var overwrite := arguments.has("--overwrite")

	var units := Importer.DEFAULT_UNITS_PER_METRE
	var units_text := _value_of(arguments, "--units-per-metre")
	if not units_text.is_empty():
		units = float(units_text)
		if units <= 0.0:
			printerr("the number of units to a metre has to be more than zero")
			quit(1)
			return

	if not template_id.is_empty():
		_quit_with(_write_the_template(template_id, out_path, units))
		return

	if map_path.is_empty() or section_id.is_empty():
		printerr("a map and a section are needed: --map maps/P1_02.map --section P1.02")
		quit(1)
		return

	var importer: RefCounted = Importer.new()
	importer.units_per_metre = units
	var worked: bool = importer.import_map(map_path, section_id, overwrite)

	print("windshear: %s from %s" % [section_id, map_path])
	for line in importer.report:
		print("  %s" % line)
	for problem in importer.problems:
		printerr("problem: %s" % problem)

	_quit_with(worked)


## Writes the starter map of a section.
func _write_the_template(section_id: String, out_path: String, units: float) -> bool:
	if out_path.is_empty():
		out_path = "res://maps/%s.map" % section_id.replace(".", "_")
	var problem := Template.write(section_id, out_path, units)
	if not problem.is_empty():
		printerr("problem: %s" % problem)
		return false
	print("wrote %s" % out_path)
	return true


## The value that follows a flag, or an empty string.
func _value_of(arguments: PackedStringArray, flag: String) -> String:
	for index in arguments.size():
		if arguments[index] != flag:
			continue
		if index + 1 < arguments.size():
			return arguments[index + 1]
	return ""


## Ends the run with the right status.
func _quit_with(worked: bool) -> void:
	quit(0 if worked else 1)
