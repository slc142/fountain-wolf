class_name LevelManager
extends Node

@export var grid_manager: GridManager
@export var flow_controller: FlowController

var current_level: LevelData = null
var source_position: Vector3i = Vector3i.ZERO
var source_direction: Vector3i = Vector3i.FORWARD
var goal_position: Vector3i = Vector3i.ZERO
var goal_direction: Vector3i = Vector3i.FORWARD

func _ready():
	# Set default values in case no level is loaded
	source_position = Vector3i(0, 2, 0)
	source_direction = Vector3i.FORWARD

func load_level(level_data: LevelData):
	"""Load a level from LevelData resource"""
	current_level = level_data
	
	# Clear existing grid
	grid_manager.clear_grid()
	
	# Load source and goal info
	source_position = level_data.source_position
	source_direction = level_data.source_direction
	goal_position = level_data.goal_position
	goal_direction = level_data.goal_direction
	
	# Place all pieces from the level data
	for placement in level_data.piece_placements:
		var position = placement["position"]
		var piece_data = placement["piece_data"]
		grid_manager.place_piece(position, piece_data)
	
	print("Loaded level: ", level_data.level_name)
	print("Source at: ", source_position, " facing: ", source_direction)
	print("Goal at: ", goal_position, " facing: ", goal_direction)

func get_source_info() -> Dictionary:
	"""Get current source position and direction"""
	return {"position": source_position, "direction": source_direction}

func get_goal_info() -> Dictionary:
	"""Get current goal position and direction"""
	return {"position": goal_position, "direction": goal_direction}

func recalculate_flow(from_coord: Vector3i = Vector3i(-999, -999, -999)):
	"""Recalculate flow from source or from a specific coordinate"""
	if from_coord != Vector3i(-999, -999, -999):
		# Partial recalculation from specific coordinate
		flow_controller.recalculate_flow_from_coord(from_coord)
	else:
		# Full recalculation from source
		flow_controller.calculate_flow(source_position, source_direction)

func check_win_condition() -> bool:
	"""Check if water reaches the goal piece"""
	# This is a basic implementation - you may want to enhance this
	# based on your specific win condition logic
	
	# Check if goal position exists in grid
	if not grid_manager.is_occupied(goal_position):
		return false
	
	# For now, just check if water can reach the goal
	# You might want to track actual water flow in FlowController
	# and check if it reaches the goal position
	
	# TODO: Implement proper win condition checking
	# This could involve checking if water flow path includes goal_position
	return false

func create_test_level() -> LevelData:
	"""Create a test level with the current setup from Main.gd"""
	var level = LevelData.new()
	level.level_name = "Test Level"
	
	# Set source and goal
	level.source_position = Vector3i(0, 2, 0)
	level.source_direction = Vector3i.FORWARD
	level.goal_position = Vector3i(1, 0, 2)
	level.goal_direction = Vector3i.FORWARD
	
	# This would need the scene references - for now just return the basic structure
	# In practice, you'd pass the scene references when creating pieces
	
	return level
