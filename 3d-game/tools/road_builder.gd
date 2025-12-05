@tool
extends Node3D

@export_node_path("Path3D") var path_node: NodePath
@export var road_width: float = 6.0
@export var resolution: int = 400
@export var uv_length_tiling: float = 10.0
@export var auto_add_collision: bool = true
@export var auto_assign_material: bool = true

@export var regenerate_road: bool = false:
	set(value):
		regenerate_road = value
		if value:
			_build_road()
			regenerate_road = false


func _clear_old() -> void:
	if has_node("RoadMesh"):
		get_node("RoadMesh").queue_free()
	if has_node("RoadCollision"):
		get_node("RoadCollision").queue_free()


func _get_path() -> Path3D:
	return get_node_or_null(path_node) as Path3D


func _build_road() -> void:
	_clear_old()

	var path: Path3D = _get_path()
	if path == null:
		push_error("RoadBuilder: path_node is not set or path was not found.")
		return

	var curve: Curve3D = path.curve
	if curve == null:
		push_error("RoadBuilder: Path3D has no Curve3D.")
		return

	var total_length: float = curve.get_baked_length()
	if total_length <= 0.0:
		push_error("RoadBuilder: Curve has no baked length (add more points?).")
		return

	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var basis := path.global_transform.basis
	var origin := path.global_transform.origin

	for i in range(resolution):
		var t: float = float(i) / float(resolution - 1)
		var dist: float = t * total_length

		var pos_local: Vector3 = curve.sample_baked(dist)
		var pos: Vector3 = basis * pos_local + origin

		var next_dist: float = min(dist + (total_length / float(resolution)), total_length)
		var next_local: Vector3 = curve.sample_baked(next_dist)
		var next_pos: Vector3 = basis * next_local + origin

		var forward: Vector3 = next_pos - pos
		if forward.length() < 0.0001:
			forward = Vector3.FORWARD
		forward = forward.normalized()

		var right: Vector3 = forward.cross(Vector3.UP).normalized()

		var left_pt: Vector3 = pos - right * (road_width * 0.5)
		var right_pt: Vector3 = pos + right * (road_width * 0.5)

		# Add left vertex
		st.add_vertex(left_pt)
		# Add right vertex
		st.add_vertex(right_pt)

	# Build triangles
	for i in range(resolution - 1):
		var a: int = i * 2
		var b: int = a + 1
		var c: int = a + 2
		var d: int = a + 3

		st.add_index(a)
		st.add_index(c)
		st.add_index(b)

		st.add_index(b)
		st.add_index(c)
		st.add_index(d)

	# generate normals for shading
	if st.has_method("generate_normals"):
		st.generate_normals()
	else:
		# older/newer builds: attempt to still commit; mesh may need smoothing manually later
		pass

	var mesh: ArrayMesh = st.commit() as ArrayMesh

	# Create mesh instance
	var mesh_instance: MeshInstance3D = MeshInstance3D.new()
	mesh_instance.name = "RoadMesh"
	mesh_instance.mesh = mesh
	add_child(mesh_instance)

	if auto_assign_material:
		var mat: StandardMaterial3D = StandardMaterial3D.new()
		mat.albedo_color = Color(0.12, 0.12, 0.12)
		mat.roughness = 1.0
		mesh_instance.material_override = mat

	# Collision
	if auto_add_collision:
		var body: StaticBody3D = StaticBody3D.new()
		body.name = "RoadCollision"

		var col: CollisionShape3D = CollisionShape3D.new()
		col.shape = mesh.create_trimesh_shape()

		body.add_child(col)
		add_child(body)

	print("RoadBuilder: Road generated successfully (no UVs).")
