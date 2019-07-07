extends Node2D

# Class member variables
# onready var g = get_node("/root/g")
var debug := false

var xy := Vector2(0,0) setget set_xy

signal dying(cell)
signal swapped()
signal xy_changed(new, old)

func _id(): return str(xy)

func _ready():
	if not is_instance_valid(self): return
	# Called when the node is added to the scene for the first time.
	# Initialization here
	
	if debug:
		var label = get_node('ColorRect/Label')
		var color_rect = get_node('ColorRect')
		if not is_instance_valid(label) or not is_instance_valid(color_rect): return
		
		label.set_text(_id())
		color_rect.color = Color(rand_range(0.0,1.0),rand_range(0.0,1.0),rand_range(0.0,1.0),0.5)

	#print("Cell",_id(),' ',self,'alive')

func _process(delta):
	if debug: get_node('ColorRect/Label').set_text(_id())

func _notification(what):
	if what == NOTIFICATION_PREDELETE:
		emit_signal("dying",self)
		#print("Cell",_id(),' ',self,'dying')

func set_xy(new_xy):
	if xy != new_xy:
		var _xy = Vector2( xy.x, xy.y )
		xy = new_xy
		#print("Cell",_id(),' ',_xy,'->',xy)
		emit_signal("xy_changed",xy,_xy)
		
