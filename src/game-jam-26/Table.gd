extends StaticBody2D

signal table_finished
signal table_vacated

enum State { AVAILABLE, OCCUPIED }

var current_state = State.AVAILABLE
var seated_customers: Array = []
var done_customers: int = 0
var capacity: int = 2

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
		customer.position = $SeatPositions.get_child(i).position

func _on_customer_done():
	done_customers += 1
	print("Customer done, ", done_customers, "/", seated_customers.size())
	if done_customers == seated_customers.size():
		emit_signal("table_finished")
		clear_table()

func _on_patience_expired():
	print("Patience expired, clearing table")
	emit_signal("table_vacated")
	clear_table()

func clear_table():
	print("Clearing table")
	for customer in seated_customers:
		customer.patience_expired.disconnect(_on_patience_expired)
		customer.customer_done.disconnect(_on_customer_done)
		customer.queue_free()
	seated_customers = []
	done_customers = 0
	current_state = State.AVAILABLE
