class_name PieceData
extends Resource

enum Type { STRAIGHT, TURN }

@export var type: Type
@export var model_scene: PackedScene
@export var rotation_degrees: float = 0.0
@export var path_points: Dictionary = {} # Key: Entry Direction, Value: Array[Vector3]
@export var flow_map: Dictionary = {}
@export var pipe_radius: float = 0.5

static func create_straight_pipe(scene: PackedScene, axis: String) -> PieceData:
	var p = PieceData.new()
	p.type = Type.STRAIGHT
	p.model_scene = scene
	
	if axis == "X":
		p.rotation_degrees = 90.0
		p.flow_map[Vector3i.LEFT] = [Vector3i.RIGHT]
		p.flow_map[Vector3i.RIGHT] = [Vector3i.LEFT]
	else: # Z Axis
		p.rotation_degrees = 0.0
		p.flow_map[Vector3i.FORWARD] = [Vector3i.BACK]
		p.flow_map[Vector3i.BACK] = [Vector3i.FORWARD]
	return p

static func create_turn_pipe(scene: PackedScene, rot: float, in_dir: Vector3i, out_dir: Vector3i) -> PieceData:
	var p = PieceData.new()
	p.type = Type.TURN
	p.model_scene = scene
	p.rotation_degrees = rot
	p.flow_map[in_dir] = [out_dir]
	p.flow_map[out_dir] = [in_dir]
	return p
