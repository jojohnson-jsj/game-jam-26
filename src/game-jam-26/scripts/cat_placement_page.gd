extends Control

const INTERACT_SFX = preload("res://assets/sound assests/interact-sound.mp3")

var selected_cat_id: String = ""
var _place_btn: Button = null
var _selected_label: Label = null
var _active_beds: Array = []
var _cat_buttons: Dictionary = {}  # cat_id -> Button
var _in_placement_mode: bool = false
var _all_cats_unlocked: bool = false
var _original_cats: Dictionary = {}
var _unlock_btn: Button = null

const BROWN      = Color(0.45, 0.28, 0.12, 1.0)
const CREAM      = Color(0.98, 0.95, 0.88, 1.0)
const CREAM_DARK = Color(0.88, 0.82, 0.70, 1.0)
const TEXT_DARK  = Color(0.28, 0.15, 0.05, 1.0)
const TEXT_MID   = Color(0.45, 0.28, 0.12, 0.6)

const CAT_IDS = [
	'qr_cat', 'hermes_cat', 'money_cat', 'host_cat', 'hopper_cat',
	'nihao_cat', 'counter_cat', 'trash_cat', 'patience_cat', 'cooking_cat',
	'quality_control_cat', 'cheetah_cat', 'pretty_cat', 'valentines_cat',
	'fat_cat', 'sign_spinner_cat', 'ankle_biter_cat', 'reccomendation_cat'
]

func _make_style(bg: Color = CREAM) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = BROWN
	s.set_border_width_all(2)
	s.set_corner_radius_all(3)
	s.set_content_margin_all(0)
	return s

func _ready():
	# Dark overlay
	var bg := ColorRect.new()
	bg.color = Color(0.08, 0.04, 0.02, 0.88)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# Centered panel
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _make_style())
	panel.custom_minimum_size = Vector2(520, 0)
	center.add_child(panel)

	var outer := MarginContainer.new()
	for s in ["margin_top","margin_bottom","margin_left","margin_right"]:
		outer.add_theme_constant_override(s, 20)
	panel.add_child(outer)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	outer.add_child(vbox)

	# Title
	var title := Label.new()
	title.text = "MY CATS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", BROWN)
	vbox.add_child(title)

	var div := ColorRect.new()
	div.color = Color(BROWN, 0.3)
	div.custom_minimum_size = Vector2(0, 2)
	vbox.add_child(div)

	# Cat grid
	var grid := GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(grid)

	for cat_id in CAT_IDS:
		var card := _make_cat_card(cat_id)
		grid.add_child(card)
		_cat_buttons[cat_id] = card

	var div2 := ColorRect.new()
	div2.color = Color(BROWN, 0.3)
	div2.custom_minimum_size = Vector2(0, 2)
	vbox.add_child(div2)

	# Footer
	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 10)
	vbox.add_child(footer)

	_selected_label = Label.new()
	_selected_label.text = "Select a cat to place"
	_selected_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_selected_label.add_theme_color_override("font_color", TEXT_DARK)
	footer.add_child(_selected_label)

	_place_btn = _make_btn("Place")
	_place_btn.visible = false
	_place_btn.pressed.connect(_on_place_pressed)
	footer.add_child(_place_btn)

	var close_btn := _make_btn("Close")
	close_btn.pressed.connect(_on_exit_pressed)
	footer.add_child(close_btn)

	# Debug toggle — unlock all cats for QA testing
	_unlock_btn = _make_btn("Unlock All (Debug)")
	_unlock_btn.pressed.connect(_on_unlock_all_pressed)
	footer.add_child(_unlock_btn)

	_update_cat_buttons()


const CAT_DESCRIPTIONS = {
	'qr_cat':              "Click seated customers to take their order",
	'hermes_cat':          "Grants you a dash ability (press Shift to use)",
	'money_cat':           "Automatically collects money so you don't have to",
	'host_cat':            "Click waiting groups so that the host can seat them instantly",
	'hopper_cat':          "Queue an extra order into a machine so you can load it and walk away",
	'nihao_cat':           "She makes the day last longer through her love and whimsy",
	'counter_cat':         "Unlocks the countertop plates — drop off a finished dish and come back for it later!",
	'patience_cat':        "Customers absorb his serenity, and find they have more patience than before",
	'cooking_cat':         "Decreases cooking time so dishes are ready faster",
	'quality_control_cat': "He will only take the highest of quality items, your items sell for more",
	'cheetah_cat':         "Helps the player get around faster (base speed increase)",
	'pretty_cat':          "Makes your customers more generous with their tips, as they get to look at her",
	'valentines_cat':      "Less single people find their way to your cafe (more pairs or groups)",
	'fat_cat':             "Eats customers' food so they eat faster",
	'sign_spinner_cat':    "Spreads awareness so more customers come to your cafe!",
	'ankle_biter_cat':     "Nips at your customers' heels, making them walk faster",
	'reccomendation_cat':  "Customers order faster when this cat is pawing at the menu",
	'trash_cat':           "Click the trash can to discard inventory rather than walking to it",
	
}

