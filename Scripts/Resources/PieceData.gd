class_name PieceData
extends Resource

enum Type { STRAIGHT, TURN, T, CROSS, BLOCK, ONE_EXIT, SOURCE, GOAL }

@export var type: Type
@export var model_scene: PackedScene
@export var rotation_degrees: float = 0.0
@export var flow_map: Dictionary = {}
@export var pipe_radius: float = 0.5
@export var turn_points: Dictionary = {}
@export var is_movable: bool = true  # Whether piece can be dragged by player

static func create_straight_piece(scene: PackedScene, axis: String, is_movable: bool = true) -> PieceData:
	var p = PieceData.new()
	p.type = Type.STRAIGHT
	p.model_scene = scene
	p.is_movable = is_movable
	
	if axis == "X":
		p.rotation_degrees = 90.0
		p.flow_map[Vector3i.LEFT] = [Vector3i.RIGHT]
		p.flow_map[Vector3i.RIGHT] = [Vector3i.LEFT]
	else: # Z Axis
		p.rotation_degrees = 0.0
		p.flow_map[Vector3i.FORWARD] = [Vector3i.BACK]
		p.flow_map[Vector3i.BACK] = [Vector3i.FORWARD]
	return p

static func create_turn_piece(scene: PackedScene, in_dir: Vector3i, is_movable: bool = true) -> PieceData:
	var p = PieceData.new()
	p.type = Type.TURN
	p.model_scene = scene
	p.is_movable = is_movable
	p.rotation_degrees = Vector3(in_dir).angle_to(Vector3.LEFT) * 180.0 / PI
	var out_dir = Vector3i(Vector3(in_dir).cross(Vector3.UP))
	p.flow_map[in_dir] = [out_dir]
	p.flow_map[out_dir] = [in_dir]
	#p.turn_points = {"in": Vector3(in_dir) * 0.8, "out": Vector3(out_dir) * -0.3}
	p.turn_points = {"in": Vector3.ZERO, "out": Vector3.ZERO}
	return p

static func create_t_piece(scene: PackedScene, blocked_side: Vector3i, is_movable: bool = true) -> PieceData:
	var p = PieceData.new()
	p.type = Type.T
	p.model_scene = scene
	p.is_movable = is_movable
	
	# T-piece has 3 exits, blocked_side is the missing direction
	var directions = [Vector3i.LEFT, Vector3i.RIGHT, Vector3i.FORWARD, Vector3i.BACK]
	
	# Remove the blocked side
	directions.erase(blocked_side)
	
	# Set up flow: each direction connects to the other two
	for dir in directions:
		var other_dirs = directions.duplicate()
		other_dirs.erase(dir)
		p.flow_map[dir] = other_dirs
	
	# Set rotation based on blocked side
	p.rotation_degrees = Vector3(blocked_side).angle_to(Vector3.LEFT) * 180.0 / PI
	
	return p

static func create_cross_piece(scene: PackedScene, is_movable: bool = true) -> PieceData:
	var p = PieceData.new()
	p.type = Type.CROSS
	p.model_scene = scene
	p.is_movable = is_movable
	p.rotation_degrees = 0.0
	
	# Cross-piece connects all 4 horizontal directions
	p.flow_map[Vector3i.LEFT] = [Vector3i.RIGHT, Vector3i.FORWARD, Vector3i.BACK]
	p.flow_map[Vector3i.RIGHT] = [Vector3i.LEFT, Vector3i.FORWARD, Vector3i.BACK]
	p.flow_map[Vector3i.FORWARD] = [Vector3i.BACK, Vector3i.LEFT, Vector3i.RIGHT]
	p.flow_map[Vector3i.BACK] = [Vector3i.FORWARD, Vector3i.LEFT, Vector3i.RIGHT]
	
	return p

static func create_block(scene: PackedScene, is_movable: bool = true) -> PieceData:
	var p = PieceData.new()
	p.type = Type.BLOCK
	p.model_scene = scene
	p.is_movable = is_movable
	p.rotation_degrees = 0.0
	
	# Block has no flow connections
	p.flow_map = {}
	
	return p

static func create_one_exit_piece(scene: PackedScene, exit_side: Vector3i, is_movable: bool = true) -> PieceData:
	var p = PieceData.new()
	p.type = Type.ONE_EXIT
	p.model_scene = scene
	p.is_movable = is_movable
	
	# One-exit piece allows flow from above
	p.flow_map = {Vector3i.UP: [exit_side]}
	p.flow_map[exit_side] = {}
	
	# Set rotation based on exit side
	p.rotation_degrees = Vector3(exit_side).angle_to(Vector3.FORWARD) * 180.0 / PI
	
	return p
	
static func create_source_piece(scene: PackedScene, exit_side: Vector3i) -> PieceData:
	var p = PieceData.new()
	p.type = Type.SOURCE
	p.model_scene = scene
	p.is_movable = false
	p.flow_map[exit_side] = {}
	p.rotation_degrees = Vector3(exit_side).angle_to(Vector3.FORWARD) * 180.0 / PI
	
	return p

static func create_goal_piece(scene: PackedScene, exit_side: Vector3i) -> PieceData:
	var p = PieceData.new()
	p.type = Type.GOAL
	p.model_scene = scene
	p.is_movable = false
	p.flow_map[exit_side] = {}
	p.rotation_degrees = Vector3(exit_side).angle_to(Vector3.FORWARD) * 180.0 / PI
	
	return p
