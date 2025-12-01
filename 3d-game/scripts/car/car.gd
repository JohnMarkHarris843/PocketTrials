extends CharacterBody3D

@export var speed = 10.0
@export var acceleration = 5.0
@export var friction = 1.0 # How much the car slows down. Lower is more slippery.
@export var turn_speed = 1.0
@export var traction = 3.0 # How much grip the car has. Lower is more drifty.
@export var drift_traction_multiplier = 0.2 # How much traction is reduced when drifting.
@export var drift_turn_multiplier = 2.0 # How much sharper the car turns when drifting.

@export var steer_angle = 0.4
@export var wheel_radius = 0.4 # Adjust this to match your wheel's size

# Camera effects
@export var sway_strength = 0.1
@export var sway_speed = 5.0
@export var max_fov_increase = 20.0
@export var fov_change_speed = 5.0

@export var tire_mark_scene: PackedScene
@export var drift_threshold = 1.0 # Lateral speed at which tire marks appear
@export var tire_mark_offset_left = Vector3(-0.3, -0.4, 0.5) # Offset for left rear wheel
@export var tire_mark_offset_right = Vector3(0.3, -0.4, 0.5) # Offset for right rear wheel

@onready var wheels_node = $wheelsFront
@onready var camera = $Camera3D

var initial_fov: float

func _ready():
	initial_fov = camera.fov

func _physics_process(delta):
	var turn_direction = 0.0
	if Input.is_action_pressed("left"):
		turn_direction += 1.0
	if Input.is_action_pressed("right"):
		turn_direction -= 1.0

	var current_turn_speed = turn_speed
	var current_traction = traction
	var is_drifting = Input.is_action_pressed("drift")
	if is_drifting:
		current_traction *= drift_traction_multiplier
		current_turn_speed *= drift_turn_multiplier

	# --- Rotation and Drifting Physics ---
	if velocity.length() > 0.5:
		rotate_y(turn_direction * current_turn_speed * delta)

	# Get forward/backward input
	var input_dir = 0.0
	if Input.is_action_pressed("forward"):
		input_dir = 1.0
	
	# Apply engine force
	velocity += -transform.basis.z * input_dir * acceleration * delta
	
	# Apply friction
	velocity = velocity.move_toward(Vector3.ZERO, friction * delta)

	# Apply traction (makes the car slide)
	var forward_velocity = velocity.dot(-transform.basis.z)
	var lateral_velocity = velocity.dot(transform.basis.x)
	
	if is_drifting:
		print("Drifting! Lateral Velocity: %s, Drift Threshold: %s" % [lateral_velocity, drift_threshold])
		if lateral_velocity > drift_threshold or lateral_velocity < -drift_threshold:
			_spawn_tire_mark()

	var desired_velocity = -transform.basis.z * forward_velocity
	desired_velocity += -transform.basis.x * lerp(lateral_velocity, 0.0, current_traction * delta)
	velocity = desired_velocity.limit_length(speed)
	
	# --- Wheel and Camera Updates ---
	# Rotate wheels for steering
	for wheel in wheels_node.get_children():
		var target_rotation = turn_direction * steer_angle
		wheel.rotation.y = lerp(wheel.rotation.y, target_rotation, turn_speed * 5 * delta)

	_update_camera(turn_direction, delta)

	move_and_slide()

func _spawn_tire_mark():
	if tire_mark_scene:
		# Spawn for left tire
		var mark_left = tire_mark_scene.instantiate()
		get_parent().add_child(mark_left)
		mark_left.global_transform.origin = global_transform.origin + global_transform.basis.x * tire_mark_offset_left.x + Vector3(0, tire_mark_offset_left.y, 0) + global_transform.basis.z * tire_mark_offset_left.z
		mark_left.rotation.y = rotation.y

		# Spawn for right tire
		var mark_right = tire_mark_scene.instantiate()
		get_parent().add_child(mark_right)
		mark_right.global_transform.origin = global_transform.origin + global_transform.basis.x * tire_mark_offset_right.x + Vector3(0, tire_mark_offset_right.y, 0) + global_transform.basis.z * tire_mark_offset_right.z
		mark_right.rotation.y = rotation.y

func _update_camera(_turn_direction, delta):
	# Camera Sway
	#var target_sway = -turn_direction * sway_strength
	#camera.rotation.z = lerp(camera.rotation.z, target_sway, sway_speed * delta)

	# FOV effect based on speed
	var speed_ratio = velocity.length() / speed
	var target_fov = initial_fov + speed_ratio * max_fov_increase
	camera.fov = lerp(camera.fov, target_fov, fov_change_speed * delta)
