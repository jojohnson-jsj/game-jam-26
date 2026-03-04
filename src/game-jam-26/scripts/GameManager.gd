extends Node

var pending_order: String = ""
var has_food_ready: bool = false
var current_customer: Area2D = null

func place_order(item_type: String, customer: Area2D):
	pending_order = item_type
	current_customer = customer
	print("GameManager: order placed for ", item_type)

func food_ready(item_type: String):
	if item_type == pending_order:
		has_food_ready = true
		print("GameManager: food ready for ", item_type)

func deliver_food():
	if has_food_ready and current_customer != null:
		current_customer.receive_food()
		has_food_ready = false
		pending_order = ""
		current_customer = null
		print("GameManager: food delivered")
