# WindShear — a block of level geometry
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
## A piece of the room: a floor, a wall, a platform or a ramp.
##
## The shape is a property, not a mesh somebody modelled. You drop the piece
## in the room, type a number into the Inspector and the geometry follows,
## in the editor and in the game. There is no mesh file to open and no
## modelling tool in the loop.
##
## The mesh and the collision are generated when the piece loads, and they
## are internal children, so they never appear in the scene tree and never
## end up in the saved scene. The scene file stays a handful of numbers that
## you can read at a glance.
@tool
extends Node3D
class_name WSKitBlock

## What shape this piece is.
enum Shape {
	FLOOR,
	WALL,
	PLATFORM,
	RAMP,
}

## Which of the four PSX materials this piece wears.
enum Palette {
	SURFACE,
	DEEP,
	CHARCOAL,
	GLOW,
}

## The materials a piece can wear.
const MATERIALS := {
	Palette.SURFACE: preload("res://assets/materials/psx_surface.tres"),
	Palette.DEEP: preload("res://assets/materials/psx_deep.tres"),
	Palette.CHARCOAL: preload("res://assets/materials/psx_charcoal.tres"),
	Palette.GLOW: preload("res://assets/materials/psx_glow.tres"),
}

## The smallest size a piece can have. Anything thinner than this and the
## player falls through it.
const MIN_SIZE := 0.05

## What shape this piece is. Changing it changes what the size means.
@export var shape: Shape = Shape.FLOOR:
	set(value):
		shape = value
		_refresh()

## The size of the piece in metres.
##
## For the ramp this is the width, the thickness and the horizontal run. The
## height of the ramp is its own number.
@export var size: Vector3 = Vector3(8.0, 1.0, 8.0):
	set(value):
		size = Vector3(
			maxf(value.x, MIN_SIZE),
			maxf(value.y, MIN_SIZE),
			maxf(value.z, MIN_SIZE))
		_refresh()

## How high the ramp goes, in metres. Only the ramp reads this.
@export var ramp_rise := 3.0:
	set(value):
		ramp_rise = maxf(value, 0.0)
		_refresh()

## Which material this piece wears.
@export var palette: Palette = Palette.SURFACE:
	set(value):
		palette = value
		_refresh()

## Whether the player can stand on this piece.
@export var solid := true:
	set(value):
		solid = value
		_refresh()


func _ready() -> void:
	_refresh()


## Hides the properties that do not belong to the current shape.
func _validate_property(property: Dictionary) -> void:
	var name := str(property.get("name", ""))
	if name == "ramp_rise" and shape != Shape.RAMP:
		property["usage"] = PROPERTY_USAGE_NO_EDITOR


## Rebuilds the mesh and the collision from the current numbers.
##
## The children are internal, so the scene tree stays readable and the saved
## scene stays small.
func _refresh() -> void:
	if not is_inside_tree():
		return
	_clear()
	match shape:
		Shape.RAMP:
			_build_ramp()
		_:
			_build_box(size, Vector3.ZERO, 0.0)


## Removes the generated children.
##
## The flag matters. The mesh and the body are internal children, and the
## plain list does not show them.
func _clear() -> void:
	for child in get_children(true):
		if child.get_meta("ws_kit_generated", false):
			remove_child(child)
			child.queue_free()


## Builds a box at the given size, offset and rotation.
func _build_box(box_size: Vector3, offset: Vector3, tilt: float) -> void:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = "Mesh"
	mesh_instance.mesh = BoxMesh.new()
	(mesh_instance.mesh as BoxMesh).size = box_size
	mesh_instance.material_override = MATERIALS[palette]
	mesh_instance.position = offset
	if not is_zero_approx(tilt):
		mesh_instance.rotation.x = tilt
	add_child(mesh_instance, false, Node.INTERNAL_MODE_BACK)
	mesh_instance.set_meta("ws_kit_generated", true)

	if not solid:
		return

	var body := StaticBody3D.new()
	body.name = "Body"
	body.collision_layer = 1
	body.collision_mask = 1
	add_child(body, false, Node.INTERNAL_MODE_BACK)
	body.set_meta("ws_kit_generated", true)

	var collision := CollisionShape3D.new()
	collision.name = "Shape"
	var box := BoxShape3D.new()
	box.size = box_size
	collision.shape = box
	collision.position = offset
	if not is_zero_approx(tilt):
		collision.rotation.x = tilt
	body.add_child(collision, false, Node.INTERNAL_MODE_BACK)
	collision.set_meta("ws_kit_generated", true)


## Builds the ramp: a slab tilted so its top face is the slope.
##
## The low end sits on the floor at the origin and the ramp climbs towards
## positive Z, so a designer can place one and see which way it goes.
func _build_ramp() -> void:
	var run := size.z
	var rise := maxf(ramp_rise, 0.0)
	var thickness := size.y
	var width := size.x

	# A slope of zero is a flat slab, and a slope of nothing at all is a
	# degenerate triangle. Both are floors.
	if rise <= 0.0:
		_build_box(Vector3(width, thickness, run), Vector3.ZERO, 0.0)
		return

	var slope_length := sqrt(run * run + rise * rise)
	var angle := atan2(rise, run)
	var cosine := run / slope_length
	var sine := rise / slope_length

	# Where the middle of the slab goes so the low end of its underside
	# lands on the floor at the origin.
	var offset := Vector3(
		0.0,
		thickness * cosine * 0.5 + rise * 0.5,
		-thickness * sine * 0.5 + run * 0.5)

	_build_box(Vector3(width, thickness, slope_length), offset, -angle)
