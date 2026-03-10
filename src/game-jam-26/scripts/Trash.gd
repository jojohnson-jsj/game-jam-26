extends Area2D

func interact(player_inventory: Array):
	if player_inventory.is_empty():
		return
	player_inventory.clear()
	print("Inventory trashed")
