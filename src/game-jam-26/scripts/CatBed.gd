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
	print("enter_placement_mode called, callback valid: ", _placement_callback.is_valid())
	var cr = get_node_or_null("ColorRect")
	if cr:
		cr.visible = true
	set_process_input(true)

func exit_placement_mode() -> void:
	_placement_callback = Callable()
	var cr = get_node_or_null("ColorRect")
	if cr:
		cr.visible = false
	set_process_input(false)

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

const CAT_SPRITES: Dictionary = {
	"qr_cat":              preload("res://assets/cats/ingame/cat_sprite_qr.png"),
	"hermes_cat":          preload("res://assets/cats/ingame/cat_sprite_hermes.png"),
	"money_cat":           preload("res://assets/cats/ingame/cat_sprite_money.png"),
	"host_cat":            preload("res://assets/cats/ingame/cat_sprite_host.png"),
	"counter_cat":         preload("res://assets/cats/ingame/cat_sprite_countertop.png"),
	"trash_cat":           preload("res://assets/cats/ingame/cat_sprite_cute.png"),
	"patience_cat":        preload("res://assets/cats/ingame/cat_sprite_patience.png"),
	"quality_control_cat": preload("res://assets/cats/ingame/cat_sprite_inspector.png"),
	"cheetah_cat":         preload("res://assets/cats/ingame/cat_sprite_zoomies.png"),
	"pretty_cat":          preload("res://assets/cats/ingame/cat_sprite_pretty.png"),
	"valentines_cat":      preload("res://assets/cats/ingame/cat_sprite_valentines.png"),
	"fat_cat":             preload("res://assets/cats/ingame/cat_sprite_fat.png"),
	"ankle_biter_cat":     preload("res://assets/cats/ingame/cat_sprite_ankle.png"),
	"reccomendation_cat":  preload("res://assets/cats/ingame/cat_sprite_recommender.png"),
}

# Maps every cat name to its static Cat resource properties so we can
# reconstruct a Cat instance from a saved name without needing .tres files.
const CAT_DEFINITIONS: Dictionary = {
	"qr_cat":              {"cat_type": Cat.CatType.NON_TABLE, "ability_type": Cat.AbilityType.QR},
	"hermes_cat":          {"cat_type": Cat.CatType.NON_TABLE, "ability_type": Cat.AbilityType.HERMES},
	"money_cat":           {"cat_type": Cat.CatType.NON_TABLE, "ability_type": Cat.AbilityType.MONEY},
	"host_cat":            {"cat_type": Cat.CatType.NON_TABLE, "ability_type": Cat.AbilityType.QUEUE},
	"hopper_cat":          {"cat_type": Cat.CatType.NON_TABLE, "ability_type": Cat.AbilityType.NONE},
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
	_cat_sprite.z_index = 5
	_cat_sprite.z_as_relative = false
	_cat_sprite.visible = false
	add_child(_cat_sprite)

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
		if should_assign:
			load_cat_by_name(debug_cat_name)


func _exit_tree() -> void:
	SaveManager.unregister_bed(self)


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
	if _cat_sprite and _cat_sprite.visible:
		_cat_sprite.modulate = Color(1.4, 1.4, 1.4)


func _on_bed_mouse_exited() -> void:
	if _cat_sprite:
		_cat_sprite.modulate = Color(1, 1, 1)


func _on_bed_input_event(_viewport, event, _shape_idx) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		print("bed input, callback valid: ", _placement_callback.is_valid())
		if _placement_callback.is_valid():
			_placement_callback.call(self)
		elif _cat_sprite and _cat_sprite.visible and not _is_being_petted:
			_do_pet()


func _do_pet() -> void:
	if _is_yawning:
		return
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


func _get_player():
	return get_tree().get_first_node_in_group("player")


func _activate_cat(cat: Cat):
	match cat.ability_type:
		Cat.AbilityType.HERMES:
			var player = _get_player()
			if player:
				player.has_dash_cat = true

		Cat.AbilityType.MONEY:
			# Enable money cat on ALL tables
			for table in GameManager.tables:
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


func _deactivate_cat(cat: Cat):
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

func _set_all_tables_money_cat_position() -> void:
	for table in GameManager.tables:
		table.money_cat_bed_position = global_position

func _set_counter_plates_visible(visible: bool) -> void:
	for plate in get_tree().get_nodes_in_group("countertop_plates"):
		plate.set_active(visible)
