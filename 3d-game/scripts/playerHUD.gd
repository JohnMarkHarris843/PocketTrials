extends Control

@onready var time_label: Label = $timerContainer/Label
# In playerHUD.gd

@onready var boost_bar = $boostNode/boostBar # Or whatever your progress bar is named

func _ready():
	# Set initial value
	boost_bar.max_value = 100
	boost_bar.value = 0

# This function is called when the car emits the 'boost_meter_changed' signal
func _on_boost_meter_changed(value):
	boost_bar.value = value

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
