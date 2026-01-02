class_name GridManager
extends Node3D

# The actual 3D Grid. 
# Key: Vector3i, Value: Dictionary { "data": PieceData, "node": Node3D }
var grid: Dictionary = {}

@export var cell_size: float = 1.0 # Distance between grid centers

func place_piece(coord: Vector3i, piece_data: PieceData) -> void:
	if is_occupied(coord): return
	
	var new_node = piece_data.model_scene.instantiate()
	add_child(new_node)
	new_node.position = grid_to_world(coord)
	new_node.rotation_degrees.y = piece_data.rotation_degrees
	
	# Initialize the visuals
	# Assuming the script is on the root node of the scene
	if new_node.has_method("initialize"):
		new_node.initialize(piece_data)
		
	grid[coord] = { "data": piece_data, "node": new_node }

func move_piece(from_coord: Vector3i, to_coord: Vector3i) -> void:
	if not grid.has(from_coord) or is_occupied(to_coord):
		return
	
	var piece_info = grid[from_coord]
	grid.erase(from_coord)
	grid[to_coord] = piece_info
	piece_info["node"].position = grid_to_world(to_coord)

func remove_piece(coord: Vector3i) -> void:
	if grid.has(coord):
		grid[coord]["node"].queue_free()
		grid.erase(coord)

func get_piece_data(coord: Vector3i) -> Dictionary:
	if grid.has(coord):
		return grid[coord]
	return {}

func is_occupied(coord: Vector3i) -> bool:
	return grid.has(coord)

# Convert Grid Coordinate (1, 2, 0) -> World Position (1.0, 2.0, 0.0)
func grid_to_world(coord: Vector3i) -> Vector3:
	return Vector3(coord.x, coord.y, coord.z) * cell_size

# Convert World Position -> Grid Coordinate
func world_to_grid(pos: Vector3) -> Vector3i:
	return Vector3i(round(pos.x / cell_size), round(pos.y / cell_size), round(pos.z / cell_size))
