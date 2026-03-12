extends CharacterBody2D

const SPEED = 150.0
const INVENTORY_MAX = 2
const ACCELERATION = 1800.0
const FRICTION = 1400.0

@export var DASH_SPEED = 600.0
@export var DASH_DURATION = 0.12
@export var DASH_COOLDOWN = 5.0

var inventory: Array = []
var _nearby_groups: Array = []
var pending_order_source = null
var last_horizontal = 1
var last_vertical = 0
var was_moving = false

# Cat ability flags
var has_dash_cat: bool = true
var has_qr_cat: bool = true

# Dash state
var _is_dashing: bool = false
var _dash_timer: float = 0.0
var _dash_cooldown_timer: float = 0.0
var _dash_direction: Vector2 = Vector2.ZERO


func _ready():
	$OrderConnectionTimer.wait_time = 0.5
	$OrderConnectionTimer.one_shot = true
	$OrderConnectionTimer.timeout.connect(_on_order_connection_timeout)
	$Area2D.area_entered.connect(_on_area_entered)
	$Area2D.area_exited.connect(_on_area_exited)


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
		velocity = velocity.move_toward(direction * SPEED, ACCELERATION * delta)
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

		# Queued customer — seat via E (only if not already seated)
		if body.get("group") != null and not body.group.is_seated:
			body.group.on_clicked()
			return

		# All other interactables (seated customers, equipment, money, trash)
		if body.has_signal("order_placed") and body.is_waiting_for_order():
			if not body.order_placed.is_connected(_on_order_received):
				pending_order_source = body
				body.order_placed.connect(_on_order_received)
				$OrderConnectionTimer.start()

		body.interact(inventory)
		return


# Called by QR Cat click flow directly on the customer
func receive_order_from_qr(customer) -> void:
	if inventory.size() >= INVENTORY_MAX:
		return
	if not customer.is_waiting_for_order():
		return
	if not customer.order_placed.is_connected(_on_order_received):
		pending_order_source = customer
		customer.order_placed.connect(_on_order_received)
	customer.interact(inventory)


# ── Proximity highlight ───────────────────────────────────────────────────────

func _on_area_entered(area):
	if not area.has_method("is_waiting_for_order"):
		return
	var customer = area
	if customer.group == null or customer.group.is_seated:
		return
	if not _nearby_groups.has(customer.group):
		_nearby_groups.append(customer.group)
		customer.group.highlight()


func _on_area_exited(area):
	if not area.has_method("is_waiting_for_order"):
		return
	var customer = area
	if customer.group == null:
		return
	# Only remove this specific group if ALL its customers have left the area
	var all_exited = true
	for c in customer.group.customers:
		if $Area2D.overlaps_area(c):
			all_exited = false
			break
	if all_exited and _nearby_groups.has(customer.group):
		_nearby_groups.erase(customer.group)
		customer.group.unhighlight()


# ── Dash ──────────────────────────────────────────────────────────────────────

func _try_dash():
	if _is_dashing or _dash_cooldown_timer > 0.0:
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
	tween.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.08)
	tween.tween_property(self, "modulate", Color(1, 0.4, 0.4, 1), 0.05)
	tween.tween_property(self, "modulate", Color(1, 0.6, 0.6, 1), 0.3)


func _on_dash_ready():
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1.3, 1.3, 1.3, 1), 0.05)
	tween.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.1)


# ── Order handling ────────────────────────────────────────────────────────────

func _on_order_received(item_type: String):
	if pending_order_source != null:
		pending_order_source.order_placed.disconnect(_on_order_received)
		pending_order_source = null
	$OrderConnectionTimer.stop()
	inventory.append({"type": "order", "item": item_type})
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
