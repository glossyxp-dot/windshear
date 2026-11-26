# WindShear — export the section scenes from the command line
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
## Writes the section data from the section scenes.
##
## [codeblock]
## godot --headless --path . --script res://tools/export_sections.gd -- --export
## godot --headless --path . --script res://tools/export_sections.gd -- --check
## [/codeblock]
##
## The check is what CI runs. It fails when the committed data no longer
## matches the scenes, so a forgotten export is a failed build instead of a
## surprise in the game.
extends SceneTree

## The exporter.
const Exporter := preload("res://addons/level_tools/ws_section_exporter.gd")


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var arguments := OS.get_cmdline_user_args()
	var check_only := arguments.has("--check")

	var exporter := Exporter.new()
	var passed := false
	if check_only:
		passed = exporter.check_all()
		if passed:
			print("the section data matches the scenes")
	else:
		passed = exporter.write_all()
		if passed:
			print("the section data was written for %d sections" % [
				exporter.authored_scenes().size()])

	for problem in exporter.problems:
		printerr("problem: %s" % problem)

	if not passed:
		printerr("the section data did not pass")
	quit(0 if passed else 1)
