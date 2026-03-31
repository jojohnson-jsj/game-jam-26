class_name CountertopPlate
extends Area2D

var stored_item: Dictionary = {}  # e.g. {"type": "food", "item": "latte"}

@onready var _tray_sprite: Sprite2D = $TraySprite
@onready var _food_sprite: Sprite2D = $FoodSprite
@onready var _collision: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	add_to_group("countertop_plates")
	# Defer so all nodes are in the tree and GameManager state is set
	call_deferred("_init_active_state")


func _init_active_state() -> void:
	set_active(GameManager.has_counter_cat)


func set_active(value: bool) -> void:
	visible = value
	_collision.disabled = not value
	if not value:
		# Drop any stored item when deactivated
		stored_item = {}
		_food_sprite.visible = false


func interact(player_inventory: Array) -> bool:
	if stored_item.is_empty():
		# Try to place a food item from inventory onto the plate
		var food = _find_food(player_inventory)
		if food == null:
			return false
		player_inventory.erase(food)
		stored_item = food
		_food_sprite.texture = GameManager.get_food_sprite(food["item"])
		_food_sprite.visible = true
		return true
	else:
		# Pick up the stored item if there's room
		if player_inventory.size() >= GlobalInventory.get_inventory_max():
			return false
		player_inventory.append(stored_item)
		stored_item = {}
		_food_sprite.visible = false
		return true


func can_interact(player_inventory: Array) -> bool:
	if stored_item.is_empty():
		return _find_food(player_inventory) != null
	else:
		return player_inventory.size() < GlobalInventory.get_inventory_max()


func is_relevant() -> bool:
	return not stored_item.is_empty()


func highlight() -> void:
	modulate = Color(1.4, 1.4, 1.4)


func unhighlight() -> void:
	modulate = Color(1, 1, 1)


func _find_food(inv: Array):
	for item in inv:
		if item.get("type") == "food":
			return item
	return null
