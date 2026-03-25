extends Node2D


func _ready():
	pass


func startDay():
	GameManager.set_queue_origin($QueueOrigin.global_position)
	GameManager.set_door_point($DoorPoint.global_position)
	GameManager.start_day()
