extends Node2D

func _ready():
	var customer1 = preload("res://scenes/Customer.tscn").instantiate()
	var customer2 = preload("res://scenes/Customer.tscn").instantiate()
	$Table.add_child(customer1)
	$Table.add_child(customer2)
	$Table.seat_group([customer1, customer2])
