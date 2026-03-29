extends Node

const SAVE_PATH = "user://save_state.json"

# CatBed nodes register here so we can read/write their assignments
var _registered_beds: Array = []

# Bed assignments loaded from disk before beds have registered themselves
var _pending_bed_assignments: Dictionary = {}


# Called by CatBed._ready() — applies any pending saved assignment immediately
func register_bed(bed: Node) -> void:
	if _registered_beds.has(bed):
		return
	_registered_beds.append(bed)
	if bed.bed_id != "" and _pending_bed_assignments.has(bed.bed_id):
		var cat_name: String = _pending_bed_assignments[bed.bed_id]
		if cat_name != "":
			bed.load_cat_by_name(cat_name)


# Called by CatBed._exit_tree()
func unregister_bed(bed: Node) -> void:
	_registered_beds.erase(bed)


func save_state() -> void:
	var data: Dictionary = {
		"day": GlobalInventory.day,
		"money": Wallet.money_owned,
		"gacha_pity": GlobalInventory.gacha_pity,
		"cats": {},
		"equipment": {},
		"cat_beds": {}
	}

	for cat_name in GlobalInventory.cats:
		var c: Dictionary = GlobalInventory.cats[cat_name]
		data["cats"][cat_name] = {
			"owned": c["owned"],
			"copies": c["copies"]
		}

	for equip_name in GlobalInventory.equipment_unlocked:
		data["equipment"][equip_name] = GlobalInventory.equipment_unlocked[equip_name]

	for bed in _registered_beds:
		if bed.bed_id == "":
			push_warning("SaveManager: CatBed has no bed_id set — skipping")
			continue
		var assigned_name: String = ""
		if bed.assigned_cat != null:
			assigned_name = bed.assigned_cat.cat_name
		data["cat_beds"][bed.bed_id] = assigned_name

	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()
		print("SaveManager: state saved to ", SAVE_PATH)
	else:
		push_error("SaveManager: could not open save file for writing — error %d" % FileAccess.get_open_error())


func load_state() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("SaveManager: could not open save file for reading")
		return false

	var text := file.get_as_text()
	file.close()

	var data = JSON.parse_string(text)
	if data == null:
		push_error("SaveManager: failed to parse save JSON")
		return false

	GlobalInventory.day        = int(data.get("day", 1))
	GlobalInventory.gacha_pity = int(data.get("gacha_pity", 1))
	Wallet.money_owned         = float(data.get("money", 0.0))

	if "cats" in data:
		for cat_name in data["cats"]:
			if cat_name in GlobalInventory.cats:
				var src: Dictionary = data["cats"][cat_name]
				GlobalInventory.cats[cat_name]["owned"]  = src.get("owned", false)
				GlobalInventory.cats[cat_name]["copies"] = src.get("copies", 0)

	if "equipment" in data:
		for equip_name in data["equipment"]:
			if equip_name in GlobalInventory.equipment_unlocked:
				GlobalInventory.equipment_unlocked[equip_name] = data["equipment"][equip_name]

	_pending_bed_assignments = data.get("cat_beds", {})
	# Apply to beds that already registered (normal on subsequent days)
	for bed in _registered_beds:
		if bed.bed_id != "" and bed.bed_id in _pending_bed_assignments:
			var cat_name: String = _pending_bed_assignments[bed.bed_id]
			if cat_name != "":
				bed.load_cat_by_name(cat_name)

	print("SaveManager: state loaded — day %d, $%.0f" % [GlobalInventory.day, Wallet.money_owned])
	return true


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func reset_all() -> void:
	# Delete save file
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)

	# Reset GlobalInventory
	GlobalInventory.day = 1
	GlobalInventory.gacha_pity = 1
	for cat_name in GlobalInventory.cats:
		GlobalInventory.cats[cat_name]["owned"] = false
		GlobalInventory.cats[cat_name]["copies"] = 0
	GlobalInventory.equipment_unlocked["latte_machine"] = true
	GlobalInventory.equipment_unlocked["oven"] = true

	# Reset Wallet
	Wallet.money_owned = 0.0

	# Reset GameManager
	GameManager.tables.clear()
	GameManager.waiting_queue.clear()
	GameManager.active_customers.clear()
	GameManager.day_active = false
	GameManager.has_queue_cat = DebugConfig.queue_cat_enabled
	GameManager.has_counter_cat = false
	GameManager.has_trash_cat = false

	# Clear pending bed assignments
	_pending_bed_assignments = {}
	_registered_beds.clear()