func _format_cat_name(cat_id: String) -> String:
	const NAMES = {
		'qr_cat': 'QR', 'hermes_cat': 'Hermes', 'money_cat': 'Money',
		'host_cat': 'Host', 'hopper_cat': 'Hopper', 'nihao_cat': 'Nihao',
		'counter_cat': 'Counter', 'trash_cat': 'Trash', 'patience_cat': 'Patience',
		'cooking_cat': 'Cooking', 'quality_control_cat': 'Inspector',
		'cheetah_cat': 'Cheetah', 'pretty_cat': 'Pretty', 'valentines_cat': 'Valentines',
		'fat_cat': 'Fat', 'sign_spinner_cat': 'Sign Spinner',
		'ankle_biter_cat': 'Ankle Biter', 'reccomendation_cat': 'Recommender'
	}
	return NAMES.get(cat_id, cat_id.replace("_cat", "").replace("_", " ").capitalize())


func _make_cat_card(cat_id: String) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(90, 90)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var sn := _make_style(CREAM_DARK); sn.set_content_margin_all(6)
	var sh := _make_style(CREAM); sh.set_content_margin_all(6)
	var sd := _make_style(Color(0.75, 0.72, 0.68)); sd.set_content_margin_all(6)
	btn.add_theme_stylebox_override("normal",   sn)
	btn.add_theme_stylebox_override("hover",    sh)
	btn.add_theme_stylebox_override("pressed",  sh)
	btn.add_theme_stylebox_override("disabled", sd)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	btn.add_child(center)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 4)
	center.add_child(vbox)

	var sprite_path = CatBed.CAT_SPRITES.get(cat_id)
	if sprite_path:
		var tex := TextureRect.new()
		tex.texture = sprite_path
		tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		tex.custom_minimum_size = Vector2(40, 40)
		tex.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		vbox.add_child(tex)

	var lbl := Label.new()
	lbl.text = _format_cat_name(cat_id)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 9)
	lbl.add_theme_color_override("font_color", TEXT_DARK)
	lbl.autowrap_mode = TextServer.AUTOWRAP_OFF
	lbl.clip_text = false
	vbox.add_child(lbl)

	btn.pressed.connect(_on_cat_selected.bind(cat_id))
	btn.tooltip_text = CAT_DESCRIPTIONS.get(cat_id, "")
	return btn


func _make_btn(text: String) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(80, 32)
	var sn := _make_style(CREAM); sn.set_content_margin_all(6)
	var sh := _make_style(CREAM_DARK); sh.set_content_margin_all(6)
	btn.add_theme_stylebox_override("normal",  sn)
	btn.add_theme_stylebox_override("hover",   sh)
	btn.add_theme_stylebox_override("pressed", sh)
	btn.add_theme_color_override("font_color", TEXT_DARK)
	return btn


func open():
	$"../".visible = true
	$"../".process_mode = Node.PROCESS_MODE_ALWAYS
	var game_world = get_tree().root.get_node_or_null("Main/GameWorld")
	if game_world and game_world.has_method("_apply_equipment_unlocks"):
		game_world._apply_equipment_unlocks()
	_update_cat_buttons()


func _update_cat_buttons():
	for cat_id in CAT_IDS:
		var btn = _cat_buttons.get(cat_id)
		if not btn:
			continue
		var owned = GlobalInventory.owns_cat(cat_id)
		var placed = GlobalInventory.is_placed(cat_id)
		btn.disabled = not owned
		if placed:
			btn.modulate = Color(0.8, 1.0, 0.8)
		elif owned:
			btn.modulate = Color(1, 1, 1)
		else:
			btn.modulate = Color(0.5, 0.5, 0.5, 0.7)


func _on_cat_selected(cat_id: String):
	SoundManager.play_sfx(INTERACT_SFX)
	selected_cat_id = cat_id
	_selected_label.text = "Selected: " + _format_cat_name(cat_id)
	if GlobalInventory.is_placed(cat_id):
		_place_btn.text = "Remove"
	else:
		_place_btn.text = "Place"
	_place_btn.visible = true
	_exit_placement_mode()
	for id in _cat_buttons:
		var btn = _cat_buttons[id]
		if id == cat_id:
			var s := _make_style(CREAM); s.set_content_margin_all(6)
			btn.add_theme_stylebox_override("normal", s)
			btn.add_theme_color_override("font_color", TEXT_DARK)
		else:
			var s := _make_style(CREAM_DARK); s.set_content_margin_all(6)
			btn.add_theme_stylebox_override("normal", s)
			btn.add_theme_color_override("font_color", TEXT_DARK)


