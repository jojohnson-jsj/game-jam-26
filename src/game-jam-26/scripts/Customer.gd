extends Area2D

signal order_placed(item_type)
signal patience_expired
signal customer_done

enum State { WALKING_TO_SEAT, THINKING, WAITING_FOR_PLAYER, ORDER_TAKEN, EATING, DONE, WALKING_OUT }

var current_state = State.WALKING_TO_SEAT

@export var order_item: String = "latte"
@export var initial_patience: float = 30.0
@export var delivery_patience: float = 50.0
@export var eating_time: float = 10.0
@export var thinking_time_min: float = 3.0
@export var thinking_time_max: float = 8.0

## Customers served within this many seconds (from queue entry) get a heart emoji.
@export var fast_service_threshold: float = 20.0
## Customers served within this many seconds get a smile emoji (above fast threshold).
@export var smile_service_threshold: float = 35.0

var queue_entry_time: int = 0
var tip_delta: float = 0.0
var group = null
var table_center: Vector2 = Vector2.ZERO

var speed = 80.0
const ARRIVAL_THRESHOLD = 4.0

var _last_horizontal: float = 1.0
var _walk_target: Vector2 = Vector2.ZERO
var _walking_to_slot: bool = false

# Set by GameManager before add_child so groups never share a sprite.
# -1 means pick randomly (fallback).
var assigned_variant_index: int = -1

# Whether the player is currently within interact range of this customer.
var _player_in_range: bool = false

# ── Emoji ─────────────────────────────────────────────────────────────────────

const EMOJI_HEART   = preload("res://assets/characters/emojis/emoji_heart.png")
const EMOJI_SMILE   = preload("res://assets/characters/emojis/emoji_smile.png")
const EMOJI_VEIN    = preload("res://assets/characters/emojis/emoji_vein.png")
const EMOJI_TORNADO = preload("res://assets/characters/emojis/emoji_tornado.png")
const EMOJI_ANGRY   = preload("res://assets/characters/emojis/emoji_angry.png")

var _emoji_indicator: Sprite2D = null
var _showing_heart: bool = false
var _eating_sprite: Sprite2D = null

var _bar_bg: ColorRect = null
var _bar_fill: ColorRect = null
const BAR_WIDTH  = 14.0
const BAR_HEIGHT = 3.0

# ── Character variants ────────────────────────────────────────────────────────
# Individual const preloads — this pattern is always safe in GDScript 4.
# Putting preload() inside a const Array-of-Dicts can trip the parser, so we
# keep the preloads flat and assemble the array at runtime in _ready().

const _ANGLER_IDLE    = preload("res://assets/characters/idle/angler_idle.png")
const _ANGLER_RIGHT   = preload("res://assets/characters/walk/spritesheet format/angler_walk_right-Sheet.png")
const _ANGLER_LEFT    = preload("res://assets/characters/walk/spritesheet format/angler_walk_left-Sheet.png")

const _DOCTOR_IDLE    = preload("res://assets/characters/idle/doctor_idle.png")
const _DOCTOR_RIGHT   = preload("res://assets/characters/walk/spritesheet format/doctor_walk_right-Sheet.png")
const _DOCTOR_LEFT    = preload("res://assets/characters/walk/spritesheet format/doctor_walk_left-Sheet.png")

const _GIRL2_IDLE     = preload("res://assets/characters/idle/girl2_idle.png")
const _GIRL2_RIGHT    = preload("res://assets/characters/walk/spritesheet format/girl2_walk_right-Sheet.png")
const _GIRL2_LEFT     = preload("res://assets/characters/walk/spritesheet format/girl2_walk_left-Sheet.png")

const _OLD_MAN_IDLE   = preload("res://assets/characters/idle/old_man_idle.png")
const _OLD_MAN_RIGHT  = preload("res://assets/characters/walk/spritesheet format/old_man_walk_right-Sheet.png")
const _OLD_MAN_LEFT   = preload("res://assets/characters/walk/spritesheet format/old_man_walk_left-Sheet.png")

const _SMITH_IDLE     = preload("res://assets/characters/idle/smith_idle.png")
const _SMITH_RIGHT    = preload("res://assets/characters/walk/spritesheet format/smith_walk_right-Sheet.png")
const _SMITH_LEFT     = preload("res://assets/characters/walk/spritesheet format/smith_walk_left-Sheet.png")

