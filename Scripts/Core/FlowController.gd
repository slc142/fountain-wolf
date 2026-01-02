class_name FlowController
extends Node

@export var grid_manager: GridManager
@export var MAX_DEPTH: int = -5 # How far below Y=0 the water can fall

var active_water_path: Array[Vector3i] = []

func calculate_flow(start_coord: Vector3i, start_direction: Vector3i):
	active_water_path.clear()
	_propagate_flow(start_coord, start_direction)

func _propagate_flow(current_coord: Vector3i, entry_direction: Vector3i):
	# 1. STOP if we've already been here (prevents infinite loops)
	if current_coord in active_water_path:
		return
		
	# 2. STOP if we fall off the world
	if current_coord.y < MAX_DEPTH:
		print("Flow reached the abyss at ", current_coord)
		return

	# Add current spot to the path so we don't process it again
	active_water_path.append(current_coord)
	print("Water flowing through ", current_coord)

	var piece = grid_manager.get_piece_data(current_coord)
	
	# 3. GRAVITY LOGIC (Empty Space)
	if piece == null:
		print("Flow falling at ", current_coord)
		_propagate_flow(current_coord + Vector3i.DOWN, Vector3i.DOWN)
		return

	# 4. PIECE LOGIC
	var side_entered = -entry_direction 
	# Gravity Catching Logic
	if side_entered == Vector3i.UP:
		# If water hits the top of a half-pipe, it spreads to all available openings
		print("Water caught from above at ", current_coord)
		
		# Get every exit direction defined for this piece
		# We use a unique set to avoid flowing back into the same spot
		var all_exits = []
		for entry_points in piece.flow_map.keys():
			# In a standard pipe, the entries are the exits
			if entry_points != Vector3i.UP: 
				all_exits.append(entry_points)
		
		for exit_dir in all_exits:
			_propagate_flow(current_coord + exit_dir, exit_dir)
		return

	# Standard logic for horizontal entry
	if not piece.flow_map.has(side_entered):
		print("Flow blocked at ", current_coord)
		return

	# 5. CONTINUE to exits
	var exits = piece.flow_map[side_entered]
	for exit_dir in exits:
		_propagate_flow(current_coord + exit_dir, exit_dir)
