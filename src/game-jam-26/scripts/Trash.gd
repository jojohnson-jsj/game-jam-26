extends Area2D

func _ready() -> void:
	input_pickable = true
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	input_event.connect(_on_input_event)


func can_interact(player_inventory: Array) -> bool:
	return not player_inventory.is_empty()


func interact(player_inventory: Array) -> bool:
	if player_inventory.is_empty():
		return false
	player_inventory.clear()
	print("Inventory trashed")
	return true


func highlight():
	modulate = Color(1.4, 1.4, 1.4)


func unhighlight():
	modulate = Color(1, 1, 1)


func _on_mouse_entered():
	if GameManager.has_trash_cat:
		highlight()


func _on_mouse_exited():
	unhighlight()


func _on_input_event(_viewport, event, _shape_idx):
	if not GameManager.has_trash_cat:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var player = get_tree().get_first_node_in_group("player")
		if player and not player.inventory.is_empty():
			player.inventory.clear()
			player._update_inventory_display()
			unhighlight()
			print("Inventory trashed via click")
