extends Area3D

signal finished(time_seconds)

var race_start_time := 0.0
var race_started := false

func start_race() -> void:
	race_started = true
	race_start_time = Time.get_ticks_msec()

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if not race_started:
		return

	if body.name == "Car":
		race_started = false  # prevent double endings
		var elapsed_ms = Time.get_ticks_msec() - race_start_time
		var elapsed_sec = float(elapsed_ms) / 1000.0
		emit_signal("finished", elapsed_sec)
