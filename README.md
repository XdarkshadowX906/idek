# Browser Space God Prototype

A self-contained realistic-feeling 2D celestial sandbox that runs in a web browser.

The simulation now uses pairwise Newtonian gravity, leapfrog integration, spatial-hash collision broadphase, and impact outcomes based on specific impact energy versus a simple disruption threshold made from material strength plus gravitational binding energy. This is much more physically motivated than the first version, but it is not exact real-life destruction physics; exact planetary impact fracture requires specialized 3D continuum / hydrocode simulation, not a single browser file.

## How to use it

Open `index.html` in Chrome, Edge, Firefox, or another modern browser.

No install, build step, Godot editor, or web server is required.

## Controls

- Left click a body: select it
- Left click empty space, hold, drag, release: create a body and set its launch velocity
- Mouse wheel: zoom
- Middle mouse drag or right mouse drag: pan
- WASD or arrow keys: pan
- Space: pause/resume
- F: follow selected body
- 1 / 2 / 3 / 4: time scale presets
- 5: load an Earth analog hit by a 500 km rocky asteroid at about 20 km/s
- [ / ]: slower/faster time scale
- Tab: cycle creation material
- Escape: clear selection
- R: reset camera

The whole app is in `index.html`.
