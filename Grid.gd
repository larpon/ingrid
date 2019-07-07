extends ColorRect

var debug:= false
# The cells that make up the grid. We use a 1d array structure
# to avoid having to keep track of cell movement in the grid
# and rely on sorting algorithms and index tracking instead.
var _cells: Array = []
var _buffer: Array = []

var rows: int = 0
var cols: int = 0

var resolution:Vector2 = Vector2(1,1)

# Default cell size w,h
var cell_size: Vector2 = OS.window_size * Vector2(0.5,0.5)
var fill_on_resize: bool = true

var __cell_delegate: PackedScene = preload("./Cell.tscn")
# The scene that will be instanced per cell in the grid
# A cell delegate should always derrive from Node2D
# and have members: xy:Vector2
var delegate: String = "./Cell.tscn"

# Current amount of cells spawning
var _cells_spawning: int = 0
# Offset coordinates for centering the grid in the viewport
var _offset: Vector2 = Vector2(0,0)

signal initialized
signal moved(v)

func _id(): return "Grid"

func _ready():
	connect("resized",self,"_on_resize")
	if debug: print(_id()+"::_ready")

#func _process(delta): pass

func valid() -> bool:
	#print(_cells_spawning == 0, " ", _cells.size() > 0, " ", _cells.size() == rows*cols," (",_cells.size(),"==",rows*cols,")")
	return _cells_spawning == 0 and _cells.size() > 0 and _cells.size() == rows*cols

func init() -> void:
	_update_fills()
	_update_offset()
	
	var w = int($FillArea.rect_size.x)
	var h = int($FillArea.rect_size.y)
	
	clear()
	
	cols = ceil(w/cell_size.x)
	rows = ceil(h/cell_size.y)
	
	assert( cols * rows >= 4 )
	
	var cell_amount = cols * rows
	_cells.resize(cell_amount)
	_cells_spawning = cell_amount
	
	if debug: print(_id()+str("::init"),' spawn ',cols,'x',rows,'=',cell_amount, ' cells',' in a ',w,'x',h," rectangle",
	' cell size ',cell_size,' start pos ',$FillArea.rect_position," Viewport",self.rect_size)
	
	var res = ResourceLoader.load(delegate)
	for i in range(cell_amount):
		_on_cell_spawned(res.duplicate(),{})
		#g.spawn(delegate,funcref(self, "_on_cell_spawned"),{})

func _on_cell_spawned(res,info) -> void:
	if res == null: return
	
	var cell = res.instance()
	
	_cells_spawning -= 1
	#print(_id()+"::initializing"," ",_cells_spawning)
	
	if not is_instance_valid(self) or not g.is_valid(cell):
		print(_id()+"::initializing"," bad cell",cell," ",_cells_spawning)
		return
	
	# Add it to the grid
	add_child(cell)
	
	_cells[_cells_spawning] = cell
	if _cells_spawning == 0:
		arrange()
		if debug: print(_id()+str("::initialized"))
		emit_signal("initialized")
	#if debug: print(_id()+str('::_on_cell_spawned'),' ','grid size ',len(grid))

# Arrange cells from top-left to bottom-right, column major
func arrange() -> void:
	if debug: print(_id()+str("::arrange")," ",valid())
	_update_offset()
	var i: int = 0; var cell = null
	for x in range(0,cols):
		for y in range(0,rows):
			cell = _cells[i]
			cell.xy = Vector2( x, y ) * resolution
			cell.position = _offset + Vector2(x*cell_size.x,y*cell_size.y)
			cell.get_child(0).rect_size = Vector2(cell_size.x,cell_size.y)
			i += 1
	move(Vector2(0,0))

