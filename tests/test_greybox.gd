# WindShear — greybox scene tests
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
## The greybox is the room the movement prototype lives in, so it has to
## obey the same rules as the finished game: the player stays on the XY
## plane, the camera stays with Lancer, and the geometry stays inside the
## triangle budget.
##
## This suite needs a live scene tree, so the runner instantiates the room
## and hands it over.
extends "res://tests/ws_test.gd"

## The player controller.
const Controller := preload("res://addons/windshear/movement/lancer_controller.gd")
## The per-frame input record.
const InputState := preload("res://addons/windshear/movement/lancer_input.gd")
## The PSX shader, so the hand-made materials can be checked.
const PsxShader := preload("res://addons/windshear/render/ws_psx.gdshader")

## One physics frame.
const DT := 1.0 / 60.0
## The triangle budget for a visible scene.
const TRIANGLE_BUDGET := 35000
## The node budget for the greybox.
const NODE_BUDGET := 200


func suite_name() -> String:
	return "the greybox holds together"


func run_with_scene(scene: Node) -> void:
	_test_the_player_is_there(scene)
	_test_the_camera_stays_with_lancer(scene)
	_test_the_player_stays_on_the_plane(scene)
	_test_budget(scene)
	_test_the_materials_are_hand_editable(scene)
	_test_the_mechanics_reference(scene)
	_test_a_ninety_second_route()


func _test_the_player_is_there(scene: Node) -> void:
	heading("the player")
	var player := scene.get_node_or_null("Player")
	ok(player != null, "the greybox has a player")
	if player == null:
		return
	ok(player is CharacterBody3D, "the player is a CharacterBody3D")
	ok(player.get_node_or_null("Shape") != null, "the player has a collision shape")
	ok(player.get_node_or_null("CameraRig") != null, "the player carries the camera rig")


func _test_the_camera_stays_with_lancer(scene: Node) -> void:
	heading("the camera never leaves Lancer")
	var player := scene.get_node_or_null("Player")
	if player == null:
		return
	var rig := player.get_node_or_null("CameraRig")
	ok(rig != null, "the rig is a child of the player")
	if rig == null:
		return
	ok(rig.get_parent() == player, "the rig is parented to Lancer")
	near(rig.global_position.y, player.global_position.y, 0.001,
		"the rig sits exactly on Lancer")
	near(rig.global_position.z, player.global_position.z, 0.001,
		"the rig shares Lancer's plane")

	var camera := rig.get_node_or_null("Camera3D")
	ok(camera != null, "the rig drives a camera")
	if camera != null:
		var distance: float = camera.global_position.distance_to(player.global_position)
		ok(distance < 12.0, "the camera stays close to Lancer (%.2f m)" % distance)


func _test_the_player_stays_on_the_plane(scene: Node) -> void:
	heading("the 2.5D plane")
	var player := scene.get_node_or_null("Player")
	if player == null:
		return
	ok(absf(player.global_position.z) < 0.05,
		"Lancer stays on the play plane (z = %.4f)" % player.global_position.z)
	ok(player.velocity.z == 0.0, "the z velocity is exactly zero")
	ok(player.global_position.y > 0.5,
		"Lancer rests on the floor (y = %.3f)" % player.global_position.y)
	ok(player.global_position.y < 1.5,
		"Lancer did not fall through the floor (y = %.3f)" % player.global_position.y)


func _test_budget(scene: Node) -> void:
	heading("the budget")
	var nodes := _count_nodes(scene)
	ok(nodes <= NODE_BUDGET, "the greybox has %d nodes, the budget is %d" % [nodes, NODE_BUDGET])
	var triangles := _count_triangles(scene)
	ok(triangles <= TRIANGLE_BUDGET,
		"the greybox has %d triangles, the budget is %d" % [triangles, TRIANGLE_BUDGET])


## The surfaces have to use the PSX shader, and they have to be real
## resources on disk rather than inline blocks, so the art can be edited by
## hand in the inspector.
func _test_the_materials_are_hand_editable(scene: Node) -> void:
	heading("the materials")
	var meshes := _collect_meshes(scene)
	ok(meshes.size() > 0, "the room has meshes to dress")
	var psx_count := 0
	var external_count := 0
	for mesh in meshes:
		var material := mesh.material_override
		if material is ShaderMaterial:
			if (material as ShaderMaterial).shader == PsxShader:
				psx_count += 1
		if material != null and material.resource_path.begins_with("res://assets/"):
			external_count += 1
	ok(psx_count == meshes.size(),
		"every surface uses the PSX shader (%d of %d)" % [psx_count, meshes.size()])
	ok(external_count == meshes.size(),
		"every surface points at a material file in assets/ (%d of %d)" % [
			external_count, meshes.size()
		])


