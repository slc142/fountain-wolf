extends Node3D

@onready var grid_manager: GridManager = $GridManager
@onready var flow_controller: FlowController = $FlowController
@onready var level_manager: LevelManager = $LevelManager
@export var straight_scene: PackedScene
@export var turn_scene: PackedScene
@export var t_scene: PackedScene    
@export var cross_scene: PackedScene    
@export var block_scene: PackedScene    
@export var one_exit_scene: PackedScene
@export var source_scene: PackedScene
@export var goal_scene: PackedScene

func _ready():
	# Create a test level and load it using LevelManager
	var test_level = create_test_level()
	level_manager.load_level(test_level)
	
	# Start flow calculation using LevelManager
	level_manager.recalculate_flow()

func create_test_level() -> LevelData:
	"""Create a test level"""
	var level = LevelData.new()
	level.level_name = "Test Level"
	
	# Set source and goal
	level.source_position = Vector3i(0, 2, 0)
	level.source_direction = Vector3i.FORWARD
	level.goal_position = Vector3i(1, 0, 2)
	level.goal_direction = Vector3i.FORWARD
	
	# Create Data for all piece types
	var straight_x = PieceData.create_straight_piece(straight_scene, "X")
	var straight_x_fixed = PieceData.create_straight_piece(straight_scene, "X", false)
	var straight_z = PieceData.create_straight_piece(straight_scene, "Z")
	var turn = PieceData.create_turn_piece(turn_scene, Vector3i.RIGHT)
	var t_piece = PieceData.create_t_piece(t_scene, Vector3i.BACK)
	var cross_piece = PieceData.create_cross_piece(cross_scene)
	var block_piece = PieceData.create_block(block_scene)
	var one_exit_piece = PieceData.create_one_exit_piece(one_exit_scene, Vector3i.BACK)
	var source_piece = PieceData.create_source_piece(source_scene, Vector3i.RIGHT)
	var source_piece2 = PieceData.create_source_piece(source_scene, Vector3i.FORWARD)
	var goal_piece = PieceData.create_goal_piece(goal_scene, Vector3i.FORWARD)
	
	# Add piece placements to level
	level.add_piece_placement(Vector3i(1,0,0), straight_x_fixed)  # Another straight X
	level.add_piece_placement(Vector3i(2,0,0), turn)  # Turn piece
	level.add_piece_placement(Vector3i(1,0,1), t_piece)  # T-piece
	# level.add_piece_placement(Vector3i(1,0,1), cross_piece)  # Cross piece
	level.add_piece_placement(Vector3i(-2,0,2), block_piece)  # Block
	level.add_piece_placement(Vector3i(-2,0,1), one_exit_piece)  # One-exit
	level.add_piece_placement(Vector3i(0,0,2), straight_z)  # Straight Z for testing
	level.add_piece_placement(Vector3i(0,2,0), source_piece)
	level.add_piece_placement(Vector3i(-2,0,-2), source_piece2)
	level.add_piece_placement(Vector3i(1,0,2), goal_piece)
	
	return level
