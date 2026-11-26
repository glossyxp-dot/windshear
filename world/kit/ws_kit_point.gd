# WindShear — a point in a section (a designer-authored entity)
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
## A point in a section: the thing the designer places and names.
##
## This is the same idea as a Valve entity. You drop it in the room, set its
## properties in the Inspector, and the exporter reads them off and writes the
## section data the game loads. The designer never writes a JSON file by hand
## and the game never guesses what a node was for.
##
## The kind decides which properties matter. The Inspector hides the ones
## that do not apply, so a gate does not show you a filament anchor type.
extends Node3D
class_name WSKitPoint

## The kinds of point a section can hold.
enum Kind {
	SECTION_TRIGGER,
	REGULATION_GATE,
	CHECKPOINT,
	WIND_VOLUME,
	HAZARD_VOLUME,
	FILAMENT_ANCHOR,
	PARCEL,
	SPAWN,
}

## What this point is. Changing it changes which properties the Inspector
## shows.
@export var kind: Kind = Kind.CHECKPOINT:
	set(value):
		kind = value
		_update_property_list()
		notify_property_list_changed()

## The id this point carries. The exporter reads it.
@export var point_id := ""

## The section this point belongs to, e.g. "P1.01". The exporter reads it.
@export var section_id := ""

## A note for the owner. The game never sees it.
@export var note := ""

@export_category("Section trigger")
## The checkpoint the player enters this section at.
@export var start_checkpoint_id := ""
## The checkpoint the player respawns at when the section ends.
@export var end_checkpoint_id := ""
## The marker the speedrun split system reads.
@export var split_marker_id := ""

@export_category("Regulation gate")
## The state the gate starts in: open or closed.
@export var gate_state := "open"
## How long one cycle of the gate is, in frames. Zero means it never cycles.
@export var cycle_period_frames := 0
## Where this gate sits inside its cycle, in frames.
@export var phase_offset_frames := 0

@export_category("Wind volume")
## The kind of wind: thermal, crosswind or dead_zone.
@export var wind_kind := "thermal"
## How hard the wind pushes, in metres per second.
@export var wind_strength_mps := 0.0
## Which way the wind pushes, in degrees around Y.
@export var wind_direction_degrees := 0.0

@export_category("Hazard volume")
## The kind of hazard: fall, blade or regulator.
@export var hazard_kind := "fall"
## How much damage the hazard does a second.
@export var hazard_damage_per_second := 0.0

@export_category("Filament anchor")
## The kind of anchor: zip, ring or hold.
@export var anchor_type := "zip"


func _ready() -> void:
	if Engine.is_editor_hint():
		_update_property_list()


## Hides the properties that do not belong to this kind.
##
## Godot calls this in the editor whenever the Inspector draws, so a point
## only ever shows the properties that mean something for it.
func _validate_property(property: Dictionary) -> void:
	var name := String(property.get("name", ""))
	if name.begins_with("_"):
		return
	var hidden := _properties_for_other_kinds()
	if hidden.has(name):
		property["usage"] = PROPERTY_USAGE_NO_EDITOR


## The property names that do not belong to the current kind.
func _properties_for_other_kinds() -> PackedStringArray:
	var hidden := PackedStringArray()
	var groups := {
		Kind.SECTION_TRIGGER: ["start_checkpoint_id", "end_checkpoint_id", "split_marker_id"],
		Kind.REGULATION_GATE: ["gate_state", "cycle_period_frames", "phase_offset_frames"],
		Kind.WIND_VOLUME: ["wind_kind", "wind_strength_mps", "wind_direction_degrees"],
		Kind.HAZARD_VOLUME: ["hazard_kind", "hazard_damage_per_second"],
		Kind.FILAMENT_ANCHOR: ["anchor_type"],
	}
	for other_kind in groups.keys():
		if int(other_kind) == int(kind):
			continue
		for property_name in groups[other_kind]:
			hidden.append(String(property_name))
	return hidden


## Asks the editor for a fresh property list after the kind changed.
func _update_property_list() -> void:
	if not Engine.is_editor_hint():
		return
	notify_property_list_changed()


## The data the exporter writes for this point.
##
## Only the properties that belong to the kind are written, so the section
## data stays small and there is nothing in it that means nothing.
func to_data() -> Dictionary:
	var data := {
		"kind": _kind_name(),
		"id": point_id,
		"section_id": section_id,
		"transform": {
			"position": [snappedf(global_position.x, 0.001),
				snappedf(global_position.y, 0.001),
				snappedf(global_position.z, 0.001)],
			"rotation_y_degrees": snappedf(rad_to_deg(global_rotation.y), 0.01),
			"scale": [snappedf(global_scale.x, 0.001),
				snappedf(global_scale.y, 0.001),
				snappedf(global_scale.z, 0.001)],
		},
	}
	match kind:
		Kind.SECTION_TRIGGER:
			data["start_checkpoint_id"] = start_checkpoint_id
			data["end_checkpoint_id"] = end_checkpoint_id
			data["split_marker_id"] = split_marker_id
		Kind.REGULATION_GATE:
			data["gate_state"] = gate_state
			data["cycle_period_frames"] = cycle_period_frames
			data["phase_offset_frames"] = phase_offset_frames
		Kind.WIND_VOLUME:
			data["wind_kind"] = wind_kind
			data["wind_strength_mps"] = wind_strength_mps
			data["wind_direction_degrees"] = wind_direction_degrees
		Kind.HAZARD_VOLUME:
			data["hazard_kind"] = hazard_kind
			data["hazard_damage_per_second"] = hazard_damage_per_second
		Kind.FILAMENT_ANCHOR:
			data["anchor_type"] = anchor_type
	return data


## The name of this kind, as the data writes it.
func _kind_name() -> String:
	match kind:
		Kind.SECTION_TRIGGER:
			return "section_trigger"
		Kind.REGULATION_GATE:
			return "regulation_gate"
		Kind.CHECKPOINT:
			return "checkpoint"
		Kind.WIND_VOLUME:
			return "wind_volume"
		Kind.HAZARD_VOLUME:
			return "hazard_volume"
		Kind.FILAMENT_ANCHOR:
			return "filament_anchor"
		Kind.PARCEL:
			return "parcel"
		Kind.SPAWN:
			return "spawn"
	return "point"
