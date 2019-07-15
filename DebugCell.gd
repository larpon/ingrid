extends "./Cell.gd"

var debug := true

func _id(): return str(xy)

func _ready():
	if not is_instance_valid(self): return
	
	connect("xy_changed",self,"_on_xy_changedd")
	
	if debug and grid.visible:
		var label = get_node('Debug/Label')
		var color_rect = get_node('Debug')
		if not is_instance_valid(label) or not is_instance_valid(color_rect): return
		
		label.set_text(_id())
		color_rect.color = Color(rand_range(0.0,1.0),rand_range(0.0,1.0),rand_range(0.0,1.0),0.3)
		$Debug.rect_size = Vector2(grid.cell_size.x,grid.cell_size.y)

func _process(delta):
	if debug and grid.visible:
		get_node('Debug/Label').set_text(_id())

#func _notification(what):
#	if what == NOTIFICATION_PREDELETE:
#		print("Cell",_id(),' ',self,'dying')

func _on_xy_changedd(new_xy,old_xy):
	if debug and grid.visible:
		pass#print('Cell swapped',old_xy,' -> ',new_xy)
