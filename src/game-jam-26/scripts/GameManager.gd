extends Node

signal day_ended(final_money)

var tables: Array = []
var waiting_queue: Array = []
var day_active: bool = false

@export var spawn_interval: float = 15.0
@export var day_duration: float = 180.0
@export var min_group_size: int = 1
@export var max_group_size: int = 4
@export var queue_patience: float = 30.0
@export var tip_floor_time: float = 40.0
@export var tip_ceiling_time: float = 120.0
@export var tip_max_percent: float = 0.3

const QUEUE_SLOT_SPACING: float = 24.0
const CUSTOMER_STACK_SPACING: float = 12.0

var spawn_timer: Timer
var day_timer: Timer
var queue_origin: Vector2 = Vector2.ZERO
var door_point: Vector2 = Vector2.ZERO

var has_queue_cat: bool  # initialized in _ready() from DebugConfig

const ITEM_PRICES = {
	"latte": 3.0,
	"pie": 8.0
}

# Texture registries — add new item types here as art becomes available
const ORDER_SPRITES = {
	"latte": preload("res://assets/food/orders/order_sprite_latte.png"),
}

const FOOD_SPRITES = {
	"latte": preload("res://assets/food/food/food_sprite_latte.png"),
}


func get_order_sprite(item_type: String) -> Texture2D:
	return ORDER_SPRITES.get(item_type, null)


func get_food_sprite(item_type: String) -> Texture2D:
	return FOOD_SPRITES.get(item_type, null)


func _ready():
	has_queue_cat = DebugConfig.queue_cat_enabled
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


func set_queue_origin(origin: Vector2):
	queue_origin = origin


func set_door_point(pos: Vector2):
	door_point = pos


func start_day():
	spawn_timer.wait_time = max(5.0, spawn_interval - GlobalInventory.get_spawn_interval_reduction())
	queue_patience = 30.0 + GlobalInventory.get_patience_bonus()
	tip_floor_time = 40.0 + GlobalInventory.get_tip_floor_bonus()
	
	day_active = true
	spawn_timer.start()
	day_timer.start()
	call_deferred("spawn_group", randi_range(min_group_size, max_group_size))
	print("Day started")


func _on_spawn_timer_timeout():
	if not day_active:
		return
	spawn_group(randi_range(min_group_size, max_group_size))


func spawn_group(size: int):

	#reroll groups of 1 for valentines cat
	if size == 1 and randf() < GlobalInventory.get_valentines_reduction():
		size = randi_range(2, max_group_size)

	# Shuffle the 7 available variant indices so no two customers in the same
	# group share a sprite. For groups larger than 7 the list wraps around.
	var variant_indices = range(6)
	variant_indices.shuffle()

	var customer_list = []
	for i in range(size):
		var customer = preload("res://scenes/Customer.tscn").instantiate()
		customer.assigned_variant_index = variant_indices[i % variant_indices.size()]
		get_tree().current_scene.add_child(customer)
		customer.global_position = door_point
		customer_list.append(customer)

	var group = CustomerGroup.new()
	group.group_patience_expired.connect(_on_group_patience_expired)
	group.setup(customer_list, self, queue_patience)
	waiting_queue.append(group)
	_position_group(group, waiting_queue.size() - 1)
	print("Group of ", size, " added to queue. Queue size: ", waiting_queue.size())


func _get_slot_base(slot_index: int) -> Vector2:
	var offset = 0.0
	for i in range(slot_index):
		if i >= waiting_queue.size():
			break
		offset += waiting_queue[i].customers.size() * CUSTOMER_STACK_SPACING + QUEUE_SLOT_SPACING
	return queue_origin + Vector2(-offset, 0)


func _position_group(group: CustomerGroup, slot_index: int):
	var slot_base = _get_slot_base(slot_index)
	for i in range(group.customers.size()):
		var target = slot_base + Vector2(-i * CUSTOMER_STACK_SPACING, 0)
		group.customers[i].walk_to(target)


func _reposition_queue():
	for i in range(waiting_queue.size()):
		_walk_group_to_slot(waiting_queue[i], i)


func _walk_group_to_slot(group: CustomerGroup, slot_index: int):
	var slot_base = _get_slot_base(slot_index)
	for i in range(group.customers.size()):
		var target = slot_base + Vector2(-i * CUSTOMER_STACK_SPACING, 0)
		group.customers[i].walk_to(target)


func try_seat_next_group():
	if waiting_queue.is_empty():
		return
	for i in range(waiting_queue.size()):
		var group = waiting_queue[i]
		var table = find_best_table(group.customers.size())
		if table == null:
			continue
		waiting_queue.remove_at(i)
		seat_group_at_table(group, table)
		_reposition_queue()
		return


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


# Hook for UI and future systems — money is added via Money.collect()
func _on_table_finished(payout: float, _table):
	print("Table finished. Payout: $", payout)


# Hook for future systems
func on_payment_collected():
	pass


# Hook for future systems
func _on_table_cleared(_table):
	pass


func _on_day_ended():
	day_active = false
	GlobalInventory.day += 1
	spawn_timer.stop()
	for group in waiting_queue:
		group.cleanup()
	waiting_queue.clear()
	print("Day ended. Final money: $", Wallet.money_owned)
	emit_signal("day_ended", Wallet.money_owned)
