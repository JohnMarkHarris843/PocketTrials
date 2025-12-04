extends Control

@onready var time_label: Label = $MarginContainer/Label

var elapsed_time: float = 0.0
var is_running: bool = true # Set to false to pause the timer

func _process(delta: float):
	if is_running:
		elapsed_time += delta
	
	# Floor to get whole seconds and milliseconds
	var seconds = floori(elapsed_time)
	var milliseconds = floori((elapsed_time - seconds) * 1000)
	
	# Format the string with leading zeros and update the label
	time_label.text = "%02d:%03d" % [seconds, milliseconds]

# You can call these functions from other scripts to control the timer
func start_timer():
	is_running = true

func stop_timer():
	is_running = false

func reset_timer():
	elapsed_time = 0.0
