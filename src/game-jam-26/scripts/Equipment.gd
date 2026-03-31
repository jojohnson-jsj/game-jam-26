extends Area2D

enum State { IDLE, COOKING, READY }

var current_state = State.IDLE

@export var item_type: String = "latte"
@export var cook_time: float = 10.0
@export var indicator_y_offset: float = 0.0
@export var collision_y_offset: float = 0.0
@export var unlocked: bool = true

var order_queue: Array = []
var max_queue_size = 1 # affected by hopper cat

const BAR_WIDTH  = 12  # slightly narrower than the ~14px visible sprite content
const BAR_HEIGHT = 4
var _bar_bg:   ColorRect = null
var _bar_fill: ColorRect = null
var _queue_label: Label = null
var _has_queued_order: bool = false  # true when a second order is cooking behind a ready item
var _queued_ready: bool = false       # true when second item is also done, waiting behind first

func _ready():
	add_to_group("equipment")

	max_queue_size = 1 + (1 if GameManager.has_hopper_cat else 0)
	cook_time = max(1.0, cook_time - GlobalInventory.get_cooking_bonus())
	$CookTimer.wait_time = cook_time
	$CookTimer.one_shot = true
	$CookTimer.timeout.connect(_on_cooking_finished)

	$SpriteReady.visible = false
	$CookingLabel.visible = false
	var machine_tex = GameManager.get_machine_sprite(item_type)
	if machine_tex:
		$Sprite2D.texture = machine_tex
	var food_tex = GameManager.get_food_sprite(item_type)
	if food_tex:
		$SpriteReady.texture = food_tex

	if collision_y_offset != 0.0:
		$CollisionShape2D.position.y += collision_y_offset

	if indicator_y_offset != 0.0:
		$SpriteReady.position.y += indicator_y_offset

	var bar_y = -15.0 + indicator_y_offset
	const O := 1.0
	var outline := ColorRect.new()
	outline.size = Vector2(BAR_WIDTH + O * 2, BAR_HEIGHT + O * 2)
	outline.position = Vector2(-BAR_WIDTH / 2.0 - O, bar_y - O)
	outline.color = Color(0.45, 0.28, 0.12, 1.0)
	outline.visible = false
	add_child(outline)

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

	_bar_bg.visibility_changed.connect(func(): outline.visible = _bar_bg.visible)

	# Queue indicator label — shows "+1" when a second order is queued
	_queue_label = Label.new()
	_queue_label.text = "+1"
	_queue_label.add_theme_font_size_override("font_size", 8)
	_queue_label.add_theme_color_override("font_color", Color(0.98, 0.95, 0.88))
	_queue_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	_queue_label.add_theme_constant_override("shadow_offset_x", 1)
	_queue_label.add_theme_constant_override("shadow_offset_y", 1)
	_queue_label.position = Vector2(4, bar_y - 10)
	_queue_label.visible = false
	add_child(_queue_label)

	if not unlocked:
		visible = false
		monitoring = false
		monitorable = false


func _process(_delta):
	if _bar_bg == null:
		return
	if _queue_label:
		var show_plus = (_has_queued_order and current_state == State.COOKING) or _queued_ready
		_queue_label.visible = show_plus
	match current_state:
		State.COOKING:
			_bar_bg.visible = true
			_bar_fill.visible = true
			if not $CookTimer.is_stopped():
				_bar_fill.size.x = BAR_WIDTH * (1.0 - $CookTimer.time_left / $CookTimer.wait_time)
		State.READY:
			if _has_queued_order and not $CookTimer.is_stopped():
				_bar_bg.visible = true
				_bar_fill.visible = true
				_bar_fill.size.x = BAR_WIDTH * (1.0 - $CookTimer.time_left / $CookTimer.wait_time)
			else:
				_bar_bg.visible = false
				_bar_fill.visible = false
		_:
			_bar_bg.visible = false
			_bar_fill.visible = false


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
				# Auto-redirect to an idle machine of the same type if one exists
				for equip in get_tree().get_nodes_in_group("equipment"):
					if equip != self and equip.item_type == item_type and equip.current_state == State.IDLE and equip.unlocked:
						return equip.interact(player_inventory)
				player_inventory.erase(order)
				order_queue.append(order)
				_has_queued_order = true
				$SpriteReady.position.y = -15.0 + indicator_y_offset - 5.0
				print('queued order: ', item_type)
				return true
			else:
				print("Still cooking, please wait")
				return false
		State.READY:
			var order = find_order_in_inventory(player_inventory)
			if order != null:
				player_inventory.erase(order)
				player_inventory.append({"type": "food", "item": item_type})
				$SpriteReady.visible = false
				$SpriteReady.position.y = -16.0 + indicator_y_offset
				_has_queued_order = false
				order_queue.pop_front()
				order_queue.append(order)
				$CookTimer.start()
				current_state = State.COOKING
				unhighlight()
				print("Swapped order for food, started cooking next: ", item_type)
				return true
			elif player_inventory.size() < 2:
				player_inventory.append({"type": "food", "item": item_type})
				$SpriteReady.position.y = -16.0 + indicator_y_offset
				_has_queued_order = false
				if _queued_ready:
					# Second already done — stay READY
					_queued_ready = false
					$SpriteReady.visible = true
					current_state = State.READY
				elif not $CookTimer.is_stopped():
					$SpriteReady.visible = false
					current_state = State.COOKING
				else:
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

func set_unlocked(value: bool) -> void:
	unlocked = value
	visible = value
	monitoring = value
	monitorable = value


func force_reset() -> void:
	current_state = State.IDLE
	order_queue.clear()
	$CookTimer.stop()
	$SpriteReady.visible = false
	$CookingLabel.visible = false
	_has_queued_order = false
	_queued_ready = false
	if _queue_label:
		_queue_label.visible = false
	unhighlight()


func _on_cooking_finished():
	$CookingLabel.visible = false
	order_queue.pop_front()
	if current_state == State.READY:
		# Second order finished while first is still sitting — mark queued ready
		_queued_ready = true
		_has_queued_order = false
		# Move sprite back to default position since bar is now hidden
		$SpriteReady.position.y = -16.0 + indicator_y_offset
	else:
		$SpriteReady.visible = true
		if not order_queue.is_empty():
			$CookTimer.start()
		current_state = State.READY
	print("Order ready: ", item_type)
