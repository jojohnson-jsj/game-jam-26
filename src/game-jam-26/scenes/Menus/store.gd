extends Control

const GACHA_SCENE = preload("res://scenes/GachaController.tscn")

var _money_label: Label
var _day_label: Label
var _active_tab: int = 0
var _tab_contents: Array = []
var _tab_buttons: Array = []
var _item_rows: Array = []  # [{price_lbl, buy_btn, owned_lbl, item}]

const BROWN       = Color(0.45, 0.28, 0.12, 1.0)
const CREAM       = Color(0.98, 0.95, 0.88, 1.0)
const CREAM_DARK  = Color(0.88, 0.82, 0.70, 1.0)
const TEXT_DARK   = Color(0.28, 0.15, 0.05, 1.0)
const TEXT_MID    = Color(0.45, 0.28, 0.12, 0.6)

const HARDWARE_ITEMS = [
	{"key": "oven",          "label": "Oven",          "desc": "Unlocks more ovens",          "base_price": 300, "price_step": 50,  "max": 4},
	{"key": "latte_machine", "label": "Latte Machine", "desc": "Unlocks more latte machines", "base_price": 225, "price_step": 25,  "max": 4},
	{"key": "cat_bed",       "label": "Cat Bed",       "desc": "Adds a cat bed slot",  "base_price": -70,  "price_step": 100, "max": 7},
]

func _get_price(item: Dictionary) -> int:
	return item.base_price + item.price_step * GlobalInventory.equipment_amt(item.key)

func _ready() -> void:
	_build_ui()
	Wallet.money_changed.connect(_on_money_changed)

func _make_style(bg: Color = CREAM) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = BROWN
	s.set_border_width_all(2)
	s.set_corner_radius_all(3)
	s.set_content_margin_all(0)
	return s

func _make_button(text: String, min_w: float = 180) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(min_w, 36)
	var sn := _make_style(CREAM); sn.set_content_margin_all(6)
	var sh := _make_style(CREAM_DARK); sh.set_content_margin_all(6)
	var sd := _make_style(Color(0.85, 0.82, 0.76)); sd.set_content_margin_all(6)
	btn.add_theme_stylebox_override("normal",   sn)
	btn.add_theme_stylebox_override("hover",    sh)
	btn.add_theme_stylebox_override("pressed",  sh)
	btn.add_theme_stylebox_override("disabled", sd)
	btn.add_theme_color_override("font_color",          TEXT_DARK)
	btn.add_theme_color_override("font_disabled_color", TEXT_MID)
	return btn

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.08, 0.04, 0.02, 0.88)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _make_style())
	panel.custom_minimum_size = Vector2(480, 360)
	center.add_child(panel)

	var outer := MarginContainer.new()
	for s in ["margin_top","margin_bottom","margin_left","margin_right"]:
		outer.add_theme_constant_override(s, 20)
	panel.add_child(outer)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	outer.add_child(vbox)

	# Header
	var header := HBoxContainer.new()
	vbox.add_child(header)

	var title := Label.new()
	title.text = "SHOP"
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", BROWN)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	var info_hbox := HBoxContainer.new()
	info_hbox.add_theme_constant_override("separation", 8)
	header.add_child(info_hbox)

	_day_label = Label.new()
	_day_label.text = "DAY %d" % GlobalInventory.day
	_day_label.add_theme_color_override("font_color", TEXT_DARK)
	info_hbox.add_child(_day_label)

	var sep := Label.new()
	sep.text = "|"
	sep.add_theme_color_override("font_color", TEXT_MID)
	info_hbox.add_child(sep)

	var coin := TextureRect.new()
	coin.texture = load("res://assets/Misc/coin.png")
	coin.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	coin.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	coin.custom_minimum_size = Vector2(22, 22)
	info_hbox.add_child(coin)

	_money_label = Label.new()
	_money_label.text = "$%.0f" % Wallet.money_owned
	_money_label.add_theme_color_override("font_color", TEXT_DARK)
	_money_label.custom_minimum_size = Vector2(40, 0)
	info_hbox.add_child(_money_label)

	# Tabs
	var tab_row := HBoxContainer.new()
	tab_row.add_theme_constant_override("separation", 6)
	vbox.add_child(tab_row)

	for i in range(2):
		var tb := _make_button(["Hardware", "AdoptCat"][i], 0)
		tb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tb.pressed.connect(_on_tab_pressed.bind(i))
		tab_row.add_child(tb)
		_tab_buttons.append(tb)

	var div := ColorRect.new()
	div.color = Color(BROWN, 0.3)
	div.custom_minimum_size = Vector2(0, 2)
	vbox.add_child(div)

	# Content area
	var content_area := Control.new()
	content_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_area.custom_minimum_size = Vector2(0, 220)
	vbox.add_child(content_area)

	# Hardware tab
	var hw_scroll := ScrollContainer.new()
	hw_scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content_area.add_child(hw_scroll)

	var hw_vbox := VBoxContainer.new()
	hw_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hw_vbox.add_theme_constant_override("separation", 8)
	hw_scroll.add_child(hw_vbox)

	for item in HARDWARE_ITEMS:
		hw_vbox.add_child(_make_item_row(item))

	_tab_contents.append(hw_scroll)

	# Adopt tab
	var adopt_panel := Control.new()
	adopt_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	adopt_panel.visible = false
	content_area.add_child(adopt_panel)

	var adopt_center := CenterContainer.new()
	adopt_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	adopt_panel.add_child(adopt_center)

	var adopt_card := PanelContainer.new()
	adopt_card.add_theme_stylebox_override("panel", _make_style(CREAM_DARK))
	adopt_center.add_child(adopt_card)

	var adopt_inner := MarginContainer.new()
	for s in ["margin_top","margin_bottom","margin_left","margin_right"]:
		adopt_inner.add_theme_constant_override(s, 16)
	adopt_card.add_child(adopt_inner)

	var adopt_vbox := VBoxContainer.new()
	adopt_vbox.add_theme_constant_override("separation", 10)
	adopt_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	adopt_inner.add_child(adopt_vbox)

	var adopt_title := Label.new()
	adopt_title.text = "Adopt a Cat"
	adopt_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	adopt_title.add_theme_font_size_override("font_size", 16)
	adopt_title.add_theme_color_override("font_color", BROWN)
	adopt_vbox.add_child(adopt_title)

	var adopt_desc := Label.new()
	adopt_desc.text = "Pull from the gacha to get a new cat!\nCost: $%d" % GlobalInventory.PULL_COST
	adopt_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	adopt_desc.add_theme_color_override("font_color", TEXT_DARK)
	adopt_vbox.add_child(adopt_desc)

	var adopt_btn := _make_button("ADOPT  ($%d)" % GlobalInventory.PULL_COST, 200)
	adopt_btn.pressed.connect(_on_adopt_pressed)
	adopt_vbox.add_child(adopt_btn)

	_tab_contents.append(adopt_panel)

	# Footer
	var footer_div := ColorRect.new()
	footer_div.color = Color(BROWN, 0.3)
	footer_div.custom_minimum_size = Vector2(0, 2)
	vbox.add_child(footer_div)

	var leave_btn := _make_button("Leave", 120)
	leave_btn.pressed.connect(_on_exit_pressed)
	var footer := HBoxContainer.new()
	footer.alignment = BoxContainer.ALIGNMENT_END
	footer.add_child(leave_btn)
	vbox.add_child(footer)

	_refresh_tabs()

