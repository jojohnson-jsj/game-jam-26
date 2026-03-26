extends Control

const GACHA_SCENE = preload("res://scenes/GachaController.tscn")
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

func _on_adpot_one_pressed() -> void:
	visible = false
	#TODO ADD LOGIC TO CHECK FUNDS
	var gacha_instance = GACHA_SCENE.instantiate()
	gacha_instance.visible = true
	gacha_instance.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(gacha_instance)
	
func _on_exit_pressed() -> void:
	$"../../StartMenu".visible = true
	$"../../StartMenu".process_mode = Node.PROCESS_MODE_ALWAYS
	$"../".visible = false
	$"../".process_mode = Node.PROCESS_MODE_DISABLED
