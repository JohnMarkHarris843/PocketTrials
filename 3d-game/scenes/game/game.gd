extends Node3D

func _ready():
	_spawn_selected_car()
	$Car.boost_meter_changed.connect($HUD._on_boost_meter_changed)

func _spawn_selected_car():
	# If we have a selection in the RaceManager, use it
	if RaceManager.selected_car_scene != "":
		var car_scene = load(RaceManager.selected_car_scene)
		if car_scene:
			var existing_car = get_node_or_null("Car")
			var spawn_transform = Transform3D()
			
			if existing_car:
				spawn_transform = existing_car.transform
				existing_car.name = "OldCar"
				existing_car.queue_free()
			
			var new_car = car_scene.instantiate()
			new_car.name = "Car"
			new_car.transform = spawn_transform
			add_child(new_car)
