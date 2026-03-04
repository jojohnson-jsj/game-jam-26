extends Area2D

signal order_placed(item_type)
signal patience_expired
signal customer_done

enum State { WAITING_FOR_PLAYER, ORDER_TAKEN, EATING, DONE }

var current_state = State.WAITING_FOR_PLAYER
@export var order_item: String = "latte"
@export var initial_patience: float = 30.0
@export var delivery_patience: float = 50.0
@export var eating_time: float = 10.0
var queue_entry_time: int = 0
var tip_delta: float = 0.0

func _ready():
	$PatienceTimer.wait_time = initial_patience
	$PatienceTimer.one_shot = true
	$EatingTimer.wait_time = eating_time
	$EatingTimer.one_shot = true
	$PatienceTimer.timeout.connect(_on_patience_expired)
	$EatingTimer.timeout.connect(_on_finished_eating)
	$PatienceTimer.start()

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
	print("Customer is eating, will finish in ", $EatingTimer.wait_time, " seconds")
	print("Tip delta: ", tip_delta, "s")

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
