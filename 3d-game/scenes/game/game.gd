extends Node3D

func _ready() -> void:
	_spawn_selected_car()

	# Safely connect HUD boost meter (if HUD and Car exist)
	var car_node := get_node_or_null("Car")
	if car_node:
		var hud_node := get_node_or_null("HUD")
		if hud_node:
			var boost_callable := Callable(hud_node, "_on_boost_meter_changed")
			if not car_node.is_connected("boost_meter_changed", boost_callable):
				car_node.connect("boost_meter_changed", boost_callable)
				print("[Game] Connected Car.boost_meter_changed -> HUD._on_boost_meter_changed")
			else:
				print("[Game] Car.boost_meter_changed already connected to HUD")
		else:
			print("Warning: HUD node not found; boost meter will not be connected.")
	else:
		print("Warning: Car node not found after spawn; HUD connection skipped.")

	# Find the finish trigger and start the race (must be inside _ready)
	var finish_trigger := get_node_or_null("FinishLine/FinishTrigger")
	# fallback paths if your node is named differently:
	if finish_trigger == null:
		if has_node("FinishLine/FinishTrigger"):
			finish_trigger = $FinishLine/FinishTrigger
		elif has_node("FinishLine/FinishTrigger"):
			finish_trigger = $FinishLineWor/FinishTrigger

	if finish_trigger:
		if finish_trigger.has_method("start_race"):
			finish_trigger.start_race()
			print("[Game] Called start_race() on FinishTrigger")
		else:
			print("Warning: finish_trigger exists but has no start_race() method.")

		# connect finished signal to handler using a Callable
		if finish_trigger.has_signal("finished"):
			var finished_callable := Callable(self, "_on_FinishTrigger_finished")
			if not finish_trigger.is_connected("finished", finished_callable):
				finish_trigger.connect("finished", finished_callable)
				print("[Game] Connected FinishTrigger.finished -> _on_FinishTrigger_finished")
			else:
				print("[Game] FinishTrigger.finished already connected")
		else:
			print("Warning: finish_trigger has no 'finished' signal.")
	else:
		print("ERROR: FinishTrigger node not found. Expected path tried: FinishLineWor/FinishTrigger or FinishLine/FinishTrigger")


func _spawn_selected_car() -> void:
	# If we have a selection in the RaceManager, use it
	if RaceManager.selected_car_scene != "":
		var car_scene := load(RaceManager.selected_car_scene) as PackedScene
		if car_scene:
			var existing_car := get_node_or_null("Car")
			var spawn_transform := Transform3D.IDENTITY

			if existing_car:
				spawn_transform = existing_car.transform
				existing_car.name = "OldCar"
				existing_car.queue_free()

			# instantiate and cast to Node3D (explicit typing avoids inference error)
			var new_car: Node3D = car_scene.instantiate() as Node3D
			if not new_car:
				print("Error: instantiated car is not a Node3D - check the scene at: ", RaceManager.selected_car_scene)
				return

			new_car.name = "Car"
			new_car.transform = spawn_transform
			add_child(new_car)
			new_car.add_to_group("player")   # <-- ensure trigger detects it
			print("[Game] Spawned new car and added to 'player' group:", new_car.get_path())
		else:
			print("Error: failed to load car scene: ", RaceManager.selected_car_scene)
	else:
		print("No selected car in RaceManager.selected_car_scene")


func _on_FinishTrigger_finished(time_seconds: float) -> void:
	print("[Game] Finished in ", String("{:.2f}".format(time_seconds)), " s")
	# store result for end screen (RaceManager should be an autoload)
	RaceManager.last_time = time_seconds

	# change to the end screen (adjust path if necessary)
	var end_path := "res://scenes/end_screen.tscn"
	if ResourceLoader.exists(end_path):
		get_tree().change_scene_to_file(end_path)
	else:
		print("Warning: end screen not found at ", end_path)
