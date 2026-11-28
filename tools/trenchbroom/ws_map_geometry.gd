# WindShear — the shape of a brush
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
## The shape of the brushes in a map.
##
## A brush is a set of planes. The inside of the brush is the part that is
## behind every one of them. This works out where the corners are, how big
## the brush is and whether it is a plain box.
##
## The kit WindShear builds its rooms from is made of boxes, so this is the
## part that has to be honest: a box comes out exactly as it went in, and
## anything else says so.
class_name WSMapGeometry
extends RefCounted

## How close two numbers have to be to be the same number.
const EPSILON := 0.0001


## The planes of a brush.
##
## Each plane is a dictionary with a "normal" and a "distance". The brush
## is the set of points that are behind every plane, which means the
## normal points away from the inside.
static func planes(brush: Dictionary) -> Array:
	var result: Array = []
	for face in brush.get("faces", []):
		var points: Array = face.get("points", [])
		if points.size() < 3:
			continue
		var first: Vector3 = points[0]
		var second: Vector3 = points[1]
		var third: Vector3 = points[2]

		# The order of the three points says which way the plane faces.
		# The normal is the cross product of the two vectors that go from
		# the first point to the other two, taken in that order.
		var normal := (third - first).cross(second - first)
		if normal.length() < EPSILON:
			continue
		normal = normal.normalized()
		result.append({
			"normal": normal,
			"distance": normal.dot(first),
		})

	_turn_the_planes_the_right_way(brush, result)
	return result


## Turns the planes round when the faces were written the other way round.
##
## The middle of the brush is inside the brush, so it says which side of
## every plane the inside is on. When most of the planes say the middle is
## in front of them, they are all the wrong way round and they are turned.
static func _turn_the_planes_the_right_way(brush: Dictionary, planes: Array) -> void:
	if planes.is_empty():
		return
	var centre := _centre(brush)
	var behind := 0
	var in_front := 0
	for plane in planes:
		if plane["normal"].dot(centre) <= float(plane["distance"]) + EPSILON:
			behind += 1
		else:
			in_front += 1
	if in_front <= behind:
		return
	for plane in planes:
		plane["normal"] = -(plane["normal"] as Vector3)
		plane["distance"] = -float(plane["distance"])


## The middle of a brush, from all the points on its faces.
static func _centre(brush: Dictionary) -> Vector3:
	var total := Vector3.ZERO
	var count := 0
	for face in brush.get("faces", []):
		for point in face.get("points", []):
			total += point as Vector3
			count += 1
	if count == 0:
		return Vector3.ZERO
	return total / float(count)


## Whether a point is inside a brush.
static func contains(planes: Array, point: Vector3) -> bool:
	for plane in planes:
		if (plane["normal"] as Vector3).dot(point) > float(plane["distance"]) + EPSILON:
			return false
	return true


## The corners of a brush.
##
## A corner is where three planes meet, so every set of three planes is
## tried and the point is kept when it is inside the brush.
static func vertices(brush: Dictionary, planes: Array) -> Array:
	var result: Array = []
	var count := planes.size()
	if count < 3:
		return result
	for first in count:
		for second in range(first + 1, count):
			for third in range(second + 1, count):
				var corner: Variant = _intersection(planes[first], planes[second], planes[third])
				if corner == null:
					continue
				if contains(planes, corner):
					result.append(corner)
	return result


## Where three planes meet, or nothing when they do not.
static func _intersection(first: Dictionary, second: Dictionary, third: Dictionary) -> Variant:
	var normal_a: Vector3 = first["normal"]
	var normal_b: Vector3 = second["normal"]
	var normal_c: Vector3 = third["normal"]

	var cross_bc := normal_b.cross(normal_c)
	var denominator := normal_a.dot(cross_bc)
	if absf(denominator) < EPSILON:
		return null

	var cross_ca := normal_c.cross(normal_a)
	var cross_ab := normal_a.cross(normal_b)
	var point := (cross_bc * float(first["distance"])
			+ cross_ca * float(second["distance"])
			+ cross_ab * float(third["distance"])) / denominator
	return point


