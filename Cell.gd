extends Node2D

var xy := Vector2(0,0) setget set_xy

signal xy_changed(new, old)

onready var grid := get_parent()

func set_xy(new_xy):
	if xy.x != new_xy.x or xy.y != new_xy.y:
		var _xy = Vector2( xy.x, xy.y )
		xy = new_xy
		emit_signal("xy_changed",xy,_xy)
