extends Control
@onready var titleAniPlayer = $AnimationPlayer2

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	titleAniPlayer.play("titleBounce")
	
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/game/game.tscn")

func _on_About_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/About.tscn")
	
func _on_controls_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/HowToPlay.tscn")


func _on_quit_button_pressed() -> void: 
	get_tree().quit()
	


func _on_about_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/about.tscn")
