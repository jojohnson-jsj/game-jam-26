extends Node2D

func _ready():
	GameManager.start_day()
	GameManager.set_queue_origin($QueueOrigin.global_position)
