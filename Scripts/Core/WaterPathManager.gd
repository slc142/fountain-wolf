class_name WaterPathManager
extends Node3D

@export var water_shader: ShaderMaterial
var active_paths: Array[CSGPolygon3D] = []

func clear_paths():
	for p in active_paths:
		p.queue_free()
	active_paths.clear()

func create_flow_branch(points: Array, start_delay: float):
	if points.size() < 2: return # Can't make a curve with 1 point

	var path_node = Path3D.new()
	var curve = Curve3D.new()
	
	for p in points:
		curve.add_point(p)
		
	path_node.curve = curve
	add_child(path_node)
	
	# 3. Create the Mesh (CSGPolygon)
	var mesh = CSGPolygon3D.new()
	add_child(mesh)
	mesh.mode = CSGPolygon3D.MODE_PATH
	mesh.path_node = mesh.get_path_to(path_node)
	mesh.path_interval_type = CSGPolygon3D.PATH_INTERVAL_DISTANCE
	mesh.path_interval = 0.1 # Quality of the curve
	
	# Create the cross-section (A small square or circle)
	mesh.polygon = PackedVector2Array([
		Vector2(-0.2, -0.1), Vector2(0.2, -0.1), 
		Vector2(0.2, 0.1), Vector2(-0.2, 0.1)
	])
	
	# Assign Shader
	var mat = water_shader.duplicate()
	mesh.material = mat
	active_paths.append(mesh)
	
	# 4. Animate the Shader
	var tween = create_tween()
	tween.tween_interval(start_delay)
	tween.tween_property(mat, "shader_parameter/fill_amount", 1.0, curve.get_baked_length() / 5.0)