func _make_item_row(item: Dictionary) -> Control:
	var row := PanelContainer.new()
	row.add_theme_stylebox_override("panel", _make_style(CREAM_DARK))

	var inner := MarginContainer.new()
	for s in ["margin_top","margin_bottom","margin_left","margin_right"]:
		inner.add_theme_constant_override(s, 10)
	row.add_child(inner)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	inner.add_child(hbox)

	var icon_tex = GameManager.get_machine_sprite(item.key)
	if icon_tex:
		var icon := TextureRect.new()
		icon.texture = icon_tex
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon.custom_minimum_size = Vector2(40, 40)
		hbox.add_child(icon)

	var text_vbox := VBoxContainer.new()
	text_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_vbox.add_theme_constant_override("separation", 2)
	hbox.add_child(text_vbox)

	var name_lbl := Label.new()
	name_lbl.text = item.label
	name_lbl.add_theme_color_override("font_color", TEXT_DARK)
	text_vbox.add_child(name_lbl)

	var desc_lbl := Label.new()
	desc_lbl.text = item.desc
	desc_lbl.add_theme_color_override("font_color", TEXT_MID)
	desc_lbl.add_theme_font_size_override("font_size", 11)
	text_vbox.add_child(desc_lbl)

	var owned_lbl := Label.new()
	owned_lbl.text = "Owned: %d / %d" % [GlobalInventory.equipment_amt(item.key), item.max]
	owned_lbl.add_theme_color_override("font_color", TEXT_MID)
	owned_lbl.add_theme_font_size_override("font_size", 11)
	text_vbox.add_child(owned_lbl)

	var right_vbox := VBoxContainer.new()
	right_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	right_vbox.add_theme_constant_override("separation", 4)
	hbox.add_child(right_vbox)

	var amt = GlobalInventory.equipment_amt(item.key)
	var at_max = amt >= item.max

	var price_lbl := Label.new()
	price_lbl.text = "SOLD OUT" if at_max else "$%d" % _get_price(item)
	price_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	price_lbl.add_theme_color_override("font_color", BROWN)
	right_vbox.add_child(price_lbl)

	var buy_btn := _make_button("BUY", 80)
	buy_btn.disabled = at_max
	if at_max:
		buy_btn.text = "MAX"
	buy_btn.pressed.connect(_on_buy_pressed.bind(item, buy_btn, price_lbl, owned_lbl))
	right_vbox.add_child(buy_btn)

	return row


func _refresh_tabs() -> void:
	for i in range(_tab_buttons.size()):
		var active = i == _active_tab
		var style = _make_style(BROWN if active else CREAM)
		style.set_content_margin_all(6)
		_tab_buttons[i].add_theme_stylebox_override("normal", style)
		_tab_buttons[i].add_theme_stylebox_override("hover",  style)
		_tab_buttons[i].add_theme_color_override("font_color", CREAM if active else TEXT_DARK)
		_tab_contents[i].visible = active


func _on_tab_pressed(idx: int) -> void:
	_active_tab = idx
	_refresh_tabs()


func _on_buy_pressed(item: Dictionary, btn: Button, price_lbl: Label, owned_lbl: Label) -> void:
	var price = _get_price(item)
	if not Wallet.remove_money(price):
		return
	GlobalInventory.unlock_equipment(item.key)
	var amt = GlobalInventory.equipment_amt(item.key)
	owned_lbl.text = "Owned: %d / %d" % [amt, item.max]
	if amt >= item.max:
		btn.text = "MAX"
		btn.disabled = true
		price_lbl.text = "SOLD OUT"
	else:
		price_lbl.text = "$%d" % _get_price(item)

func _on_adopt_pressed() -> void:
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


func _on_money_changed(amount: float) -> void:
	if _money_label:
		_money_label.text = "$%.0f" % amount
	if _day_label:
		_day_label.text = "DAY %d" % GlobalInventory.day
