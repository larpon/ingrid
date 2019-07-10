extends "./Cell.gd"

var debug := true

func _id(): return str(xy)

func _ready():
	if not is_instance_valid(self): return
	
	if debug:
		var label = get_node('ColorRect/Label')
		var color_rect = get_node('ColorRect')
		if not is_instance_valid(label) or not is_instance_valid(color_rect): return
		
		label.set_text(_id())
		color_rect.color = Color(rand_range(0.0,1.0),rand_range(0.0,1.0),rand_range(0.0,1.0),0.5)
	$ColorRect.rect_size = Vector2(grid.cell_size.x,grid.cell_size.y)

func _process(delta):
	if debug: get_node('ColorRect/Label').set_text(_id())

#func _notification(what):
#	if what == NOTIFICATION_PREDELETE:
#		print("Cell",_id(),' ',self,'dying')