# Instantly go to this cell coordinate
func warp_to(xy:Vector2) -> void:
	if debug: print(_id()+"::warp_to"," ",xy)
	var _xy:Vector2 = Vector2(xy.x - floor(cols/2), xy.y - floor(rows/2) )
	
	_cells.sort_custom(self, "_sort_by_position_y")
	
	var xmod = 0; var ymod = -1
	var cell; var center
	for i in range(0, _cells.size()):
		if i % cols == 0:
			xmod = 0
			ymod += 1
		cell = _cells[i]
		cell.xy = Vector2( _xy.x + xmod, _xy.y + ymod ) * resolution
		
		if cell.xy == xy:
			center = cell
		xmod += 1

	# Center in view
	var c_pos = center.position
	if debug: print(c_pos)
	var x = (-c_pos.x if c_pos.x > 0 else c_pos.x) #+ (rect_size.x*0.5) - (cell_size.x*0.5)
	var y = (c_pos.y if c_pos.y < 0 else -c_pos.y) #+ (rect_size.y*0.5) - (cell_size.y*0.5)
	
	if cell_size.x > rect_size.x: x = x * -1
	if cell_size.y > rect_size.y: y = y * -1
	
	x = x + (rect_size.x*0.5) - (cell_size.x*0.5)
	y = y + (rect_size.y*0.5) - (cell_size.y*0.5)
	
	move( Vector2( x, y ) )

# Move all cells relativly by 'v'
func move(v : Vector2) -> void:
	if not valid(): return
	#if debug: print(_id()+str('::move'),' ','moving ',rows*cols,' cells relatively ',x,',',y)
	var cell;
	var nx: float; var ny: float
	var swapped: bool = false
	
	var limit_tl: Vector2 = $BoundsArea.rect_position
	var limit_br: Vector2 = Vector2(limit_tl.x+$BoundsArea.rect_size.x-cell_size.x, limit_tl.y+$BoundsArea.rect_size.y-cell_size.y)
	
	var swap: Vector2
	for cell in _cells:
		if cell != null:
			# Check if new position will be outside of bounding box
			nx = cell.position.x + v.x
			ny = cell.position.y + v.y
			
			swap = Vector2(cell.xy.x,cell.xy.y)
			if nx < limit_tl.x:
				cell.position.x = cell.position.x + (cols*cell_size.x)
				swap.x += cols* resolution.x
			if ny < limit_tl.y:
				cell.position.y = cell.position.y + (rows*cell_size.y)
				swap.y += rows* resolution.y
			if nx > limit_br.x:
				cell.position.x = cell.position.x - (cols*cell_size.x)
				swap.x -= cols* resolution.x
			if ny > limit_br.y:
				cell.position.y = cell.position.y - (rows*cell_size.y)
				swap.y -= rows* resolution.y
				
			cell.position += v
			cell.xy = swap
	emit_signal("moved",v)

# Get cell at viewport x,y coordinate
func cell(xy:Vector2):
	var vp = self.rect_size
	
	if xy.x < 0 or xy.x > vp.x: return null
	if xy.y < 0 or xy.y > vp.y: return null
	
	for cell in _cells:
		if cell != null:
			if (xy.x >= cell.position.x and xy.x <= cell.position.x+cell_size.x) and (xy.y >= cell.position.y and xy.y <= cell.position.y+cell_size.y):
				return cell
	return null

