extends Node3D

@onready var grid_manager: GridManager = $GridManager
@onready var flow_controller: FlowController = $FlowController
@export var straight_scene: PackedScene # Assign PipeStraight.tscn in Inspector
@export var turn_scene: PackedScene     # Assign PipeTurn.tscn in Inspector

func _ready():
	# Manually build a simple level
	# Level: Start -> Straight -> Turn -> Down
	
	# 1. Create Data
	var pipe_x = PieceData.create_straight_pipe(straight_scene, "X")
	var pipe_z = PieceData.create_straight_pipe(straight_scene, "Z")
	var turn = PieceData.create_turn_pipe(turn_scene, 0.0, Vector3i.LEFT, Vector3i.FORWARD)	
	# 2. Place Pieces
	# (0,0,0) Start Point (Left to Right)
	grid_manager.place_piece(Vector3i(0,0,0), pipe_x)
	#grid_manager.place_piece(Vector3i(0,0,-1), pipe_z)
	#grid_manager.place_piece(Vector3i(0,0,1), pipe_z)
	
	# (1,0,0) Another Straight
	grid_manager.place_piece(Vector3i(1,0,0), pipe_x)
	
	# (2,0,0) Turn (Enters Left, Exits Forward - which is Z-)
	grid_manager.place_piece(Vector3i(2,0,0), turn)
	
	# (2,0,-1) Catch the flow? Let's put a straight pipe aligned with Z
	var z_pipe = PieceData.new()
	z_pipe.flow_map[Vector3i.BACK] = [Vector3i.FORWARD] # Enters from BACK (Z-), Exits FORWARD (Z-)
	grid_manager.place_piece(Vector3i(2,0,-1), pipe_z)

	# 3. Start Simulation
	print("--- TEST START ---")
	flow_controller.calculate_flow(Vector3i(0,1,0), Vector3i.DOWN)
