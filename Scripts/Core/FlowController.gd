class_name FlowController
extends Node

class BranchNode:
	var points: Array = []
	var delay: float = 0.0
	var parent: BranchNode = null
	var children: Array[BranchNode] = []
	var visited_coords: Array[Vector3i] = [] # Coordinates visited by this branch
	var path3d: Path3D = null  # Reference to visual representation
	var animation_tween: Tween = null  # Reference to running animation
	var node_coord: Vector3i  # Coordinate of this node
	
	func _init(p_points: Array = [], p_delay: float = 0.0, p_parent: BranchNode = null, p_visited_coords: Array[Vector3i] = [], p_entry_coord: Vector3i = Vector3i.ZERO):
		points = p_points.duplicate(true)
		delay = p_delay
		parent = p_parent
		visited_coords = p_visited_coords.duplicate()
		node_coord = p_entry_coord
		if p_parent:
			p_parent.children.append(self)

@export var grid_manager: GridManager
@export var MAX_DEPTH: int = 0
@export var water_path_manager: WaterPathManager
@export var delay_factor: float = 0.05

var root_nodes: Array[BranchNode] = [] # Root nodes of the flow tree structure
var visited_coords: Array[Vector3i] = [] # Track coordinates visited by water
var goal_reached: bool = false
var total_animation_time: float = 0.0

func calculate_flow(start_coord: Vector3i, start_direction: Vector3i):
	water_path_manager.clear_paths()
	root_nodes.clear()
	visited_coords.clear()
	goal_reached = false
	total_animation_time = 0.0
	
	_trace_branch(start_coord, start_direction, null, [], 0.0, [])
	
	# Debug: Print tree structure
	print_tree_structure()
	
	# Calculate total animation time
	_calculate_animation_time()
	
	# Create flow paths from tree
	_create_flow_paths()

func print_tree_structure():
	print("=== Tree Structure Debug ===")
	print("Number of root nodes: ", root_nodes.size())
	print("Visited coordinates: ", visited_coords)
	for i in range(root_nodes.size()):
		print("Root ", i, ":")
		_print_node_recursive(root_nodes[i], 1)
	print("=== End Tree Debug ===")

func print_all_flow_coordinates():
	print("=== All Flow Coordinates ===")
	for coord in visited_coords:
		print("Flow passes through: ", coord)
	print("=== End Flow Coordinates ===")

func _print_node_recursive(node: BranchNode, depth: int):
	var indent = "  ".repeat(depth)
	print(indent, "Node at ", node.node_coord, " (delay: ", node.delay, ", children: ", node.children.size(), ")")
	for child in node.children:
		_print_node_recursive(child, depth + 1)