# Will ensure that the grid's viewport is filled with cells
func auto_cell() -> void:
	if not valid(): return
	
	_update_fills()
	_update_offset()
	
	var w: int = int($FillArea.rect_size.x)
	var h: int = int($FillArea.rect_size.y)
	
	var _cols: int = ceil(w/cell_size.x)
	var _rows: int = ceil(h/cell_size.y)
	
	var cell_amount: int = _rows * _cols - rows * cols
	
	var col_amount: int = _cols - cols
	var row_amount: int = _rows - rows
	
	#if debug: print(_id()+str("::fix"),' spawn ',_cols,'x',_rows,'=',cell_amount, ' cells',' in ',row_amount,' rows and ',col_amount," columns",
	#' in a ',w,'x',h," rectangle",
	#' cell size ',cell_size,' start pos ',$FillArea.rect_position," Viewport",self.rect_size)
	
	if abs(cell_amount) > 0:
		var cell; var res
		_cells.sort_custom(self, "_sort_by_position_y")
		var tl = _cells[0]
		_cells_spawning = cell_amount
		
		if cell_amount > 0:
			res = ResourceLoader.load(delegate)
		
		# TODO bug on removing more than 1
		if col_amount < 0:
			for j in range(0,abs(col_amount)):
				var index: int = 0; var ei:int = 0
				for i in range(0,rows):
					index = ((i+1) * cols)-1+ei
					cell = _cells[index]
					cell.free()
					_cells[index] = null
					
					_cells.remove(index)
					ei -= 1
					
					_cells_spawning += 1
				cols -= 1

		if col_amount > 0:
			for j in range(0,col_amount):
				for i in range(0,rows):
					cell = res.duplicate().instance()
					_cells_spawning -= 1
					
					add_child(cell)
					
					cell.xy = Vector2( tl.xy.x + cols, tl.xy.y + i ) * resolution
					
					cell.position = Vector2(tl.position.x+(cols*cell_size.x),tl.position.y+(i*cell_size.y))
					cell.get_child(0).rect_size = Vector2(cell_size.x,cell_size.y)
					_cells.push_back(cell)
				cols += 1

		if row_amount < 0:
			for i in range(0,cols*abs(row_amount)):
				cell = _cells.pop_back()
				cell.free()
				_cells_spawning += 1
			rows += row_amount
		
		if row_amount > 0:
			for j in range(0,row_amount):
				for i in range(0,cols):
					cell = res.duplicate().instance()
					_cells_spawning -= 1
					
					add_child(cell)
					
					cell.xy = Vector2( tl.xy.x + i , tl.xy.y + rows ) * resolution
					
					cell.position = Vector2(tl.position.x+(i*cell_size.x),tl.position.y+(rows*cell_size.y))
					cell.get_child(0).rect_size = Vector2(cell_size.x,cell_size.y)
					_cells.push_back(cell)
				rows += 1
		
		_cells.sort_custom(self, "_sort_by_position_y")
		
		_update_fills()
		_update_offset()
		
		#if debug: print(_id()+str("::fix"),' layout ',_cols,'x',_rows,'=',cell_amount, ' cells',
		#' in ',row_amount,' rows and ',col_amount," columns",
		#' in a ',w,'x',h," rectangle")
		
		assert( rows * cols >= 4 )

func _on_resize() -> void:
	if debug: print(_id(),"Resize")
	auto_cell()
	
#func _notification(what):
#	if what == NOTIFICATION_PREDELETE:
#		if debug: print(_id(),' ','freeing all cells')
#		for s in grid:
#			s.free()

#func _on_cell_dying(cell):
	#pass
	#if debug: print('cell ',cell._id(),' ','dying',len(grid))
	
func clear() -> void:
	if debug: print(_id()+str('::clear'))
	g.clear_spawns()
	var cell
	for cell in _cells:
		if cell != null:
			cell.free()
	_cells.clear()
	rows = 0
	cols = 0
	_cells_spawning = 0
	
func clear_buffer() -> void:
	if debug: print(_id()+str('::clear_buffer'))
	var cell
	for cell in _buffer:
		if cell != null:
			cell.free()
	_buffer.clear()

func _update_fills():
	var fill_box: Vector2 = Vector2(cell_size.x * 3, cell_size.y * 3)
	var bounds_box: Vector2 = Vector2((fill_box.x+cell_size.x)*1.0,(fill_box.y+cell_size.y)*1.0)
	
	var rect: Rect2 = Rect2(rect_position,rect_size)
	var fill_area = rect.grow_individual(fill_box.x,fill_box.y,fill_box.x,fill_box.y)
	var bounds_area = rect.grow_individual(bounds_box.x,bounds_box.y,bounds_box.x,bounds_box.y)
	
	$FillArea.rect_position = fill_area.position
	$FillArea.rect_size = fill_area.size
	
	$BoundsArea.rect_position = bounds_area.position
	$BoundsArea.rect_size = bounds_area.size

func _update_offset() -> void:
	_offset.x = -(((rows*cell_size.x)-(rect_size.x))/2)
	_offset.y = -(((cols*cell_size.y)-(rect_size.y))/2)

static func _sort_by_position_y(a, b) -> bool:
	#var resy = a.position.y - b.position.y
	#var resx = a.position.x - b.position.x
	#if debug: print(a.position.y, " - ",b.position.y," = ",res)
	if a.position.y == b.position.y: return a.position.x < b.position.x
	return a.position.y < b.position.y

static func _sort_by_position_x(a, b) -> bool:
	if a.position.x == b.position.x: return a.position.y - b.position.y
	return a.position.x - b.position.x
