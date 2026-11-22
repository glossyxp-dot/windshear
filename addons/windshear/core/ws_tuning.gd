# WindShear — movement tuning constants (the single source of truth)
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
## Every number in this file is locked by `TECH_SPEC.md` §3. The test suite
## asserts them, so changing one here without changing the document (or the
## other way round) breaks the build.
##
## Nothing in here allocates or touches the scene tree: the file is safe to
## load from a worker thread and from the headless test runner.
extends RefCounted
class_name WSTuning

# --- Simulation ----------------------------------------------------------
## Fixed physics tick. The game never runs a variable-step simulation.
const PHYSICS_TICK := 60
## One physics frame, in seconds.
const FRAME_DELTA := 1.0 / 60.0

# --- Ground movement -----------------------------------------------------
## Top running speed, in metres per second.
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

# --- Wall-kiss ------------------------------------------------------------
## Frames after a slide starts during which a wall contact arms a wall-kiss.
const WALL_KISS_WINDOW_FRAMES := 2
## Speed added along the wall by one wall-kiss, in m/s.
const WALL_KISS_BOOST := 0.8
## Maximum wall-kisses in one chain.
const WALL_KISS_CAP := 5
## Frames without a wall-kiss after which the chain expires and the counter
## starts over. Half a second is long enough to chain a jump-slide-jump
## sequence and short enough that an accidental kiss does not stick around.
const WALL_KISS_CHAIN_FRAMES := 30
## The fastest speed a wall-kiss chain can produce: the run speed plus the
## full chain of five boosts. Nothing may go past this.
const WALL_KISS_SPEED_CEILING := MAX_RUN_SPEED + WALL_KISS_CAP * WALL_KISS_BOOST

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
