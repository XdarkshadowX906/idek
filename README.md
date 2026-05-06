# Browser Space God Prototype

A self-contained realistic-feeling 2D celestial sandbox that runs in a web browser.

The simulation now uses pairwise Newtonian gravity, leapfrog integration, spatial-hash collision broadphase, and impact outcomes based on specific impact energy versus a simple disruption threshold made from material strength plus gravitational binding energy. It also supports planets/asteroids, stars, black holes, and speculative white holes. This is much more physically motivated than the first version, but it is not exact real-life destruction physics or exact cosmology; exact planetary impact fracture, stellar plasma, and relativistic black hole physics require specialized 3D solvers, not a single browser file.

Impact visuals intentionally avoid arcade-style expanding shockwave rings, fake particles, or decorative ejecta streaks. Feedback is limited to crater/damage marks, body heat tint, changed motion, and real simulated fragment bodies. Catastrophic breakups now preserve large remnant chunks plus smaller ejecta instead of making the destroyed body simply disappear into equal tiny asteroids; when fragments fall back into a much larger body, they crater and accrete instead of bouncing into permanent circular orbits.

## How to use it

Open `index.html` in Chrome, Edge, Firefox, or another modern browser.

No install, build step, Godot editor, or web server is required.

## Controls

- Left click a body: select it
- Left click empty space, hold, drag, release: create a body and set its launch velocity. Creation radius has no hard maximum; the longer you hold, the larger the planet gets.
- Mouse wheel: zoom
- Middle mouse drag or right mouse drag: pan
- WASD or arrow keys: pan
- Space: pause/resume
- F: follow selected body
- O: cycle object type: planet, star, black hole, white hole
- 1 / 2 / 3 / 4: time scale presets
- 5: load an Earth analog hit by a 500 km rocky asteroid at about 20 km/s
- [ / ]: slower/faster time scale
- Tab: cycle creation material
- Escape: clear selection
- R: reset camera

The whole app is in `index.html`.
