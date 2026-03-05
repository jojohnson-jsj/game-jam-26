extends CharacterBody2D

const SPEED = 150.0
const INVENTORY_MAX = 2
const ACCELERATION = 1800.0
const FRICTION = 1400.0

var inventory: Array = []
var pending_order_source = null
var last_horizontal = 1  # 1 = right, -1 = left
var was_moving = false

func _ready():
	$OrderConnectionTimer.wait_time = 0.5
	$OrderConnectionTimer.one_shot = true
	$OrderConnectionTimer.timeout.connect(_on_order_connection_timeout)
	
func _physics_process(delta):
	var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	if direction != Vector2.ZERO:
		if not was_moving:
			$SpriteIdle.visible = false
			_squash_stretch(direction)
		was_moving = true
		if direction.x != 0:
			last_horizontal = sign(direction.x)
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
		var bodies = $Area2D.get_overlapping_areas()
		for body in bodies:
			if body.has_method("interact"):
				if body.has_signal("order_placed") and not body.order_placed.is_connected(_on_order_received) and body.is_waiting_for_order():
					pending_order_source = body
					body.order_placed.connect(_on_order_received)
					$OrderConnectionTimer.start()
				body.interact(inventory)

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