const _WITCH_IDLE     = preload("res://assets/characters/idle/witch_idle.png")
const _WITCH_RIGHT    = preload("res://assets/characters/walk/spritesheet format/witch_walk_right-Sheet.png")
const _WITCH_LEFT     = preload("res://assets/characters/walk/spritesheet format/witch_walk_left-Sheet.png")

const _AMELIA_IDLE     = preload("res://assets/characters/idle/amelia_idle.png")
const _AMELIA_RIGHT    = preload("res://assets/characters/walk/spritesheet format/amelia_walk_right-Sheet.png")
const _AMELIA_LEFT     = preload("res://assets/characters/walk/spritesheet format/amelia_walk_left-Sheet.png")

const _STEVEN_IDLE     = preload("res://assets/characters/idle/steven_idle.png")
const _STEVEN_RIGHT    = preload("res://assets/characters/walk/spritesheet format/steven_walk_right-Sheet.png")
const _STEVEN_LEFT     = preload("res://assets/characters/walk/spritesheet format/steven_walk_left-Sheet.png")

const _SARAH_IDLE      = preload("res://assets/characters/idle/sarah_idle.png")
const _SARAH_RIGHT     = preload("res://assets/characters/walk/spritesheet format/sarah_walk_right-Sheet.png")
const _SARAH_LEFT      = preload("res://assets/characters/walk/spritesheet format/sarah_walk_left-Sheet.png")

const _MEGHANA_IDLE    = preload("res://assets/characters/idle/meghana_idle.png")
const _MEGHANA_RIGHT   = preload("res://assets/characters/walk/spritesheet format/meghana_walk_right-Sheet.png")
const _MEGHANA_LEFT    = preload("res://assets/characters/walk/spritesheet format/meghana_walk_left-Sheet.png")

const _JO_IDLE         = preload("res://assets/characters/idle/jo_idle.png")
const _JO_RIGHT        = preload("res://assets/characters/walk/spritesheet format/jo_walk_right-Sheet.png")
const _JO_LEFT         = preload("res://assets/characters/walk/spritesheet format/jo_walk_left-Sheet.png")

# Assembled in _ready() from the consts above. Each entry has idle, walk_right,
# and walk_left keys. The walk sheets are 4 frames of 32×32 laid out horizontally.
var _character_variants: Array


func _ready():
	eating_time = max(1.0, eating_time - GlobalInventory.get_eating_time_reduction())
	thinking_time_min = max(1.0, thinking_time_min - GlobalInventory.get_thinking_time_reduction())
	thinking_time_max = max(1.0, thinking_time_max - GlobalInventory.get_thinking_time_reduction())
	speed *= (1.0 + GlobalInventory.get_npc_speed_bonus())

	$NavigationAgent2D.path_desired_distance = ARRIVAL_THRESHOLD
	$NavigationAgent2D.target_desired_distance = ARRIVAL_THRESHOLD

	$PatienceTimer.one_shot = true
	$EatingTimer.wait_time = eating_time
	$EatingTimer.one_shot = true
	$ThinkingTimer.one_shot = true

	$PatienceTimer.timeout.connect(_on_patience_expired)
	$EatingTimer.timeout.connect(_on_finished_eating)
	$ThinkingTimer.timeout.connect(_on_thinking_finished)

	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	input_event.connect(_on_input_event)

	$ThinkingLabel.visible = false
	$OrderIndicator.visible = false
	_show_idle()

	_build_character_variants()
	_apply_random_variant()
	_create_emoji_indicator()
	_create_eating_sprite()
	_create_patience_bar()


