extends StaticBody2D

signal table_finished(payout)
signal table_vacated

enum State { AVAILABLE, OCCUPIED, AWAITING_PAYMENT }

@export var capacity: int = 4

var current_state = State.AVAILABLE
var seated_customers: Array = []
var done_customers: int = 0
var has_money_cat: bool  # initialized in _ready() from DebugConfig
var money_cat_bed_position: Vector2 = Vector2.ZERO


func _ready():
	# has_money_cat is set on ALL tables by CatBed when a money_cat is assigned.
	# Coins from any table auto-collect when the money cat is active.
	has_money_cat = false
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
		var flat_rate = GameManager.get_item_price(customer.order_item) * (1.0 + GlobalInventory.get_price_bonus())
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
	money.global_position = global_position + Vector2(0, -7)

	# Money Cat — animate coin flying to bed, then collect
	if has_money_cat:
		# Disable player interaction during animation
		money.set_process_input(false)
		money.monitoring = false
		money.monitorable = false
		_fly_coin_to_bed(money)


func _fly_coin_to_bed(money_node: Node2D) -> void:
	var target = money_cat_bed_position if money_cat_bed_position != Vector2.ZERO else global_position
	var tween = create_tween()
	# Sit on table for 1 second
	tween.tween_interval(1.0)
	# Fly to bed over 0.5s, scaling down to zero
	tween.tween_property(money_node, "global_position", target, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(money_node, "scale", Vector2.ZERO, 0.75).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(func():
		if is_instance_valid(money_node):
			Wallet.add_money(money_node.amount)
			money_node.source_table = null  # prevent double payment_collected
			money_node.queue_free()
		payment_collected()
	)


func payment_collected():
	current_state = State.AVAILABLE
	GameManager.on_payment_collected()


# Called by GameManager at the start of each new day to guarantee a clean slate.
func force_reset() -> void:
	for customer in seated_customers:
		if customer.patience_expired.is_connected(_on_patience_expired):
			customer.patience_expired.disconnect(_on_patience_expired)
		if customer.customer_done.is_connected(_on_customer_done):
			customer.customer_done.disconnect(_on_customer_done)
	seated_customers = []
	done_customers = 0
	current_state = State.AVAILABLE
