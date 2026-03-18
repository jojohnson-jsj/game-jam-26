extends Area2D

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
