extends Area2D

enum State { IDLE, COOKING, READY }

var current_state = State.IDLE

@export var item_type: String = "latte"
@export var cook_time: float = 10.0


func _ready():
	$CookTimer.wait_time = cook_time
	$CookTimer.one_shot = true
	$CookTimer.timeout.connect(_on_cooking_finished)

	# Set machine sprite from GameManager registry if not already set in scene
	# SpriteReady shows the food art when the item is ready for pickup
	$SpriteReady.visible = false
	var food_tex = GameManager.get_food_sprite(item_type)
	if food_tex:
		$SpriteReady.texture = food_tex


func interact(player_inventory: Array):
	match current_state:
		State.IDLE:
			var order = find_order_in_inventory(player_inventory)
			if order == null:
				return
			player_inventory.erase(order)
			$CookTimer.start()
			current_state = State.COOKING
			print("Started cooking: ", item_type)
		State.COOKING:
			print("Still cooking, please wait")
		State.READY:
			if player_inventory.size() < 2:
				# Normal pickup
				player_inventory.append({"type": "food", "item": item_type})
				$SpriteReady.visible = false
				current_state = State.IDLE
				print("Picked up: ", item_type)
			else:
				# Inventory full — check for a matching order to swap
				var order = find_order_in_inventory(player_inventory)
				if order == null:
					return
				# Swap: remove order, add food, start cooking new order immediately
				player_inventory.erase(order)
				player_inventory.append({"type": "food", "item": item_type})
				$SpriteReady.visible = false
				$CookTimer.start()
				current_state = State.COOKING
				print("Swapped order for food, started cooking next: ", item_type)


func find_order_in_inventory(player_inventory: Array):
	for item in player_inventory:
		if item["type"] == "order" and item["item"] == item_type:
			return item
	return null


func _on_cooking_finished():
	current_state = State.READY
	$SpriteReady.visible = true
	print("Order ready: ", item_type)
