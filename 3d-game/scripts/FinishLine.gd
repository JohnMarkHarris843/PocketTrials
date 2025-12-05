extends Area3D
signal finished(body)

func _ready() -> void:
	connect("body_entered", Callable(self, "_on_body_entered"))

func _on_body_entered(body: Node) -> void:
	if body.name == "Car":
		emit_signal("finished", body)
