extends Node2D

const FIVE_STAR_POOL = ['qr_cat', 'hermes_cat', 'money_cat', 'host_cat', 'hopper_cat', 'nihao_cat', 'counter_cat']
const FOUR_STAR_POOL = ['patience_cat', 'cooking_cat', 'quality_control_cat', 'cheetah_cat', 'pretty_cat', 'valentines_cat', 'fat_cat', 'sign_spinner_cat', 'ankle_biter_cat', 'reccomendation_cat']

const FIVE_STAR_RATE = 0.1 
const FOUR_STAR_RATE = 1 

func _get_five_star_rate() -> float:
	if GlobalInventory.gacha_pity < 8:
		return FIVE_STAR_RATE
	# Ramps from 0.06 to 1.0 over pulls 8-10
	return FIVE_STAR_RATE + (1.0 - FIVE_STAR_RATE) * ((GlobalInventory.gacha_pity - 7) / 3.0)

func pull_cat() -> String:
	if not Wallet.remove_money(GlobalInventory.PULL_COST):
		return ""
	
	var cat_id:String
	if randf() < _get_five_star_rate():
		GlobalInventory.gacha_pity = 0
		cat_id = FIVE_STAR_POOL[randi() % FIVE_STAR_POOL.size()]
	else:
		GlobalInventory.gacha_pity += 1
		cat_id = FOUR_STAR_POOL[randi() % FOUR_STAR_POOL.size()]
	
	GlobalInventory.add_cat(cat_id)
	return cat_id
	
func show_gacha_ui(cat_id : String):
	get_tree().paused = true

	var ui = load("res://scenes/GachaController.tscn").instantiate()
	ui.cat_id = cat_id
	$CanvasLayer.add_child(ui)

	await ui.finished  # wait until user is done

	get_tree().paused = false
	
func multi_pull(number:int) -> Array:
	var results = []
	for i in range(number):
		results.append(pull_cat())
	return results
	
func debug_pull(count: int = 10) -> void:
	print("=== GACHA DEBUG: %d pulls ===" % count)
	Wallet.add_money(GlobalInventory.PULL_COST * count)  # fund it
	for i in range(count):
		var pity_before = GlobalInventory.gacha_pity
		var rate = _get_five_star_rate()
		var result = pull_cat()
		var rarity = "5★" if FIVE_STAR_POOL.has(result) else "4★"
		print("Pull %d | pity: %d | rate: %.0f%% | got: %s %s" % [i+1, pity_before, rate*100, rarity, result])
	print("=== END | wallet: $%.0f ===" % Wallet.money_owned)
