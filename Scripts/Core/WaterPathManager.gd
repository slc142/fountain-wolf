class_name WaterPathManager
extends Node3D

@export var water_shader: ShaderMaterial
#var active_paths: Array[CSGPolygon3D] = []
var active_paths = []

func clear_paths():
	for p in active_paths:
		p.queue_free()
	active_paths.clear()

func create_flow_branch(points: Array, start_delay: float):
	if points.size() < 2: return # Can't make a curve with 1 point

	var path_node = Path3D.new()
	var curve = Curve3D.new()
	
	for p in points:
		if p is Vector3: # this shouldn't happen, but it does
			curve.add_point(p)
		else:
			curve.add_point(p["pos"], p["in"], p["out"])
		
	path_node.curve = curve
	add_child(path_node)
	
	# 3. Create the Mesh (CSGPolygon)
	var mesh = CSGPolygon3D.new()
	add_child(mesh)
	mesh.mode = CSGPolygon3D.MODE_PATH
	mesh.path_node = mesh.get_path_to(path_node)
	mesh.path_interval_type = CSGPolygon3D.PATH_INTERVAL_DISTANCE
	mesh.path_interval = 0.1 # Quality of the curve
	
	# Create the cross-section
	mesh.polygon = PackedVector2Array([
		Vector2(-0.2, -0.2), Vector2(0.2, -0.2), 
		Vector2(0.2, 0.2), Vector2(-0.2, 0.2)
	])
	
	# Assign Shader
	var mat = water_shader.duplicate()
	mesh.material = mat
	active_paths.append(mesh)
	active_paths.append(path_node) # Store path to clear too!
	
	# 4. Animate the Shader
	var path_length = curve.get_baked_length() # Get actual length in meters
	
	# Set the shader to 'empty' (fill_amount 0)
	mat.set_shader_parameter("fill_amount", 0.0)
	
	var tween = create_tween()
	tween.tween_interval(start_delay)
	
	# Animate fill_amount to the TOTAL LENGTH, not 1.0
	# Also adjust duration so speed is constant (e.g. 5 meters takes 2.5 seconds)
	var flow_duration = path_length / 2.0 
	tween.tween_property(mat, "shader_parameter/fill_amount", path_length, flow_duration)
