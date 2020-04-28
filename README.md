# Infinity Grid (InGrid)
An infinite scrolling grid for the [Godot](https://godotengine.org) game engine (3.x).

A solid component - excellent for things like:
* 2D procedural universes and worlds
* Variated parallax scrolling
* Inifinite runners/jumpers/fallers
* &lt;insert your fantastic infinite grid abuse here&gt;

![Example usage](https://user-images.githubusercontent.com/768942/62859170-a656d600-bcfc-11e9-9a1d-7244c8c367d2.gif)

## Features

* Infinite scrolling!
* Simple. Only 2 components, simple concept
* Custom grid cell units (as many bits available as each coordinate in a Vector2 can hold)
* Lightweight
* Fairly optimized GDScript code

## Important

**How Stuff Works™**
In order for the grid to be "infinite" the movement model of the grid is like that of a `KinematicBody2D`.
You move the grid relativly to it's current position.

Each cell's `xy: Vector2` property combined with some clever position swapping is what allow the grid to continue to scroll
to the end of the universe and beyond (given you have enough time on your hands).

When a grid cell leave the viewport, it's `position` and `xy` value will be swapped to match the next cell's values in the grid
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

The grid will work out of the box, with sane defaults, but you won't see much unless you do a few things first.

**Initialize**
To initialize the grid with (optional) custom values
```gdscript
func _ready():
    # Optional
    $Grid2D.cell_size = Vector2(256,256)
    $Grid2D.delegate = "res://<path/to/custom/MyCustomCell.tscn>"
    $Grid2D.units = Vector2(1,1)
    $Grid2D.connect("initialized",self,"_on_grid_initialized")

    # Mandatory
    $Grid2D.init()

func _on_grid_initialized():
    $Grid2D.warp(Vector2(0,0))
```

**Move the grid**
```gdscript
func _process(delta):
    # Moves the grid one pixel right, relative to it's current position
    $Grid2D.move(Vector2(1,0))
```

**Cell delegates**
```gdscript
func _ready():
    ...
    $Grid2D.delegate = "res://<path/to/custom/Cell.tscn>"
    ...
```
To make the grid seem infinite you'll want to derrive from the supplied `Cell` type
and change the cell Node's contents based on the values of the `xy` property.

**Cell units**
```gdscript
func _ready():
    ...
    $Grid2D.units = Vector2(1,1)
    ...
```
Cell units can be any `Vector2` based value set you want. The most common (and default!) value is probably `Vector2(1,1)`.
Units are arbitrary and solely used to distinguish each cell from it's neighbours in the grid.

Here's a few examples:
```gdscript
# Every cell.xy increases by 0.5 on each axis on each cell swap
$Grid2D.units = Vector2(0.5,0.5)

# Every cell.xy increases by 10 on each axis on each cell swap
$Grid2D.units = Vector2(10,10)
```
What units you choose to act on is your choice - and your choice alone

## Known issues
There's currently a few known issues you need to consider before deciding to use this.

* Rigid bodies (`RigidBody2D`) doesn't work well inside grid cells with the grid's relative movement model.
  So you must be creative if you want to use `RigidBody2D` types within grid cells.
* Grid auto cell filling when resizing is b0rked when more than one row or column need to be added/removed in one call.
* Only access grid functions from the same thread (Calling from multiple threads will result in wrong coordinates).
  So don't initialize in `_ready` while moving in `_physics_process`. Lock access with a mutex if you try to do so.

## Support my work
[![ko-fi](https://www.ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/larpon)

## Webring
Check out my games and other indie dev stuff
* [non - The First Warp](https://blackgrain.dk/games/non/) (2.5D point-and-click adventure with a genre-first fluid time warp mechanic)
* [Dead Ascend](https://blackgrain.itch.io/dead-ascend) (2D point-and-click-like adventure)
* [Hammer Bees](https://blackgrain.itch.io/hammer-bees) (2D top-down action puzzler)
