extends CharacterBody2D

const INVENTORY_MAX = 2
const ACCELERATION = 1800.0
const FRICTION = 1400.0

@export var DASH_SPEED = 600.0
@export var DASH_DURATION = 0.12
@export var DASH_COOLDOWN = 5.0

var speed = 150.0
var inventory: Array = []
var _nearby_groups: Array = []
var _nearby_interactables: Array = []
var pending_order_source = null
var last_horizontal = 1
var last_vertical = 0
var was_moving = false

# Cat ability flags — defaults come from DebugConfig so they can be toggled
# centrally without touching this file.
var has_dash_cat: bool
var has_qr_cat: bool

# Dash state
var _is_dashing: bool = false
var _dash_timer: float = 0.0
var _dash_cooldown_timer: float = 0.0
var _dash_direction: Vector2 = Vector2.ZERO


func _ready():
	has_dash_cat = DebugConfig.hermes_cat_enabled
	has_qr_cat   = DebugConfig.qr_cat_enabled
	speed *= (1.0 + GlobalInventory.get_speed_bonus())
	
	$OrderConnectionTimer.wait_time = 0.5
	$OrderConnectionTimer.one_shot = true
	$OrderConnectionTimer.timeout.connect(_on_order_connection_timeout)
	$Area2D.area_entered.connect(_on_area_entered)
	$Area2D.area_exited.connect(_on_area_exited)
	$InventorySlot1.visible = false
	$InventorySlot2.visible = false


func _physics_process(delta):
	_tick_dash(delta)

	if _is_dashing:
		velocity = _dash_direction * DASH_SPEED
		move_and_slide()
		return

	var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")

	if direction != Vector2.ZERO:
		if not was_moving:
			$SpriteIdle.visible = false
			_squash_stretch(direction)
		was_moving = true
		if direction.x != 0:
			last_horizontal = sign(direction.x)
		if direction.y != 0:
			last_vertical = sign(direction.y)
		$SpriteLeft.visible = last_horizontal == -1
		$SpriteRight.visible = last_horizontal == 1
		$SpriteLeft.play()
		$SpriteRight.play()
		velocity = velocity.move_toward(direction * speed, ACCELERATION * delta)
	else:
		if was_moving:
			$SpriteLeft.visible = false
			$SpriteRight.visible = false
			$SpriteIdle.visible = true
			$SpriteIdle.flip_h = last_horizontal == 1
		$SpriteLeft.stop()
		$SpriteRight.stop()
		velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
		was_moving = false

	move_and_slide()


func _unhandled_input(event):
	if event.is_action_pressed("interact"):
		_handle_interact()
	if event.is_action_pressed("dash") and has_dash_cat:
		_try_dash()


func _handle_interact():
	var bodies = $Area2D.get_overlapping_areas()
	for body in bodies:
		if body == $Area2D:
			continue
		if not body.has_method("interact"):
			continue

		# Queue groups are always clickable regardless of inventory.
		if body.get("group") != null and not body.group.is_seated:
			body.group.on_clicked()
			return

		# Skip anything that can't be acted on with the current inventory.
		if body.has_method("can_interact") and not body.can_interact(inventory):
			continue

		if body.has_signal("order_placed") and body.is_waiting_for_order():
			if not body.order_placed.is_connected(_on_order_received):
				pending_order_source = body
				body.order_placed.connect(_on_order_received)
				$OrderConnectionTimer.start()

		var success = body.interact(inventory)
		_update_inventory_display()
		if not success:
			_flash_error()
		return

	# Nothing was actionable — flash if something nearby is actively waiting
	# on the player but the current inventory is the bottleneck.
	for body in bodies:
		if body == $Area2D:
			continue
		if not body.has_method("interact"):
			continue
		if body.get("group") != null and not body.group.is_seated:
			continue
		if body.has_method("is_relevant") and body.is_relevant():
			_flash_error()
			return


func receive_order_from_qr(customer) -> void:
	if inventory.size() >= INVENTORY_MAX:
		return
	if not customer.is_waiting_for_order():
		return
	if not customer.order_placed.is_connected(_on_order_received):
		pending_order_source = customer
		customer.order_placed.connect(_on_order_received)
	customer.interact(inventory)
	_update_inventory_display()


# ── Inventory display ─────────────────────────────────────────────────────────

func _update_inventory_display():
	# Slot 1 — left of player
	if inventory.size() >= 1:
		var item = inventory[0]
		var tex = _get_item_texture(item)
		$InventorySlot1.texture = tex
		$InventorySlot1.visible = tex != null
	else:
		$InventorySlot1.visible = false

	# Slot 2 — right of player
	if inventory.size() >= 2:
		var item = inventory[1]
		var tex = _get_item_texture(item)
		$InventorySlot2.texture = tex
		$InventorySlot2.visible = tex != null
	else:
		$InventorySlot2.visible = false

	# Re-evaluate highlights — interactability depends on what's in the inventory.
	_refresh_all_interactable_highlights()


