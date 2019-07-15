# Infinity Grid (InGrid)
An (almost) infinite scrolling grid for the [Godot](https://godotengine.org) game engine.

## Features

* Infinite scrolling
* Custom grid cell units
* Lightweight and fairly optimized GDScript code
* Debug node types included for easy visualization

## Known issues
There' currently a few known issues you need to consider
before use.

* Rigid bodies (`RigidBody2D`) doesn't work well with the grid's relative movement model.
* Grid auto cell filling when resizing is b0rked when more than one row or column need to be added/removed in one call.
* Only access grid functions from the same thread (Calling from multiple threads wil result in wrong coordinates).
  So don't initialize in `_ready` while moving in `_physics_process`. Lock access with a mutex if you try to do so.
