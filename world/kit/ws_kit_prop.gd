# WindShear — a model the designer put in the room
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
## A model in the room: something the designer imported.
##
## The kit blocks are boxes the engine builds from four numbers. This is the
## other kind of piece: a mesh that came from a file. The file is copied
## into `assets/models/` and the scene keeps a note of where it is, so the
## model follows the section everywhere it goes.
##
## The model itself is loaded when the piece loads, in the editor and in the
## game, and it is an internal child, so the scene file stays a handful of
## numbers that can be read at a glance.
@tool
extends Node3D
class_name WSKitProp

## The model file, relative to the project.
##
## A `.glb` or `.gltf` is a scene and is instantiated. An `.obj` is a mesh
## and is put in a mesh instance. Either way the designer does not have to
## know which one they picked.
@export_file("*.glb", "*.gltf", "*.obj") var model_path := "":
	set(value):
		model_path = value
		_refresh()

## How big the model is, as a multiple of what the file says.
@export var model_scale := Vector3.ONE:
	set(value):
		model_scale = value
		_refresh()

## Whether the player can walk into this.
@export var solid := false:
	set(value):
		solid = value
		_refresh()

## The box the player bumps into, in metres.
##
## This is a plain box and not the shape of the model. A collision shape
## that follows every triangle of an imported mesh is slow and almost never
## what a level designer means.
@export var collision_size := Vector3(1.0, 1.0, 1.0):
	set(value):
		collision_size = Vector3(
			maxf(value.x, 0.05),
			maxf(value.y, 0.05),
			maxf(value.z, 0.05))
		_refresh()

## Whether the model is drawn.
@export var visible_model := true:
	set(value):
		visible_model = value
		_refresh()


func _ready() -> void:
	_refresh()


## Rebuilds the model and the body from the current numbers.
func _refresh() -> void:
	if not is_inside_tree():
		return
	_clear()
	if model_path.is_empty():
		return
	if not ResourceLoader.exists(model_path):
		return

	var resource: Resource = load(model_path)
	if resource == null:
		return

	if resource is PackedScene:
		var scene: PackedScene = resource
		var instance := scene.instantiate()
		add_child(instance, false, Node.INTERNAL_MODE_BACK)
		instance.set_meta("ws_kit_generated", true)
		instance.scale = model_scale
		instance.visible = visible_model
	elif resource is Mesh:
		var mesh_instance := MeshInstance3D.new()
		mesh_instance.name = "Mesh"
		mesh_instance.mesh = resource as Mesh
		mesh_instance.scale = model_scale
		mesh_instance.visible = visible_model
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
	box.size = collision_size
	collision.shape = box
	body.add_child(collision, false, Node.INTERNAL_MODE_BACK)
	collision.set_meta("ws_kit_generated", true)


## Removes the generated children.
##
## The flag matters. The model and the body are internal children, and the
## plain list does not show them.
func _clear() -> void:
	for child in get_children(true):
		if child.get_meta("ws_kit_generated", false):
			remove_child(child)
			child.queue_free()
