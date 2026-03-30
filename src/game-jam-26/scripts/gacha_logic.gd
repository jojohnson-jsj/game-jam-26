extends Node2D

const CAT_POOL = ['qr_cat', 'hermes_cat', 'money_cat', 'host_cat', 'hopper_cat', 'nihao_cat', 'counter_cat', 'patience_cat', 'cooking_cat', 'quality_control_cat', 'cheetah_cat', 'pretty_cat', 'valentines_cat', 'fat_cat', 'sign_spinner_cat', 'ankle_biter_cat', 'reccomendation_cat']

func pull_cat() -> String:
	if not Wallet.remove_money(GlobalInventory.PULL_COST):
		return ""

	GlobalInventory.gacha_pity += 1

	var unowned := CAT_POOL.filter(func(c): return not GlobalInventory.owns_cat(c))
	var force_new := GlobalInventory.gacha_pity >= 5 and not unowned.is_empty()

	var cat_id: String
	if force_new:
		cat_id = unowned[randi() % unowned.size()]
	else:
		cat_id = CAT_POOL[randi() % CAT_POOL.size()]

	if not GlobalInventory.owns_cat(cat_id):
		GlobalInventory.gacha_pity = 0

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
