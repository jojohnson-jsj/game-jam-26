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

func _on_oven_buy_button_pressed() -> void:
	var ovenBuyButton = $"Websites/Hardware,com/ScrollContainer/VBoxContainer/Oven Unlocks/buyOven"
	if (GlobalInventory.unlock_equipment("oven") == 4):
		ovenBuyButton.disabled = true
		ovenBuyButton.text = "SOLD"	

func _on_buy_latte_pressed() -> void:
	var latteBuyButton = $"Websites/Hardware,com/ScrollContainer/VBoxContainer/Latte Unlocks/buyLatte"
	if (GlobalInventory.unlock_equipment("latte_machine") == 4):
		latteBuyButton.disabled = true
		latteBuyButton.text = "SOLD"	

func _on_buy_catbed_pressed() -> void:
	var catBedBuyButton = $"Websites/Hardware,com/ScrollContainer/VBoxContainer/Catbed Unlock/buyCatbed"
	if (GlobalInventory.unlock_equipment("cat_bed") == 7):
		catBedBuyButton.disabled = true
		catBedBuyButton.text = "SOLD"	
