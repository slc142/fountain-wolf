class_name WaterPathManager
extends Node3D

@export var water_shader: ShaderMaterial
#var active_paths: Array[CSGPolygon3D] = []
var active_paths = []

func clear_paths():
	for p in active_paths:
		p.queue_free()
	active_paths.clear()

func remove_paths_from_index(start_index: int, total_branches: int):
	"""Remove only paths that correspond to branches from a specific index"""
	print("=== DEBUG: remove_paths_from_index called ===")
	print("start_index: ", start_index)
	print("active_paths.size(): ", active_paths.size())
	
	# Get reference to FlowController to access branch information
	var flow_controller = get_node_or_null("../FlowController")
	if not flow_controller:
		print("Warning: Cannot access FlowController for selective path removal")
		return
	
	var branches = flow_controller.branches
	print("branches.size(): ", branches.size())
	
	var paths_to_remove = []
	
	# Find which branches should be removed based on their delay
	# Branches are stored in order, so we can match them to paths
	var branch_index = 0
	var path_index = 0
	
	while branch_index < branches.size() and path_index < active_paths.size():
		var _branch = branches[branch_index]
		
		# Check if this branch should be removed
		if branch_index >= start_index:
			# Remove both mesh and path_node for this branch
			if path_index < active_paths.size():
				paths_to_remove.append(active_paths[path_index])  # mesh
				print("Marking path[", path_index, "] for removal (branch ", branch_index, ")")
			if path_index + 1 < active_paths.size():
				paths_to_remove.append(active_paths[path_index + 1])  # path_node
				print("Marking path[", path_index + 1, "] for removal (branch ", branch_index, ")")
		
		branch_index += 1
		path_index += 2  # Each branch creates 2 paths
	
	# Remove all paths that come after the last valid branch
	while path_index < active_paths.size():
		paths_to_remove.append(active_paths[path_index])
		print("Marking extra path[", path_index, "] for removal")
		path_index += 1
	
	print("Total paths to remove: ", paths_to_remove.size())
	
	# Remove the identified paths
	for path in paths_to_remove:
		path.queue_free()
		active_paths.erase(path)
	
	print("Removed ", paths_to_remove.size(), " paths starting from branch index ", start_index)
	print("Remaining active_paths: ", active_paths.size())
	print("=== END DEBUG ===")

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
	
	# Create the Mesh (CSGPolygon)
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