func _on_place_pressed():
	SoundManager.play_sfx(INTERACT_SFX)
	if selected_cat_id == "":
		return

	# Remove path
	if GlobalInventory.is_placed(selected_cat_id):
		for bed in get_tree().get_nodes_in_group("cat_beds"):
			if bed.assigned_cat and bed.assigned_cat.cat_name == selected_cat_id:
				bed.remove_cat()
		_selected_label.text = "Removed!"
		_place_btn.text = "Place"
		_update_cat_buttons()
		return

	var def = CatBed.CAT_DEFINITIONS.get(selected_cat_id, {})
	if def.is_empty():
		return

	_exit_placement_mode()
	var all_beds = get_tree().get_nodes_in_group("cat_beds")
	for bed in all_beds:
		if not bed.unlocked:
			bed.modulate = Color(0.3, 0.3, 0.3)
			_active_beds.append(bed)
			continue
		bed.enter_placement_mode(_on_bed_clicked)
		_active_beds.append(bed)

	if _active_beds.is_empty():
		_selected_label.text = "No valid beds available!"
		return

	var game_world = get_tree().root.get_node("Main/GameWorld")
	game_world.visible = true
	game_world.process_mode = Node.PROCESS_MODE_ALWAYS
	self.modulate.a = 0.0
	self.mouse_filter = Control.MOUSE_FILTER_IGNORE
	self.process_mode = Node.PROCESS_MODE_ALWAYS
	_in_placement_mode = true
	for cat_id in _cat_buttons:
		_cat_buttons[cat_id].tooltip_text = ""


func _on_bed_clicked(bed):
	_exit_placement_mode()
	for other_bed in get_tree().get_nodes_in_group("cat_beds"):
		if other_bed.assigned_cat and other_bed.assigned_cat.cat_name == selected_cat_id:
			other_bed.remove_cat()
	var def = CatBed.CAT_DEFINITIONS.get(selected_cat_id, {})
	var cat = Cat.new()
	cat.cat_name = selected_cat_id
	cat.cat_type = def.get("cat_type", Cat.CatType.NON_TABLE)
	cat.ability_type = def.get("ability_type", Cat.AbilityType.NONE)
	if bed.assigned_cat:
		bed.remove_cat()
	bed.assign_cat(cat)
	var game_world = get_tree().root.get_node("Main/GameWorld")
	game_world.visible = false
	game_world.process_mode = Node.PROCESS_MODE_DISABLED
	self.modulate.a = 1.0
	self.mouse_filter = Control.MOUSE_FILTER_STOP
	self.visible = true
	_in_placement_mode = false
	for cat_id in _cat_buttons:
		_cat_buttons[cat_id].tooltip_text = CAT_DESCRIPTIONS.get(cat_id, "")
	_selected_label.text = "Placed!"
	_place_btn.text = "Remove"
	_place_btn.visible = true
	_update_cat_buttons()


func _exit_placement_mode():
	for bed in _active_beds:
		if is_instance_valid(bed):
			bed.exit_placement_mode()
			bed.modulate = Color(1, 1, 1)
	_active_beds.clear()


func _on_unlock_all_pressed() -> void:
	_all_cats_unlocked = not _all_cats_unlocked
	if _all_cats_unlocked:
		_original_cats.clear()
		for cat_id in CAT_IDS:
			_original_cats[cat_id] = GlobalInventory.cats[cat_id].duplicate()
			GlobalInventory.add_cat(cat_id)
		for bed in get_tree().get_nodes_in_group("cat_beds"):
			bed.set_unlocked(true)
	else:
		for cat_id in CAT_IDS:
			if _original_cats.has(cat_id):
				GlobalInventory.cats[cat_id] = _original_cats[cat_id].duplicate()
		# Restore bed unlock state from equipment_amt
		var game_world = get_tree().root.get_node_or_null("Main/GameWorld")
		if game_world and game_world.has_method("_apply_equipment_unlocks"):
			game_world._apply_equipment_unlocks()
	_update_cat_buttons()
	_unlock_btn.text = "Lock All (Debug)" if _all_cats_unlocked else "Unlock All (Debug)"


func is_in_placement_mode() -> bool:
	return _in_placement_mode

func cancel_placement() -> void:
	_in_placement_mode = false
	_exit_placement_mode()
	for cat_id in _cat_buttons:
		_cat_buttons[cat_id].tooltip_text = CAT_DESCRIPTIONS.get(cat_id, "")
	var game_world = get_tree().root.get_node("Main/GameWorld")
	game_world.visible = false
	game_world.process_mode = Node.PROCESS_MODE_DISABLED
	self.modulate.a = 1.0
	self.mouse_filter = Control.MOUSE_FILTER_STOP
	self.visible = true

func _on_exit_pressed() -> void:
	SoundManager.play_sfx(INTERACT_SFX)
	selected_cat_id = ""
	_place_btn.visible = false
	_exit_placement_mode()
	$"../../StartMenu".visible = true
	$"../../StartMenu".process_mode = Node.PROCESS_MODE_ALWAYS
	$"../".visible = false
	$"../".process_mode = Node.PROCESS_MODE_DISABLED
