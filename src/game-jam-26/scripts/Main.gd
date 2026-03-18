extends Node2D

var gacha = load("res://scripts/gacha_logic.gd").new()

func _ready():
	gacha.debug_pull(20)
	GameManager.set_queue_origin($QueueOrigin.global_position)
	GameManager.set_door_point($DoorPoint.global_position)
	GameManager.start_day()
