class_name CustomerGroup
extends RefCounted

signal group_patience_expired(group)

var customers: Array = []
var waiting_timer: Timer
var node_parent: Node

func setup(customer_list: Array, parent: Node, waiting_time: float = 30.0):
	customers = customer_list
	node_parent = parent

	var queue_entry_time = Time.get_ticks_msec()
	for customer in customer_list:
		customer.queue_entry_time = queue_entry_time

	waiting_timer = Timer.new()
	waiting_timer.wait_time = waiting_time
	waiting_timer.one_shot = true
	waiting_timer.timeout.connect(_on_waiting_patience_expired)
	parent.add_child(waiting_timer)
	waiting_timer.start()

	print("Group of ", customers.size(), " waiting. Timer started.")

func stop_waiting_timer():
	waiting_timer.stop()

func cleanup():
	waiting_timer.queue_free()
	for customer in customers:
		customer.queue_free()
	customers = []

func _on_waiting_patience_expired():
	print("Group patience expired in queue, booting group")
	emit_signal("group_patience_expired", self)
