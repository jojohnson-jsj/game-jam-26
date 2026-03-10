class_name CatBed
extends Node2D

enum BedType { TABLE, NON_TABLE }

@export var bed_type: BedType = BedType.NON_TABLE
@export var unlocked: bool = false

# For TABLE beds only — assign the Table node this bed sits on in the editor
@export var assigned_table: NodePath

var assigned_cat: Cat = null

signal cat_assigned(cat: Cat)
signal cat_removed


func assign_cat(cat: Cat) -> bool:
	if not unlocked:
		return false
	var required_bed = BedType.TABLE if cat.cat_type == Cat.CatType.TABLE else BedType.NON_TABLE
	if required_bed != bed_type:
		return false
	if assigned_cat != null:
		_deactivate_cat(assigned_cat)
	assigned_cat = cat
	emit_signal("cat_assigned", cat)
	_activate_cat(cat)
	return true


func remove_cat():
	if assigned_cat == null:
		return
	_deactivate_cat(assigned_cat)
	assigned_cat = null
	emit_signal("cat_removed")


func _get_player():
	return get_tree().get_first_node_in_group("player")


func _get_table():
	if assigned_table.is_empty():
		return null
	return get_node(assigned_table)


func _activate_cat(cat: Cat):
	match cat.ability_type:
		Cat.AbilityType.HERMES:
			var player = _get_player()
			if player:
				player.has_dash_cat = true

		Cat.AbilityType.MONEY:
			var table = _get_table()
			if table:
				table.has_money_cat = true

		Cat.AbilityType.QR:
			var player = _get_player()
			if player:
				player.has_qr_cat = true

		Cat.AbilityType.QUEUE:
			GameManager.has_queue_cat = true


func _deactivate_cat(cat: Cat):
	match cat.ability_type:
		Cat.AbilityType.HERMES:
			var player = _get_player()
			if player:
				player.has_dash_cat = false

		Cat.AbilityType.MONEY:
			var table = _get_table()
			if table:
				table.has_money_cat = false

		Cat.AbilityType.QR:
			var player = _get_player()
			if player:
				player.has_qr_cat = false

		Cat.AbilityType.QUEUE:
			GameManager.has_queue_cat = false
