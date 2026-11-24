# WindShear — per-cell memory budget checker
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
## Checks every section cell against the per-cell budgets in `TECH_SPEC.md`
## §2 and §12:
##
## [codeblock]
## textures <= 45 MB   meshes <= 20 MB   audio <= 12 MB
## [/codeblock]
##
## Run it in CI after every content change:
##
## [codeblock]
## godot --headless --path . --script res://tools/cell_budget_checker.gd
## [/codeblock]
##
## These budgets are a hard requirement, not a suggestion. The game has to run
## on a 4 GB machine without swapping.
extends SceneTree

## The directory that holds the section cells.
const SECTIONS_PATH := "res://data/sections"

## The per-cell budgets in bytes.
const TEXTURE_BUDGET := 45 * 1024 * 1024
const MESH_BUDGET := 20 * 1024 * 1024
const AUDIO_BUDGET := 12 * 1024 * 1024

## Which budget a file extension falls into.
const EXTENSION_GROUPS := {
	"png": "textures", "jpg": "textures", "jpeg": "textures", "webp": "textures",
	"svg": "textures", "ktx": "textures", "dds": "textures", "exr": "textures",
	"glb": "meshes", "gltf": "meshes", "obj": "meshes", "fbx": "meshes",
	"mesh": "meshes", "tres": "meshes", "res": "meshes",
	"ogg": "audio", "wav": "audio", "mp3": "audio", "flac": "audio",
}


func _initialize() -> void:
	var cells := _find_cells(SECTIONS_PATH)
	if cells.is_empty():
		print("no section cells found in %s — nothing to check" % SECTIONS_PATH)
		quit(0)
		return

	var failures := 0
	for cell in cells:
		var sizes := {"textures": 0, "meshes": 0, "audio": 0, "other": 0}
		_measure(cell, sizes)
		var over := false
		if sizes["textures"] > TEXTURE_BUDGET:
			over = true
		if sizes["meshes"] > MESH_BUDGET:
			over = true
		if sizes["audio"] > AUDIO_BUDGET:
			over = true
		print("%-40s textures %6.2f MB   meshes %6.2f MB   audio %6.2f MB" % [
			cell,
			float(sizes["textures"]) / 1048576.0,
			float(sizes["meshes"]) / 1048576.0,
			float(sizes["audio"]) / 1048576.0,
		])
		if over:
			failures += 1
			print("    OVER BUDGET")

	print("")
	if failures == 0:
		print("=== %d cells, all inside the budget ===" % cells.size())
		quit(0)
		return
	print("=== %d of %d cells are over budget ===" % [failures, cells.size()])
	quit(1)


## Lists the cell directories below [param path].
func _find_cells(path: String) -> PackedStringArray:
	var cells := PackedStringArray()
	var dir := DirAccess.open(path)
	if dir == null:
		return cells
	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		if dir.current_is_dir() and not entry.begins_with("."):
			cells.append(path.path_join(entry))
		entry = dir.get_next()
	dir.list_dir_end()
	return cells


## Adds up the file sizes of one cell.
func _measure(path: String, sizes: Dictionary) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		return
	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		if dir.current_is_dir():
			if not entry.begins_with("."):
				_measure(path.path_join(entry), sizes)
		else:
			var extension := entry.get_extension().to_lower()
			var group := String(EXTENSION_GROUPS.get(extension, "other"))
			sizes[group] = int(sizes[group]) + _file_size(path.path_join(entry))
		entry = dir.get_next()
	dir.list_dir_end()


## The size of a file in bytes.
func _file_size(path: String) -> int:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return 0
	var length := file.get_length()
	file.close()
	return length
