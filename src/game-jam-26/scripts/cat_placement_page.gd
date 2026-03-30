extends Control

var selected_cat_id: String = ""
var _place_btn: Button = null
var _selected_label: Label = null
var _active_beds: Array = []
var _cat_buttons: Dictionary = {}  # cat_id -> Button

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

	_update_cat_buttons()


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
		btn.disabled = not owned
		btn.modulate = Color(1, 1, 1) if owned else Color(0.5, 0.5, 0.5, 0.7)


func _on_cat_selected(cat_id: String):
	selected_cat_id = cat_id
	_selected_label.text = "Selected: " + _format_cat_name(cat_id)
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
	if selected_cat_id == "":
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
	_selected_label.text = "Placed!"
	selected_cat_id = ""
	_place_btn.visible = false


func _exit_placement_mode():
	for bed in _active_beds:
		if is_instance_valid(bed):
			bed.exit_placement_mode()
			bed.modulate = Color(1, 1, 1)
	_active_beds.clear()


func _on_exit_pressed() -> void:
	selected_cat_id = ""
	_place_btn.visible = false
	_exit_placement_mode()
	$"../../StartMenu".visible = true
	$"../../StartMenu".process_mode = Node.PROCESS_MODE_ALWAYS
	$"../".visible = false
	$"../".process_mode = Node.PROCESS_MODE_DISABLED
