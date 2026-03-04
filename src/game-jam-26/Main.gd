extends Node2D

func _ready():
	var customer = preload("res://Customer.tscn").instantiate()
	$Table.add_child(customer)
	$Table.seat_group([customer])
	print("Customer position after seating: ", customer.position)
