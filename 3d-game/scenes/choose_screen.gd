extends Control

var worldSelected = "forest"


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_play_button_pressed() -> void:
	if worldSelected == "forest":
		get_tree().change_scene_to_file("res://scenes/game/game.tscn")
	if worldSelected == "desert":
		get_tree().change_scene_to_file("res://scenes/game/game_desert.tscn")
	


func _on_select_forest_pressed() -> void:
	worldSelected = "forest"


func _on_select_desert_pressed() -> void:
	worldSelected = "desert"
