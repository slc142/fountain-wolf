extends Camera3D

func _ready():
	center_camera_on_grid(5, 5)

func center_camera_on_grid(grid_width: int, grid_height: int):
	## TODO: actually use the grid size values
	
	var center_pos = Vector3(1, 0, 1)
	# Move camera to a fixed offset relative to that center
	# (Offset X, Height Y, Offset Z)
	position = center_pos + Vector3(2, 4, 2) 
	
	# Look at the calculated center
	look_at(center_pos, Vector3.UP, false)
