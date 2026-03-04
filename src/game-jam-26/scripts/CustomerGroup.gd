class_name CustomerGroup
extends RefCounted

signal group_patience_expired(group)

var customers: Array = []
var waiting_timer: Timer
var tip_timer: Timer
var node_parent: Node

func setup(customer_list: Array, parent: Node):
	customers = customer_list
	node_parent = parent
	
	waiting_timer = Timer.new()
	waiting_timer.wait_time = 30.0
	waiting_timer.one_shot = true
	waiting_timer.timeout.connect(_on_waiting_patience_expired)
	parent.add_child(waiting_timer)
	
	tip_timer = Timer.new()
	tip_timer.one_shot = true
	parent.add_child(tip_timer)
	
	waiting_timer.start()
	tip_timer.start()
	print("Group of ", customers.size(), " waiting. Timer started.")

func stop_waiting_timer():
	waiting_timer.stop()

func get_tip_time() -> float:
	return tip_timer.get_time_left()

func cleanup():
	waiting_timer.queue_free()
	tip_timer.queue_free()
	for customer in customers:
		customer.queue_free()
	customers = []

func _on_waiting_patience_expired():
	print("Group patience expired in queue, booting group")
	emit_signal("group_patience_expired", self)
