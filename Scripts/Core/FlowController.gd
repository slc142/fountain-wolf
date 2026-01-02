class_name FlowController
extends Node

@export var grid_manager: GridManager
@export var MAX_DEPTH: int = 0
@export var water_path_manager: WaterPathManager

var branches: Array = [] # Array of Dictionaries: { "points": [], "delay": 0.0 }

func calculate_flow(start_coord: Vector3i, start_direction: Vector3i):
	water_path_manager.clear_paths()
	branches.clear()
	_trace_branch(start_coord, start_direction, [], 0.0)
	for b in branches:
		water_path_manager.create_flow_branch(b["points"], b["delay"])

# Recursive function to trace paths
func _trace_branch(current_coord: Vector3i, entry_dir: Vector3i, current_points: Array, accumulated_delay: float):
	
	# 1. Safety Check (Bounds & Loops)
	if current_coord.y < MAX_DEPTH: 
		print("Fell into the abyss at ", current_coord)
		branches.append({ "points": current_points.duplicate(), "delay": accumulated_delay })
		return

	# 2. Get the piece
	var piece_info = grid_manager.get_piece_data(current_coord) # Should return {data, node, rotation}
	
	# --- CASE A: FALLING (No Piece) ---
	if piece_info == {}:
		# Falling is a straight line downwards
		var start_pos = grid_manager.grid_to_world(current_coord) + Vector3(0, 0.5, 0)
		var end_pos = start_pos + Vector3(0, -1.0, 0) # Fall 1 unit
		
		# Add to current branch
		#if current_points.is_empty():
		current_points.append(start_pos)
		current_points.append(end_pos)
		
		print("Flow falling at ", current_coord)
		
		# Continue falling
		_trace_branch(current_coord + Vector3i.DOWN, Vector3i.DOWN, current_points, accumulated_delay)
		return
	
	var data = piece_info["data"]
	var node = piece_info["node"]
	
	# 1. Determine Local Directions
	# We must convert Global vectors to the Piece's Local space to ask for points
	# Then convert the result back to Global space to draw them.
	var piece_basis = node.global_transform.basis
	var local_entry = (piece_basis.inverse() * Vector3(entry_dir)).round() # Convert global -> local
	
	# We need Vector3i for dictionary/logic lookups
	var local_entry_i = Vector3i(local_entry)
	var local_side_entered = -local_entry_i # The side of the cube we entered
	
	# 2. Find Exits (In Local Space)
	var local_exits = []
		
	# --- CASE B: FLOWING THROUGH PIECE ---
	print("Water flowing through ", current_coord)
	
	if entry_dir == Vector3i.DOWN: # Water moving down means it entered from UP
		# If falling in, we look for ALL valid exits in the piece data
		for k in data.flow_map.keys():
			if k != Vector3i.UP: local_exits.append(k)

	# If entered from SIDE, get specific exits
	elif data.flow_map.has(local_side_entered):
		local_exits = data.flow_map[local_side_entered]
	else:
		print("Flow blocked at ", current_coord, " entering from ", local_side_entered)
		branches.append({ "points": current_points.duplicate(), "delay": accumulated_delay })
		return # Blocked
	
	# 3. Process Exits
	# If Split (size > 1), we finalize the current branch here
	if local_exits.size() > 1:
		# Important: Add the CENTER point to connect the fall to the split
		var center_pos = grid_manager.grid_to_world(current_coord)
		current_points.append(center_pos)
		
		branches.append({ "points": current_points.duplicate(), "delay": accumulated_delay })
		
		# Start new branches from the center
		for local_exit in local_exits:
			var global_exit = (piece_basis * Vector3(local_exit)).round() # Local -> Global
			var start_delay = accumulated_delay + (current_points.size() * 0.05)
			
			# Start new branch list with the Center Point
			var new_branch = [center_pos]
			
			# Get the path from Center -> Edge
			# Note: We pass UP as entry to signify "Start at Center"
			var local_path = data.get_local_points(Vector3i.UP, local_exit)
			var global_path = _transform_points(local_path, piece_basis, center_pos)
			
			# Append path (skipping first point if it duplicates center)
			if global_path.size() > 0 and global_path[0].distance_to(center_pos) < 0.01:
				global_path.remove_at(0)
			new_branch.append_array(global_path)
			
			# Recurse
			_trace_branch(current_coord + Vector3i(global_exit), Vector3i(global_exit), new_branch, start_delay)
	
	# 4. Handle Branching vs Continuation
	
	# If Single Path (Extension)
	elif local_exits.size() == 1:
		var local_exit = local_exits[0]
		var global_exit = (piece_basis * Vector3(local_exit)).round()
		
		# Get path from Entry Edge -> Exit Edge
		var local_path = data.get_local_points(local_side_entered, local_exit)
		var center_pos = grid_manager.grid_to_world(current_coord)
		var global_path = _transform_points(local_path, piece_basis, center_pos)
		
		# Connect: If the new path start doesn't match current end, add a bridge line?
		# Usually exact grid alignment makes this unnecessary, but let's be safe:
		if not current_points.is_empty():
			var last_pt = current_points.back()
			if global_path.size() > 0 and last_pt.distance_to(global_path[0]) > 0.01:
				# If there's a gap, fill it (or debug why)
				pass
		
		current_points.append_array(global_path)
		_trace_branch(current_coord + Vector3i(global_exit), Vector3i(global_exit), current_points, accumulated_delay)
	
	# If we are at the very end of a branch (no splits, but loop finished), save it
	else:
		if not current_points.is_empty():
			branches.append({ "points": current_points.duplicate(), "delay": accumulated_delay })

func _transform_points(local_points: Array, basis: Basis, center: Vector3) -> Array:
	var world_pts = []
	for p in local_points:
		world_pts.append(center + (basis * p))
	return world_pts
