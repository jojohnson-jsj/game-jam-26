class_name CatBed
extends Node2D

enum BedType { TABLE, NON_TABLE }

@export var bed_type: BedType = BedType.NON_TABLE
@export var unlocked: bool = false
# Unique string ID used by SaveManager to persist cat assignments.
# Set this in the editor — e.g. "bed_hermes", "bed_money_table1".
@export var bed_id: String = ""

# For TABLE beds only — assign the Table node this bed sits on in the editor
@export var assigned_table: NodePath

var assigned_cat: Cat = null

signal cat_assigned(cat: Cat)
signal cat_removed

# Maps every cat name to its static Cat resource properties so we can
# reconstruct a Cat instance from a saved name without needing .tres files.
const CAT_DEFINITIONS: Dictionary = {
	"qr_cat":              {"cat_type": Cat.CatType.NON_TABLE, "ability_type": Cat.AbilityType.QR},
	"hermes_cat":          {"cat_type": Cat.CatType.NON_TABLE, "ability_type": Cat.AbilityType.HERMES},
	"money_cat":           {"cat_type": Cat.CatType.TABLE,     "ability_type": Cat.AbilityType.MONEY},
	"host_cat":            {"cat_type": Cat.CatType.NON_TABLE, "ability_type": Cat.AbilityType.QUEUE},
	"hopper_cat":          {"cat_type": Cat.CatType.NON_TABLE, "ability_type": Cat.AbilityType.NONE},
	"nihao_cat":           {"cat_type": Cat.CatType.NON_TABLE, "ability_type": Cat.AbilityType.NONE},
	"counter_cat":         {"cat_type": Cat.CatType.NON_TABLE, "ability_type": Cat.AbilityType.NONE},
	"patience_cat":        {"cat_type": Cat.CatType.NON_TABLE, "ability_type": Cat.AbilityType.NONE},
	"cooking_cat":         {"cat_type": Cat.CatType.NON_TABLE, "ability_type": Cat.AbilityType.NONE},
	"quality_control_cat": {"cat_type": Cat.CatType.NON_TABLE, "ability_type": Cat.AbilityType.NONE},
	"cheetah_cat":         {"cat_type": Cat.CatType.NON_TABLE, "ability_type": Cat.AbilityType.NONE},
	"pretty_cat":          {"cat_type": Cat.CatType.NON_TABLE, "ability_type": Cat.AbilityType.NONE},
	"valentines_cat":      {"cat_type": Cat.CatType.NON_TABLE, "ability_type": Cat.AbilityType.NONE},
	"fat_cat":             {"cat_type": Cat.CatType.NON_TABLE, "ability_type": Cat.AbilityType.NONE},
	"sign_spinner_cat":    {"cat_type": Cat.CatType.NON_TABLE, "ability_type": Cat.AbilityType.NONE},
	"ankle_biter_cat":     {"cat_type": Cat.CatType.NON_TABLE, "ability_type": Cat.AbilityType.NONE},
	"reccomendation_cat":  {"cat_type": Cat.CatType.NON_TABLE, "ability_type": Cat.AbilityType.NONE},
}


func _ready() -> void:
	SaveManager.register_bed(self)
	# Debug: auto-assign money_cat to TABLE beds when the flag is on.
	# Mirrors how hermes/qr/queue are applied globally via Player/GameManager.
	# Only runs if nothing was already loaded from a save file.
	if bed_type == BedType.TABLE and DebugConfig.money_cat_enabled and assigned_cat == null:
		load_cat_by_name("money_cat")


func _exit_tree() -> void:
	SaveManager.unregister_bed(self)


# Reconstruct and assign a cat from a saved name string.
# Used exclusively by SaveManager on load — bypasses nothing, still validates.
func load_cat_by_name(cat_name: String) -> void:
	if not CAT_DEFINITIONS.has(cat_name):
		push_error("CatBed: unknown cat name '%s' in save file" % cat_name)
		return
	var def: Dictionary = CAT_DEFINITIONS[cat_name]
	var cat := Cat.new()
	cat.cat_name    = cat_name
	cat.cat_type    = def["cat_type"]
	cat.ability_type = def["ability_type"]
	assign_cat(cat)


func assign_cat(cat: Cat) -> bool:
	if not unlocked:
		return false
	var required_bed = BedType.TABLE if cat.cat_type == Cat.CatType.TABLE else BedType.NON_TABLE
	if required_bed != bed_type:
		return false
	if assigned_cat != null:
		_deactivate_cat(assigned_cat)
	assigned_cat = cat
	emit_signal("cat_assigned", cat)
	_activate_cat(cat)
	return true


func remove_cat():
	if assigned_cat == null:
		return
	_deactivate_cat(assigned_cat)
	assigned_cat = null
	emit_signal("cat_removed")


func _get_player():
	return get_tree().get_first_node_in_group("player")


func _get_table():
	if assigned_table.is_empty():
		return null
	return get_node(assigned_table)


func _activate_cat(cat: Cat):
	match cat.ability_type:
		Cat.AbilityType.HERMES:
			var player = _get_player()
			if player:
				player.has_dash_cat = true

		Cat.AbilityType.MONEY:
			var table = _get_table()
			if table:
				table.has_money_cat = true

		Cat.AbilityType.QR:
			var player = _get_player()
			if player:
				player.has_qr_cat = true

		Cat.AbilityType.QUEUE:
			GameManager.has_queue_cat = true


func _deactivate_cat(cat: Cat):
	match cat.ability_type:
		Cat.AbilityType.HERMES:
			var player = _get_player()
			if player:
				player.has_dash_cat = false

		Cat.AbilityType.MONEY:
			var table = _get_table()
			if table:
				table.has_money_cat = false

		Cat.AbilityType.QR:
			var player = _get_player()
			if player:
				player.has_qr_cat = false

		Cat.AbilityType.QUEUE:
			GameManager.has_queue_cat = false