## The in-game mechanics reference has to exist and tell the truth.
func _test_the_mechanics_reference(scene: Node) -> void:
	heading("the mechanics reference")
	var panel := scene.get_node_or_null("HUD/HelpPanel")
	ok(panel != null, "the room has a help panel")
	if panel == null:
		return
	ok(not panel.visible, "the help panel starts hidden")

	var label := panel.get_node_or_null("Label") as Label
	ok(label != null, "the help panel has a label")
	if label == null:
		return

	var text := label.text
	ok(text.contains("RUN"), "the reference lists the run verb")
	ok(text.contains("SLIDE"), "the reference lists the slide verb")
	ok(text.contains("JUMP"), "the reference lists the jump verb")
	ok(text.contains("WALL"), "the reference lists the wall-jump verb")
	ok(text.contains("GRAB"), "the reference lists the ledge grab")
	ok(text.contains("TETHER"), "the reference lists the filament")
	ok(text.contains("LMB / RMB"), "the reference lists the two triggers")

	# The numbers have to be the real ones, or the reference is a lie.
	var tuning := preload("res://addons/windshear/core/ws_tuning.gd")
	ok(text.contains("%.1f" % tuning.MAX_RUN_SPEED),
		"the reference quotes the real run speed")
	ok(text.contains("%.1f" % tuning.WALL_KISS_SPEED_CEILING),
		"the reference quotes the real wall-kiss ceiling")
	ok(text.contains("not built yet"),
		"the reference says which verbs do not exist yet")

	# And the toggle has to be bound to something.
	ok(InputMap.has_action("toggle_help"), "the help toggle is an input action")


func _test_a_ninety_second_route() -> void:
	heading("a 90 second route")
	var controller := Controller.new()
	var input := InputState.new()
	var position := Vector3(-24.0, 0.9, 0.0)
	var left_the_room := false
	var left_the_plane := false
	var fell_out := false
	var grounded := true

	# A route that runs the length of the room and back, with a jump and a
	# slide in every leg. The point is not the route itself but that ninety
	# seconds of movement never leaves the plane, never leaves the room and
	# never falls out of the world.
	for frame in range(5400):
		var leg := frame / 180
		input.move_axis = 1.0 if leg % 2 == 0 else -1.0
		input.jump_pressed = (frame % 97) == 60
		input.jump_released = (frame % 97) == 66
		input.slip_pressed = (frame % 97) == 20
		input.wall_contact = (frame % 97) >= 20 and (frame % 97) <= 24
		input.wall_normal = Vector3(0.0, 0.0, 1.0)
		input.on_floor = grounded
		controller.simulate(DT, input)
		if grounded and controller.velocity.y > 0.0:
			grounded = false
		if grounded:
			# The floor stops the fall: the body rests on it.
			position.y = 0.9
			controller.velocity.y = 0.0
			position.x += controller.velocity.x * DT
		else:
			position += controller.velocity * DT
			if position.y <= 0.9 and controller.velocity.y <= 0.0:
				grounded = true
				position.y = 0.9
				controller.velocity.y = 0.0
		if absf(position.z) > 0.001:
			left_the_plane = true
		if position.x < -31.0 or position.x > 31.0:
			left_the_room = true
		if position.y < -1.0:
			fell_out = true

	ok(not left_the_plane, "the route never leaves the XY plane")
	ok(not left_the_room, "the route stays inside the room")
	ok(not fell_out, "the route never falls out of the world")
	controller.free()


func _count_nodes(node: Node) -> int:
	var total := 1
	for child in node.get_children():
		total += _count_nodes(child)
	return total


func _count_triangles(node: Node) -> int:
	var total := 0
	if node is MeshInstance3D:
		var mesh := (node as MeshInstance3D).mesh
		if mesh != null:
			total += mesh.get_faces().size() / 3
	for child in node.get_children():
		total += _count_triangles(child)
	return total


## Every mesh in the tree.
func _collect_meshes(node: Node) -> Array[MeshInstance3D]:
	var found: Array[MeshInstance3D] = []
	if node is MeshInstance3D:
		found.append(node as MeshInstance3D)
	for child in node.get_children():
		found.append_array(_collect_meshes(child))
	return found