func _get_item_texture(item: Dictionary) -> Texture2D:
	if item["type"] == "order":
		return GameManager.get_order_sprite(item["item"])
	elif item["type"] == "food":
		return GameManager.get_food_sprite(item["item"])
	return null


# ── Proximity highlight ───────────────────────────────────────────────────────

func _on_area_entered(area):
	if area.has_method("is_waiting_for_order"):
		var customer = area
		if customer.group != null and not customer.group.is_seated:
			# Queue group — always highlightable, not inventory-dependent.
			if not _nearby_groups.has(customer.group):
				_nearby_groups.append(customer.group)
				customer.group.highlight()
		else:
			# Seated customer — track and let can_interact decide the highlight.
			customer.on_player_entered()
			if not _nearby_interactables.has(customer):
				_nearby_interactables.append(customer)
			_refresh_interactable_highlight(customer)
	elif area.has_method("interact"):
		# Equipment / trash — track and let can_interact decide the highlight.
		if not _nearby_interactables.has(area):
			_nearby_interactables.append(area)
		_refresh_interactable_highlight(area)


func _on_area_exited(area):
	if area.has_method("is_waiting_for_order"):
		var customer = area
		if customer.group != null and not customer.group.is_seated:
			# Only unhighlight the group once every member has left range.
			var all_exited = true
			for c in customer.group.customers:
				if $Area2D.overlaps_area(c):
					all_exited = false
					break
			if all_exited and _nearby_groups.has(customer.group):
				_nearby_groups.erase(customer.group)
				customer.group.unhighlight()
		else:
			customer.on_player_exited()
			_nearby_interactables.erase(customer)
	elif area.has_method("interact"):
		_nearby_interactables.erase(area)
		area.unhighlight()


func _refresh_interactable_highlight(area):
	if not is_instance_valid(area):
		return
	if area.has_method("can_interact") and area.can_interact(inventory):
		area.highlight()
	else:
		area.unhighlight()


func _refresh_all_interactable_highlights():
	for area in _nearby_interactables:
		_refresh_interactable_highlight(area)


# ── Dash ──────────────────────────────────────────────────────────────────────

func _flash_error():
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1.6, 0.3, 0.3, 1), 0.04)
	tween.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.18)


func _try_dash():
	if _is_dashing or _dash_cooldown_timer > 0.0:
		_flash_error()
		return
	var input_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input_dir != Vector2.ZERO:
		_dash_direction = input_dir.normalized()
	else:
		_dash_direction = Vector2(last_horizontal, last_vertical).normalized()
		if _dash_direction == Vector2.ZERO:
			_dash_direction = Vector2(last_horizontal, 0)
	_is_dashing = true
	_dash_timer = DASH_DURATION
	_dash_cooldown_timer = DASH_COOLDOWN
	_on_dash_started()


func _tick_dash(delta):
	if _is_dashing:
		_dash_timer -= delta
		if _dash_timer <= 0.0:
			_is_dashing = false
			_on_dash_ended()
	if _dash_cooldown_timer > 0.0:
		_dash_cooldown_timer -= delta
		if _dash_cooldown_timer <= 0.0:
			_dash_cooldown_timer = 0.0
			_on_dash_ready()


func _on_dash_started():
	_squash_stretch(_dash_direction)
	modulate = Color(1, 1, 1, 0.7)


func _on_dash_ended():
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.1)


func _on_dash_ready():
	# Scale pop on all sprites so it fires regardless of which is currently visible.
	for sprite in [$SpriteIdle, $SpriteLeft, $SpriteRight]:
		var t = create_tween()
		t.tween_property(sprite, "scale", Vector2(1.5, 1.5), 0.07).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		t.tween_property(sprite, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN_OUT)


# ── Order handling ────────────────────────────────────────────────────────────

func _on_order_received(item_type: String):
	if pending_order_source != null:
		pending_order_source.order_placed.disconnect(_on_order_received)
		pending_order_source = null
	$OrderConnectionTimer.stop()
	inventory.append({"type": "order", "item": item_type})
	_update_inventory_display()  # also calls _refresh_all_interactable_highlights
	print("Inventory: ", inventory)


func _on_order_connection_timeout():
	if pending_order_source != null:
		pending_order_source.order_placed.disconnect(_on_order_received)
		pending_order_source = null
	print("Order connection timed out")


func _squash_stretch(direction: Vector2):
	var tween = create_tween()
	var squash = Vector2(0.9, 1.1) if abs(direction.y) > abs(direction.x) else Vector2(1.1, 0.9)
	tween.tween_property($SpriteLeft, "scale", squash, 0.08)
	tween.tween_property($SpriteLeft, "scale", Vector2.ONE, 0.08)

	var tween2 = create_tween()
	tween2.tween_property($SpriteRight, "scale", squash, 0.08)
	tween2.tween_property($SpriteRight, "scale", Vector2.ONE, 0.08)
