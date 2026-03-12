extends StaticBody2D

signal table_finished(payout)
signal table_vacated

enum State { AVAILABLE, OCCUPIED, AWAITING_PAYMENT }

@export var capacity: int = 4

var current_state = State.AVAILABLE
var seated_customers: Array = []
var done_customers: int = 0
var has_money_cat: bool = false


func _ready():
	GameManager.register_table(self)


func is_available() -> bool:
	return current_state == State.AVAILABLE


func seat_group(customers: Array):
	seated_customers = customers
	done_customers = 0
	current_state = State.OCCUPIED
	for customer in customers:
		customer.patience_expired.connect(_on_patience_expired)
		customer.customer_done.connect(_on_customer_done)


func calculate_payout() -> float:
	var total = 0.0
	for customer in seated_customers:
		var flat_rate = GameManager.get_item_price(customer.order_item)
		var tip = flat_rate * GameManager.calculate_tip(customer.tip_delta)
		total += flat_rate + tip
	return total


func _on_customer_done():
	done_customers += 1
	if done_customers == seated_customers.size():
		var payout = calculate_payout()
		clear_table()
		spawn_money(payout)
		emit_signal("table_finished", payout)


func _on_patience_expired():
	clear_table()
	emit_signal("table_vacated")


func clear_table():
	for customer in seated_customers:
		if customer.patience_expired.is_connected(_on_patience_expired):
			customer.patience_expired.disconnect(_on_patience_expired)
		if customer.customer_done.is_connected(_on_customer_done):
			customer.customer_done.disconnect(_on_customer_done)
		customer.walk_out(GameManager.door_point)
	seated_customers = []
	done_customers = 0
	current_state = State.AWAITING_PAYMENT


func spawn_money(payout: float):
	var money = preload("res://scenes/Money.tscn").instantiate()
	money.setup(payout, self)
	get_parent().add_child(money)
	money.global_position = global_position

	# Money Cat — collect automatically instead of waiting for player
	if has_money_cat:
		call_deferred("_auto_collect", money)


func _auto_collect(money_node):
	print("Auto collect called, valid: ", is_instance_valid(money_node))
	if money_node and is_instance_valid(money_node):
		print("Calling collect")
		money_node.collect()


func payment_collected():
	current_state = State.AVAILABLE
	GameManager.on_payment_collected()