func _process(delta):
	if current_state == State.WAITING_FOR_PLAYER and group != null and not group.is_seated:
		$SpriteIdle.flip_h = true

	if current_state == State.WALKING_OUT:
		var walk_dir = (_walk_target - global_position).normalized()
		global_position = global_position.move_toward(_walk_target, speed * delta)
		_update_animation(walk_dir)
		if global_position.distance_to(_walk_target) <= ARRIVAL_THRESHOLD:
			queue_free()
		return

	if current_state != State.WALKING_TO_SEAT:
		_update_emoji()
		_update_patience_bar()
		return

	if _walking_to_slot:
		var slot_direction = (_walk_target - global_position).normalized()
		global_position = global_position.move_toward(_walk_target, speed * delta)
		_update_animation(slot_direction)
		if global_position.distance_to(_walk_target) <= ARRIVAL_THRESHOLD:
			_walking_to_slot = false
			_on_arrived_at_slot()
		return

	if $NavigationAgent2D.is_navigation_finished():
		_on_arrived_at_seat()
		return
	var next = $NavigationAgent2D.get_next_path_position()
	var direction = (next - global_position).normalized()
	global_position = global_position.move_toward(next, speed * delta)
	_update_animation(direction)


func _update_animation(direction: Vector2):
	if direction.length() < 0.1:
		return
	if direction.x > 0.1:
		_last_horizontal = 1.0
		$SpriteIdle.visible = false
		$SpriteRight.visible = true
		$SpriteLeft.visible = false
		if not $SpriteRight.is_playing():
			$SpriteRight.play("walk")
	elif direction.x < -0.1:
		_last_horizontal = -1.0
		$SpriteIdle.visible = false
		$SpriteRight.visible = false
		$SpriteLeft.visible = true
		if not $SpriteLeft.is_playing():
			$SpriteLeft.play("walk")
	else:
		$SpriteIdle.visible = false
		if _last_horizontal > 0:
			$SpriteRight.visible = true
			$SpriteLeft.visible = false
			if not $SpriteRight.is_playing():
				$SpriteRight.play("walk")
		else:
			$SpriteRight.visible = false
			$SpriteLeft.visible = true
			if not $SpriteLeft.is_playing():
				$SpriteLeft.play("walk")


func _show_idle():
	$SpriteIdle.visible = true
	$SpriteRight.visible = false
	$SpriteLeft.visible = false
	$SpriteRight.stop()
	$SpriteLeft.stop()


func _show_order_indicator():
	var tex = GameManager.get_order_sprite(order_item)
	if tex:
		$OrderIndicator.texture = tex
	$OrderIndicator.visible = true


func _show_food_indicator():
	var tex = GameManager.get_food_sprite(order_item)
	if tex:
		$OrderIndicator.texture = tex
	$OrderIndicator.position = Vector2(0, -23)
	$OrderIndicator.visible = true


func _hide_order_indicator():
	$OrderIndicator.visible = false


func navigate_to(target_global: Vector2):
	_walking_to_slot = false
	current_state = State.WALKING_TO_SEAT
	call_deferred("_set_nav_target", target_global)


func walk_to(target_global: Vector2):
	_walk_target = target_global
	_walking_to_slot = true
	current_state = State.WALKING_TO_SEAT


func walk_out(door_pos: Vector2):
	$PatienceTimer.stop()
	$EatingTimer.stop()
	$ThinkingTimer.stop()
	$ThinkingLabel.visible = false
	_hide_order_indicator()
	if _bar_bg:   _bar_bg.visible   = false
	if _bar_fill: _bar_fill.visible = false
	z_index = 6  # restore walking z-index before walking out
	# Don't hide the emoji here — an angry face should persist while the customer
	# walks out. queue_free() will clean it up when they leave the building.
	current_state = State.WALKING_OUT
	_walk_target = door_pos
	_walking_to_slot = false


func _set_nav_target(pos: Vector2):
	$NavigationAgent2D.target_position = pos


func _on_arrived_at_seat():
	_show_idle()
	$SpriteIdle.flip_h = global_position.x < table_center.x
	# z=3: always above TileMap_PlantChairDecor (chairs, z=2),
	# always below TileMap_Furniture (table tops, z=4) — no y_sort dependency.
	z_index = 3
	current_state = State.THINKING
	$ThinkingLabel.visible = true
	$ThinkingTimer.wait_time = randf_range(thinking_time_min, thinking_time_max)
	$ThinkingTimer.start()


func _on_arrived_at_slot():
	_show_idle()
	current_state = State.WAITING_FOR_PLAYER


func _on_thinking_finished():
	$ThinkingLabel.visible = false
	current_state = State.WAITING_FOR_PLAYER
	_show_order_indicator()
	$PatienceTimer.wait_time = initial_patience
	$PatienceTimer.start()
	_update_proximity_highlight()


