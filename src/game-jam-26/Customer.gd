extends Area2D

signal order_placed(item_type)
signal patience_expired
signal finished_eating

enum State { WAITING_FOR_PLAYER, ORDER_TAKEN, EATING }

var current_state = State.WAITING_FOR_PLAYER
var order_item = "latte"

func _ready():
	$PatienceTimer.wait_time = 30.0
	$EatingTimer.wait_time = 10.0
	$PatienceTimer.timeout.connect(_on_patience_expired)
	$EatingTimer.timeout.connect(_on_finished_eating)
	$PatienceTimer.start()

func interact():
	match current_state:
		State.WAITING_FOR_PLAYER:
			emit_signal("order_placed", order_item)
			current_state = State.ORDER_TAKEN
			$PatienceTimer.wait_time = 50.0
			$PatienceTimer.start()
			print("Order taken: ", order_item)
		State.ORDER_TAKEN:
			print("Order already taken, waiting for food")

func receive_food():
	current_state = State.EATING
	$PatienceTimer.stop()
	$EatingTimer.start()

func _on_patience_expired():
	emit_signal("patience_expired")
	queue_free()

func _on_finished_eating():
	emit_signal("finished_eating")
	queue_free()
