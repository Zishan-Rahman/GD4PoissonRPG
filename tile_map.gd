extends TileMap

var cell_points: Array[Vector2]
@export var point_radius: float = 1.0
@export var region_size: Vector2 = Vector2.ONE
@export var rejection_samples: int = 30

var x_tile_range: int = ProjectSettings.get_setting("display/window/size/viewport_width") / tile_set.tile_size.x
var y_tile_range: int = ProjectSettings.get_setting("display/window/size/viewport_height") / tile_set.tile_size.y

# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	var start_time: float = Time.get_ticks_msec()
	cell_points = generate_points(point_radius, region_size, rejection_samples)
	var new_time: float = Time.get_ticks_msec() - start_time
	print("Time taken: " + str(new_time) + "ms")

func generate_points(radius: float, sample_region_size: Vector2, number_of_samples_before_rejection: int = 30) -> Array[Vector2]:
	var cell_size: float = radius / sqrt(2)
	var grid: Array[Array] = []
	var points: Array[Vector2] = []
	var spawn_points: Array[Vector2] = []
	
	spawn_points.append(sample_region_size/2)
	
	while spawn_points.size() > 0:
		var spawn_index: int = randi_range(0, spawn_points.size() - 1)
		var spawn_centre: Vector2 = spawn_points[spawn_index]
		var candidate_accepted: bool = false
		
		for i in range(number_of_samples_before_rejection):
			var angle: float = randf_range(0.0, 1.0) * TAU # TAU = PI * 2
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
				var point_index: int = grid[x][y]
				if point_index != -1:
					var distance: float = (candidate - points[point_index]).length()
					if distance < radius:
						return false
		return true
	return false
