class_name LevelData
extends Resource

@export var level_name: String = ""
@export var source_position: Vector3i = Vector3i.ZERO
@export var source_direction: Vector3i = Vector3i.FORWARD
@export var goal_position: Vector3i = Vector3i.ZERO
@export var goal_direction: Vector3i = Vector3i.FORWARD
@export var piece_placements: Array[Dictionary] = []  # [{"position": Vector3i, "piece_data": PieceData}]

# Helper function to add a piece placement
func add_piece_placement(position: Vector3i, piece_data: PieceData):
	piece_placements.append({"position": position, "piece_data": piece_data})

# Helper function to get source info
func get_source_info() -> Dictionary:
	return {"position": source_position, "direction": source_direction}

# Helper function to get goal info
func get_goal_info() -> Dictionary:
	return {"position": goal_position, "direction": goal_direction}
