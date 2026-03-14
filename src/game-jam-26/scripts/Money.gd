extends Area2D

var amount: float = 0.0
var source_table = null

func setup(payout: float, table):
	amount = payout
	source_table = table

func collect():
	Wallet.add_money(amount)
	if source_table != null:
		source_table.payment_collected()
	queue_free()

func interact(_player_inventory: Array):
	collect()
