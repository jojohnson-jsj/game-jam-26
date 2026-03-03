extends CharacterBody2D

const SPEED = 200.0
const INVENTORY_MAX = 2

var inventory: Array = []
var pending_order_source = null

func _ready():
	$OrderConnectionTimer.wait_time = 0.5
	$OrderConnectionTimer.one_shot = true
	$OrderConnectionTimer.timeout.connect(_on_order_connection_timeout)

func _physics_process(delta):
	var direction = Vector2.ZERO
	
	if Input.is_action_pressed("ui_right"):
		direction.x += 1
	if Input.is_action_pressed("ui_left"):
		direction.x -= 1
	if Input.is_action_pressed("ui_down"):
		direction.y += 1
	if Input.is_action_pressed("ui_up"):
		direction.y -= 1
	
	if direction != Vector2.ZERO:
		direction = direction.normalized()
	
	velocity = direction * SPEED
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

func _on_order_received(item_type: String, customer_id: String):
	if pending_order_source != null:
		pending_order_source.order_placed.disconnect(_on_order_received)
		pending_order_source = null
	$OrderConnectionTimer.stop()
	inventory.append({"type": "order", "item": item_type, "customer_id": customer_id})
	print("Inventory: ", inventory)

func _on_order_connection_timeout():
	if pending_order_source != null:
		pending_order_source.order_placed.disconnect(_on_order_received)
		pending_order_source = null
	print("Order connection timed out")
