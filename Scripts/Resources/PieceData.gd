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

# Returns points in LOCAL space, ordered from Entry -> Exit
func get_local_points(entry_dir: Vector3i, exit_dir: Vector3i) -> Array[Vector3]:
	var points: Array[Vector3] = []
	
	# CASE 1: Falling into the piece (Center Split)
	# We need a path from the Center (0,0,0) to the Exit Edge
	if entry_dir == Vector3i.UP:
		points.append(Vector3.ZERO) # Start at center
		# End at the edge of the exit direction
		points.append(Vector3(exit_dir))
		return points

	# CASE 2: Normal Flow (Edge to Edge)
	# Start at the entrance edge
	var start = Vector3(entry_dir)
	# End at the exit edge
	var end = Vector3(exit_dir)
	
	# If it's a TURN, add a control point for a smooth curve
	if type == Type.TURN:
		points.append(start)
		points.append(Vector3.ZERO) # Corner/Center pivot
		points.append(end)
	else:
		# Straight pipe
		points.append(start)
		points.append(end)
		
	return points
