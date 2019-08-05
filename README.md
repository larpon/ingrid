# Infinity Grid (InGrid)
An infinite scrolling grid for the [Godot](https://godotengine.org) game engine (3.x).

## Features

* Infinite scrolling
* Custom grid cell units (as many bits available as each coordinate in a Vector2 can hold)
* Lightweight and fairly optimized GDScript code

## Known issues
There's currently a few known issues you need to consider before use.

* Rigid bodies (`RigidBody2D`) doesn't work well inside grid cells with the grid's relative movement model.
* Grid auto cell filling when resizing is b0rked when more than one row or column need to be added/removed in one call.
* Only access grid functions from the same thread (Calling from multiple threads wil result in wrong coordinates).
  So don't initialize in `_ready` while moving in `_physics_process`. Lock access with a mutex if you try to do so.
