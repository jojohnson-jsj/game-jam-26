extends Node

signal day_started(day_number)
signal day_ended(final_money)
signal night_started

var tables: Array = []
var waiting_queue: Array = []
var active_customers: Array = []   # every customer node spawned this day
var day_active: bool = false

@export var spawn_interval: float = 22.0
@export var day_duration: float = 180.0
@export var min_group_size: int = 1
@export var max_group_size: int = 3
@export var queue_patience: float = 45.0
@export var tip_floor_time: float = 50.0
@export var tip_ceiling_time: float = 120.0
@export var tip_max_percent: float = 0.3

# Day-scaling state — set each day by _apply_day_scaling()
var _pie_chance: float = 0.1
var _customer_initial_patience: float = 40.0
var _customer_delivery_patience: float = 60.0

const QUEUE_SLOT_SPACING: float = 24.0
const CUSTOMER_STACK_SPACING: float = 12.0

var spawn_timer: Timer
var day_timer: Timer
var queue_origin: Vector2 = Vector2.ZERO
var door_point: Vector2 = Vector2.ZERO

var has_queue_cat: bool  # initialized in _ready() from DebugConfig
var has_counter_cat: bool = false
var has_trash_cat: bool = false
var has_hopper_cat: bool = false

const ITEM_PRICES = {
	"latte": 3.0,
	"pie": 8.0
}

# Texture registries — add new item types here as art becomes available
const ORDER_SPRITES = {
	"latte": preload("res://assets/food/orders/order_sprite_latte.png"),
	"pie": preload("res://assets/food/orders/order_sprite_pie.png"),
}

const FOOD_SPRITES = {
	"latte": preload("res://assets/food/food/food_sprite_latte.png"),
	"pie": preload("res://assets/food/food/food_sprite_pie.png"),
}

const MACHINE_SPRITES = {
	"latte": preload("res://assets/food/machines/latte_machine.png"),
	"pie": preload("res://assets/food/machines/oven.png"),
}


func get_order_sprite(item_type: String) -> Texture2D:
	return ORDER_SPRITES.get(item_type, null)


func get_food_sprite(item_type: String) -> Texture2D:
	return FOOD_SPRITES.get(item_type, null)


func get_machine_sprite(item_type: String) -> Texture2D:
	return MACHINE_SPRITES.get(item_type, null)


func _ready():
	has_queue_cat = DebugConfig.queue_cat_enabled
	day_duration = DebugConfig.day_duration
	spawn_timer = Timer.new()
	spawn_timer.wait_time = spawn_interval
	spawn_timer.one_shot = false
	spawn_timer.process_mode = Node.PROCESS_MODE_PAUSABLE
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	add_child(spawn_timer)

	day_timer = Timer.new()
	day_timer.wait_time = day_duration
	day_timer.one_shot = true
	day_timer.process_mode = Node.PROCESS_MODE_PAUSABLE
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
	tables = tables.filter(func(t): return is_instance_valid(t))
	tables.append(table)
	table.table_finished.connect(_on_table_finished.bind(table))
	table.table_vacated.connect(_on_table_cleared.bind(table))


func set_queue_origin(origin: Vector2):
	queue_origin = origin


func set_door_point(pos: Vector2):
	door_point = pos


func _reset_for_new_day() -> void:
	# Free any customer nodes still alive from the previous day
	for customer in active_customers:
		if is_instance_valid(customer):
			customer.queue_free()
	active_customers.clear()

	# Reset all table states so they're available from the first moment
	for table in tables:
		table.force_reset()

	# Waiting queue should already be empty, but guard anyway
	waiting_queue.clear()

	# Reset all equipment back to idle
	for equip in get_tree().get_nodes_in_group("equipment"):
		equip.force_reset()

	# Remove any uncollected money nodes
	for money in get_tree().get_nodes_in_group("money"):
		if is_instance_valid(money):
			money.queue_free()

	# Clear the player's inventory and refresh their display
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.inventory.clear()
		player._update_inventory_display()


## Returns a 0→1 scalar that grows quickly in early days and flattens later.
## Day 1 = 0.0, Day 5 ≈ 0.59, Day 10 ≈ 0.89, Day 20 ≈ 0.99
func _get_day_scale() -> float:
	return 1.0 - pow(0.80, GlobalInventory.day - 1)


