# Infinity Grid (InGrid)
An (almost) infinite scrolling grid for the [Godot](https://godotengine.org) game engine.

## Features

* Infinite scrolling
* Custom grid cell units
* Lightweight and fairly optimized GDScript code
* Debug version included for easy visualization

## Known issues
There' currently a few known issues you need to consider
before use.

* Rigid bodies (`RigidBody2D`) doesn't work well with the grid's relative movement
* Grid auto cell fill when resizing is b0rked when more than one row or column need to be added/removed in one call
