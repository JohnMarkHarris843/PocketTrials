extends CharacterBody3D

@export var speed = 10.0
@export var acceleration = 5.0
@export var friction = 3.0

func _physics_process(delta):
	# Get the car's forward direction
	var forward_direction = -transform.basis.z
	# Handle acceleration
	if Input.is_action_pressed("forward"):
		# Accelerate towards max speed
		print("Acceleration input detected")
		velocity = velocity.move_toward(forward_direction * speed, acceleration * delta)
	else:
		velocity = velocity.move_toward(Vector3.ZERO, friction * delta)

	move_and_slide()


# This function will print any key press the engine sends to it.
func _unhandled_input(event):
	if event is InputEventKey:
		print("Key Event Received: ", event.as_text())
