extends Camera3D
@export var offset: Vector3 = Vector3(3, 4, 3)

func _ready():
	setup_camera(offset)

func setup_camera(camera_offset: Vector3):	
	var center_pos = Vector3.ZERO
	# Move camera to a fixed offset relative to that center
	position = center_pos + camera_offset
	
	# Look at the calculated center
	look_at(center_pos, Vector3.UP, false)
