extends Area2D

enum State { IDLE, COOKING, READY }

var current_state = State.IDLE

@export var item_type: String = "latte"
@export var cook_time: float = 10.0
@export var indicator_y_offset: float = 0.0

var order_queue: Array = []
var max_queue_size = 1 # affected by hopper cat

const BAR_WIDTH  = 12  # slightly narrower than the ~14px visible sprite content
const BAR_HEIGHT = 4
var _bar_bg:   ColorRect = null
var _bar_fill: ColorRect = null

func _ready():
	add_to_group("equipment")

	max_queue_size = 1 + (1 if GlobalInventory.owns_cat('hopper_cat') else 0)

	cook_time = max(1.0, cook_time - GlobalInventory.get_cooking_bonus())

	$CookTimer.wait_time = cook_time
	$CookTimer.one_shot = true
	$CookTimer.timeout.connect(_on_cooking_finished)

	# Set machine and food sprites from GameManager registry
	# SpriteReady shows the food art when the item is ready for pickup
	$SpriteReady.visible = false
	$CookingLabel.visible = false
	var machine_tex = GameManager.get_machine_sprite(item_type)
	if machine_tex:
		$Sprite2D.texture = machine_tex
	var food_tex = GameManager.get_food_sprite(item_type)
	if food_tex:
		$SpriteReady.texture = food_tex

	if indicator_y_offset != 0.0:
		$SpriteReady.position.y += indicator_y_offset

	# Progress bar — centered in the region where "..." used to appear (y=-29 to y=-6)
	var bar_y = -20.0 + indicator_y_offset
	_bar_bg = ColorRect.new()
	_bar_bg.size = Vector2(BAR_WIDTH, BAR_HEIGHT)
	_bar_bg.position = Vector2(-BAR_WIDTH / 2.0, bar_y)
	_bar_bg.color = Color(0.15, 0.15, 0.15)
	_bar_bg.visible = false
	add_child(_bar_bg)

	_bar_fill = ColorRect.new()
	_bar_fill.size = Vector2(0, BAR_HEIGHT)
	_bar_fill.position = Vector2(-BAR_WIDTH / 2.0, bar_y)
	_bar_fill.color = Color(0.9, 0.6, 0.1)
	_bar_fill.visible = false
	add_child(_bar_fill)


func _process(_delta):
	if _bar_bg == null:
		return
	var cooking = (current_state == State.COOKING)
	_bar_bg.visible = cooking
	_bar_fill.visible = cooking
	if cooking and not $CookTimer.is_stopped():
		var ratio = 1.0 - ($CookTimer.time_left / $CookTimer.wait_time)
		_bar_fill.size.x = BAR_WIDTH * ratio


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
			var order = find_order_in_inventory(player_inventory)
			if order != null:
				# Always swap: pick up food and immediately start cooking the held order
				player_inventory.erase(order)
				player_inventory.append({"type": "food", "item": item_type})
				$SpriteReady.visible = false
				order_queue.pop_front()
				order_queue.append(order)
				$CookTimer.start()
				current_state = State.COOKING
				unhighlight()
				print("Swapped order for food, started cooking next: ", item_type)
				return true
			elif player_inventory.size() < 2:
				# No order in hand — normal pickup if there's room
				player_inventory.append({"type": "food", "item": item_type})
				$SpriteReady.visible = false
				current_state = State.IDLE
				print("Picked up: ", item_type)
				return true
			return false
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
			# Interactable if holding a matching order (swap) or inventory has room (pickup)
			return find_order_in_inventory(player_inventory) != null or player_inventory.size() < 2
	return false


func highlight():
	modulate = Color(1.4, 1.4, 1.4)


func unhighlight():
	modulate = Color(1, 1, 1)


func apply_day_bonuses() -> void:
	max_queue_size = 1 + (1 if GameManager.has_hopper_cat else 0)

func force_reset() -> void:
	current_state = State.IDLE
	order_queue.clear()
	$CookTimer.stop()
	$SpriteReady.visible = false
	$CookingLabel.visible = false
	unhighlight()


func _on_cooking_finished():
	current_state = State.READY
	$SpriteReady.visible = true
	$CookingLabel.visible = false
	order_queue.pop_front()
	if not order_queue.is_empty():
		$CookTimer.start()
		current_state = State.COOKING

	print("Order ready: ", item_type)
