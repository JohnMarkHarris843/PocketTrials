# res://scripts/RaceManager.gd
extends Node

# selected car scene path (example usage)
var selected_car_scene: String = ""

# last_time recorded at race end in seconds
var last_time: float = 0.0

# NEW: track identifier for highscores (forest, desert, etc.)
var last_track: String = ""

# optional helper
func set_last_time(t: float) -> void:
	last_time = t
