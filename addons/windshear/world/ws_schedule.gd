# WindShear — the gate schedule
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
## The gate schedule, read the way the game reads it.
##
## `data/schedule.json` says when every regulation gate in the campaign is
## open and when it is closed. The rules are written in the file itself: a
## gate that cycles moves through its windows, and a gate that does not
## uses its one window as it is.
##
## The functions here are pure. The same frame and the same schedule give
## the same state on every machine, which is what a replay needs.
class_name WsSchedule
extends RefCounted

## Where the schedule lives.
const SCHEDULE_PATH := "res://data/schedule.json"

## The state a gate is in when the schedule says nothing about the frame.
const FALLBACK_STATE := "closed"

## The state names the schedule uses.
const OPEN := "open"
const CLOSED := "closed"
const CYCLING := "cycling"


## Reads the schedule from disk.
##
## An empty dictionary means the file is missing or is not a schedule.
static func read() -> Dictionary:
	if not FileAccess.file_exists(SCHEDULE_PATH):
		return {}
	var file := FileAccess.open(SCHEDULE_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed


## Every gate in the schedule, by id.
##
## The lookup is made once, because the game asks about a gate sixty times
## a second and walking three hundred sections every time would be silly.
static func index(schedule: Dictionary) -> Dictionary:
	var entries: Dictionary = {}
	for chapter in schedule.get("chapters", []):
		for section in chapter.get("sections", []):
			for gate in section.get("gates", []):
				var gate_id := str(gate.get("gate_id", ""))
				if gate_id.is_empty():
					continue
				entries[gate_id] = gate
	return entries


## The entry of one gate, by its id.
##
## An empty dictionary means the schedule has no such gate.
static func gate_for(schedule: Dictionary, gate_id: String) -> Dictionary:
	return index(schedule).get(gate_id, {})


## The state of a gate on a frame of the global clock.
##
## A gate that cycles works out where it is in its cycle and looks that
## frame up in its windows. A gate that does not cycle uses its windows as
## they are, against the global frame.
##
## The state is "closed" when the schedule says nothing about the frame.
## That is the same fallback the schedule file names.
static func state_at(gate: Dictionary, global_frame: int) -> String:
	if gate.is_empty():
		return FALLBACK_STATE

	var period := int(gate.get("cycle_period_frames", 0))
	var local_frame := global_frame
	if period > 0:
		var offset := int(gate.get("phase_offset_frames", 0))
		local_frame = (global_frame + offset) % period

	for window in gate.get("windows", []):
		var start := int(window.get("start_frame", 0))
		if local_frame < start:
			continue
		var end_value: Variant = window.get("end_frame", null)
		if end_value != null and local_frame >= int(end_value):
			continue
		return str(window.get("state", FALLBACK_STATE))
	return FALLBACK_STATE


## Whether a gate is open on a frame of the global clock.
static func is_open(gate: Dictionary, global_frame: int) -> bool:
	return state_at(gate, global_frame) == OPEN
