extends Area2D

signal order_placed(item_type)
signal patience_expired
signal customer_done

enum State { WALKING_TO_SEAT, WAITING_FOR_PLAYER, ORDER_TAKEN, EATING, DONE }

var current_state = State.WALKING_TO_SEAT

@export var order_item: String = "latte"
@export var initial_patience: float = 30.0
@export var delivery_patience: float = 50.0
@export var eating_time: float = 10.0

var queue_entry_time: int = 0
var tip_delta: float = 0.0
var group = null

const SPEED = 80.0
const ARRIVAL_THRESHOLD = 4.0


func _ready():
	$NavigationAgent2D.path_desired_distance = ARRIVAL_THRESHOLD
	$NavigationAgent2D.target_desired_distance = ARRIVAL_THRESHOLD

	$PatienceTimer.one_shot = true
	$EatingTimer.wait_time = eating_time
	$EatingTimer.one_shot = true
	$PatienceTimer.timeout.connect(_on_patience_expired)
	$EatingTimer.timeout.connect(_on_finished_eating)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	input_event.connect(_on_input_event)


func _process(delta):
	if current_state != State.WALKING_TO_SEAT:
		return
	if $NavigationAgent2D.is_navigation_finished():
		_on_arrived_at_seat()
		return
	var next = $NavigationAgent2D.get_next_path_position()
	global_position = global_position.move_toward(next, SPEED * delta)


func navigate_to(target_global: Vector2):
	current_state = State.WALKING_TO_SEAT
	call_deferred("_set_nav_target", target_global)


func _set_nav_target(pos: Vector2):
	$NavigationAgent2D.target_position = pos


func _on_arrived_at_seat():
	current_state = State.WAITING_FOR_PLAYER
	$PatienceTimer.wait_time = initial_patience
	$PatienceTimer.start()


func _on_mouse_entered():
	if group != null and not group.is_seated:
		group.highlight()


func _on_mouse_exited():
	if group != null and not group.is_seated:
		group.unhighlight()


func _on_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if group != null:
			group.unhighlight()
			group.on_clicked()


func interact(player_inventory: Array):
	match current_state:
		State.WAITING_FOR_PLAYER:
			if player_inventory.size() >= 2:
				return
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
	print("Customer eating, finishes in ", $EatingTimer.wait_time, "s | tip_delta: ", tip_delta, "s")


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
	print("Customer done eating")
	emit_signal("customer_done")


func is_waiting_for_order() -> bool:
	return current_state == State.WAITING_FOR_PLAYER
