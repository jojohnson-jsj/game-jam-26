extends Node

signal money_changed(new_total)

var money: float = 0.0
var tables: Array = []
var waiting_queue: Array = []
var day_active: bool = false

@export var spawn_interval: float = 20.0
@export var day_duration: float = 180.0
@export var min_group_size: int = 1
@export var max_group_size: int = 4
@export var queue_patience: float = 30.0
@export var tip_floor_time: float = 40.0
@export var tip_ceiling_time: float = 120.0
@export var tip_max_percent: float = 0.3

const QUEUE_SLOT_SPACING: float = 48.0
const CUSTOMER_STACK_SPACING: float = 12.0

var spawn_timer: Timer
var day_timer: Timer
var queue_origin: Vector2 = Vector2.ZERO

const ITEM_PRICES = {
	"latte": 3.0,
	"pie": 8.0
}


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


func get_item_price(item: String) -> float:
	return ITEM_PRICES.get(item, 0.0)


func calculate_tip(delta: float) -> float:
	if delta <= tip_floor_time:
		return tip_max_percent
	if delta >= tip_ceiling_time:
		return 0.0
	return tip_max_percent * (1.0 - (delta - tip_floor_time) / (tip_ceiling_time - tip_floor_time))


func register_table(table):
	tables.append(table)
	table.table_finished.connect(_on_table_finished.bind(table))
	table.table_vacated.connect(_on_table_cleared.bind(table))
	print("Table registered. Total tables: ", tables.size())


func set_queue_origin(origin: Vector2):
	queue_origin = origin


func start_day():
	day_active = true
	spawn_timer.start()
	day_timer.start()
	spawn_group(randi_range(min_group_size, max_group_size))
	print("Day started")


func _on_spawn_timer_timeout():
	if not day_active:
		return
	spawn_group(randi_range(min_group_size, max_group_size))


func spawn_group(size: int):
	var customer_list = []
	for i in range(size):
		var customer = preload("res://scenes/Customer.tscn").instantiate()
		get_tree().current_scene.add_child(customer)
		customer_list.append(customer)

	var group = CustomerGroup.new()
	group.group_patience_expired.connect(_on_group_patience_expired)
	group.setup(customer_list, self, queue_patience)
	waiting_queue.append(group)
	_position_group(group, waiting_queue.size() - 1)
	print("Group of ", size, " added to queue. Queue size: ", waiting_queue.size())


func _position_group(group: CustomerGroup, slot_index: int):
	var slot_base = queue_origin + Vector2(-slot_index * QUEUE_SLOT_SPACING, 0)
	for i in range(group.customers.size()):
		group.customers[i].global_position = slot_base + Vector2(-i * CUSTOMER_STACK_SPACING, 0)


func _reposition_queue():
	for i in range(waiting_queue.size()):
		_position_group(waiting_queue[i], i)


func try_seat_next_group():
	if waiting_queue.is_empty():
		return
	var group = waiting_queue[0]
	var table = find_best_table(group.customers.size())
	if table == null:
		print("No available table for group of ", group.customers.size())
		return
	waiting_queue.pop_front()
	seat_group_at_table(group, table)
	_reposition_queue()


func find_best_table(group_size: int):
	var candidates = tables.filter(func(t): return t.is_available() and t.capacity >= group_size)
	if candidates.is_empty():
		return null
	candidates.sort_custom(func(a, b): return a.capacity < b.capacity)
	return candidates[0]


func seat_group_at_table(group: CustomerGroup, table):
	group.stop_waiting_timer()
	var room = get_tree().current_scene
	group.seat_at_table(table, room)
	table.seat_group(group.customers)
	print("Seated group of ", group.customers.size(), " at table with capacity ", table.capacity)


func on_group_clicked(group: CustomerGroup):
	var table = find_best_table(group.customers.size())
	if table == null:
		print("No available table for group of ", group.customers.size())
		return
	waiting_queue.erase(group)
	seat_group_at_table(group, table)
	_reposition_queue()


func _on_group_patience_expired(group: CustomerGroup):
	waiting_queue.erase(group)
	group.cleanup()
	_reposition_queue()
	print("Group removed from queue. Queue size: ", waiting_queue.size())


func _on_table_finished(payout: float, _table):
	print("Table finished. Payout: $", payout)
	add_money(payout)
	try_seat_next_group()


func on_payment_collected():
	print("Payment collected, checking queue")
	try_seat_next_group()


func _on_table_cleared(_table):
	print("Table cleared, trying to seat next group")
	try_seat_next_group()


func add_money(amount: float):
	money += amount
	emit_signal("money_changed", money)
	print("Total money: $", money)


func _on_day_ended():
	day_active = false
	spawn_timer.stop()
	for group in waiting_queue:
		group.cleanup()
	waiting_queue.clear()
	print("Day ended. Final money: $", money)
