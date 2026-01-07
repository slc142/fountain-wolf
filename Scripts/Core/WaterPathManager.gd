class_name WaterPathManager
extends Node3D

@export var water_shader: ShaderMaterial
var paths: Array[Path3D] = []

func clear_paths():
	for p in paths:
		p.queue_free()
	paths.clear()

# Selective clearing methods for partial recalculation
func clear_subtree_paths(node):
	_clear_subtree_recursive(node)

func _clear_subtree_recursive(node):
	# Clear this node's path
	if node.path3d:
		node.path3d.queue_free()
		node.path3d = null
		
	# Kill animation if it exists
	if node.animation_tween:
		node.animation_tween.kill()
		node.animation_tween = null
	
	# Clear children
	for child in node.children:
		_clear_subtree_recursive(child)

func get_animation_tween(path_node: Path3D) -> Tween:
	# Get the tween from the path's mesh material animation
	if not path_node or path_node.get_child_count() == 0:
		return null
		
	var mesh = path_node.get_child(0)
	if not mesh or not mesh.material:
		return null
		
	# This is a bit tricky - we need to store the tween reference
	# For now, we'll modify create_flow_branch to return both
	return null

func create_flow_branch(points: Array, start_delay: float) -> Dictionary:
	if points.size() < 2: return {"path": null, "tween": null} # Can't make a curve with 1 point

	var path_node = Path3D.new()
	var curve = Curve3D.new()
	
	for p in points:
		if p is Vector3: # this shouldn't happen, but it does
			curve.add_point(p)
		else:
			curve.add_point(p["pos"], p["in"], p["out"])
		
	path_node.curve = curve
	add_child(path_node)
	
	# Create the Mesh (CSGPolygon)
	var mesh = CSGPolygon3D.new()
	path_node.add_child(mesh)
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
	paths.append(path_node)
	
	# Animate the Shader
	var path_length = curve.get_baked_length() # Get actual length in meters
	
	# Set the shader to 'empty' (fill_amount 0)
	mat.set_shader_parameter("fill_amount", 0.0)
	
	var tween = create_tween()
	tween.tween_interval(start_delay)
	
	# Animate fill_amount to the TOTAL LENGTH, not 1.0
	# Also adjust duration so speed is constant (e.g. 5 meters takes 2.5 seconds)
	var flow_duration = path_length / 2.0 
	tween.tween_property(mat, "shader_parameter/fill_amount", path_length, flow_duration)
	
	return {"path": path_node, "tween": tween}
