extends ColorRect

# Public members

# Units or resolution of the cell coordinates
var units: Vector2 = Vector2(1,1)

# Default cell size w,h
var cell_size: Vector2 = OS.window_size * Vector2(0.5,0.5)
# Will keep cell fill rate when grid is resized
var auto_fit_cells: bool = true
# The scene that will be instanced per cell in the grid
# A cell delegate should always derrive from Node2D
# and have members: xy:Vector2
var delegate: String = "./Cell.tscn"

# Private members

# The cells that make up the grid. We use a 1d array structure
# to avoid having to keep track of cell movement in the grid
# and rely on sorting algorithms and index tracking instead.
var _cells: Array = []

var rows: int = 0
var cols: int = 0

# Current amount of cells spawning
var _cells_spawning: int = 0

# Offset coordinates for centering the grid in the viewport
var _offset: Vector2 = Vector2(0,0)

var _fill: Rect2 = Rect2(self.rect_position,self.rect_size)
var _bounds: Rect2 = Rect2(self.rect_position,self.rect_size)


# Signals

signal initialized
signal moved(v)

func _ready():
	preload("./Cell.tscn")
	connect("resized",self,"_on_resize")

# The grid is considered 'valid' if no cells are spawning, the amount of cells
# in the grid are more than 0 and equal to the total amount of cells needed
# to fill the grid
func valid() -> bool:
	return _cells_spawning == 0 and _cells.size() > 0 and _cells.size() == rows*cols

# (Re)initialize the grid with cells when called
func init() -> void:
	_update_fills()
	_update_offset()
	
	var w = int(_fill.size.x)
	var h = int(_fill.size.y)
	
	clear()
	
	cols = ceil(w/cell_size.x)
	rows = ceil(h/cell_size.y)
	
	assert( cols * rows >= 4 )
	
	var cell_amount = cols * rows
	_cells.resize(cell_amount)
	_cells_spawning = cell_amount
	
	#if debug: print("Grid2D::init"),' spawn ',cols,'x',rows,'=',cell_amount, ' cells',' in a ',w,'x',h," rectangle",
	#' cell size ',cell_size,' start pos ',$FillArea.rect_position," Viewport",self.rect_size)
	
	var res = ResourceLoader.load(delegate)
	for i in range(cell_amount):
		_on_cell_spawned(res.duplicate(),{})
	
func _on_cell_spawned(res,info) -> void:
	if res == null: return
	
	var cell = res.instance()
	
	_cells_spawning -= 1
	
	if not is_instance_valid(self) or not cell != null:
		print("Grid2D ERROR Bad cell ",cell," ",_cells_spawning)
		return
	
	# Add it to the grid
	add_child(cell)
	
	_cells[_cells_spawning] = cell
	if _cells_spawning == 0:
		arrange()
		emit_signal("initialized")

# Arrange cells from top-left to bottom-right, column major
# Expects all cells to be done spawning
func arrange() -> void:
	if not valid(): return
	
	_update_offset()
	var i: int = 0; var cell = null
	for x in range(0,cols):
		for y in range(0,rows):
			cell = _cells[i]
			cell.xy = Vector2( x, y ) * units
			cell.position = _offset + Vector2(x*cell_size.x,y*cell_size.y)
			i += 1
	#_sort_cells()
	move(Vector2(0,0))

# Instantly 'warp' to this cell coordinate
var __dbg_calls = 0
func warp(xy:Vector2) -> void:
	if not valid(): return
	
	var _xy:Vector2 = Vector2(xy.x - floor(cols/2), xy.y - floor(rows/2) )
	
	_sort_cells()
	
	var xmod = 0; var ymod = -1
	var cell; var center
	for i in range(0, _cells.size()):
		if i % cols == 0:
			xmod = 0; ymod += 1
		
		cell = _cells[i]
		cell.xy = Vector2( _xy.x + xmod, _xy.y + ymod ) * units
		
		if cell.xy == xy:
			center = cell
		xmod += 1

	# Center in grid
	var c_pos = center.position
	
	var x = (-c_pos.x if c_pos.x > 0 else c_pos.x)
	var y = (c_pos.y if c_pos.y < 0 else -c_pos.y)
	
	if cell_size.x > rect_size.x: x = x * -1
	if cell_size.y > rect_size.y: y = y * -1
	
	x = x + (rect_size.x*0.5) - (cell_size.x*0.5)
	y = y + (rect_size.y*0.5) - (cell_size.y*0.5)
	
	move( Vector2( x, y ) )

