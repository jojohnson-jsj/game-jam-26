extends Node2D

signal money_changed

var money_owned:float = 0 

func add_money(number: int) -> void:
	money_owned += number
	emit_signal('money_changed', money_owned)
	
func remove_money(number: int) -> bool:
	if money_owned < number:
		return false
	money_owned -= number
	emit_signal('money_changed', money_owned)
	return true
