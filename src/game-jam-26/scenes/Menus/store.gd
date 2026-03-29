extends Control

const GACHA_SCENE = preload("res://scenes/GachaController.tscn")

var _money_label: Label
var _day_label: Label

func _ready() -> void:
	_build_info_panel()
	Wallet.money_changed.connect(_on_money_changed)

func _build_info_panel() -> void:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_top", 45)
	margin.add_theme_constant_override("margin_right", 43)
	margin.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	margin.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	add_child(margin)

	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color     = Color(0.98, 0.95, 0.88, 1.0)
	style.border_color = Color(0.45, 0.28, 0.12, 1.0)
	style.set_border_width_all(2)
	style.set_corner_radius_all(3)
	style.set_content_margin_all(0)
	panel.add_theme_stylebox_override("panel", style)
	margin.add_child(panel)

	var inner := MarginContainer.new()
	inner.add_theme_constant_override("margin_top", 5)
	inner.add_theme_constant_override("margin_bottom", 5)
	inner.add_theme_constant_override("margin_left", 12)
	inner.add_theme_constant_override("margin_right", 12)
	panel.add_child(inner)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	inner.add_child(hbox)

	_day_label = Label.new()
	_day_label.text = "DAY %d" % GlobalInventory.day
	_day_label.add_theme_color_override("font_color", Color(0.28, 0.15, 0.05))
	hbox.add_child(_day_label)

	var sep := Label.new()
	sep.text = "|"
	sep.add_theme_color_override("font_color", Color(0.45, 0.28, 0.12, 0.5))
	hbox.add_child(sep)

	var coin := TextureRect.new()
	coin.texture = load("res://assets/Misc/coin.png")
	coin.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	coin.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	coin.custom_minimum_size = Vector2(26, 32)
	hbox.add_child(coin)

	_money_label = Label.new()
	_money_label.text = "$%.0f" % Wallet.money_owned
	_money_label.add_theme_color_override("font_color", Color(0.28, 0.15, 0.05))
	_money_label.custom_minimum_size = Vector2(40, 0)
	hbox.add_child(_money_label)

func _on_money_changed(amount: float) -> void:
	if _money_label:
		_money_label.text = "$%.0f" % amount
	if _day_label:
		_day_label.text = "DAY %d" % GlobalInventory.day

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