func interact(player_inventory: Array) -> bool:
	match current_state:
		State.WAITING_FOR_PLAYER:
			# Hotswap: player already has matching food → deliver immediately,
			# hand back the order slip (mirrors equipment hotswap behaviour).
			var food = find_food_in_inventory(player_inventory)
			if food != null:
				player_inventory.erase(food)
				emit_signal("order_placed", order_item)
				receive_food()
				return true
			# Normal path: take the order if there's inventory room.
			if player_inventory.size() >= 2:
				return false
			modulate = Color(1, 1, 1)
			emit_signal("order_placed", order_item)
			current_state = State.ORDER_TAKEN
			_show_food_indicator()
			$PatienceTimer.wait_time = delivery_patience
			$PatienceTimer.start()
			_update_proximity_highlight()
			return true
		State.ORDER_TAKEN:
			var food = find_food_in_inventory(player_inventory)
			if food == null:
				return false
			player_inventory.erase(food)
			receive_food()
			return true
		State.EATING:
			return false
		State.DONE:
			return false
	return false


func receive_food():
	tip_delta = (Time.get_ticks_msec() - queue_entry_time) / 1000.0
	current_state = State.EATING
	_hide_order_indicator()
	$PatienceTimer.stop()
	$EatingTimer.start()
	_update_proximity_highlight()
	_show_eating_sprite()

	# Brief reaction emoji based on how fast the customer was served.
	if tip_delta <= fast_service_threshold:
		_show_reaction_emoji(EMOJI_HEART)
	elif tip_delta <= smile_service_threshold:
		_show_reaction_emoji(EMOJI_SMILE)
	else:
		if _emoji_indicator:
			_emoji_indicator.visible = false


func find_food_in_inventory(player_inventory: Array):
	for item in player_inventory:
		if item["type"] == "food" and item["item"] == order_item:
			return item
	return null


func _on_patience_expired():
	# Route through _show_reaction_emoji so _showing_heart blocks _update_emoji
	# from immediately hiding it on the next frame (timer is stopped by now).
	_show_reaction_emoji(EMOJI_ANGRY, true)
	emit_signal("patience_expired")


func _on_finished_eating():
	current_state = State.DONE
	$EatingTimer.stop()
	if _eating_sprite:
		_eating_sprite.visible = false
	emit_signal("customer_done")


func _on_mouse_entered():
	if group != null and not group.is_seated:
		group.highlight()
	elif current_state == State.WAITING_FOR_PLAYER:
		var player = get_tree().get_first_node_in_group("player")
		if player and player.has_qr_cat:
			modulate = Color(1.4, 1.4, 1.4)


func _on_mouse_exited():
	if group != null and not group.is_seated:
		group.unhighlight()
	elif current_state == State.WAITING_FOR_PLAYER:
		modulate = Color(1, 1, 1)


func _on_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if group != null and not group.is_seated and GameManager.has_queue_cat:
			group.unhighlight()
			group.on_clicked()
			return
		if current_state == State.WAITING_FOR_PLAYER and (group == null or group.is_seated):
			var player = get_tree().get_first_node_in_group("player")
			if player and player.has_qr_cat:
				modulate = Color(1, 1, 1)
				player.receive_order_from_qr(self)


func is_waiting_for_order() -> bool:
	return current_state == State.WAITING_FOR_PLAYER


func on_player_entered():
	_player_in_range = true
	_update_proximity_highlight()


func on_player_exited():
	_player_in_range = false
	_update_proximity_highlight()


func is_relevant() -> bool:
	return current_state == State.WAITING_FOR_PLAYER or current_state == State.ORDER_TAKEN


func can_interact(player_inventory: Array) -> bool:
	match current_state:
		State.WAITING_FOR_PLAYER:
			# Hotswap path (food in hand) works even on a full inventory
			return find_food_in_inventory(player_inventory) != null or player_inventory.size() < 2
		State.ORDER_TAKEN:
			return find_food_in_inventory(player_inventory) != null
	return false


