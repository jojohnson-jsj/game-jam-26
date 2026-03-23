extends Node2D

var gacha = load("res://scripts/gacha_logic.gd").new()

func _ready():
	#pass
	$GameWorld.visible = false
	$GameWorld.process_mode = Node.PROCESS_MODE_DISABLED
	$StartMenu.visible = true
	$StartMenu.process_mode = Node.PROCESS_MODE_ALWAYS
	##$StartMenu/Music.stop()
	#gacha.debug_pull(20)
	#GameManager.set_queue_origin($GameWorld/QueueOrigin.global_position)
	#GameManager.set_door_point($GameWorld/DoorPoint.global_position)
	#GameManager.start_day()
