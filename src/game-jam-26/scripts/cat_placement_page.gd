extends Control

var selected_cat_id: String = ""

@onready var selected_label = $HBox/VBox/SelectedLabel
@onready var close_btn = $HBox/VBox/HBox/CloseButton

const CAT_IDS = [
	'qr_cat', 'hermes_cat', 'money_cat', 'host_cat', 'hopper_cat',
	'nihao_cat', 'counter_cat', 'trash_cat', 'patience_cat', 'cooking_cat',
	'quality_control_cat', 'cheetah_cat', 'pretty_cat', 'valentines_cat',
	'fat_cat', 'sign_spinner_cat', 'ankle_biter_cat', 'reccomendation_cat'
]

var _place_btn: Button = null
var _active_beds: Array = []

func _ready():
	close_btn.pressed.connect(_on_exit_pressed)
	_place_btn = Button.new()
	_place_btn.text = "Place"
	_place_btn.visible = false
	_place_btn.pressed.connect(_on_place_pressed)
	$HBox/VBox/HBox.add_child(_place_btn)
	$HBox/VBox/HBox.move_child(_place_btn, 0)
	# connect cat buttons once here only
	for cat_id in CAT_IDS:
		var node = find_child(cat_id, true, false)
		if node:
			node.pressed.connect(_on_cat_selected.bind(cat_id))
	_update_cat_buttons()

func open():
	$"../".visible = true
	$"../".process_mode = Node.PROCESS_MODE_ALWAYS
	# Ensure newly purchased beds/equipment are visible
	var game_world = get_tree().root.get_node_or_null("Main/GameWorld")
	if game_world and game_world.has_method("_apply_equipment_unlocks"):
		game_world._apply_equipment_unlocks()
	_update_cat_buttons()

func _update_cat_buttons():
	for cat_id in CAT_IDS:
		var node = find_child(cat_id, true, false)
		if not node:
			continue
		var owned = GlobalInventory.owns_cat(cat_id)
		node.disabled = not owned
		node.modulate = Color(1, 1, 1) if owned else Color(0.3, 0.3, 0.3)

func _on_cat_selected(cat_id: String):
	selected_cat_id = cat_id
	if selected_label:
		selected_label.text = "Selected: " + cat_id.replace("_", " ").capitalize()
	_place_btn.visible = true
	_exit_placement_mode()

func _on_place_pressed():
	print("place pressed, selected_cat_id: ", selected_cat_id)
	if selected_cat_id == "":
		return
	var def = CatBed.CAT_DEFINITIONS.get(selected_cat_id, {})
	print("def: ", def)
	if def.is_empty():
		return

	_exit_placement_mode()
	var all_beds = get_tree().get_nodes_in_group("cat_beds")
	for bed in all_beds:
		if not bed.unlocked:
			bed.modulate = Color(0.3, 0.3, 0.3)
			_active_beds.append(bed)  # track for cleanup
			continue
		bed.enter_placement_mode(_on_bed_clicked)
		_active_beds.append(bed)

	print("active beds: ", _active_beds.size())
	if _active_beds.is_empty():
		selected_label.text = "No valid beds available!"
		return

	var game_world = get_tree().root.get_node("Main/GameWorld")
	game_world.visible = true
	game_world.process_mode = Node.PROCESS_MODE_ALWAYS
	self.modulate.a = 0.0
	self.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$HBox/VBox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$HBox/VBox.visible = false
	self.process_mode = Node.PROCESS_MODE_ALWAYS

func _on_bed_clicked(bed: CatBed):
	_exit_placement_mode()
	# remove this cat from any bed it's already in
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
	$HBox/VBox.mouse_filter = Control.MOUSE_FILTER_STOP
	$HBox/VBox.visible = true
	self.visible = true
	if selected_label:
		selected_label.text = "Placed!"
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
