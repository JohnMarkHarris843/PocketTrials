@tool
extends MultiMeshInstance3D

@export var mesh: Mesh:
	set(value):
		mesh = value
		if is_inside_tree(): generate_circles()

@export var circle_radii: Array[float] = [20.0, 30.0, 40.0]:
	set(value):
		circle_radii = value
		if is_inside_tree(): generate_circles()

@export var circle_counts: Array[int] = [10, 15, 20]:
	set(value):
		circle_counts = value
		if is_inside_tree(): generate_circles()

@export var height: float = 0.0:
	set(value):
		height = value
		if is_inside_tree(): generate_circles()

@export var random_seed: int = 12345:
	set(value):
		random_seed = value
		if is_inside_tree(): generate_circles()

@export var vary_colors: bool = true:
	set(value):
		vary_colors = value
		if is_inside_tree(): generate_circles()

@export var min_brightness: float = 0.1:
	set(value):
		min_brightness = value
		if is_inside_tree(): generate_circles()

@export var max_brightness: float = 2:
	set(value):
		max_brightness = value
		if is_inside_tree(): generate_circles()

@export var position_jitter: float = 2.5:
	set(value):
		position_jitter = value
		if is_inside_tree(): generate_circles()

func _ready():
	generate_circles()

func generate_circles():
	if not mesh:
		return
		
	seed(random_seed)
	
	var num_circles = min(circle_radii.size(), circle_counts.size())
	var total_instances = 0
	for i in range(num_circles):
		total_instances += circle_counts[i]
		
	if total_instances == 0:
		self.multimesh = null
		return

	# Create a MultiMesh
	var mm = MultiMesh.new()
	mm.mesh = mesh
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = vary_colors
	mm.instance_count = total_instances
	
	var idx = 0
	
	for c in range(num_circles):
		var radius = circle_radii[c]
		var count = circle_counts[c]
		
		for i in range(count):
			var angle = (TAU * i) / float(count)
			
			var jx = randf_range(-position_jitter, position_jitter)
			var jz = randf_range(-position_jitter, position_jitter)
			
			var x = (cos(angle) * radius) + jx
			var z = (sin(angle) * radius) + jz
			
			# Create Basis for rotation and scale
			var scale_val = randf_range(0.8, 1.2)
			var rotation_y = randf() * TAU
			
			var basis = Basis()
			basis = basis.scaled(Vector3(scale_val, scale_val, scale_val))
			basis = basis.rotated(Vector3.UP, rotation_y)
			
			var transform = Transform3D(basis, Vector3(x, height, z))
			
			mm.set_instance_transform(idx, transform)
			
			if vary_colors:
				var b = randf_range(min_brightness, max_brightness)
				mm.set_instance_color(idx, Color(b, b, b, 1.0))
			
			idx += 1
	
	self.multimesh = mm
