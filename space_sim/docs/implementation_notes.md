# Simulation-First Space God Vertical Slice

This project is a Godot 4.6 GDScript-only prototype for a realistic-feeling 2D celestial sandbox.

## How to run

Open `project.godot` in Godot 4.6 and run the main scene:

`res://space_sim/main/SpaceSimMain.tscn`

## Controls

- Pan camera: right mouse drag, middle mouse drag, or WASD/arrow keys
- Zoom: mouse wheel
- Select body: left click a body
- Follow selected: `F`
- Pause/resume: `Space`
- Time scale: `1`/`2`/`3`/`4`, or `[` and `]`
- Cycle material: `Tab` or use the material dropdown
- Create body: left-click empty space, hold to grow radius, drag to set initial velocity, release to spawn

## Simulation model

- Positions, velocities, accelerations, radii, masses, densities, temperatures, and gravity are SI-style values internally.
- Gravity uses Newtonian pairwise acceleration with `G = 6.67430e-11`.
- Motion uses kick-drift-kick leapfrog integration. This is still a first-slice approximation, but it behaves better than explicit Euler for gravity at fast-forward scales.
- Bodies are custom `Node2D` instances managed by `SimManager`; Godot `RigidBody2D` is not used for astronomical dynamics.
- Mass is derived from spherical volume, body radius, and selected material density.

## Collision model approximations

The collision solver is physically motivated but not a perfect real-universe impact model.

- Collision energy is estimated from reduced mass and relative velocity.
- Low specific impact energy produces crater-style damage and heat.
- Moderate impacts eject real simulated fragment bodies.
- Severe impacts can shatter the weaker/smaller participant into real simulated fragments.
- Low-speed or highly overlapping contacts merge/accrete into one larger body while conserving total momentum.
- Fragment size/count and ejecta angles are deterministic gameplay approximations, not hydrodynamics.

## Rendering approximations

- Bodies are shaded circles with a highlight to suggest volume.
- Trails are optional body history rendered in local draw space.
- Impact flashes and shock rings are visual feedback only; debris fragments are real simulated bodies.
- Heat glow appears above a simple temperature threshold.

## Current vertical slice limits

- Pairwise gravity is O(n^2), suitable for a small sandbox but not thousands of bodies.
- No tidal forces, rotation, atmosphere, N-body tree approximation, fluid dynamics, or orbital prediction UI.
- Collision resolution favors readable gameplay behavior over exact material failure science.