func _update_proximity_highlight():
	if not _player_in_range:
		modulate = Color(1, 1, 1)
		return
	var player = get_tree().get_first_node_in_group("player")
	var inv = player.inventory if player else []
	if can_interact(inv):
		modulate = Color(1.4, 1.4, 1.4)
	else:
		modulate = Color(1, 1, 1)


func highlight():
	modulate = Color(1.4, 1.4, 1.4)


func unhighlight():
	modulate = Color(1, 1, 1)


# ── Emoji helpers ──────────────────────────────────────────────────────────────

func _create_emoji_indicator():
	_emoji_indicator = Sprite2D.new()
	_emoji_indicator.position = Vector2(0, -30)
	_emoji_indicator.z_index = 8
	_emoji_indicator.z_as_relative = false
	_emoji_indicator.visible = false
	add_child(_emoji_indicator)

func _create_eating_sprite():
	_eating_sprite = Sprite2D.new()
	_eating_sprite.position = Vector2(0, -14)
	_eating_sprite.z_index = 7
	_eating_sprite.z_as_relative = false
	_eating_sprite.visible = false
	add_child(_eating_sprite)

const FOOD_SPRITES = {
	"latte": preload("res://assets/food/food/food_sprite_latte.png"),
	"pie":   preload("res://assets/food/food/food_sprite_pie.png"),
}

