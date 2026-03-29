extends Node2D


func startDay():
	GameManager.set_queue_origin($QueueOrigin.global_position)
	GameManager.set_door_point($DoorPoint.global_position)
	_apply_equipment_unlocks()
	GameManager.start_day()


func _apply_equipment_unlocks() -> void:
	_apply_unlocks("LatteMachine", GlobalInventory.equipment_amt("latte_machine"), 4)
	_apply_unlocks("Oven", GlobalInventory.equipment_amt("oven"), 4)
	_apply_bed_unlocks(GlobalInventory.equipment_amt("cat_bed"), 7)


func _apply_unlocks(prefix: String, amt: int, max_count: int) -> void:
	for i in range(1, max_count + 1):
		var node = get_node_or_null(prefix + str(i))
		if node and node.has_method("set_unlocked"):
			node.set_unlocked(i <= amt)


func _apply_bed_unlocks(amt: int, max_count: int) -> void:
	for i in range(1, max_count + 1):
		var node = get_node_or_null("NonTableCatBed" + str(i))
		if node and node.has_method("set_unlocked"):
			node.set_unlocked(i <= amt)
