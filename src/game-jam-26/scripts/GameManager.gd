extends Node

signal money_changed(new_total)

var money: float = 0.0
var tables: Array = []
var waiting_queue: Array = []
var day_active: bool = false
var spawn_interval: float = 15.0
var day_duration: float = 180.0

var spawn_timer: Timer
var day_timer: Timer

func _ready():
	spawn_timer = Timer.new()
	spawn_timer.wait_time = spawn_interval
	spawn_timer.one_shot = false
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	add_child(spawn_timer)

	day_timer = Timer.new()
	day_timer.wait_time = day_duration
	day_timer.one_shot = true
	day_timer.timeout.connect(_on_day_ended)
	add_child(day_timer)

func register_table(table):
	tables.append(table)
	table.table_finished.connect(_on_table_cleared.bind(table))
	table.table_vacated.connect(_on_table_cleared.bind(table))
	print("Table registered. Total tables: ", tables.size())

func start_day():
	day_active = true
	spawn_timer.start()
	day_timer.start()
	print("Day started")

func _on_spawn_timer_timeout():
	if not day_active:
		return
	var group_size = randi_range(1, 4)
	spawn_group(group_size)

func spawn_group(size: int):
	var customer_list = []
	for i in range(size):
		var customer = preload("res://scenes/Customer.tscn").instantiate()
		customer_list.append(customer)
	
	var group = CustomerGroup.new()
	group.group_patience_expired.connect(_on_group_patience_expired)
	group.setup(customer_list, self)
	
	waiting_queue.append(group)
	print("Group of ", size, " added to queue. Queue size: ", waiting_queue.size())
	try_seat_next_group()

func try_seat_next_group():
	if waiting_queue.is_empty():
		return
	var available_table = find_available_table(waiting_queue[0].customers.size())
	if available_table == null:
		print("No available table for group of ", waiting_queue[0].customers.size())
		return
	var group = waiting_queue.pop_front()
	seat_group_at_table(group, available_table)

func find_available_table(group_size: int):
	for table in tables:
		if table.is_available() and table.capacity >= group_size:
			return table
	return null

func seat_group_at_table(group: CustomerGroup, table):
	group.stop_waiting_timer()
	for customer in group.customers:
		table.add_child(customer)
	table.seat_group(group.customers)
	print("Seated group of ", group.customers.size(), " at table")

func _on_group_patience_expired(group: CustomerGroup):
	waiting_queue.erase(group)
	group.cleanup()
	print("Group removed from queue. Queue size: ", waiting_queue.size())
	
func _on_table_cleared(_table):
	print("Table cleared, trying to seat next group")
	try_seat_next_group()

func add_money(amount: float):
	money += amount
	emit_signal("money_changed", money)
	print("Money: $", money)

func _on_day_ended():
	day_active = false
	spawn_timer.stop()
	for group in waiting_queue:
		group.cleanup()
	waiting_queue.clear()
	print("Day ended. Final money: $", money)
