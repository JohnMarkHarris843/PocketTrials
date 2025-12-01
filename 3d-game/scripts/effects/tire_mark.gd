extends Decal

@export var fade_out_time = 5.0
var life = 0.0

func _process(delta):
	life += delta
	if life < fade_out_time:
		var a = 1.0 - (life / fade_out_time)
		modulate.a = a
	else:
		queue_free()
