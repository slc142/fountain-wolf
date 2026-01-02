extends Node3D

@export var grid_manager: GridManager
@export var flow_controller: FlowController
@export var camera: Camera3D

var selected_coord = null
var is_dragging = false

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
			selected_coord = coord
			is_dragging = true
			# Visual feedback: Lift the piece slightly
			grid_manager.grid[selected_coord]["node"].position.y += 0.5

func attempt_drop():
	if not is_dragging: return
	
	var ray_result = shoot_ray()
	if ray_result:
		var target_coord = grid_manager.world_to_grid(ray_result.position)
		
		# If target is empty, move it. If occupied, return to original.
		if not grid_manager.is_occupied(target_coord):
			grid_manager.move_piece(selected_coord, target_coord)
		else:
			grid_manager.grid[selected_coord]["node"].position = grid_manager.grid_to_world(selected_coord)
	
	is_dragging = false
	selected_coord = null
	
	# Recalculate flow whenever a piece is moved
	# TODO: add a way to change the flow source
	flow_controller.calculate_flow(Vector3i(0,1,0), Vector3i.DOWN)

func handle_drag():
	var ray_result = shoot_ray()
	if ray_result:
		# Hover effect: move the visual node to follow mouse (snapped to grid)
		var hover_coord = grid_manager.world_to_grid(ray_result.position)
		var target_pos = grid_manager.grid_to_world(hover_coord)
		target_pos.y += 0.5 # Keep it "floating" while dragging
		grid_manager.grid[selected_coord]["node"].position = target_pos

func shoot_ray():
	var mouse_pos = get_viewport().get_mouse_position()
	var from = camera.project_ray_origin(mouse_pos)
	var to = from + camera.project_ray_normal(mouse_pos) * 100
	
	var query = PhysicsRayQueryParameters3D.create(from, to)
	
	# If we are NOT dragging, look for Pieces (Layer 1)
	if not is_dragging:
		query.collision_mask = 1 
	# If we ARE dragging, look for the Floor (Layer 2) to know where to move the piece
	else:
		query.collision_mask = 2 
		
	var space_state = get_world_3d().direct_space_state
	return space_state.intersect_ray(query)