# Recursive function to trace paths
func _trace_branch(current_coord: Vector3i, entry_dir: Vector3i, parent_node: BranchNode, current_points: Array, accumulated_delay: float, branch_visited_coords: Array[Vector3i] = []):
	var center_pos = grid_manager.grid_to_world(current_coord)
	
	# Track visited coordinates and build flow path
	if current_coord not in visited_coords:
		visited_coords.append(current_coord)
	if current_coord not in branch_visited_coords:
		branch_visited_coords.append(current_coord)
	
	# Check if this is the goal position
	var level_manager = get_node_or_null("../LevelManager")
	if level_manager and current_coord == level_manager.goal_position:
		goal_reached = true
		print("Goal piece reached at coordinate: ", current_coord)

	# 1. Safety Check (Bounds & Loops)
	if current_coord.y < MAX_DEPTH: 
		print("Fell into the abyss at ", current_coord)
		current_points.append({"pos": center_pos, "in": Vector3.ZERO, "out": Vector3.ZERO})
		var node = BranchNode.new(current_points, accumulated_delay, parent_node, branch_visited_coords, current_coord)
		if parent_node == null:
			root_nodes.append(node)
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
		
		var node = BranchNode.new(current_points, accumulated_delay, parent_node, branch_visited_coords, current_coord)
		if parent_node == null:
			root_nodes.append(node)
		_trace_branch(current_coord + Vector3i.DOWN, Vector3i.DOWN, node, current_points, accumulated_delay + (current_points.size() * delay_factor), branch_visited_coords)
		return
	
	var data = piece_info["data"]
	#var node = piece_info["node"]
	
	var exits = [] # exit directions for the piece
	var side_entered = -entry_dir

	# --- CASE B: FLOWING THROUGH PIECE ---
	
	if entry_dir == Vector3i.DOWN or data.type == PieceData.Type.SOURCE: # Water moving down means it entered from UP
		# If falling in, we look for ALL valid exits in the piece data
		if entry_dir == Vector3i.DOWN and data.type != PieceData.Type.SOURCE:
			print("Water falling into ", current_coord)
		for k in data.flow_map.keys():
			if k != Vector3i.UP: exits.append(k)
	
	# If entered from SIDE, get specific exits
	elif data.flow_map.has(side_entered):
		print("Water flowing through ", current_coord)
		exits = data.flow_map[side_entered]
	else:
		print("Flow blocked at ", current_coord)
		current_points.append({"pos": center_pos - entry_dir * 0.5, "in": Vector3.ZERO, "out": Vector3.ZERO})
		var node = BranchNode.new(current_points, accumulated_delay, parent_node, branch_visited_coords, current_coord)
		if parent_node == null:
			root_nodes.append(node)
		return # Blocked
	
	# If Split (size > 1), we finalize the current branch here
	if exits.size() > 1:
		# Important: Add the CENTER point to connect the fall to the split
		current_points.append({"pos": center_pos, "in": Vector3.ZERO, "out": Vector3.ZERO})
		var split_node = BranchNode.new(current_points, accumulated_delay, parent_node, branch_visited_coords, current_coord)
		if parent_node == null:
			root_nodes.append(split_node)
		
		# Start new branches from the center
		for exit in exits:
			var start_delay = accumulated_delay + (current_points.size() * delay_factor)
			
			# Start new branch list with the Center Point
			var new_branch = [center_pos]
			
			# Create new visited coords list for child branch (inherits parent's coords)
			var child_visited_coords = branch_visited_coords.duplicate()
			
			# Recurse
			_trace_branch(current_coord + exit, exit, split_node, new_branch, start_delay, child_visited_coords)
		
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
		var node = BranchNode.new(current_points, accumulated_delay, parent_node, branch_visited_coords, current_coord)
		if parent_node == null:
			root_nodes.append(node)
		_trace_branch(current_coord + exit, exit, node, current_points, accumulated_delay, branch_visited_coords) # don't add delay here
		
	# If we are at the very end of a branch (no splits, but loop finished), save it
	else:
		current_points.append({"pos": center_pos + entry_dir * 0.5, "in": Vector3.ZERO, "out": Vector3.ZERO})
		current_points.append({"pos": center_pos - entry_dir * 0.5, "in": Vector3.ZERO, "out": Vector3.ZERO})
		var node = BranchNode.new(current_points, accumulated_delay, parent_node, branch_visited_coords, current_coord)
		if parent_node == null:
			root_nodes.append(node)

# Helper function to calculate total animation time from tree
func _calculate_animation_time():
	total_animation_time = 0.0
	for root in root_nodes:
		_calculate_animation_time_recursive(root)

func _calculate_animation_time_recursive(node: BranchNode):
	var path_length = 0.0
	if node.points.size() >= 2:
		# Calculate approximate path length
		for i in range(1, node.points.size()):
			var prev_pos = node.points[i-1]["pos"] if node.points[i-1] is Dictionary else node.points[i-1]
			var curr_pos = node.points[i]["pos"] if node.points[i] is Dictionary else node.points[i]
			path_length += prev_pos.distance_to(curr_pos)
	
	var flow_duration = path_length / 2.0  # Same as in WaterPathManager
	var total_time = node.delay + flow_duration
	if total_time > total_animation_time:
		total_animation_time = total_time
	
	# Recursively calculate for children
	for child in node.children:
		_calculate_animation_time_recursive(child)

