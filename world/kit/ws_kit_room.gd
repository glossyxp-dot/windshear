# WindShear — a room shell
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
## A room: a floor, four walls and optionally a ceiling.
##
## The room is one node with four numbers on it. The designer types the size
## into the Inspector and the shell follows, in the editor and in the game.
## The pieces it is made of are ordinary `WSKitBlock` nodes, so a wall can
## be taken out and put back by hand when a section needs a doorway.
@tool
extends Node3D
class_name WSKitRoom

## The block the shell is made of.
const KitBlock := preload("res://world/kit/ws_kit_block.gd")

## The size of the room inside, in metres. The floor is at zero and the
## walls go up from there.
@export var room_size := Vector3(40.0, 12.0, 24.0):
	set(value):
		room_size = Vector3(
			maxf(value.x, 1.0),
			maxf(value.y, 1.0),
			maxf(value.z, 1.0))
		_refresh()

## How thick the walls are.
@export var wall_thickness := 0.4:
	set(value):
		wall_thickness = maxf(value, 0.05)
		_refresh()

## How thick the floor is.
@export var floor_thickness := 1.0:
	set(value):
		floor_thickness = maxf(value, 0.05)
		_refresh()

## Which material the room wears.
@export var palette: KitBlock.Palette = KitBlock.Palette.DEEP:
	set(value):
		palette = value
		_refresh()

## Whether the wall on the negative Z side is there.
@export var wall_north := true:
	set(value):
		wall_north = value
		_refresh()

## Whether the wall on the positive Z side is there.
@export var wall_south := true:
	set(value):
		wall_south = value
		_refresh()

## Whether the wall on the negative X side is there.
@export var wall_west := true:
	set(value):
		wall_west = value
		_refresh()

## Whether the wall on the positive X side is there.
@export var wall_east := true:
	set(value):
		wall_east = value
		_refresh()

## Whether there is a ceiling.
@export var ceiling := false:
	set(value):
		ceiling = value
		_refresh()


func _ready() -> void:
	_refresh()


## Rebuilds the shell from the current numbers.
func _refresh() -> void:
	if not is_inside_tree():
		return
	for child in get_children(true):
		if child.get_meta("ws_kit_generated", false):
			remove_child(child)
			child.queue_free()

	var width := room_size.x
	var height := room_size.y
	var depth := room_size.z
	var thickness := wall_thickness

	# The floor sits under zero, so the walkable surface is at zero.
	_add_piece("Floor",
		Vector3(0.0, -floor_thickness * 0.5, 0.0),
		Vector3(width, floor_thickness, depth),
		KitBlock.Shape.FLOOR)

	if wall_north:
		_add_piece("NorthWall",
			Vector3(0.0, height * 0.5, -depth * 0.5 - thickness * 0.5),
			Vector3(width + thickness * 2.0, height, thickness),
			KitBlock.Shape.WALL)
	if wall_south:
		_add_piece("SouthWall",
			Vector3(0.0, height * 0.5, depth * 0.5 + thickness * 0.5),
			Vector3(width + thickness * 2.0, height, thickness),
			KitBlock.Shape.WALL)
	if wall_west:
		_add_piece("WestWall",
			Vector3(-width * 0.5 - thickness * 0.5, height * 0.5, 0.0),
			Vector3(thickness, height, depth),
			KitBlock.Shape.WALL)
	if wall_east:
		_add_piece("EastWall",
			Vector3(width * 0.5 + thickness * 0.5, height * 0.5, 0.0),
			Vector3(thickness, height, depth),
			KitBlock.Shape.WALL)
	if ceiling:
		_add_piece("Ceiling",
			Vector3(0.0, height + floor_thickness * 0.5, 0.0),
			Vector3(width, floor_thickness, depth),
			KitBlock.Shape.FLOOR)


## Adds one piece of the shell.
func _add_piece(piece_name: String, offset: Vector3, piece_size: Vector3,
		shape: KitBlock.Shape) -> void:
	var piece := KitBlock.new()
	piece.name = piece_name
	piece.shape = shape
	piece.size = piece_size
	piece.palette = palette
	add_child(piece, false, Node.INTERNAL_MODE_BACK)
	piece.set_meta("ws_kit_generated", true)
	piece.position = offset
