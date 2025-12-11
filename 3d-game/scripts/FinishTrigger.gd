# res://scripts/FinishTrigger.gd
extends Area3D

signal finished(time_seconds)

var race_started: bool = false
var race_start_ms: int = 0

func _ready() -> void:
	# start disabled, enable when start_race() is called
	monitoring = false
	body_entered.connect(_on_body_entered)
	print("[FinishTrigger] ready() — monitoring set to false")

func start_race() -> void:
	race_started = true
	race_start_ms = Time.get_ticks_msec()
	# short delay prevents immediate triggering if overlapping at spawn
	await get_tree().create_timer(0.12).timeout
	monitoring = true
	print("[FinishTrigger] start_race called — monitoring=", monitoring, " race_start_ms=", race_start_ms)

func _on_body_entered(body: Node) -> void:
	# Keep this handler minimal and defer dangerous scene-tree changes
	print("[FinishTrigger] body_entered:", body.name, " class:", body.get_class(), " race_started=", race_started)
	if not race_started:
		return

	if body.is_in_group("player"):
		# compute elapsed time now, but defer the actual disabling & signal emission
		var elapsed_ms := Time.get_ticks_msec() - race_start_ms
		var elapsed_s := float(elapsed_ms) / 1000.0
		# defer the rest of the work to avoid 'Function blocked during in/out signal'
		call_deferred("_handle_finish_deferred", elapsed_s)

# deferred handler — runs after the current signal returns
func _handle_finish_deferred(elapsed_s: float) -> void:
	# safe to modify monitoring & other properties here
	race_started = false
	set_deferred("monitoring", false)   # set_deferred is safe for node properties
	print("[FinishTrigger] deferred finish handler — emitting finished(", elapsed_s, ")")
	emit_signal("finished", elapsed_s)
