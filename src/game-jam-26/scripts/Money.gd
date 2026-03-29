extends Area2D

var amount: float = 0.0
var source_table = null


func setup(payout: float, table):
	amount = payout
	source_table = table
	add_to_group("money")


func collect():
	Wallet.add_money(amount)
	if source_table != null:
		source_table.payment_collected()
	queue_free()


func can_interact(_player_inventory: Array) -> bool:
	return true


func interact(_player_inventory: Array) -> bool:
	var player = get_tree().get_first_node_in_group("player")
	if player:
		_fly_to(player.global_position)
	else:
		collect()
	return true


func _fly_to(target: Vector2) -> void:
	monitoring = false
	monitorable = false
	var tween = create_tween()
	tween.tween_property(self, "global_position", target, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(self, "scale", Vector2.ZERO, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(collect)


func highlight():
	modulate = Color(1.4, 1.4, 1.0, 1.0)


func unhighlight():
	modulate = Color(1.0, 1.0, 1.0, 1.0)