## Applies difficulty parameters for the current day number.
## Cat bonuses are applied on top of these values in start_day().
func _apply_day_scaling() -> void:
	var s := _get_day_scale()
	# Spawn interval: day 1 = 22s → floors at 7s around day 15
	spawn_interval = max(7.0, 22.0 - s * 15.0)
	# Queue patience: day 1 = 45s → floors at 15s
	queue_patience = max(15.0, 45.0 - s * 30.0)
	# Tip floor: day 1 = 50s → floors at 20s (tips decay sooner)
	tip_floor_time = max(20.0, 50.0 - s * 30.0)
	# Max group size: 3 on day 1, +1 at day 5, +1 at day 10 (cap 5)
	max_group_size = min(5, 3 + int(GlobalInventory.day >= 5) + int(GlobalInventory.day >= 10))
	# Pie order rate: 10% on day 1, up to 60% as days progress
	_pie_chance = clamp(0.15 + s * 0.50, 0.15, 0.60)
	# Per-customer seated patience (used after they're thinking)
	_customer_initial_patience  = max(15.0, 40.0 - s * 22.0)
	_customer_delivery_patience = max(20.0, 60.0 - s * 35.0)
	print("Day %d scaling — spawn:%.1fs  q_patience:%.1fs  grp_max:%d  pie:%.0f%%" % [
		GlobalInventory.day, spawn_interval, queue_patience, max_group_size, _pie_chance * 100
	])


func start_day():
	_reset_for_new_day()
	_apply_day_scaling()

	spawn_timer.wait_time = max(5.0, spawn_interval - GlobalInventory.get_spawn_interval_reduction())
	queue_patience += GlobalInventory.get_patience_bonus()
	tip_floor_time += GlobalInventory.get_tip_floor_bonus()
	day_timer.wait_time = day_duration + GlobalInventory.get_day_extension()

	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.speed = player.BASE_SPEED * (1.0 + GlobalInventory.get_speed_bonus())

	for equip in get_tree().get_nodes_in_group("equipment"):
		equip.apply_day_bonuses()

	day_active = true
	spawn_timer.start()
	day_timer.start()
	call_deferred("spawn_group", randi_range(min_group_size, max_group_size))
	emit_signal("day_started", GlobalInventory.day)
	print("Day started")


func _on_spawn_timer_timeout():
	if not day_active:
		return
	spawn_group(randi_range(min_group_size, max_group_size))


func spawn_group(size: int):

	#reroll groups of 1 for valentines cat
	if size == 1 and randf() < GlobalInventory.get_valentines_reduction():
		size = randi_range(2, max_group_size)

	# Build a variant priority list: variants not currently in the scene come
	# first (shuffled), then variants already present (shuffled). This makes
	# repeats unlikely without making them impossible.
	var in_scene: Dictionary = {}
	for c in active_customers:
		if is_instance_valid(c) and c.assigned_variant_index >= 0:
			in_scene[c.assigned_variant_index] = true

	var free_variants: Array = range(11).filter(func(v): return not in_scene.has(v))
	var busy_variants: Array = range(11).filter(func(v): return in_scene.has(v))
	free_variants.shuffle()
	busy_variants.shuffle()
	var variant_indices: Array = free_variants + busy_variants

	var customer_list = []
	for i in range(size):
		var customer = preload("res://scenes/Customer.tscn").instantiate()
		customer.assigned_variant_index = variant_indices[i % variant_indices.size()]
		if randf() < _pie_chance:
			customer.order_item = "pie"
		get_tree().current_scene.add_child(customer)
		customer.process_mode = Node.PROCESS_MODE_PAUSABLE
		customer.global_position = door_point
		customer.initial_patience  = _customer_initial_patience
		customer.delivery_patience = _customer_delivery_patience
		customer_list.append(customer)
		active_customers.append(customer)

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
	spawn_timer.stop()
	# Dismiss waiting queue only — seated customers stay to be served
	for group in waiting_queue:
		group.cleanup()
	waiting_queue.clear()
	print("Day timer ended — waiting for restaurant to clear")
	_wait_for_day_clear()


func _wait_for_day_clear() -> void:
	# Poll until all customers are gone and no money remains, then 2s buffer
	await get_tree().create_timer(0.5).timeout  # small initial delay
	while true:
		var customers_remain = active_customers.any(func(c): return is_instance_valid(c))
		var money_remains = not get_tree().get_nodes_in_group("money").is_empty()
		if not customers_remain and not money_remains:
			break
		await get_tree().create_timer(0.5).timeout
	await get_tree().create_timer(2.0).timeout
	print("Day ended. Final money: $", Wallet.money_owned)
	emit_signal("day_ended", Wallet.money_owned)
	emit_signal("night_started")