## The box around a brush, in map units.
static func bounds(brush: Dictionary, planes: Array) -> AABB:
	var corners := vertices(brush, planes)
	if corners.is_empty():
		return _bounds_of_the_points(brush)
	var lowest := corners[0] as Vector3
	var highest := lowest
	for corner in corners:
		var point := corner as Vector3
		lowest = Vector3(minf(lowest.x, point.x), minf(lowest.y, point.y), minf(lowest.z, point.z))
		highest = Vector3(maxf(highest.x, point.x), maxf(highest.y, point.y), maxf(highest.z, point.z))
	return AABB(lowest, highest - lowest)


## The box around all the points of the faces.
##
## This is the answer when the brush has no corners at all, which happens
## when the brush is broken.
static func _bounds_of_the_points(brush: Dictionary) -> AABB:
	var lowest := Vector3.ZERO
	var highest := Vector3.ZERO
	var first := true
	for face in brush.get("faces", []):
		for point in face.get("points", []):
			var value := point as Vector3
			if first:
				lowest = value
				highest = value
				first = false
				continue
			lowest = Vector3(minf(lowest.x, value.x), minf(lowest.y, value.y), minf(lowest.z, value.z))
			highest = Vector3(maxf(highest.x, value.x), maxf(highest.y, value.y), maxf(highest.z, value.z))
	return AABB(lowest, highest - lowest)


## Whether a brush is a plain box with its faces square to the floor.
static func is_box(planes: Array) -> bool:
	if planes.size() != 6:
		return false
	var directions := {}
	for plane in planes:
		var normal: Vector3 = plane["normal"]
		var direction := _axis_of(normal)
		if direction.is_empty():
			return false
		directions[direction] = true
	return directions.size() == 6


## The name of the axis a normal points along, or nothing when it does not
## point along one.
static func _axis_of(normal: Vector3) -> String:
	if absf(normal.x) > 1.0 - EPSILON and absf(normal.y) < EPSILON and absf(normal.z) < EPSILON:
		return "+x" if normal.x > 0.0 else "-x"
	if absf(normal.y) > 1.0 - EPSILON and absf(normal.x) < EPSILON and absf(normal.z) < EPSILON:
		return "+y" if normal.y > 0.0 else "-y"
	if absf(normal.z) > 1.0 - EPSILON and absf(normal.x) < EPSILON and absf(normal.y) < EPSILON:
		return "+z" if normal.z > 0.0 else "-z"
	return ""


## The slope of a brush, when it has one.
##
## A slope is a brush with one face that is not square to the floor. The
## answer says which way it climbs, how far it climbs and how long the
## climb is. An empty dictionary means the brush has no slope.
##
## This is in map units, where Z is up and the floor is the X and Y plane.
static func slope(planes: Array, box: AABB) -> Dictionary:
	var slanted: Dictionary = {}
	var square := 0
	for plane in planes:
		var normal: Vector3 = plane["normal"]
		if _axis_of(normal).is_empty():
			if not slanted.is_empty():
				return {}
			slanted = plane
			continue
		square += 1
	if slanted.is_empty() or square < 5:
		return {}

	var normal: Vector3 = slanted["normal"]
	var distance := float(slanted["distance"])
	if normal.z < 0.0:
		normal = -normal
		distance = -distance

	# The slope runs along one horizontal axis. The steeper one is the one
	# it runs along.
	var centre := box.get_center()
	var along_x := absf(normal.x) >= absf(normal.y)
	var low := 0.0
	var high := 0.0
	if along_x:
		low = _height_at(normal, distance, box.position.x, centre.y)
		high = _height_at(normal, distance, box.end.x, centre.y)
	else:
		low = _height_at(normal, distance, centre.x, box.position.y)
		high = _height_at(normal, distance, centre.x, box.end.y)

	var uphill := high >= low
	return {
		"normal": normal,
		"distance": distance,
		"along_x": along_x,
		"low": minf(low, high),
		"high": maxf(low, high),
		"uphill": uphill,
		"rise": absf(high - low),
		"run": box.size.x if along_x else box.size.y,
		"width": box.size.y if along_x else box.size.x,
	}


## The height of a slanted plane at a place on the floor.
##
## The map has Z up, so the height is what is left of the plane when the
## two flat directions are taken out.
static func _height_at(normal: Vector3, distance: float, x: float, y: float) -> float:
	if absf(normal.z) < EPSILON:
		return 0.0
	return (distance - normal.x * x - normal.y * y) / normal.z
