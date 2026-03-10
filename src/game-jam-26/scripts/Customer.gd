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

var queue_entry_time: int = 0
var tip_delta: float = 0.0
var group = null
var table_center: Vector2 = Vector2.ZERO

const SPEED = 80.0
const ARRIVAL_THRESHOLD = 4.0

var _last_horizontal: float = 1.0
var _walk_target: Vector2 = Vector2.ZERO
var _walking_to_slot: bool = false


func _ready():
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
	_show_idle()


func _process(delta):
	if current_state == State.WAITING_FOR_PLAYER and group != null and not group.is_seated:
		$SpriteIdle.flip_h = true

	if current_state == State.WALKING_OUT:
		var direction = (_walk_target - global_position).normalized()
		global_position = global_position.move_toward(_walk_target, SPEED * delta)
		_update_animation(direction)
		if global_position.distance_to(_walk_target) <= ARRIVAL_THRESHOLD:
			queue_free()
		return

	if current_state != State.WALKING_TO_SEAT:
		return

	if _walking_to_slot:
		var slot_direction = (_walk_target - global_position).normalized()
		global_position = global_position.move_toward(_walk_target, SPEED * delta)
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
	global_position = global_position.move_toward(next, SPEED * delta)
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
	current_state = State.WALKING_OUT
	_walk_target = door_pos
	_walking_to_slot = false


func _set_nav_target(pos: Vector2):
	$NavigationAgent2D.target_position = pos


func _on_arrived_at_seat():
	_show_idle()
	$SpriteIdle.flip_h = global_position.x < table_center.x
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
	$PatienceTimer.wait_time = initial_patience
	$PatienceTimer.start()


func interact(player_inventory: Array):
	match current_state:
		State.WAITING_FOR_PLAYER:
			if player_inventory.size() >= 2:
				return
			modulate = Color(1, 1, 1)
			emit_signal("order_placed", order_item)
			current_state = State.ORDER_TAKEN
			$PatienceTimer.wait_time = delivery_patience
			$PatienceTimer.start()
		State.ORDER_TAKEN:
			var food = find_food_in_inventory(player_inventory)
			if food == null:
				return
			player_inventory.erase(food)
			receive_food()
		State.EATING:
			pass
		State.DONE:
			pass


func receive_food():
	tip_delta = (Time.get_ticks_msec() - queue_entry_time) / 1000.0
	current_state = State.EATING
	$PatienceTimer.stop()
	$EatingTimer.start()


func find_food_in_inventory(player_inventory: Array):
	for item in player_inventory:
		if item["type"] == "food" and item["item"] == order_item:
			return item
	return null


func _on_patience_expired():
	emit_signal("patience_expired")


func _on_finished_eating():
	current_state = State.DONE
	$EatingTimer.stop()
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
		# Click to seat only with Queue Cat
		if group != null and not group.is_seated and GameManager.has_queue_cat:
			group.unhighlight()
			group.on_clicked()
			return

		# QR Cat — click seated customer to take order
		if current_state == State.WAITING_FOR_PLAYER:
			var player = get_tree().get_first_node_in_group("player")
			if player and player.has_qr_cat:
				modulate = Color(1, 1, 1)
				player.receive_order_from_qr(self)


func is_waiting_for_order() -> bool:
	return current_state == State.WAITING_FOR_PLAYER
