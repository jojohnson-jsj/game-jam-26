### Note: right now, Equipment scenes don't know which customer they're cooking for. We're gonna have to fix this by wiring it up in the GameManager TBD.

extends Area2D

signal order_ready(item_type)

enum State { IDLE, COOKING, READY }

var current_state = State.IDLE
var item_type = "latte"
var cook_time = 10.0

func _ready():
	$CookTimer.wait_time = cook_time
	$CookTimer.timeout.connect(_on_cooking_finished)

func interact():
	match current_state:
		State.IDLE:
			$CookTimer.start()
			current_state = State.COOKING
			print("Started cooking: ", item_type)
		State.COOKING:
			print("Still cooking, please wait")
		State.READY:
			emit_signal("order_ready", item_type)
			current_state = State.IDLE
			print("Picked up: ", item_type)

func _on_cooking_finished():
	current_state = State.READY
	print("Order ready: ", item_type)
