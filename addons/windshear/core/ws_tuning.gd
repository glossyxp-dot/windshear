# WindShear — movement tuning constants (one source of truth)
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
## Movement numbers live here. `TECH_SPEC.md` §3 locks them, and the test suite
## asserts the same values. Change one side and the build breaks until the other
## catches up.
##
## I keep this file free of allocations and scene-tree access, so it loads
## safely from a worker thread and from the headless test runner.
extends RefCounted
class_name WSTuning

# --- Simulation ----------------------------------------------------------
## Fixed physics tick. The game never runs a variable-step simulation.
const PHYSICS_TICK := 60
## One physics frame, in seconds.
const FRAME_DELTA := 1.0 / 60.0

# --- Ground movement -----------------------------------------------------
## Top running speed, in m/s.
const MAX_RUN_SPEED := 14.0
## Acceleration towards the target speed while grounded, in m/s².
const GROUND_ACCEL := 90.0
## Deceleration towards a standstill while grounded, in m/s².
const GROUND_DECEL := 60.0

# --- Air movement --------------------------------------------------------
## Air acceleration, in m/s².
const AIR_ACCEL := 32.0
## Total speed the air acceleration may contribute over one airborne stretch,
## in m/s. This is the "air-strafe mini-accel": strong, but bounded.
const AIR_ACCEL_MAX_CONTRIB := 2.2

# --- Jump ----------------------------------------------------------------
## Downward acceleration, in m/s². Chosen during Milestone 0 so that the
## locked jump velocity produces an apex of about 2 m (15.5² / (2 × 60)).
const GRAVITY := 60.0
## Upward velocity applied by a jump, in m/s.
const JUMP_VELOCITY := 15.5
## Multiplier applied to the vertical velocity when jump is released early.
## Below 1.0 means variable jump height.
const JUMP_CUT := 0.5
## Frames of coyote time after leaving the ground.
const COYOTE_FRAMES := 8
## Frames a jump press stays buffered before landing.
const JUMP_BUFFER_FRAMES := 10

# --- Slide ----------------------------------------------------------------
## Slide length in seconds.
const SLIDE_DURATION := 0.45
## Slide length in frames (0.45 s × 60 Hz = 27 frames).
const SLIDE_FRAMES := 27
## Linear friction applied while sliding, in m/s².
const SLIDE_FRICTION := 6.0
## Minimum horizontal speed required to start a slide, in m/s.
const SLIDE_MIN_SPEED := 5.0

# --- Wall-jump chain ------------------------------------------------------
## Frames after a slide starts during which a wall contact arms a wall-jump.
const WALL_KISS_WINDOW_FRAMES := 2
## Speed added along the route by one wall-jump, in m/s.
const WALL_KISS_BOOST := 0.8
## Wall-jumps allowed in one chain in the base game. Three. Then the chain is
## done.
const WALL_KISS_CAP := 3
## The shipped `wall_kiss_chain` Fracture takes the chain to five. Its registry
## text is immutable, so the fourth and fifth jump belong to the Fracture.
const WALL_KISS_FRACTURE_CAP := 5
## Frames without a wall-jump after which the chain expires and the counter
## starts over. Half a second is enough for a jump-slide-jump sequence and
## short enough that an accidental wall-jump doesn't stick around.
const WALL_KISS_CHAIN_FRAMES := 30
## The horizontal ceiling for a base chain: the run speed plus three boosts,
## 14.0 + 3 × 0.8 = 16.4 m/s.
const WALL_KISS_SPEED_CEILING := MAX_RUN_SPEED + WALL_KISS_CAP * WALL_KISS_BOOST
## The ceiling with the Fracture active: 14.0 + 5 × 0.8 = 18.0 m/s.
const WALL_KISS_FRACTURE_SPEED_CEILING := MAX_RUN_SPEED \
	+ WALL_KISS_FRACTURE_CAP * WALL_KISS_BOOST

# --- Filament -------------------------------------------------------------
## Time the aim assist needs to lock onto an anchor, in seconds.
const FILAMENT_LOCK_TIME := 0.25
## Half-angle of the filament lock-on cone, in degrees.
const FILAMENT_CONE_DEGREES := 18.0

# --- Plane ----------------------------------------------------------------
## Z coordinate of the gameplay plane. Gameplay happens on XY.
const PLAY_PLANE_Z := 0.0
## Tolerance used by the tests when asserting "the player stayed on the plane".
const PLANE_EPSILON := 0.0001
