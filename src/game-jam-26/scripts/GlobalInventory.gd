extends Node2D

#persist across days -- store money, all cats owned and euqipment unlocks
signal inventory_changed
var day:int = 1 

# Cats Dictionary
var cats: Dictionary = {
	'qr_cat': {'owned': false, 'copies': 0, 'stars': 5},
	'hermes_cat': {'owned': false, 'copies': 0, 'stars': 5},
	'money_cat': {'owned': false, 'copies': 0, 'stars': 5},
	'host_cat': {'owned': false, 'copies': 0, 'stars': 5},
	'hopper_cat': {'owned': false, 'copies': 0, 'stars': 5},
	'nihao_cat': {'owned': false, 'copies': 0, 'stars': 5},
	'counter_cat': {'owned': false, 'copies': 0, 'stars': 5},
	'trash_cat': {'owned': false, 'copies': 0, 'stars': 5},
	'patience_cat': {'owned': false, 'copies': 0, 'stars': 4},
	'cooking_cat': {'owned': false, 'copies': 0, 'stars': 4},
	'quality_control_cat': {'owned': false, 'copies': 0, 'stars': 4},
	'cheetah_cat': {'owned': false, 'copies': 0, 'stars': 4},
	'pretty_cat': {'owned': false, 'copies': 0, 'stars': 4},
	'valentines_cat': {'owned': false, 'copies': 0, 'stars': 4},
	'fat_cat': {'owned': false, 'copies': 0, 'stars': 4},
	'sign_spinner_cat': {'owned': false, 'copies': 0, 'stars': 4},
	'ankle_biter_cat': {'owned': false, 'copies': 0, 'stars': 4},
	'reccomendation_cat': {'owned': false, 'copies': 0, 'stars': 4},
}

func debug_cats() -> void: 
	print(JSON.stringify(cats, "\t"))

#Equipment unlocks
var equipment_unlocked: Dictionary = {
	'latte_machine': true,
	'oven': true
}

#gacha pity 
var gacha_pity:int = 1 #pity currently: 10 -- reset on 5-star
const PITY_THRESHOLD:int = 10
const PULL_COST:int = 160 

#queries
func owns_cat(catId: String) -> bool: 
	return cats.get(catId).get("owned", false)

func copies_of(catId: String) -> int: 
	return cats.get(catId).get('copies')
	
func is_equipment_unlocked(equipment) -> bool:
	return equipment_unlocked.get(equipment)
	

#mutations 
func add_cat(catId:String) -> void:
	cats[catId]['copies'] += 1
	cats[catId]['owned'] = true
	emit_signal('inventory_changed')
	

func unlock_equipment(equipment:String) -> void:
	equipment_unlocked[equipment] = true
	emit_signal('inventory_changed')
	

#Cat mutations 
func get_patience_bonus() -> float:
	# patience cat c1 - 8 second increase, c2 - 16 second increase
	return min(copies_of('patience_cat'), 2) * 8 
	
func get_cooking_bonus() -> float:
	#cooking cat c1 - 3 second decrease, c2 - 6 second decrease
	return min(copies_of('cooking_cat'), 2) * 3 
	
func get_price_bonus() -> float:
	#qa cat c1 - 10 percent increase, c2 - 15 percent increase
	return [0.0, 0.10, 0.15][min(copies_of('quality_control_cat'), 2)] 
	
func get_speed_bonus() -> float:
	# cheetah cat c1 - +10% speed, c2 - +15% speed
	return [0.0, 0.10, 0.15][min(copies_of('cheetah_cat'), 2)]

func get_tip_floor_bonus() -> float:
	# pretty cat c1 - delays tip decay by 8s, c2 - 16s
	return [0.0, 8.0, 16.0][min(copies_of('pretty_cat'), 2)]

func get_eating_time_reduction() -> float:
	# fat cat c1 - -3s eating time, c2 - -6s
	return min(copies_of('fat_cat'), 2) * 3.0

func get_spawn_interval_reduction() -> float:
	# sign spinner cat c1 - -3s between spawns, c2 - -6s
	return min(copies_of('sign_spinner_cat'), 2) * 3.0

func get_thinking_time_reduction() -> float:
	# recommendation cat c1 - -3s thinking time, c2 - -6s
	return min(copies_of('reccomendation_cat'), 2) * 3.0

func get_npc_speed_bonus() -> float:
	# ankle biter cat c1 - +10% NPC walk speed, c2 - +15%
	return [0.0, 0.10, 0.15][min(copies_of('ankle_biter_cat'), 2)]

func get_valentines_reduction() -> float:
	# valentines cat c1 - 10% fewer solo customers, c2 - 30%
	return [0.0, 0.10, 0.30][min(copies_of('valentines_cat'), 2)]
