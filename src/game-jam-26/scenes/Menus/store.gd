extends Control

const GACHA_SCENE = preload("res://scenes/GachaController.tscn")
# Called when the node enters the scene tree for the first time.
@onready var oven = $"Websites/Hardware,com/ScrollContainer/VBoxContainer/Oven Unlocks"
@onready var latte = $"Websites/Hardware,com/ScrollContainer/VBoxContainer/Latte Unlocks"
@onready var catBed = $"Websites/Hardware,com/ScrollContainer/VBoxContainer/Catbed Unlock"

func _ready() -> void:
	oven.get_node("VBoxContainer/NumOwn").text = "Number Owned: " + str(GlobalInventory.equipment_amt("oven"))
	oven.get_node("VBoxContainer/Price").text = "Price: " + str(300 + 50*GlobalInventory.equipment_amt("oven"))
	
	latte.get_node("VBoxContainer/NumOwn").text = "Number Owned: " + str(GlobalInventory.equipment_amt("latte_machine"))
	latte.get_node("VBoxContainer/Price").text = "Price: " + str(250 + 25*GlobalInventory.equipment_amt("latte_machine"))
	
	catBed.get_node("VBoxContainer/NumOwn").text = "Number Owned: " + str(GlobalInventory.equipment_amt("cat_bed"))
	catBed.get_node("VBoxContainer/Price").text = "Price: " + str(30 + 100*GlobalInventory.equipment_amt("cat_bed"))
	
func _on_adpot_one_pressed() -> void:
	visible = false
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
	var ovenBuyButton = oven.get_node("buyOven")
	var ovenLabelCont = oven.get_node("VBoxContainer")
	
	var amt = GlobalInventory.unlock_equipment("oven")
	print(amt)
	ovenLabelCont.get_node("NumOwn").text = "Number Owned: " + str(amt)
	
	if (amt == 4):
		ovenBuyButton.disabled = true
		ovenBuyButton.text = "SOLD"	
		ovenLabelCont.get_node("Price").text = "Price: SOLD OUT"
		return
		
	ovenLabelCont.get_node("Price").text = "Price: " + str(int(ovenLabelCont.get_node("Price").text)+50)

func _on_buy_latte_pressed() -> void:
	var latteBuyButton = latte.get_node("buyLatte")
	if (GlobalInventory.unlock_equipment("latte_machine") == 4):
		latteBuyButton.disabled = true
		latteBuyButton.text = "SOLD"	

func _on_buy_catbed_pressed() -> void:
	var catBedBuyButton = catBed.get_node("buyCatbed")
	if (GlobalInventory.unlock_equipment("cat_bed") == 7):
		catBedBuyButton.disabled = true
		catBedBuyButton.text = "SOLD"	
