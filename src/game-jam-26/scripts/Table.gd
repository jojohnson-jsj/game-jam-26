extends StaticBody2D

signal table_finished(payout)
signal table_vacated

enum State { AVAILABLE, OCCUPIED, AWAITING_PAYMENT }

var current_state = State.AVAILABLE
var seated_customers: Array = []
var done_customers: int = 0
var capacity: int = 4

func _ready():
	GameManager.register_table(self)

func is_available() -> bool:
	return current_state == State.AVAILABLE

func seat_group(customers: Array):
	seated_customers = customers
	done_customers = 0
	current_state = State.OCCUPIED
	for i in range(customers.size()):
		var customer = customers[i]
		customer.patience_expired.connect(_on_patience_expired)
		customer.customer_done.connect(_on_customer_done)
		if i < $SeatPositions.get_child_count():
			customer.position = $SeatPositions.get_child(i).position

func calculate_payout() -> float:
	var total = 0.0
	for customer in seated_customers:
		var flat_rate = GameManager.get_item_price(customer.order_item)
		var tip = flat_rate * GameManager.calculate_tip(customer.tip_delta)
		total += flat_rate + tip
		print("Customer payout: $", flat_rate, " + $", tip, " tip (delta: ", customer.tip_delta, "s)")
	return total

func _on_customer_done():
	done_customers += 1
	print("Customer done, ", done_customers, "/", seated_customers.size())
	if done_customers == seated_customers.size():
		var payout = calculate_payout()
		clear_table()
		spawn_money(payout)
		emit_signal("table_finished", payout)

func spawn_money(payout: float):
	var money = preload("res://scenes/Money.tscn").instantiate()
	money.setup(payout, self)
	get_parent().add_child(money)
	money.global_position = global_position
	print("Money spawned at: ", money.global_position)

func _on_patience_expired():
	print("Patience expired, clearing table")
	clear_table()
	emit_signal("table_vacated")

func clear_table():
	print("Clearing table")
	for customer in seated_customers:
		customer.patience_expired.disconnect(_on_patience_expired)
		customer.customer_done.disconnect(_on_customer_done)
		customer.queue_free()
	seated_customers = []
	done_customers = 0
	current_state = State.AWAITING_PAYMENT

func payment_collected():
	current_state = State.AVAILABLE
	print("Payment collected, table now available")
	GameManager.on_payment_collected()
