extends Area2D

enum State { IDLE, COOKING, READY }

var current_state = State.IDLE
var item_type = "latte"
var cook_time = 10.0
var cooking_customer_id: String = ""

func _ready():
	$CookTimer.wait_time = cook_time
	$CookTimer.one_shot = true
	$CookTimer.timeout.connect(_on_cooking_finished)

func interact(player_inventory: Array):
	match current_state:
		State.IDLE:
			var order = find_order_in_inventory(player_inventory)
			if order == null:
				return
			cooking_customer_id = order["customer_id"]
			player_inventory.erase(order)
			$CookTimer.start()
			current_state = State.COOKING
			print("Started cooking: ", item_type)
		State.COOKING:
			print("Still cooking, please wait")
		State.READY:
			if player_inventory.size() >= 2:
				return
			player_inventory.append({"type": "food", "item": item_type, "customer_id": cooking_customer_id})
			current_state = State.IDLE
			print("Picked up: ", item_type)

func find_order_in_inventory(player_inventory: Array):
	for item in player_inventory:
		if item["type"] == "order" and item["item"] == item_type:
			return item
	return null

func _on_cooking_finished():
	current_state = State.READY
	print("Order ready: ", item_type)
