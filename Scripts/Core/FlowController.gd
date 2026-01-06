class_name FlowController
extends Node

@export var grid_manager: GridManager
@export var MAX_DEPTH: int = 0
@export var water_path_manager: WaterPathManager
@export var delay_factor: float = 0.05

var branches: Array = [] # Array of Dictionaries: { "points": [], "delay": 0.0 }
var visited_coords: Array[Vector3i] = [] # Track coordinates visited by water
var goal_reached: bool = false
var total_animation_time: float = 0.0

func calculate_flow(start_coord: Vector3i, start_direction: Vector3i):
	water_path_manager.clear_paths()
	branches.clear()
	visited_coords.clear()
	goal_reached = false
	total_animation_time = 0.0
	
	_trace_branch(start_coord, start_direction, [], 0.0)
	
	# Calculate total animation time
	for b in branches:
		var path_length = 0.0
		if b["points"].size() >= 2:
			# Calculate approximate path length
			for i in range(1, b["points"].size()):
				var prev_pos = b["points"][i-1]["pos"] if b["points"][i-1] is Dictionary else b["points"][i-1]
				var curr_pos = b["points"][i]["pos"] if b["points"][i] is Dictionary else b["points"][i]
				path_length += prev_pos.distance_to(curr_pos)
		
		var flow_duration = path_length / 2.0  # Same as in WaterPathManager
		var total_time = b["delay"] + flow_duration
		if total_time > total_animation_time:
			total_animation_time = total_time
	
	for b in branches:
		water_path_manager.create_flow_branch(b["points"], b["delay"])
	
	if goal_reached:
		_start_victory_check_timer()
	else:
		print("Goal not reached. Flow calculation complete.")

# Recursive function to trace paths
func _trace_branch(current_coord: Vector3i, entry_dir: Vector3i, current_points: Array, accumulated_delay: float):
	var center_pos = grid_manager.grid_to_world(current_coord)
	
	# Track visited coordinates
	if current_coord not in visited_coords:
		visited_coords.append(current_coord)
	
	# Check if this is the goal position
	var level_manager = get_node_or_null("../LevelManager")
	if level_manager and current_coord == level_manager.goal_position:
		goal_reached = true
		print("Goal piece reached at coordinate: ", current_coord)

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
		_trace_branch(current_coord + Vector3i.DOWN, Vector3i.DOWN, current_points, accumulated_delay + (current_points.size() * delay_factor))
		return
	
	var data = piece_info["data"]
	#var node = piece_info["node"]
	
	var exits = [] # exit directions for the piece
	var side_entered = -entry_dir

	# --- CASE B: FLOWING THROUGH PIECE ---
	
	if entry_dir == Vector3i.DOWN or data.type == PieceData.Type.SOURCE: # Water moving down means it entered from UP
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
			var start_delay = accumulated_delay + (current_points.size() * delay_factor)
			
			# Start new branch list with the Center Point
			var new_branch = [center_pos]
			
			# Recurse
			_trace_branch(current_coord + exit, exit, new_branch, start_delay)
		
	# If Single Path (Extension)
	elif exits.size() == 1:
		var exit = exits[0]
		if entry_dir != Vector3i.DOWN:
			current_points.append({
				"pos": center_pos - entry_dir * 0.5,
				"in": data.turn_points.get("in", Vector3.ZERO),
				"out": data.turn_points.get("out", Vector3.ZERO)}
			)
		current_points.append({
			"pos": center_pos,
			"in": data.turn_points.get("in", Vector3.ZERO),
			"out": data.turn_points.get("out", Vector3.ZERO)}
		)
		#current_points.append({
			#"pos": center_pos + entry_dir * 0.5,
			#"in": data.turn_points.get("in", Vector3.ZERO),
			#"out": data.turn_points.get("out", Vector3.ZERO)}
		#)
		_trace_branch(current_coord + exit, exit, current_points, accumulated_delay ) # don't add delay here
		
	# If we are at the very end of a branch (no splits, but loop finished), save it
	else:
		current_points.append({"pos": center_pos + entry_dir * 0.5, "in": Vector3.ZERO, "out": Vector3.ZERO})
		current_points.append({"pos": center_pos - entry_dir * 0.5, "in": Vector3.ZERO, "out": Vector3.ZERO})
		branches.append({ "points": current_points.duplicate(), "delay": accumulated_delay })

func _start_victory_check_timer():
	"""Start timer to check victory condition after animations complete"""
	print("Starting victory check timer. Water flow animation time: ", total_animation_time, " seconds")
	print("Will check if goal is still reachable after animations complete...")
	
	# Wait for animations to complete + 3 extra seconds
	var total_wait_time = total_animation_time + 3.0
	
	# Create a timer to wait for animations + extra delay
	var win_timer = Timer.new()
	win_timer.wait_time = total_wait_time
	win_timer.one_shot = true
	win_timer.timeout.connect(_on_victory_check_complete)
	add_child(win_timer)
	win_timer.start()
	
	print("Victory check will occur in ", total_wait_time, " seconds")

func _on_victory_check_complete():
	"""Called when victory check timer completes - re-evaluates if goal is reachable"""
	print("Checking victory condition after animations complete...")
	
	# Re-calculate flow to see if goal is still reachable with current piece arrangement
	var level_manager = get_node_or_null("../LevelManager")
	if not level_manager:
		print("No LevelManager found - cannot check victory condition")
		return
	
	# Temporarily store current state
	var old_visited = visited_coords.duplicate()
	var old_goal_reached = goal_reached
	
	# Reset tracking and recalculate flow
	visited_coords.clear()
	goal_reached = false
	var old_branches = branches.duplicate()
	branches.clear()
	
	# Recalculate flow from current source position
	_trace_branch(level_manager.source_position, level_manager.source_direction, [], 0.0)
	
	# Check if goal is still reachable
	if goal_reached:
		print("*** LEVEL COMPLETE! ***")
		print("Congratulations! Water successfully reached the goal!")
		print("Goal is still reachable after animations completed.")
		
		# TODO: Add actual victory UI, sound effects, level progression, etc.
	else:
		print("Victory condition not met - goal is no longer reachable.")
		print("Player changed the path during animations.")
		
		# Restore the original flow paths for visual consistency
		branches = old_branches
		visited_coords = old_visited
		goal_reached = old_goal_reached
