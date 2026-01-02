class_name PieceVisuals
extends Node3D

# We store the water meshes here. Key = Direction (Vector3i), Value = MeshInstance3D
var water_legs: Dictionary = {}
@export var water_color: Color = Color(0.0, 0.6, 1.0) # Nice distinct blue
@export var pipe_radius: float = 0.5
@export var pipe_length: float = 1

func _ready():
	# We wait for the GridManager to inject the PieceData so we know what shape we are
	pass

# Called by GridManager after placing the piece
func initialize(data: PieceData):
	# Create a mesh for every connection direction defined in the data
	# We also add the 'UP' direction for the "Center" if water falls in
	var directions = data.flow_map.keys()
	
	# De-duplicate directions (since flow_map has both In and Out keys)
	var unique_dirs = []
	for d in directions:
		if not d in unique_dirs and d != Vector3i.UP: # Ignore UP for legs
			unique_dirs.append(d)
	
	for dir in unique_dirs:
		create_leg_mesh(dir)

func create_leg_mesh(direction: Vector3i):
	var mesh_inst = MeshInstance3D.new()
	var box = BoxMesh.new()
	
	# Setup the visual shape of the water
	box.size = Vector3(pipe_length, pipe_radius, pipe_radius) 
	
	# Create a simple blue material
	var mat = StandardMaterial3D.new()
	mat.albedo_color = water_color
	mat.emission_enabled = true
	mat.emission = water_color
	mat.emission_energy_multiplier = 0.5
	box.material = mat
	
	mesh_inst.mesh = box
	add_child(mesh_inst)
	
	# Rotate the mesh to align with the direction
	# Default BoxMesh length is on Z axis. We rotate based on direction.
	if direction == Vector3i.FORWARD:
		mesh_inst.rotation_degrees.y = 0   # Z-
	elif direction == Vector3i.BACK:
		mesh_inst.rotation_degrees.y = 180 # Z+
	elif direction == Vector3i.LEFT:
		mesh_inst.rotation_degrees.y = 90  # X-
	elif direction == Vector3i.RIGHT:
		mesh_inst.rotation_degrees.y = -90 # X+
		
	# Start HIDDEN (Scale 0 on Z axis)
	mesh_inst.scale = Vector3(1, 1, 0)
	
	# Store reference
	water_legs[direction] = mesh_inst

# The Main Animation Function
func animate_fill(entry_dir: Vector3i, exit_dirs: Array, duration: float = 1.5):
	var tween = create_tween()
	
	# 1. ANIMATE INFLOW (Edge -> Center)
	# If we didn't fall from above, we must flow in from the side
	if entry_dir != Vector3i.UP:
		var in_leg = water_legs.get(entry_dir) # The leg facing the entry
		if in_leg:
			# Logic: Grow from Edge (-0.5) to Center (0)
			# We set pivot behavior by manipulating position and scale together
			
			# Start at edge
			in_leg.scale.z = 0
			in_leg.position = (Vector3(entry_dir) * 0.5)
			
			# Tween to center
			tween.tween_property(in_leg, "scale:z", 1.0, duration / 2)
			tween.parallel().tween_property(in_leg, "position", Vector3(entry_dir) * 0.25, duration / 2)
	
	# 2. ANIMATE OUTFLOW (Center -> Edge)
	# This runs after inflow is done (chaining)
	for exit_dir in exit_dirs:
		var out_leg = water_legs.get(exit_dir)
		if out_leg:
			# Logic: Grow from Center (0) to Edge (0.5)
			
			# Start at center
			out_leg.scale.z = 0
			out_leg.position = Vector3(0,0,0) # Actually center is slightly offset for the leg center
			
			# Tween to edge
			var target_pos = Vector3(exit_dir) * 0.25
			
			tween.parallel().tween_property(out_leg, "scale:z", 1.0, duration / 2).set_delay(duration/2)
			tween.parallel().tween_property(out_leg, "position", target_pos, duration / 2).set_delay(duration/2)
	
	# Return the tween so the controller knows when to start the next piece
	return tween

func reset_water():
	for dir in water_legs:
		var leg = water_legs[dir]
		leg.scale = Vector3(1, 1, 0) # Reset scale to 0 (hidden)
