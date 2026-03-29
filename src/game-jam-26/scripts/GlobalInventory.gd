extends Node2D

#persist across days -- store money, all cats owned and euqipment unlocks
signal inventory_changed
var day:int = 1 

# Cats Dictionary
var cats: Dictionary = {
	'qr_cat': {'owned': false, 'copies': 0},
	'hermes_cat': {'owned': false, 'copies': 0},
	'money_cat': {'owned': false, 'copies': 0},
	'host_cat': {'owned': false, 'copies': 0},
	'hopper_cat': {'owned': false, 'copies': 0},
	'nihao_cat': {'owned': false, 'copies': 0},
	'counter_cat': {'owned': false, 'copies': 0},
	'trash_cat': {'owned': false, 'copies': 0},
	'patience_cat': {'owned': false, 'copies': 0},
	'cooking_cat': {'owned': false, 'copies': 0},
	'quality_control_cat': {'owned': false, 'copies': 0},
	'cheetah_cat': {'owned': false, 'copies': 0},
	'pretty_cat': {'owned': false, 'copies': 0},
	'valentines_cat': {'owned': false, 'copies': 0},
	'fat_cat': {'owned': false, 'copies': 0},
	'sign_spinner_cat': {'owned': false, 'copies': 0},
	'ankle_biter_cat': {'owned': false, 'copies': 0},
	'reccomendation_cat': {'owned': false, 'copies': 0},
}

func debug_cats() -> void: 
	print(JSON.stringify(cats, "\t"))

#Equipment unlocks
var equipment_unlocked: Dictionary = {
	'latte_machine': 2,
	'oven': 2,
	'cat_bed': 1
}

#gacha pity 
var gacha_pity:int = 1 #pity currently: 10 -- reset on 5-star
const PITY_THRESHOLD:int = 10
const PULL_COST:int = 40 

#queries
func owns_cat(catId: String) -> bool: 
	return cats.get(catId).get("owned", false)

func copies_of(catId: String) -> int: 
	return cats.get(catId).get('copies')

func is_equipment_unlocked(equipment) -> bool:
	return equipment_unlocked.get(equipment) > 0

func equipment_amt(equipment: String) -> int:
	return equipment_unlocked.get(equipment, 0)

# cats currently placed in a bed — managed by CatBed activate/deactivate
var placed_cats: Array = []

func is_placed(catId: String) -> bool:
	return catId in placed_cats
	

#mutations 
func add_cat(catId:String) -> void:
	cats[catId]['copies'] += 1
	cats[catId]['owned'] = true
	emit_signal('inventory_changed')
	

func unlock_equipment(equipment:String) -> int:
	if(equipment == 'cat_bed' && equipment_unlocked[equipment] < 7):
		equipment_unlocked[equipment] += 1
		emit_signal('inventory_changed')
		return equipment_unlocked[equipment]
	elif(equipment_unlocked[equipment] < 4):
		equipment_unlocked[equipment] += 1
		emit_signal('inventory_changed')
		return equipment_unlocked[equipment]
	return -1


#Cat mutations 
func get_patience_bonus() -> float:
	return min(copies_of('patience_cat'), 2) * 8 if is_placed('patience_cat') else 0.0
	
func get_cooking_bonus() -> float:
	return min(copies_of('cooking_cat'), 2) * 3 if is_placed('cooking_cat') else 0.0
	
func get_price_bonus() -> float:
	return [0.0, 0.10, 0.15][min(copies_of('quality_control_cat'), 2)] if is_placed('quality_control_cat') else 0.0
	
func get_speed_bonus() -> float:
	return [0.0, 0.10, 0.15][min(copies_of('cheetah_cat'), 2)] if is_placed('cheetah_cat') else 0.0

func get_tip_floor_bonus() -> float:
	return [0.0, 8.0, 16.0][min(copies_of('pretty_cat'), 2)] if is_placed('pretty_cat') else 0.0

func get_eating_time_reduction() -> float:
	return min(copies_of('fat_cat'), 2) * 3.0 if is_placed('fat_cat') else 0.0

func get_spawn_interval_reduction() -> float:
	return min(copies_of('sign_spinner_cat'), 2) * 3.0 if is_placed('sign_spinner_cat') else 0.0

func get_thinking_time_reduction() -> float:
	return min(copies_of('reccomendation_cat'), 2) * 3.0 if is_placed('reccomendation_cat') else 0.0

func get_npc_speed_bonus() -> float:
	return [0.0, 0.10, 0.15][min(copies_of('ankle_biter_cat'), 2)] if is_placed('ankle_biter_cat') else 0.0

func get_valentines_reduction() -> float:
	return [0.0, 0.10, 0.30][min(copies_of('valentines_cat'), 2)] if is_placed('valentines_cat') else 0.0

func get_day_extension() -> float:
	return min(copies_of('nihao_cat'), 2) * 15.0 if is_placed('nihao_cat') else 0.0
