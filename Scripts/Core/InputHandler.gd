extends Node3D

@export var grid_manager: GridManager
@export var flow_controller: FlowController
@export var camera: Camera3D
@export var drop_indicator_material: Material  # Material for the drop indicator

var selected_coord = null
var is_dragging = false
var dragged_piece_data = null
var drop_indicator = null  # Visual indicator for drop location

func _ready():
	create_drop_indicator()

func create_drop_indicator():
	# Create a container for the square border
	drop_indicator = Node3D.new()
	drop_indicator.visible = false
	add_child(drop_indicator)
	
	# Border parameters
	var border_thickness = 0.05
	var border_height = 0.01
	var square_size = 1.0

	# TODO: make the border not cast shadows
	
	# Create four edges of the square border
	var edges = [
		# Top edge (X direction)
		{"pos": Vector3(0, 0, square_size/2), "size": Vector3(square_size, border_height, border_thickness)},
		# Bottom edge (X direction)
		{"pos": Vector3(0, 0, -square_size/2), "size": Vector3(square_size, border_height, border_thickness)},
		# Right edge (Z direction)
		{"pos": Vector3(square_size/2, 0, 0), "size": Vector3(border_thickness, border_height, square_size)},
		# Left edge (Z direction)
		{"pos": Vector3(-square_size/2, 0, 0), "size": Vector3(border_thickness, border_height, square_size)}
	]
	
	for edge in edges:
		var box_mesh = BoxMesh.new()
		box_mesh.size = edge.size
		
		var mesh_instance = MeshInstance3D.new()
		mesh_instance.mesh = box_mesh
		mesh_instance.position = edge.pos
		
		if drop_indicator_material:
			mesh_instance.material_override = drop_indicator_material
		
		drop_indicator.add_child(mesh_instance)

func _exit_tree():
	if drop_indicator:
		drop_indicator.queue_free()

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				attempt_pick_up()
			else:
				attempt_drop()

	if event is InputEventMouseMotion and is_dragging:
		handle_drag()

func attempt_pick_up():
	var ray_result = shoot_ray()
	if ray_result:
		var world_pos = ray_result.position
		var coord = grid_manager.world_to_grid(world_pos)
		if grid_manager.is_occupied(coord):
			var piece_data = grid_manager.grid[coord]["data"]
			
			# Only pick up movable pieces
			if not piece_data.is_movable:
				return
			
			# Don't pick up pieces that have something on top
			var above_coord = coord + Vector3i(0, 1, 0)
			if grid_manager.is_occupied(above_coord):
				return
			
			selected_coord = coord
			is_dragging = true
			
			# Store piece data and remove from grid while dragging
			dragged_piece_data = grid_manager.grid[coord]
			grid_manager.grid.erase(coord)
			
			# Visual feedback: Lift piece slightly
			dragged_piece_data["node"].position.y += 0.5
			
			# Show drop indicator
			# drop_indicator.visible = true

func attempt_drop():
	if not is_dragging: return
	
	var ray_result = shoot_ray()
	if ray_result:
		var target_coord = grid_manager.world_to_grid(ray_result.position)
		
		# If target is empty, place. If occupied, find the top of the stack.
		if not grid_manager.is_occupied(target_coord):
			# Place piece at new location
			dragged_piece_data["node"].position = grid_manager.grid_to_world(target_coord)
			grid_manager.grid[target_coord] = dragged_piece_data
			print("placed at:", target_coord)
		else:
			# Find the highest occupied position at this X,Z coordinate
			var highest_y = -1
			for coord in grid_manager.grid.keys():
				if coord.x == target_coord.x and coord.z == target_coord.z:
					if coord.y > highest_y:
						highest_y = coord.y
			
			# Place piece on top of the stack
			var top_coord = Vector3i(target_coord.x, highest_y + 1, target_coord.z)
			dragged_piece_data["node"].position = grid_manager.grid_to_world(top_coord)
			grid_manager.grid[top_coord] = dragged_piece_data
			print("placed on top at:", top_coord)
	
	# Hide drop indicator
	drop_indicator.visible = false
	
	is_dragging = false
	selected_coord = null
	dragged_piece_data = null
	
	# Recalculate flow whenever a piece is moved
	# TODO: add a way to change the flow source
	flow_controller.calculate_flow(Vector3i(0,1,0), Vector3i.DOWN)

func handle_drag():
	var ray_result = shoot_ray()
	if ray_result:
		# Hover effect: move the visual node to follow mouse (snapped to grid)
		# var hover_coord = grid_manager.world_to_grid(ray_result.position)
		# var target_pos = grid_manager.grid_to_world(hover_coord)

		# TODO: make the hover effect smoothly animated

		var target_pos = ray_result.position
		target_pos.y += 0.5 # Keep it "floating" while dragging
		dragged_piece_data["node"].position = target_pos
		
		# Update drop indicator position
		# update_drop_indicator(hover_coord)

func update_drop_indicator(grid_coord: Vector3i):
	# Find the actual drop position (accounting for stacking)
	var drop_coord = grid_coord
	
	# Find the highest occupied position at this X,Z coordinate
	var highest_y = -1
	for coord in grid_manager.grid.keys():
		if coord.x == grid_coord.x and coord.z == grid_coord.z:
			if coord.y > highest_y:
				highest_y = coord.y
	
	# Position the indicator at the top of the stack
	var indicator_pos = grid_manager.grid_to_world(drop_coord)
	if highest_y >= 0:
		indicator_pos.y += 0.01 + highest_y * 0.5
	else:
		indicator_pos.y += 0.01
	
	drop_indicator.position = indicator_pos

func shoot_ray():
	var mouse_pos = get_viewport().get_mouse_position()
	var from = camera.project_ray_origin(mouse_pos)
	var to = from + camera.project_ray_normal(mouse_pos) * 100
	
	var query = PhysicsRayQueryParameters3D.create(from, to)
	
	# If we are NOT dragging, look for Pieces (Layer 1)
	if not is_dragging:
		query.collision_mask = 1 
	else:
		query.collision_mask = 2
		# Exclude the currently dragged piece to prevent self-collision
		if dragged_piece_data:
			query.exclude = [dragged_piece_data["node"]]
		
	var space_state = get_world_3d().direct_space_state
	var result = space_state.intersect_ray(query)
	
	# When dragging and we hit something, ensure proper grid alignment
	if is_dragging and result:
		var grid_coord = grid_manager.world_to_grid(result.position)
		
		# Find the highest occupied position at this X,Z coordinate
		var highest_y = -1
		for coord in grid_manager.grid.keys():
			if coord.x == grid_coord.x and coord.z == grid_coord.z:
				if coord.y > highest_y:
					highest_y = coord.y
		
		# Position the result at the top of the stack
		if highest_y >= 0:
			result.position.y += 0.5 + highest_y * 0.5
	
	return result
