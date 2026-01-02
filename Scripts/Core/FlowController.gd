class_name FlowController
extends Node

@export var grid_manager: GridManager
@export var MAX_DEPTH: int = -1 # How far water can fall below y=0

# A queue of animation steps
# Each step is a Dictionary: { "type": "pipe" or "fall", "coord": ..., "from": ..., "to": ... }
var animation_queue: Array = []
var is_animating = false

func calculate_flow(start_coord: Vector3i, start_direction: Vector3i):
	# 1. Stop any current animations
	if is_animating:
		# Ideally we would kill active tweens here, 
		# but for now let's just clear the queue
		animation_queue.clear()
		clear_existing_water()
	
	# 2. Build the new path instantly (Logic)
	animation_queue.clear()
	var visited = []
	_build_path_recursive(start_coord, start_direction, visited)
	
	# 3. Play the path (Visuals)
	_play_animations()

func _build_path_recursive(current_coord: Vector3i, entry_direction: Vector3i, visited: Array):
	if current_coord in visited or current_coord.y < MAX_DEPTH: return
	visited.append(current_coord)

	var piece = grid_manager.get_piece_data(current_coord)
	
	# FALLING LOGIC
	if piece == null:
		# Record a "Fall" event
		animation_queue.append({
			"type": "fall",
			"coord": current_coord,
			"from": entry_direction
		})
		_build_path_recursive(current_coord + Vector3i.DOWN, Vector3i.DOWN, visited)
		return

	# PIECE LOGIC
	var side_entered = -entry_direction 
	var valid_exits = []
	
	# Handle Top Entry (Split)
	if side_entered == Vector3i.UP:
		for dir in piece.flow_map.keys():
			if dir != Vector3i.UP: valid_exits.append(dir)
	# Handle Side Entry
	elif piece.flow_map.has(side_entered):
		valid_exits = piece.flow_map[side_entered]
	else:
		return # Blocked

	# Record "Pipe Flow" event
	animation_queue.append({
		"type": "pipe",
		"coord": current_coord,
		"from": entry_direction,
		"to": valid_exits
	})

	for exit in valid_exits:
		_build_path_recursive(current_coord + exit, exit, visited)

func _play_animations():
	is_animating = true
	
	for step in animation_queue:
		if step["type"] == "pipe":
			var node = grid_manager.grid[step["coord"]]["node"]
			if node.has_method("animate_fill"):
				# Wait for this piece to finish filling before moving to next
				var tween = node.animate_fill(step["from"], step["to"])
				if tween: await tween.finished
		
		elif step["type"] == "fall":
			# Spawn a temporary falling water mesh
			await _animate_fall(step["coord"])
			
	is_animating = false

func _animate_fall(coord: Vector3i):
	# Create a simple cylinder to represent falling water
	var mesh = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = 0.2
	cyl.bottom_radius = 0.2
	cyl.height = 1.0
	
	# Use same blue material
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.0, 0.6, 1.0)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh.material_override = mat
	mesh.mesh = cyl
	
	add_child(mesh)
	
	# Position at center of the empty cell
	mesh.position = grid_manager.grid_to_world(coord)
	
	# Animate Scale Y from 0 to 1 (Top down)
	# Cylinder pivot is center, so we need to offset position while scaling
	mesh.scale.y = 0
	mesh.position.y += 0.5 # Start at top
	
	var tween = create_tween()
	tween.tween_property(mesh, "scale:y", 1.0, 0.2)
	tween.parallel().tween_property(mesh, "position:y", mesh.position.y - 0.5, 0.2)
	
	await tween.finished
	# Note: We don't delete the mesh immediately so the path stays visible!
	# You'll need a way to clear these meshes when recalculating.

func clear_existing_water():
	# 1. Clear pipe water
	for coord in grid_manager.grid:
		grid_manager.grid[coord]["node"].reset_water()
	
	# 2. Delete falling water meshes (Need to track them in an array)
	# (Add a 'falling_meshes' array to FlowController, iterate and queue_free them here)
