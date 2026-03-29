class_name CustomerGroup
extends RefCounted

signal group_patience_expired(group)

var customers: Array = []
var waiting_timer: Timer
var node_parent: Node
var is_seated: bool = false


func setup(customer_list: Array, parent: Node, waiting_time: float = 30.0):
	customers = customer_list
	node_parent = parent
	var queue_entry_time = Time.get_ticks_msec()
	for customer in customer_list:
		customer.queue_entry_time = queue_entry_time
		customer.group = self

	waiting_timer = Timer.new()
	waiting_timer.wait_time = waiting_time
	waiting_timer.one_shot = true
	waiting_timer.process_mode = Node.PROCESS_MODE_PAUSABLE
	waiting_timer.timeout.connect(_on_waiting_patience_expired)
	parent.add_child(waiting_timer)
	waiting_timer.start()
	print("Group of ", customers.size(), " waiting. Timer started.")


func stop_waiting_timer():
	waiting_timer.stop()


func seat_at_table(table, _room_scene: Node):
	is_seated = true
	print("Group is_seated set to: ", is_seated)
	# rest unchanged
	var seat_positions = table.get_node("SeatPositions")
	var table_center = table.global_position
	for i in range(customers.size()):
		var customer = customers[i]
		var seat_node = seat_positions.get_child(i)
		customer.table_center = table_center
		customer.navigate_to(seat_node.global_position)
	print("Group of ", customers.size(), " navigating to seats")


func highlight():
	for customer in customers:
		customer.modulate = Color(1.4, 1.4, 1.4)


func unhighlight():
	for customer in customers:
		customer.modulate = Color(1, 1, 1)


func on_clicked():
	if is_seated:
		return
	GameManager.on_group_clicked(self)


func cleanup():
	waiting_timer.queue_free()
	for customer in customers:
		customer.walk_out(GameManager.door_point)
	customers = []


func _on_waiting_patience_expired():
	print("Group patience expired in queue, booting group")
	emit_signal("group_patience_expired", self)
