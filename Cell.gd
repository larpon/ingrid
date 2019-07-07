extends Node2D

var xy := Vector2(0,0) setget set_xy

signal swapped()
signal xy_changed(new, old)

func set_xy(new_xy):
	if xy != new_xy:
		var _xy = Vector2( xy.x, xy.y )
		xy = new_xy
		emit_signal("xy_changed",xy,_xy)
