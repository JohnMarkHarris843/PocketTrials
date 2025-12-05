extends Area3D
@export var checkpoint_id: int = 0
signal passed(checkpoint_id, body)

func _ready() -> void:
	connect("body_entered", Callable(self, "_on_body_entered"))

func _on_body_entered(body: Node) -> void:
	if body.name == "Car":
		emit_signal("passed", checkpoint_id, body)
