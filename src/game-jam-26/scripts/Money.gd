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
	_spawn_pickup_label()
	var tween = create_tween()
	tween.tween_property(self, "global_position", target, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(self, "scale", Vector2.ZERO, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(collect)


func _spawn_pickup_label() -> void:
	var lbl := Label.new()
	lbl.text = "+$%.0f" % amount
	lbl.add_theme_font_size_override("font_size", 10)
	lbl.add_theme_color_override("font_color", Color(0.95, 0.85, 0.1, 1.0))
	lbl.add_theme_color_override("font_shadow_color", Color(0.28, 0.15, 0.05, 1.0))
	lbl.add_theme_constant_override("shadow_offset_x", 1)
	lbl.add_theme_constant_override("shadow_offset_y", 1)
	lbl.z_index = 20
	get_tree().current_scene.add_child(lbl)
	lbl.global_position = global_position + Vector2(-10, -8)
	var t = lbl.create_tween()
	t.tween_property(lbl, "global_position", lbl.global_position + Vector2(0, -20), 0.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(lbl, "modulate:a", 0.0, 0.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.tween_callback(lbl.queue_free)


func highlight():
	modulate = Color(1.4, 1.4, 1.0, 1.0)


func unhighlight():
	modulate = Color(1.0, 1.0, 1.0, 1.0)
