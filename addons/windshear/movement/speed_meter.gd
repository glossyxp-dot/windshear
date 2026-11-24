# WindShear — speed measurement (m/s)
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
## Measures Lancer's horizontal speed in m/s.
##
## The unit is m/s throughout the project: tuning constants, the
## mechanics reference, the discovery report and the HUD readout all use it.
## Engine pixels don't have a stable scale outside the renderer, so a speed
## number based on them can't be checked against a route.
##
## The meter keeps two numbers:
##
## - `current`, the horizontal speed right now
## - `peak`, the fastest horizontal speed since the last reset
##
## Horizontal only. The game plays on the XY plane and the Z axis is always
## zero. A vertical number would be noise.
extends RefCounted

## The current horizontal speed, in m/s.
var current := 0.0
## The fastest horizontal speed since the last reset, in m/s.
var peak := 0.0


## Takes a reading from a velocity vector.
##
## The peak only ever goes up until `reset()` is called.
func sample(velocity: Vector3) -> void:
	current = absf(velocity.x)
	if current > peak:
		peak = current


## Clears both numbers. The game calls this on a respawn, so the peak belongs
## to the current attempt rather than the whole session.
func reset() -> void:
	current = 0.0
	peak = 0.0


## The current speed as a short string, for the HUD.
##
## One decimal place, because two is more precision than a 60 Hz readout can
## honestly claim and the number jitters.
func current_text() -> String:
	return "%.1f m/s" % current


## The peak speed as a short string, for the HUD.
func peak_text() -> String:
	return "%.1f m/s" % peak
