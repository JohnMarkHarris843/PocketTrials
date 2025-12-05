extends Node3D

func _ready():
	$Car.boost_meter_changed.connect($HUD._on_boost_meter_changed)
