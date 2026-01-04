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
	var center_pos = grid_manager.grid_to_world(current_coord)

	# 1. Safety Check (Bounds & Loops)
	if current_coord.y < MAX_DEPTH: 
		print("Fell into the abyss at ", current_coord)
		current_points.append({"pos": center_pos, "in": Vector3.ZERO, "out": Vector3.ZERO})
		branches.append({ "points": current_points.duplicate(), "delay": accumulated_delay })
		return

	# 2. Get the piece
	var piece_info = grid_manager.get_piece_data(current_coord) # Should return {data, node, rotation}
	
	# --- CASE A: FALLING (No Piece) ---
	if piece_info == {}:
		# Falling is a straight line downwards
		# Add to current branch
		# TODO: add control points for falling water
		current_points.append({"pos": center_pos, "in": Vector3.ZERO, "out": Vector3.ZERO})
		
		print("Flow falling at ", current_coord)
		
		# Continue falling
		_trace_branch(current_coord + Vector3i.DOWN, Vector3i.DOWN, current_points, accumulated_delay + (current_points.size() * 0.05))
		return
	
	var data = piece_info["data"]
	#var node = piece_info["node"]
	
	var exits = [] # exit directions for the piece
	var side_entered = -entry_dir

	# --- CASE B: FLOWING THROUGH PIECE ---
	
	if entry_dir == Vector3i.DOWN: # Water moving down means it entered from UP
		# If falling in, we look for ALL valid exits in the piece data
		for k in data.flow_map.keys():
			if k != Vector3i.UP: exits.append(k)
	
	# If entered from SIDE, get specific exits
	elif data.flow_map.has(side_entered):
		print("Water flowing through ", current_coord)
		exits = data.flow_map[side_entered]
	else:
		print("Flow blocked at ", current_coord)
		current_points.append({"pos": center_pos - entry_dir * 0.5, "in": Vector3.ZERO, "out": Vector3.ZERO})
		branches.append({ "points": current_points.duplicate(), "delay": accumulated_delay })
		return # Blocked
	
	# If Split (size > 1), we finalize the current branch here
	if exits.size() > 1:
		# Important: Add the CENTER point to connect the fall to the split
		current_points.append({"pos": center_pos, "in": Vector3.ZERO, "out": Vector3.ZERO})
		branches.append({ "points": current_points.duplicate(), "delay": accumulated_delay })
		
		# Start new branches from the center
		for exit in exits:
			var start_delay = accumulated_delay + (current_points.size() * 0.05)
			
			# Start new branch list with the Center Point
			var new_branch = [center_pos]
			
			# Recurse
			_trace_branch(current_coord + exit, exit, new_branch, start_delay)
		
	# If Single Path (Extension)
	elif exits.size() == 1:
		var exit = exits[0]
		current_points.append({
			"pos": center_pos - entry_dir * 0.5,
			"in": data.turn_points.get("in", Vector3.ZERO),
			"out": data.turn_points.get("out", Vector3.ZERO)}
		)
		_trace_branch(current_coord + exit, exit, current_points, accumulated_delay)
		
	# If we are at the very end of a branch (no splits, but loop finished), save it
	else:
		current_points.append({"pos": center_pos, "in": Vector3.ZERO, "out": Vector3.ZERO})
		branches.append({ "points": current_points.duplicate(), "delay": accumulated_delay })
