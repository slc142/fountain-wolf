extends Node3D

@onready var grid_manager: GridManager = $GridManager
@onready var flow_controller: FlowController = $FlowController
@export var straight_scene: PackedScene # Assign PipeStraight.tscn in Inspector
@export var turn_scene: PackedScene     # Assign PipeTurn.tscn in Inspector
@export var t_scene: PackedScene        # Assign PipeT.tscn in Inspector
@export var cross_scene: PackedScene    # Assign PipeCross.tscn in Inspector
@export var block_scene: PackedScene    # Assign PipeBlock.tscn in Inspector
@export var one_exit_scene: PackedScene # Assign PipeOneExit.tscn in Inspector

func _ready():
	# Manually build a simple level with all piece types for testing
	
	# 1. Create Data for all piece types
	var straight_x = PieceData.create_straight_piece(straight_scene, "X")
	var straight_z = PieceData.create_straight_piece(straight_scene, "Z")
	var turn = PieceData.create_turn_piece(turn_scene, Vector3i.LEFT)
	var t_piece = PieceData.create_t_piece(t_scene, Vector3i.BACK)  # T-piece with back blocked
	var cross_piece = PieceData.create_cross_piece(cross_scene)
	var block_piece = PieceData.create_block(block_scene)
	var one_exit_piece = PieceData.create_one_exit_piece(one_exit_scene, Vector3i.FORWARD)
	
	# 2. Place Pieces in a test pattern
	# Row 0: Basic straight pieces
	grid_manager.place_piece(Vector3i(0,0,0), straight_x)  # Straight X
	grid_manager.place_piece(Vector3i(1,0,0), straight_x)  # Another straight X
	
	# Row 1: Turn piece
	grid_manager.place_piece(Vector3i(2,0,0), turn)  # Turn piece
	
	# Row 2: T-piece
	grid_manager.place_piece(Vector3i(-1,0,1), t_piece)  # T-piece
	
	# Row 3: Cross piece
	grid_manager.place_piece(Vector3i(1,0,1), cross_piece)  # Cross piece
	
	# Row 4: Block and One-exit
	grid_manager.place_piece(Vector3i(-2,0,2), block_piece)  # Block
	grid_manager.place_piece(Vector3i(-2,0,1), one_exit_piece)  # One-exit
	
	# Additional test pieces
	grid_manager.place_piece(Vector3i(0,0,2), straight_z)  # Straight Z for testing
	
	# 3. Start Simulation
	print("--- TEST START ---")
	
	flow_controller.calculate_flow(Vector3i(0,1,0), Vector3i.DOWN)
