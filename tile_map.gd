extends TileMap

var buildings: Array[Vector2i] = [
	Vector2i(0, 19),
	Vector2i(1, 19),
	Vector2i(2, 19),
	Vector2i(3, 19),
	Vector2i(4, 19),
	Vector2i(5, 19),
	Vector2i(6, 19),
	Vector2i(7, 19),
	Vector2i(8, 20),
	Vector2i(0, 20),
	Vector2i(1, 20),
	Vector2i(2, 20),
	Vector2i(3, 20),
	Vector2i(4, 20),
	Vector2i(5, 20),
	Vector2i(6, 20),
	Vector2i(7, 20),
	Vector2i(8, 20),
	Vector2i(0, 21),
	Vector2i(1, 21),
	Vector2i(2, 21),
	Vector2i(3, 21),
	Vector2i(4, 21),
	Vector2i(5, 21),
	Vector2i(6, 21),
	Vector2i(7, 21),
	Vector2i(8, 21)
]
var trees: Array[Vector2i] = [
	Vector2i(0,1),
	Vector2i(1,1),
	Vector2i(2,1),
	Vector2i(3,1),
	Vector2i(4,1),
	Vector2i(5,1),
	Vector2i(6,1),
	Vector2i(7,1),
	Vector2i(0,2),
	Vector2i(1,2),
	Vector2i(2,2),
	Vector2i(3,2),
	Vector2i(4,2)
]
const PLAYER_SPRITE: Vector2i = Vector2i(24, 7)
var player_placement_cell: Vector2i

var x_tile_range: int = ProjectSettings.get_setting("display/window/size/viewport_width") / tile_set.tile_size.x
var y_tile_range: int = ProjectSettings.get_setting("display/window/size/viewport_height") / tile_set.tile_size.y

var cell_points: Array[Vector2]
@export var point_radius: float = 1.0
@export var region_size: Vector2 = Vector2(x_tile_range, y_tile_range)
@export var rejection_samples: int = 30

# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	var start_time: float = Time.get_ticks_msec()
	cell_points = generate_points(point_radius, region_size, rejection_samples)
	var new_time: float = Time.get_ticks_msec() - start_time
	print("Time taken: " + str(new_time) + "ms")
	place_player()

func _get_player_placement_cell() -> Vector2i:
	return Vector2i(randi() % x_tile_range, randi() % y_tile_range)

func place_player():
	while get_used_cells(0).has(player_placement_cell):
		player_placement_cell = _get_player_placement_cell()
	set_cell(0, player_placement_cell, 0, PLAYER_SPRITE)

func _is_not_out_of_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < x_tile_range and cell.y >= 0 and cell.y < y_tile_range

func _physics_process(_delta):
	var previous_cell: Vector2i = player_placement_cell
	var direction: Vector2i = Vector2i.ZERO
	if Input.is_action_pressed("ui_up"): direction = Vector2i.UP
	elif Input.is_action_pressed("ui_down"): direction = Vector2i.DOWN
	elif Input.is_action_pressed("ui_left"): direction = Vector2i.LEFT
	elif Input.is_action_pressed("ui_right"): direction = Vector2i.RIGHT
	var new_placement_cell: Vector2i = player_placement_cell + direction
	if (not get_used_cells(0).has(new_placement_cell) or trees.has(get_cell_atlas_coords(0, new_placement_cell))) and _is_not_out_of_bounds(new_placement_cell):
		player_placement_cell = new_placement_cell
		set_cell(0, previous_cell, 0)
		set_cell(0, player_placement_cell, 0, PLAYER_SPRITE)

func generate_points(radius: float, sample_region_size: Vector2, number_of_samples_before_rejection: int = 30) -> Array[Vector2]:
	var cell_size: float = radius / sqrt(2)
	var grid: Array[Array] = []
	var points: Array[Vector2] = []
	var spawn_points: Array[Vector2] = []
	
	for i in range(ceili(sample_region_size.x/cell_size)):
		grid.append([])
		for j in range(ceili(sample_region_size.y/cell_size)):
			grid[i].append(0)
	
	spawn_points.append(sample_region_size/2)
	
	while spawn_points.size() > 0:
		var spawn_index: int = randi_range(0, spawn_points.size() - 1)
		var spawn_centre: Vector2 = spawn_points[spawn_index]
		var candidate_accepted: bool = false
		
		for i in range(number_of_samples_before_rejection):
			var angle: float = randf() * TAU # TAU = PI * 2
			var direction: Vector2 = Vector2(sin(angle), cos(angle))
			var candidate: Vector2 = spawn_centre + direction * randf_range(radius, 2 * radius)
			if is_valid(candidate, sample_region_size, cell_size, radius, points, grid):
				points.append(candidate)
				spawn_points.append(candidate)
				grid[int(candidate.x/cell_size)][int(candidate.y/cell_size)] = len(points)
				candidate_accepted = true
				break
		
		if not candidate_accepted:
			spawn_points.remove_at(spawn_index)
			
	return points

func is_valid(candidate: Vector2, sample_region_size: Vector2, cell_size: float, radius: float, points: Array[Vector2], grid: Array[Array]):
	if candidate.x >= 0 and candidate.x < sample_region_size.x and candidate.y >= 0 and candidate.y < sample_region_size.y:
		var cell_x: int = candidate.x / cell_size
		var cell_y: int = candidate.y / cell_size
		var search_start_x: int = max(0, cell_x - 2)
		var search_end_x: int = min(cell_x + 2, x_tile_range - 1)
		var search_start_y: int = max(0, cell_y - 2)
		var search_end_y: int = min(cell_y + 2, y_tile_range - 1)
		for x in range(search_start_x, search_end_x):
			for y in range(search_start_y, search_end_y):
				var point_index: int = grid[x][y] - 1
				if point_index != -1:
					var distance: float = (candidate - points[point_index]).length_squared()
					if distance < radius:
						return false
		return true
	return false