# Helper function to create flow paths from tree
func _create_flow_paths():
	for root in root_nodes:
		_create_flow_paths_recursive(root)
	
	# Always start the victory check timer
	if goal_reached:
		_start_victory_check_timer()
	else:
		print("Goal not reached. Flow calculation complete.")

func _create_flow_paths_recursive(node: BranchNode):
	var result = water_path_manager.create_flow_branch(node.points, node.delay)
	
	# Store references to the created path and animation
	node.path3d = result["path"]
	node.animation_tween = result["tween"]
	
	# Recursively create paths for children
	for child in node.children:
		_create_flow_paths_recursive(child)

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
	var old_root_nodes = root_nodes.duplicate()
	root_nodes.clear()
	
	# Recalculate flow from current source position
	_trace_branch(level_manager.source_position, level_manager.source_direction, null, [], 0.0, [])
	
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
		root_nodes = old_root_nodes
		visited_coords = old_visited
		goal_reached = old_goal_reached

# Helper functions for partial flow recalculation
func _find_node_containing_coord(coord: Vector3i) -> BranchNode:
	print("Searching for node at coordinate: ", coord)
	for root in root_nodes:
		var result = _find_node_recursive(root, coord)
		if result:
			print("Found node: ", result.node_coord)
			return result
	print("Node not found for coordinate: ", coord)
	return null

func _find_node_recursive(node: BranchNode, coord: Vector3i) -> BranchNode:
	if node.node_coord == coord:
		print("Match found: node.node_coord (", node.node_coord, ") == coord (", coord, ")")
		return node
	
	for child in node.children:
		var result = _find_node_recursive(child, coord)
		if result:
			return result
	return null

func _calculate_preserved_delay(node: BranchNode) -> float:
	var total_delay = 0.0
	var current = node.parent
	
	while current:
		total_delay += current.delay
		current = current.parent
	
	return total_delay

func _determine_entry_direction(coord: Vector3i) -> Vector3i:
	# Find which direction water enters this coordinate
	var node = _find_node_containing_coord(coord)
	if not node:
		print("No node found for coordinate ", coord)
		return Vector3i.DOWN
	
	if not node.parent:
		print("No parent found for coordinate ", coord)
		return Vector3i.DOWN
	
	var parent_coord = node.parent.node_coord
	var direction_vector = coord - parent_coord
	
	return direction_vector

func recalculate_flow_from_coord(changed_coord: Vector3i):
	"""Recalculate flow only from a specific piece coordinate onward"""
	print("Recalculating flow from piece coordinate: ", changed_coord)
	
	# 1. Find the affected node
	var affected_node = _find_node_containing_coord(changed_coord)
	if not affected_node:
		## DO NOT EDIT THIS CODE
		print("Coordinate ", changed_coord, " not in current flow path. Skipping recalculation.")
		return
	
	print("Found affected node with ", affected_node.children.size(), " children")
	
	# 2. Calculate preserved delay from parent chain
	var preserved_delay = _calculate_preserved_delay(affected_node)
	print("Preserved delay from parent chain: ", preserved_delay)
	
	# 3. Determine entry direction BEFORE removing node from tree
	var entry_dir = _determine_entry_direction(changed_coord)
	print("Entry direction: ", entry_dir)
	
	# 4. Clear affected subtree visuals
	water_path_manager.clear_subtree_paths(affected_node)
	
	# 5. Store parent reference and remove from tree
	var parent_node = affected_node.parent
	if parent_node:
		parent_node.children.erase(affected_node)
	else:
		root_nodes.erase(affected_node)
	
	# 6. Recalculate from this coordinate
	goal_reached = false
	_trace_branch(changed_coord, entry_dir, parent_node, parent_node.points, preserved_delay, parent_node.visited_coords)
	# _trace_branch(changed_coord, entry_dir, parent_node, [], preserved_delay, [changed_coord])

	# 7. Update animations and create new paths
	_calculate_animation_time()
	_create_flow_paths()
	
	# 8. Start victory check if goal was reached and still is
	if goal_reached:
		_start_victory_check_timer()
	else:
		print("Flow recalculation complete. Goal not reached from coordinate ", changed_coord)