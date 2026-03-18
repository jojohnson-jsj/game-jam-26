extends Area2D

enum State { IDLE, COOKING, READY }

var current_state = State.IDLE

@export var item_type: String = "latte"
@export var cook_time: float = 10.0

var order_queue: Array = []
var max_queue_size = 1 # affected by hopper cat 

func _ready():
	max_queue_size = 1 + (1 if GlobalInventory.owns_cat('hopper_cat') else 0)
	
	cook_time = max(1.0, cook_time - GlobalInventory.get_cooking_bonus())
	
	$CookTimer.wait_time = cook_time
	$CookTimer.one_shot = true
	$CookTimer.timeout.connect(_on_cooking_finished)

	# Set machine sprite from GameManager registry if not already set in scene
	# SpriteReady shows the food art when the item is ready for pickup
	$SpriteReady.visible = false
	$CookingLabel.visible = false
	var food_tex = GameManager.get_food_sprite(item_type)
	if food_tex:
		$SpriteReady.texture = food_tex


func interact(player_inventory: Array) -> bool:
	match current_state:
		State.IDLE:
			var order = find_order_in_inventory(player_inventory)
			if order == null:
				return false
			player_inventory.erase(order)
			order_queue.append(order)
			$CookTimer.start()
			current_state = State.COOKING
			$CookingLabel.visible = true
			unhighlight()
			print("Started cooking: ", item_type)
			return true
		State.COOKING:
			if order_queue.size() < max_queue_size: # hopper cat
				var order = find_order_in_inventory(player_inventory)
				if order == null:
					return false
				player_inventory.erase(order)
				order_queue.append(order)
				print('queued order: ', item_type)
				return true
			else:
				print("Still cooking, please wait")
				return false
		State.READY:
			if player_inventory.size() < 2:
				# Normal pickup
				player_inventory.append({"type": "food", "item": item_type})
				$SpriteReady.visible = false
				current_state = State.IDLE
				print("Picked up: ", item_type)
				return true
			else:
				# Inventory full — check for a matching order to swap
				var order = find_order_in_inventory(player_inventory)
				if order == null:
					return false
				# Swap: remove order, add food, start cooking new order immediately
				player_inventory.erase(order)
				player_inventory.append({"type": "food", "item": item_type})
				$SpriteReady.visible = false
				order_queue.pop_front()
				order_queue.append(order)
				$CookTimer.start()
				current_state = State.COOKING
				$CookingLabel.visible = true
				unhighlight()
				print("Swapped order for food, started cooking next: ", item_type)
				return true
	return false


func find_order_in_inventory(player_inventory: Array):
	for item in player_inventory:
		if item["type"] == "order" and item["item"] == item_type:
			return item
	return null


func is_relevant() -> bool:
	return current_state == State.READY


func can_interact(player_inventory: Array) -> bool:
	match current_state:
		State.IDLE:
			return find_order_in_inventory(player_inventory) != null
		State.COOKING:
			return order_queue.size() < max_queue_size and find_order_in_inventory(player_inventory) != null
		State.READY:
			if player_inventory.size() < 2:
				return true
			return find_order_in_inventory(player_inventory) != null
	return false


func highlight():
	modulate = Color(1.4, 1.4, 1.4)


func unhighlight():
	modulate = Color(1, 1, 1)


func _on_cooking_finished():
	current_state = State.READY
	$SpriteReady.visible = true
	$CookingLabel.visible = false
	order_queue.pop_front()
	if not order_queue.is_empty():
		$CookTimer.start()
		current_state = State.COOKING
		$CookingLabel.visible = true
	print("Order ready: ", item_type)
