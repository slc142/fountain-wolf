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
	
	# Apply visual effects for non-movable pieces
	if not piece_data.is_movable:
		apply_dull_effect(new_node)
	
	# Initialize the visuals
	# Assuming the script is on the root node of the scene
	if new_node.has_method("initialize"):
		new_node.initialize(piece_data)
		
	grid[coord] = { "data": piece_data, "node": new_node }

func apply_dull_effect(node: Node3D):
	# Apply dulling effect to make piece appear non-interactive
	# Create unique material copies to avoid affecting shared materials
	for child in node.get_children():
		if child is MeshInstance3D:
			var original_material = child.get_active_material(0)
			if original_material != null and original_material is StandardMaterial3D:
				# Create a unique copy of the material
				var dull_material = original_material.duplicate()
				
				# Dull the color by reducing albedo and increasing roughness
				dull_material.albedo_color = dull_material.albedo_color.darkened(0.5)
				dull_material.roughness = min(dull_material.roughness + 0.3, 1.0)
				dull_material.metallic = max(dull_material.metallic - 0.2, 0.0)
				
				# Apply the unique dull material
				child.material_override = dull_material

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

func grid_to_world(coord: Vector3i) -> Vector3:
	return Vector3(coord.x, coord.y * 0.5, coord.z) * cell_size

# Convert World Position -> Grid Coordinate
func world_to_grid(pos: Vector3) -> Vector3i:
	var x = round(pos.x / cell_size)
	var y = max(round((pos.y / (cell_size * 0.5)) - 0.5), 0)
	var z = round(pos.z / cell_size)
	return Vector3i(x, y, z)

func clear_grid() -> void:
	for coord in grid.keys():
		remove_piece(coord)
	grid.clear()