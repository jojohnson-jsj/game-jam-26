class_name CatBed
extends Node2D

enum BedType { TABLE, NON_TABLE }

@export var bed_type: BedType = BedType.NON_TABLE
@export var unlocked: bool = false
# Unique string ID used by SaveManager to persist cat assignments.
# Set this in the editor — e.g. "bed_hermes", "bed_money_table1".
@export var bed_id: String = ""

# Set this to a cat name (e.g. "hermes_cat") to auto-assign that cat when its
# debug flag is enabled. Only applies if nothing was already loaded from a save.
@export var debug_cat_name: String = ""

var assigned_cat: Cat = null
var _cat_sprite: Sprite2D = null
var _interaction_area: Area2D = null

var _placement_callback: Callable = Callable()

func enter_placement_mode(callback: Callable) -> void:
	_placement_callback = callback
	# Gentle idle pulse to indicate this bed is selectable
	var tween = create_tween().set_loops()
	tween.tween_property(self, "scale", Vector2(1.08, 1.08), 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	set_meta("placement_tween", tween)

func exit_placement_mode() -> void:
	_placement_callback = Callable()
	if has_meta("placement_tween"):
		get_meta("placement_tween").kill()
		remove_meta("placement_tween")
	scale = Vector2.ONE
	modulate = Color(1, 1, 1)

func _input(event: InputEvent) -> void:
	if not _placement_callback.is_valid():
		return
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	if global_position.distance_to(get_global_mouse_position()) < 16.0:
		_placement_callback.call(self)

# ── Animation ─────────────────────────────────────────────────────────────────
var _is_yawning:     bool = false
var _is_being_petted: bool = false

signal cat_assigned(cat: Cat)
signal cat_removed

const MEOW_SOUNDS: Array = [
	preload("res://assets/sound assests/cat-meows/virtual_vibes-cat-meow-sound-383823.mp3"),
	preload("res://assets/sound assests/cat-meows/sound_garage-cat-meow-8-fx-306184.mp3"),
	preload("res://assets/sound assests/cat-meows/u_6ekfl947a2-cat-meow-297927.mp3"),
	preload("res://assets/sound assests/cat-meows/dragon-studio-cat-meow-401729.mp3"),
	preload("res://assets/sound assests/cat-meows/dragon-studio-cute-cat-meow-472372.mp3"),
]

const CAT_SPRITES: Dictionary = {
	"qr_cat":              preload("res://assets/cats/ingame/cat_sprite_qr.png"),
	"hermes_cat":          preload("res://assets/cats/ingame/cat_sprite_hermes.png"),
	"money_cat":           preload("res://assets/cats/ingame/cat_sprite_money.png"),
	"host_cat":            preload("res://assets/cats/ingame/cat_sprite_host.png"),
	"counter_cat":         preload("res://assets/cats/ingame/cat_sprite_countertop.png"),
	"trash_cat":           preload("res://assets/cats/ingame/cat_sprite_trash.png"),
	"patience_cat":        preload("res://assets/cats/ingame/cat_sprite_patience.png"),
	"quality_control_cat": preload("res://assets/cats/ingame/cat_sprite_inspector.png"),
	"cheetah_cat":         preload("res://assets/cats/ingame/cat_sprite_zoomies.png"),
	"pretty_cat":          preload("res://assets/cats/ingame/cat_sprite_pretty.png"),
	"valentines_cat":      preload("res://assets/cats/ingame/cat_sprite_valentines.png"),
	"fat_cat":             preload("res://assets/cats/ingame/cat_sprite_fat.png"),
	"ankle_biter_cat":     preload("res://assets/cats/ingame/cat_sprite_ankle.png"),
	"reccomendation_cat":  preload("res://assets/cats/ingame/cat_sprite_recommender.png"),
	"cooking_cat":         preload("res://assets/cats/ingame/cat_sprite_chef.png"),
	"sign_spinner_cat":    preload("res://assets/cats/ingame/cat_sprite_cute.png"),
	"hopper_cat":          preload("res://assets/cats/ingame/cat_sprite_queue.png"),
	"nihao_cat":           preload("res://assets/cats/ingame/cat_sprite_celebrity.png"),
}

# Maps every cat name to its static Cat resource properties so we can
# reconstruct a Cat instance from a saved name without needing .tres files.
const CAT_DEFINITIONS: Dictionary = {
	"qr_cat":              {"cat_type": Cat.CatType.NON_TABLE, "ability_type": Cat.AbilityType.QR},
	"hermes_cat":          {"cat_type": Cat.CatType.NON_TABLE, "ability_type": Cat.AbilityType.HERMES},
	"money_cat":           {"cat_type": Cat.CatType.NON_TABLE, "ability_type": Cat.AbilityType.MONEY},
	"host_cat":            {"cat_type": Cat.CatType.NON_TABLE, "ability_type": Cat.AbilityType.QUEUE},
	"hopper_cat":          {"cat_type": Cat.CatType.NON_TABLE, "ability_type": Cat.AbilityType.HOPPER},
	"nihao_cat":           {"cat_type": Cat.CatType.NON_TABLE, "ability_type": Cat.AbilityType.NONE},
	"counter_cat":         {"cat_type": Cat.CatType.NON_TABLE, "ability_type": Cat.AbilityType.COUNTER},
	"trash_cat":           {"cat_type": Cat.CatType.NON_TABLE, "ability_type": Cat.AbilityType.TRASH},
	"patience_cat":        {"cat_type": Cat.CatType.NON_TABLE, "ability_type": Cat.AbilityType.NONE},
	"cooking_cat":         {"cat_type": Cat.CatType.NON_TABLE, "ability_type": Cat.AbilityType.NONE},
	"quality_control_cat": {"cat_type": Cat.CatType.NON_TABLE, "ability_type": Cat.AbilityType.NONE},
	"cheetah_cat":         {"cat_type": Cat.CatType.NON_TABLE, "ability_type": Cat.AbilityType.NONE},
	"pretty_cat":          {"cat_type": Cat.CatType.NON_TABLE, "ability_type": Cat.AbilityType.NONE},
	"valentines_cat":      {"cat_type": Cat.CatType.NON_TABLE, "ability_type": Cat.AbilityType.NONE},
	"fat_cat":             {"cat_type": Cat.CatType.NON_TABLE, "ability_type": Cat.AbilityType.NONE},
	"sign_spinner_cat":    {"cat_type": Cat.CatType.NON_TABLE, "ability_type": Cat.AbilityType.NONE},
	"ankle_biter_cat":     {"cat_type": Cat.CatType.NON_TABLE, "ability_type": Cat.AbilityType.NONE},
	"reccomendation_cat":  {"cat_type": Cat.CatType.NON_TABLE, "ability_type": Cat.AbilityType.NONE},
}


func _ready() -> void:
	add_to_group("cat_beds")
	_cat_sprite = Sprite2D.new()
	_cat_sprite.position = Vector2(0, -7)
	_cat_sprite.z_index = 6
	_cat_sprite.z_as_relative = false
	_cat_sprite.visible = false
	add_child(_cat_sprite)

	if not unlocked:
		_set_visible(false)
	else:
		_set_visible(true)

	# Ensure bed art renders above furniture
	var art = get_node_or_null("Sprite2D - for art replacement later")
	if art:
		art.z_index = 6
		art.z_as_relative = false

	# Area2D for hover highlight and click-to-pet
	var shape = RectangleShape2D.new()
	shape.size = Vector2(22, 16)
	var col = CollisionShape2D.new()
	col.shape = shape
	col.position = Vector2(0, -7)
	_interaction_area = Area2D.new()
	_interaction_area.input_pickable = true
	_interaction_area.add_child(col)
	_interaction_area.mouse_entered.connect(_on_bed_mouse_entered)
	_interaction_area.mouse_exited.connect(_on_bed_mouse_exited)
	_interaction_area.input_event.connect(_on_bed_input_event)
	_interaction_area.set_meta("cat_bed", self)
	add_child(_interaction_area)

	SaveManager.register_bed(self)
	# Debug: auto-assign cats based on debug_cat_name + DebugConfig flags.
	if debug_cat_name != "" and assigned_cat == null:
		var should_assign = false
		match debug_cat_name:
			"money_cat":    should_assign = DebugConfig.money_cat_enabled
			"hermes_cat":   should_assign = DebugConfig.hermes_cat_enabled
			"qr_cat":       should_assign = DebugConfig.qr_cat_enabled
			"host_cat":     should_assign = DebugConfig.queue_cat_enabled
			"counter_cat":  should_assign = DebugConfig.counter_cat_enabled
			"trash_cat":    should_assign = DebugConfig.trash_cat_enabled
			"hopper_cat":   should_assign = DebugConfig.hopper_cat_enabled
		if should_assign:
			load_cat_by_name(debug_cat_name)


func _exit_tree() -> void:
	SaveManager.unregister_bed(self)


func _set_visible(show: bool) -> void:
	var art = get_node_or_null("Sprite2D - for art replacement later")
	if art:
		art.visible = show
		art.z_index = 6
		art.z_as_relative = false
	if _interaction_area:
		_interaction_area.input_pickable = show
		_interaction_area.monitoring = show


func set_unlocked(value: bool) -> void:
	unlocked = value
	_set_visible(value)
	if not value and assigned_cat != null:
		remove_cat()


# Reconstruct and assign a cat from a saved name string.
# Used exclusively by SaveManager on load — bypasses nothing, still validates.
func load_cat_by_name(cat_name: String) -> void:
	if not CAT_DEFINITIONS.has(cat_name):
		push_error("CatBed: unknown cat name '%s' in save file" % cat_name)
		return
	var def: Dictionary = CAT_DEFINITIONS[cat_name]
	var cat := Cat.new()
	cat.cat_name    = cat_name
	cat.cat_type    = def["cat_type"]
	cat.ability_type = def["ability_type"]
	assign_cat(cat)


func assign_cat(cat: Cat) -> bool:
	if not unlocked:
		return false
	if assigned_cat != null:
		_deactivate_cat(assigned_cat)
	assigned_cat = cat
	_update_cat_sprite(cat.cat_name)
	emit_signal("cat_assigned", cat)
	_activate_cat(cat)
	return true


func remove_cat():
	if assigned_cat == null:
		return
	_deactivate_cat(assigned_cat)
	assigned_cat = null
	_stop_cat_animations()
	if _cat_sprite:
		_cat_sprite.visible = false
	emit_signal("cat_removed")


func _update_cat_sprite(cat_name: String) -> void:
	if _cat_sprite == null:
		return
	if CAT_SPRITES.has(cat_name):
		_cat_sprite.texture = CAT_SPRITES[cat_name]
		_cat_sprite.visible = true
		_start_cat_animations()
	else:
		_stop_cat_animations()
		_cat_sprite.visible = false


# ── Animation helpers ─────────────────────────────────────────────────────────

func _start_cat_animations() -> void:
	_stop_cat_animations()
	_is_yawning = false
	_schedule_blink()
	_schedule_yawn()


func _stop_cat_animations() -> void:
	_is_yawning = false
	_is_being_petted = false
	if _cat_sprite:
		_cat_sprite.scale    = Vector2.ONE
		_cat_sprite.modulate = Color(1, 1, 1)


func _schedule_blink() -> void:
	get_tree().create_timer(randf_range(14.0, 25.0)).timeout.connect(_do_blink)

func _do_blink() -> void:
	if _cat_sprite == null or not _cat_sprite.visible:
		return
	if _is_yawning:
		_schedule_blink()  # try again later
		return
	var t = create_tween()
	# 30% chance of a lazy slow blink, otherwise normal
	if randf() < 0.3:
		t.tween_property(_cat_sprite, "scale:y", 0.1, 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		t.tween_property(_cat_sprite, "scale:y", 1.0, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	else:
		t.tween_property(_cat_sprite, "scale:y", 0.1, 0.05)
		t.tween_property(_cat_sprite, "scale:y", 1.0, 0.08)
	t.tween_callback(_schedule_blink)


func _schedule_yawn() -> void:
	get_tree().create_timer(randf_range(25.0, 45.0)).timeout.connect(_do_yawn)

func _do_yawn() -> void:
	if _cat_sprite == null or not _cat_sprite.visible:
		return
	_is_yawning = true
	var t = create_tween()
	# squash down (inhale)
	t.tween_property(_cat_sprite, "scale", Vector2(1.1, 0.8), 0.3) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	# stretch up (big yawn)
	t.tween_property(_cat_sprite, "scale", Vector2(0.9, 1.25), 0.4) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	# snap back
	t.tween_property(_cat_sprite, "scale", Vector2.ONE, 0.25) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	# settle: gentle horizontal squash then release, like the cat relaxing back into position
	t.tween_property(_cat_sprite, "scale", Vector2(1.08, 0.95), 0.2) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t.tween_property(_cat_sprite, "scale", Vector2.ONE, 0.25) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_callback(func():
		_is_yawning = false
		if _cat_sprite and _cat_sprite.visible:
			_schedule_yawn()
	)


func _on_bed_mouse_entered() -> void:
	if _placement_callback.is_valid():
		if has_meta("placement_tween"):
			get_meta("placement_tween").kill()
		var tween = create_tween()
		tween.tween_property(self, "scale", Vector2(1.25, 1.25), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		modulate = Color(1.5, 1.5, 1.0)
		if assigned_cat:
			_show_hover_label(_get_cat_tooltip(assigned_cat.cat_name))
	elif _cat_sprite and _cat_sprite.visible:
		_cat_sprite.modulate = Color(1.4, 1.4, 1.4)


func _on_bed_mouse_exited() -> void:
	_hide_hover_label()
	if _placement_callback.is_valid():
		var tween = create_tween()
		tween.tween_property(self, "scale", Vector2.ONE, 0.1).set_trans(Tween.TRANS_SINE)
		modulate = Color(1, 1, 1)
		var loop_tween = create_tween().set_loops()
		loop_tween.tween_property(self, "scale", Vector2(1.08, 1.08), 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		loop_tween.tween_property(self, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		set_meta("placement_tween", loop_tween)
	elif _cat_sprite:
		_cat_sprite.modulate = Color(1, 1, 1)


func _on_bed_input_event(_viewport, event, _shape_idx) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		print("bed input, callback valid: ", _placement_callback.is_valid())
		if _placement_callback.is_valid():
			_placement_callback.call(self)
		elif _cat_sprite and _cat_sprite.visible and not _is_being_petted:
			_do_pet()


func interact(_player_inventory: Array) -> bool:
	if _cat_sprite and _cat_sprite.visible and not _is_being_petted:
		_do_pet()
		return true
	return false


func can_interact(_player_inventory: Array) -> bool:
	return _cat_sprite != null and _cat_sprite.visible


func highlight():
	if _cat_sprite and _cat_sprite.visible:
		_cat_sprite.modulate = Color(1.4, 1.4, 1.4)


func unhighlight():
	if _cat_sprite:
		_cat_sprite.modulate = Color(1, 1, 1)


func _do_pet() -> void:
	if _is_yawning:
		return
	SoundManager.play_sfx(MEOW_SOUNDS[randi() % MEOW_SOUNDS.size()], -6)
	_is_being_petted = true
	var t = create_tween()
	# squish sideways (leaning into the pet)
	t.tween_property(_cat_sprite, "scale", Vector2(1.25, 0.8), 0.07) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	# bounce up happy
	t.tween_property(_cat_sprite, "scale", Vector2(0.9, 1.2), 0.1) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	# settle back
	t.tween_property(_cat_sprite, "scale", Vector2.ONE, 0.15) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN_OUT)
	t.tween_callback(func(): _is_being_petted = false)


func _show_hover_label(text: String) -> void:
	_hide_hover_label()
	var page = get_tree().root.get_node_or_null("Main/CatPlacementPage/CatPlacementPage")
	if page == null or page._cancel_layer == null:
		return
	var panel := PanelContainer.new()
	panel.name = "_bed_hover_label"
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.98, 0.95, 0.88, 0.95)
	style.border_color = Color(0.45, 0.28, 0.12, 1.0)
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	style.set_content_margin_all(6)
	panel.add_theme_stylebox_override("panel", style)
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_color_override("font_color", Color(0.28, 0.15, 0.05))
	lbl.add_theme_font_size_override("font_size", 11)
	panel.add_child(lbl)
	var screen_pos = get_global_transform_with_canvas().origin
	panel.position = screen_pos + Vector2(10, -50)
	page._cancel_layer.add_child(panel)

func _hide_hover_label() -> void:
	var page = get_tree().root.get_node_or_null("Main/CatPlacementPage/CatPlacementPage")
	if page == null or page._cancel_layer == null:
		return
	var lbl = page._cancel_layer.get_node_or_null("_bed_hover_label")
	if lbl:
		lbl.queue_free()

func _get_player():
	return get_tree().get_first_node_in_group("player")

func _get_cat_tooltip(cat_name: String) -> String:
	const TOOLTIPS = {
		'qr_cat': 'QR Cat\nClick seated customers to take their order',
		'hermes_cat': 'Hermes Cat\nGrants you a dash ability (press Shift)',
		'money_cat': 'Money Cat\nAutomatically collects money',
		'host_cat': 'Host Cat\nClick waiting groups to seat them instantly',
		'hopper_cat': 'Hopper Cat\nQueue an extra order into a machine',
		'nihao_cat': 'Nihao Cat\nMakes the day last longer',
		'counter_cat': 'Counter Cat\nUnlocks countertop plates',
		'trash_cat': 'Trash Cat\nClick trash can to discard inventory',
		'patience_cat': 'Patience Cat\nCustomers have more patience',
		'cooking_cat': 'Chef Cat\nDecreases cooking time',
		'quality_control_cat': 'Inspector Cat\nItems sell for more',
		'cheetah_cat': 'Cheetah Cat\nPlayer moves faster',
		'pretty_cat': 'Pretty Cat\nCustomers tip more generously',
		'valentines_cat': 'Valentines Cat\nFewer solo customers',
		'fat_cat': 'Fat Cat\nCustomers eat faster',
		'sign_spinner_cat': 'Sign Spinner Cat\nMore customers arrive',
		'ankle_biter_cat': 'Ankle Biter Cat\nCustomers walk faster',
		'reccomendation_cat': 'Recommendation Cat\nCustomers order faster',
	}
	return TOOLTIPS.get(cat_name, cat_name)


func _activate_cat(cat: Cat):
	if not cat.cat_name in GlobalInventory.placed_cats:
		GlobalInventory.placed_cats.append(cat.cat_name)
	match cat.ability_type:
		Cat.AbilityType.HERMES:
			var player = _get_player()
			if player:
				player.has_dash_cat = true

		Cat.AbilityType.MONEY:
			# Enable money cat on ALL tables
			for table in GameManager.tables:
				if is_instance_valid(table):
					table.has_money_cat = true
			# Defer so global_position is valid after the node is in the scene tree
			call_deferred("_set_all_tables_money_cat_position")

		Cat.AbilityType.QR:
			var player = _get_player()
			if player:
				player.has_qr_cat = true

		Cat.AbilityType.QUEUE:
			GameManager.has_queue_cat = true

		Cat.AbilityType.COUNTER:
			GameManager.has_counter_cat = true
			call_deferred("_set_counter_plates_visible", true)

		Cat.AbilityType.TRASH:
			GameManager.has_trash_cat = true

		Cat.AbilityType.HOPPER:
			GameManager.has_hopper_cat = true


func _deactivate_cat(cat: Cat):
	GlobalInventory.placed_cats.erase(cat.cat_name)
	match cat.ability_type:
		Cat.AbilityType.HERMES:
			var player = _get_player()
			if player:
				player.has_dash_cat = false

		Cat.AbilityType.MONEY:
			# Clear money cat from ALL tables
			for table in GameManager.tables:
				table.has_money_cat = false
				table.money_cat_bed_position = Vector2.ZERO

		Cat.AbilityType.QR:
			var player = _get_player()
			if player:
				player.has_qr_cat = false

		Cat.AbilityType.QUEUE:
			GameManager.has_queue_cat = false

		Cat.AbilityType.COUNTER:
			GameManager.has_counter_cat = false
			_set_counter_plates_visible(false)

		Cat.AbilityType.TRASH:
			GameManager.has_trash_cat = false

		Cat.AbilityType.HOPPER:
			GameManager.has_hopper_cat = false

func _set_all_tables_money_cat_position() -> void:
	for table in GameManager.tables:
		table.money_cat_bed_position = global_position

func _set_counter_plates_visible(visible: bool) -> void:
	for plate in get_tree().get_nodes_in_group("countertop_plates"):
		plate.set_active(visible)
