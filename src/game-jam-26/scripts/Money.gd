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
	collect()
	return true


func highlight():
	modulate = Color(1.4, 1.4, 1.0, 1.0)


func unhighlight():
	modulate = Color(1.0, 1.0, 1.0, 1.0)
