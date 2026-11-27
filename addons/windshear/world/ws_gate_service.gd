# WindShear — the regulation gates of a running section
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
## The gates in a section, and the schedule they obey.
##
## A gate is a point the designer put in the room. The point says where the
## gate is and how wide it is; the schedule says when it opens. This service
## joins the two: it gives every gate a body to stand in the way with, and
## it opens and closes that body as the clock runs.
##
## The barrier is made when the section loads and it is an internal child of
## the gate point, so the saved scene stays a handful of numbers and the
## designer never sees a mesh to clean up.
class_name WsGateService
extends RefCounted

## The designer-authored point.
const KitPoint := preload("res://world/kit/ws_kit_point.gd")
## The schedule.
const Schedule := preload("res://addons/windshear/world/ws_schedule.gd")
## What the barrier wears.
const BARRIER_MATERIAL := preload("res://assets/materials/psx_glow.tres")

## How thick the barrier is, in metres.
const THICKNESS := 0.3

## The state every gate starts in before the schedule says otherwise.
const UNSET := ""

## The gates of the running section.
##
## Each one is a dictionary: the point, the body, the mesh, the id and the
## state it is in now.
var _gates: Array = []

## The schedule, by gate id.
var _entries: Dictionary = {}


## The number of gates the service is looking after.
func count() -> int:
	return _gates.size()


## The ids of the gates the service is looking after.
func gate_ids() -> PackedStringArray:
	var ids := PackedStringArray()
	for gate in _gates:
		ids.append(str(gate.get("id", "")))
	return ids


## Sets the service to a section.
##
## The barriers of the old section are freed with it, because they are
## children of the points of that section.
func configure(section: Node, schedule: Dictionary) -> void:
	_entries = Schedule.index(schedule)
	_gates.clear()
	if section == null:
		return
	_collect(section)


## Puts every gate in the state the schedule says for this frame.
##
## The frame is the global clock of the run, so a gate that cycles keeps
## its rhythm from one section to the next.
func update(global_frame: int) -> void:
	for gate in _gates:
		var gate_id := str(gate.get("id", ""))
		var timing: Dictionary = _entries.get(gate_id, {})
		var state := Schedule.state_at(timing, global_frame)
		if str(gate.get("state", UNSET)) == state:
			continue
		gate["state"] = state
		_apply(gate, state)


## The state of one gate on a frame, without changing anything.
func state_of(gate_id: String, global_frame: int) -> String:
	var timing: Dictionary = _entries.get(gate_id, {})
	return Schedule.state_at(timing, global_frame)


## Whether a gate is open on a frame.
func is_open(gate_id: String, global_frame: int) -> bool:
	return state_of(gate_id, global_frame) == Schedule.OPEN


## Finds every gate point under a section and gives it a body.
func _collect(node: Node) -> void:
	for child in node.get_children():
		if child is KitPoint and int(child.get("kind")) == KitPoint.Kind.REGULATION_GATE:
			_gates.append(_build(child as Node3D))
		_collect(child)


## Gives one gate point its barrier.
##
## The barrier stands on the point: the point says where the gate meets the
## floor, and the barrier grows upwards from there.
func _build(point: Node3D) -> Dictionary:
	var width := 4.0
	var height := 3.0
	if "gate_width" in point:
		width = maxf(float(point.get("gate_width")), 0.1)
	if "gate_height" in point:
		height = maxf(float(point.get("gate_height")), 0.1)

	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = "Barrier"
	var mesh := BoxMesh.new()
	mesh.size = Vector3(width, height, THICKNESS)
	mesh_instance.mesh = mesh
	mesh_instance.material_override = BARRIER_MATERIAL
	mesh_instance.position = Vector3(0.0, height * 0.5, 0.0)
	point.add_child(mesh_instance, false, Node.INTERNAL_MODE_BACK)
	mesh_instance.set_meta("ws_gate_generated", true)

	var body := StaticBody3D.new()
	body.name = "BarrierBody"
	body.collision_layer = 0
	body.collision_mask = 1
	point.add_child(body, false, Node.INTERNAL_MODE_BACK)
	body.set_meta("ws_gate_generated", true)

	var collision := CollisionShape3D.new()
	collision.name = "Shape"
	var shape := BoxShape3D.new()
	shape.size = Vector3(width, height, THICKNESS)
	collision.shape = shape
	collision.position = Vector3(0.0, height * 0.5, 0.0)
	body.add_child(collision, false, Node.INTERNAL_MODE_BACK)
	collision.set_meta("ws_gate_generated", true)

	return {
		"point": point,
		"body": body,
		"mesh": mesh_instance,
		"id": str(point.get("point_id")),
		"state": UNSET,
	}


## Opens or closes one gate.
##
## A closed gate stands in the way. An open gate is not there at all: the
## barrier is hidden and the body stops colliding, so the player walks
## through where it was.
func _apply(gate: Dictionary, state: String) -> void:
	var closed := state == Schedule.CLOSED
	var body: StaticBody3D = gate.get("body")
	var mesh: MeshInstance3D = gate.get("mesh")
	if body != null:
		body.collision_layer = 1 if closed else 0
	if mesh != null:
		mesh.visible = closed
