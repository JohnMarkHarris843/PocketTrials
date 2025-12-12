extends CharacterBody3D

@export var speed = 10.0
@export var acceleration = 5.0
@export var friction = 1.0 # How much the car slows down. Lower is more slippery.
@export var turn_speed = 1.0
@export var traction = 3.0 # How much grip the car has. Lower is more drifty.
@export var drift_traction_multiplier = 0.2 # How much traction is reduced when drifting.
@export var drift_turn_multiplier = 2.0 # How much sharper the car turns when drifting.

signal boost_meter_changed(value)
@export var boost_meter: float = 0.0
@export var boost_capacity: float = 100.0
@export var boost_generation_rate: float = 10.0 # Points per second while drifting
@export var boost_consumption_rate: float = 30.0 # Points per second while boosting

@export var steer_angle = 0.4
@export var wheel_radius = 0.4 # Adjust this to match your wheel's size

# Camera effects
@export var sway_strength = 0.1
@export var sway_speed = 5.0
@export var max_fov_increase = 20.0
@export var boost_fov_increase = 5
@export var fov_change_speed = 5.0

@export var tire_mark_scene: PackedScene
@export var drift_threshold = 1.0 # Lateral speed at which tire marks appear
@export var tire_mark_offset_left = Vector3(-0.45, -0.5, 0.5) # Offset for left rear wheel
@export var tire_mark_offset_right = Vector3(0.45, -0.5, 0.5) # Offset for right rear wheel

@export var collision_cooldown = 0.5 # Cooldown in seconds to prevent multiple shakes
var _time_since_collision = 0.0

@onready var wheels_node = $body/wheelsFront
@onready var camera = $Camera3D
@onready var animation_player = $AnimationPlayer # Assumes you have a node named AnimationPlayer
@onready var boostEffectMesh = $body/exhaust/boostEffect

var initial_fov: float

func _ready():
	initial_fov = camera.fov
	boostEffectMesh.visible = false

func _physics_process(delta):
	_time_since_collision += delta

	var turn_direction = 0.0
	if Input.is_action_pressed("left"):
		turn_direction += 1.0
	if Input.is_action_pressed("right"):
		turn_direction -= 1.0

	var current_turn_speed = turn_speed
	var current_traction = traction
	var max_speed = speed
	var is_drifting = Input.is_action_pressed("drift")
	var is_boosting = Input.is_action_pressed("boost") and boost_meter > 0

	boostEffectMesh.visible = is_boosting

	if is_boosting:
		max_speed *= 1.5
		boost_meter -= boost_consumption_rate * delta
		if boost_meter < 0:
			boost_meter = 0
		emit_signal("boost_meter_changed", boost_meter)

	if Input.is_action_just_pressed("drift"):
		if animation_player:
			animation_player.play("driftJump")

	if is_drifting:
		current_traction *= drift_traction_multiplier
		current_turn_speed *= drift_turn_multiplier
		max_speed *= 0.8
		if boost_meter < boost_capacity:
			boost_meter += boost_generation_rate * delta
			if boost_meter > boost_capacity:
				boost_meter = boost_capacity
			emit_signal("boost_meter_changed", boost_meter)

	# --- Rotation and Drifting Physics ---
	if velocity.length() > 0.5:
		rotate_y(turn_direction * current_turn_speed * delta)

	# Get forward/backward input
	var input_dir = 0.0
	var current_acceleration = acceleration
	if Input.is_action_pressed("forward"):
		input_dir = 1.0
	elif Input.is_action_pressed("reverse"):
		input_dir = -1.0
		current_acceleration = acceleration * 0.5
		max_speed = speed * 0.25
	
	# Apply engine force
	if is_boosting and input_dir > 0:
		velocity = -transform.basis.z * max_speed
	else:
		velocity += -transform.basis.z * input_dir * current_acceleration * delta
	
	# Apply friction
	velocity = velocity.move_toward(Vector3.ZERO, friction * delta)

	# Apply traction (makes the car slide)
	var forward_velocity = velocity.dot(-transform.basis.z)
	var lateral_velocity = velocity.dot(transform.basis.x)
	
	if is_drifting:
		if lateral_velocity > drift_threshold or lateral_velocity < -drift_threshold:
			_spawn_tire_mark()

	var desired_velocity = -transform.basis.z * forward_velocity
	desired_velocity += -transform.basis.x * lerp(lateral_velocity, 0.0, current_traction * delta)
	velocity = desired_velocity.limit_length(max_speed)
	
	# --- Wheel and Camera Updates ---
	_update_camera(turn_direction, is_boosting, delta)
	# Rotate wheels for steering
	for wheel in wheels_node.get_children():
		var target_rotation = turn_direction * steer_angle
		wheel.rotation.y = lerp(wheel.rotation.y, target_rotation, turn_speed * 5 * delta)

	move_and_slide()

	if _time_since_collision >= collision_cooldown:
		for i in get_slide_collision_count():
			var collision = get_slide_collision(i)
			if collision:
				print("Collision detected!")
				if animation_player:
					animation_player.play("shake")
				_time_since_collision = 0.0 # Reset timer
				break # Exit loop after first valid collision

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


func _update_camera(_turn_direction, is_boosting, delta):
	# Camera Sway
	#var target_sway = -turn_direction * sway_strength
	#camera.rotation.z = lerp(camera.rotation.z, target_sway, sway_speed * delta)

	# FOV effect based on speed
	var speed_ratio = velocity.length() / speed
	var target_fov = initial_fov + speed_ratio * max_fov_increase
	if is_boosting:
		target_fov += boost_fov_increase
	camera.fov = lerp(camera.fov, target_fov, fov_change_speed * delta)
