# Infinity Grid (InGrid)
An infinite scrolling grid for the [Godot](https://godotengine.org) game engine (3.x).

## Features

* Infinite scrolling
* Custom grid cell units (as many bits available as each coordinate in a Vector2 can hold)
* Lightweight and fairly optimized GDScript code

## Important

**How Stuff Works™**
In order for the grid to be "infinite" the movement model of the grid is like that of a `KinematicBody2D`.
You move the grid relativly to it's current position.

Each cell's `xy: Vector2` property combined with some clever position swapping is what allow the grid to continue to scroll
to the end of the universe (given you have enough time on your hands).

When a grid cell leave the viewport it's `position` and `xy` value will be swapped to match the next cell's values in the grid
thus allowing for a illusion of infinity if the cell's content changes based on these values.

## Install

Simply clone this repository into your project's `addons` folder.

```bash
cd "<path/to/project/root>"
mkdir -p "addons"
cd addons
git clone git@github.com:Larpon/ingrid.git
```

## Usage

Use `Grid2D` as a base for any grid (you can also derrive from it).
Adding multiple grids is supported although performance will depend on various factors
such as the cell size of each grid, viewport size etc.

The grid will work out of the box but you won't see much unless you do a few things first.

To initialize the grid with custom values
```gdscript
func _ready():
    $Grid2D.cell_size = Vector2(256,256)
    $Grid2D.delegate = "res://<path/to/custom/MyCustomCell.tscn>"
    $Grid2D.connect("initialized",self,"_on_grid_initialized")
    $Grid2D.init()

func _on_grid_initialized():
    $Grid2D.warp(Vector2(0,0))
```

Move the grid
```gdscript
func _process(delta):
    # Moves the grid one pixel right, relative to it's current position
    $Grid2D.move(Vector2(1,0))
```

Delegates
```gdscript
func _ready():
    ...
    $Grid2D.delegate = "res://<path/to/custom/Cell.tscn>"
    ...
```
To make the grid seem infinite you'll want to derrive from the supplied `Cell` type
and change the cell Node's contents based on the values of the `xy` property.

## Known issues
There's currently a few known issues you need to consider before deciding to use this.

* Rigid bodies (`RigidBody2D`) doesn't work well inside grid cells with the grid's relative movement model.
  So you must be creative if you want to use `RigidBody2D` types within grid cells.
* Grid auto cell filling when resizing is b0rked when more than one row or column need to be added/removed in one call.
* Only access grid functions from the same thread (Calling from multiple threads wil result in wrong coordinates).
  So don't initialize in `_ready` while moving in `_physics_process`. Lock access with a mutex if you try to do so.