func _show_eating_sprite():
	if _eating_sprite == null:
		return
	var tex = FOOD_SPRITES.get(order_item)
	if tex == null:
		return
	_eating_sprite.texture = tex
	_eating_sprite.scale = Vector2.ONE
	# position toward the table center from the customer
	var dir = (table_center - global_position).normalized()
	_eating_sprite.position = dir * 18.0
	_eating_sprite.visible = true
	var t = create_tween().set_loops()
	t.tween_property(_eating_sprite, "scale", Vector2(1.15, 0.85), 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(_eating_sprite, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


## Update the emoji based on how much patience the customer has left.
## Only shown for seated customers (not in queue) with an active patience timer.
func _update_emoji():
	if _showing_heart:
		return

	if _emoji_indicator == null:
		return

	var in_patience_state = (current_state == State.WAITING_FOR_PLAYER or current_state == State.ORDER_TAKEN)
	var is_seated = (group == null or group.is_seated)
	var timer_active = not $PatienceTimer.is_stopped()

	if not (in_patience_state and is_seated and timer_active):
		_emoji_indicator.visible = false
		return

	var ratio = $PatienceTimer.time_left / $PatienceTimer.wait_time

	if ratio > 0.5:
		# Customer is still content — no emoji yet.
		_emoji_indicator.visible = false
	elif ratio > 0.25:
		_emoji_indicator.texture = EMOJI_VEIN
		_emoji_indicator.visible = true
	else:
		_emoji_indicator.texture = EMOJI_TORNADO
		_emoji_indicator.visible = true


## Shows a reaction emoji. Pass persistent=true to skip the auto-hide timer
## (used for angry, which should stay on until the customer leaves the building).
func _show_reaction_emoji(texture: Texture2D, persistent: bool = false):
	_showing_heart = true
	if _emoji_indicator:
		_emoji_indicator.texture = texture
		_emoji_indicator.visible = true
	if not persistent:
		get_tree().create_timer(2.0).timeout.connect(_on_reaction_finished)


func _on_reaction_finished():
	_showing_heart = false
	if _emoji_indicator:
		_emoji_indicator.visible = false


# ── Patience bar ──────────────────────────────────────────────────────────────

func _create_patience_bar() -> void:
	_bar_bg = ColorRect.new()
	_bar_bg.size = Vector2(BAR_WIDTH, BAR_HEIGHT)
	_bar_bg.position = Vector2(-BAR_WIDTH / 2.0, -16.0)
	_bar_bg.color = Color(0.15, 0.15, 0.15)
	_bar_bg.z_index = 8
	_bar_bg.z_as_relative = false
	_bar_bg.visible = false
	add_child(_bar_bg)

	_bar_fill = ColorRect.new()
	_bar_fill.size = Vector2(BAR_WIDTH, BAR_HEIGHT)
	_bar_fill.position = Vector2(-BAR_WIDTH / 2.0, -16.0)
	_bar_fill.color = Color(0.3, 0.65, 0.9)
	_bar_fill.z_index = 9
	_bar_fill.z_as_relative = false
	_bar_fill.visible = false
	add_child(_bar_fill)


func _update_patience_bar() -> void:
	if _bar_bg == null:
		return

	var in_patience_state = (current_state == State.WAITING_FOR_PLAYER or current_state == State.ORDER_TAKEN)
	var is_seated = (group == null or group.is_seated)
	var timer_active = not $PatienceTimer.is_stopped()

	if not (in_patience_state and is_seated and timer_active):
		_bar_bg.visible   = false
		_bar_fill.visible = false
		return

	var ratio = $PatienceTimer.time_left / $PatienceTimer.wait_time
	_bar_bg.visible   = true
	_bar_fill.visible = true
	_bar_fill.size.x  = BAR_WIDTH * ratio


	if ratio > 0.5:
		_bar_fill.color = Color(0.3, 0.65, 0.9)  # blue — plenty of time
	elif ratio > 0.25:
		_bar_fill.color = Color(0.9, 0.7, 0.1)   # yellow — getting impatient
	else:
		_bar_fill.color = Color(0.9, 0.2, 0.1)   # red — about to leave


# ── Character variant helpers ──────────────────────────────────────────────────

## Assembles the variant lookup table from the flat const preloads above.
## Called once per instance in _ready() — preloaded textures are cached by the
## engine so there's no redundant I/O even though we do this per instance.
func _build_character_variants():
	_character_variants = [
		{"idle": _AMELIA_IDLE,   "walk_right": _AMELIA_RIGHT,   "walk_left": _AMELIA_LEFT},
		{"idle": _STEVEN_IDLE,   "walk_right": _STEVEN_RIGHT,   "walk_left": _STEVEN_LEFT},
		{"idle": _SARAH_IDLE,    "walk_right": _SARAH_RIGHT,    "walk_left": _SARAH_LEFT},
		{"idle": _MEGHANA_IDLE,  "walk_right": _MEGHANA_RIGHT,  "walk_left": _MEGHANA_LEFT},
		{"idle": _JO_IDLE,       "walk_right": _JO_RIGHT,       "walk_left": _JO_LEFT},
		{"idle": _ANGLER_IDLE,  "walk_right": _ANGLER_RIGHT,  "walk_left": _ANGLER_LEFT},
		{"idle": _DOCTOR_IDLE,  "walk_right": _DOCTOR_RIGHT,  "walk_left": _DOCTOR_LEFT},
		{"idle": _GIRL2_IDLE,   "walk_right": _GIRL2_RIGHT,   "walk_left": _GIRL2_LEFT},
		{"idle": _OLD_MAN_IDLE, "walk_right": _OLD_MAN_RIGHT, "walk_left": _OLD_MAN_LEFT},
		{"idle": _SMITH_IDLE,   "walk_right": _SMITH_RIGHT,   "walk_left": _SMITH_LEFT},
		{"idle": _WITCH_IDLE,   "walk_right": _WITCH_RIGHT,   "walk_left": _WITCH_LEFT},
	]


## Picks a character appearance, using the pre-assigned index if GameManager set
## one, otherwise falling back to a random pick.
func _apply_random_variant():
	var idx: int
	if assigned_variant_index >= 0 and assigned_variant_index < _character_variants.size():
		idx = assigned_variant_index
	else:
		idx = randi() % _character_variants.size()
	var variant = _character_variants[idx]
	$SpriteIdle.texture = variant.idle
	_set_walk_frames($SpriteRight, variant.walk_right)
	_set_walk_frames($SpriteLeft, variant.walk_left)


## Builds a SpriteFrames resource from a horizontal 4-frame spritesheet
## (32×32 px per frame) and assigns it to the given AnimatedSprite2D.
func _set_walk_frames(sprite: AnimatedSprite2D, sheet: Texture2D):
	var frames = SpriteFrames.new()
	frames.add_animation("walk")
	frames.set_animation_loop("walk", true)
	frames.set_animation_speed("walk", 5.0)
	for i in range(4):
		var atlas = AtlasTexture.new()
		atlas.atlas = sheet
		atlas.region = Rect2(i * 32, 0, 32, 32)
		frames.add_frame("walk", atlas)
	sprite.sprite_frames = frames
	sprite.animation = "walk"