# Move all cells relativly by 'v'
func move(v : Vector2) -> void:
	
	if not valid(): return
	
	var cell;
	var nx: float; var ny: float
	
	var update := false
	
	var limit_tl: Vector2 = _bounds.position
	var limit_br: Vector2 = Vector2(limit_tl.x+_bounds.size.x-cell_size.x, limit_tl.y+_bounds.size.y-cell_size.y)
	
	var do_sort = false
	var swap: Vector2
	for cell in _cells:
		if cell != null:
			
			update = false
			
			# Check if new position will be outside of bounding box
			nx = cell.position.x + v.x
			ny = cell.position.y + v.y
			
			swap = Vector2(cell.xy.x,cell.xy.y)
			
			if nx < limit_tl.x:
				cell.position.x = cell.position.x + (cols * cell_size.x)
				swap.x = cell.xy.x + (cols * units.x)
				update = true
			elif ny < limit_tl.y:
				cell.position.y = cell.position.y + (rows * cell_size.y)
				swap.y = cell.xy.y + (rows * units.y)
				update = true
			elif nx > limit_br.x:
				cell.position.x = cell.position.x - (cols * cell_size.x)
				swap.x = cell.xy.x - (cols * units.x)
				update = true
			elif ny > limit_br.y:
				cell.position.y = cell.position.y - (rows * cell_size.y)
				swap.y = cell.xy.y - (rows * units.y)
				update = true
				
			cell.position += v
			if update:
				do_sort = true
				cell.xy = swap # <- This uses Cell.set_xy, which will emit the swap signal (xy_changed)
				update = false
	if do_sort:
		_sort_cells()
	emit_signal("moved",v)

# Get cell at viewport (self.rect) x,y coordinate
func cell(xy:Vector2):
	var vp = self.rect_size
	
	if xy.x < 0 or xy.x > vp.x: return null
	if xy.y < 0 or xy.y > vp.y: return null
	
	for cell in _cells:
		if cell != null:
			if (xy.x >= cell.position.x and xy.x <= cell.position.x+cell_size.x) and (xy.y >= cell.position.y and xy.y <= cell.position.y+cell_size.y):
				return cell
	return null

# Ensures that the grid's viewport is filled with cells
func _auto_fit_cells() -> void:
	if not valid(): return
	
	_update_fills()
	_update_offset()
	
	var w = int(_fill.size.x)
	var h = int(_fill.size.y)
	
	var __cols: int = ceil(w/cell_size.x)
	var __rows: int = ceil(h/cell_size.y)
	
	var cell_amount: int = __rows * __cols - rows * cols
	
	var col_amount: int = __cols - cols
	var row_amount: int = __rows - rows
	
	#if debug: print("Grid2D::_auto_fit_cells",' spawn ',__cols,'x',__rows,'=',cell_amount, ' cells',' in ',row_amount,' rows and ',col_amount," columns",
	#' in a ',w,'x',h," rectangle",
	#' cell size ',cell_size,' start pos ',$FillArea.rect_position," Viewport",self.rect_size)
	
	if abs(cell_amount) > 0:
		var cell; var res
		
		_sort_cells()
		
		var tl = _cells[0]
		_cells_spawning = cell_amount
		
		if cell_amount > 0:
			res = ResourceLoader.load(delegate)
			
		# TODO bug on removing more than 1 per call
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
					
					cell.xy = Vector2( tl.xy.x + cols, tl.xy.y + i ) * units
					
					cell.position = Vector2(tl.position.x+(cols*cell_size.x),tl.position.y+(i*cell_size.y))
					
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
					
					cell.xy = Vector2( tl.xy.x + i , tl.xy.y + rows ) * units
					cell.position = Vector2(tl.position.x+(i*cell_size.x),tl.position.y+(rows*cell_size.y))
					
					_cells.push_back(cell)
				rows += 1

		_sort_cells()
		
		_update_fills()
		_update_offset()
		
		#if debug: print("Grid2D::_auto_fit_cells",' layout ',__cols,'x',__rows,'=',cell_amount, ' cells',
		#' in ',row_amount,' rows and ',col_amount," columns",
		#' in a ',w,'x',h," rectangle")
		
		assert( rows * cols >= 4 )

func _on_resize() -> void:
	if auto_fit_cells: _auto_fit_cells()

func clear() -> void:
	var cell
	for cell in _cells:
		if cell != null:
			cell.free()
	_cells.clear()
	rows = 0
	cols = 0
	_cells_spawning = 0

"""
Utility functions
"""
func _update_fills():
	var fill_box: Vector2 = Vector2(cell_size.x * 3, cell_size.y * 3)
	var bounds_box: Vector2 = Vector2((fill_box.x+cell_size.x)*1.0,(fill_box.y+cell_size.y)*1.0)
	
	var rect: Rect2 = Rect2(rect_position,rect_size)
	var fill_area = rect.grow_individual(fill_box.x,fill_box.y,fill_box.x,fill_box.y)
	var bounds_area = rect.grow_individual(bounds_box.x,bounds_box.y,bounds_box.x,bounds_box.y)
	
	_fill.position = fill_area.position
	_fill.size = fill_area.size
	
	_bounds.position = bounds_area.position
	_bounds.size = bounds_area.size

func _update_offset() -> void:
	_offset.x = -(((rows*cell_size.x)-(rect_size.x))/2)
	_offset.y = -(((cols*cell_size.y)-(rect_size.y))/2)

static func _sort_by_position_y(a, b) -> bool:
	if a.position.y == b.position.y: return a.position.x < b.position.x
	return a.position.y < b.position.y

func _sort_cells():
	_cells.sort_custom(self, "_sort_by_position_y")
	
	#if visible:
	#	for cell in _cells:
	#		if cell != null:
	#			print(cell.position)
