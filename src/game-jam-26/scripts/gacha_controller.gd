extends CanvasLayer

# Cats Dictionary
var catsArt: Dictionary = {
	'qr_cat': {'splash': 'res://assets/cats/splashes/cat_splash_qr.png', 'stars': 5},
	'hermes_cat': {'splash': 'res://assets/cats/splashes/cat_splash_hermes.png', 'stars': 5},
	'money_cat': {'splash': 'res://assets/cats/splashes/cat_splash_money.png', 'stars': 5},
	'host_cat': {'splash': 'res://assets/cats/splashes/cat_splash_host.png', 'stars': 5},
	'hopper_cat': {'splash': 'res://assets/cats/splashes/cat_splash_queue.png', 'stars': 5},
	'nihao_cat': {'splash': 'res://assets/cats/splashes/cat_splash_celebrity.png', 'stars': 5},
	'counter_cat': {'splash': 'res://assets/cats/splashes/cat_splash_countertop.png', 'stars': 5},
	'patience_cat': {'splash': 'res://assets/cats/splashes/cat_splash_patience.png', 'stars': 4},
	'cooking_cat': {'splash': 'res://assets/cats/splashes/cat_splash_qr.png', 'stars': 4},
	'quality_control_cat': {'splash': 'res://assets/cats/splashes/cat_splash_inspector.png', 'stars': 4},
	'cheetah_cat': {'splash': 'res://assets/cats/splashes/cat_splash_zoomies.png', 'stars': 4},
	'pretty_cat': {'splash': 'res://assets/cats/splashes/cat_splash_pretty.png', 'stars': 4},
	'valentines_cat': {'splash': 'res://assets/cats/splashes/cat_splash_valentines.png', 'stars': 4},
	'fat_cat': {'splash': 'res://assets/cats/splashes/cat_splash_fat.png', 'stars': 4},
	'sign_spinner_cat': {'splash': 'res://assets/cats/splashes/cat_splash_cute.png', 'stars': 4},
	'ankle_biter_cat': {'splash': 'res://assets/cats/splashes/cat_splash_ankle.png', 'stars': 4},
	'reccomendation_cat': {'splash': 'res://assets/cats/splashes/cat_splash_recommender.png', 'stars': 4},
}

var cat_id := 'cheetah_cat'
var started := false
var finished := false
var gachaSplash

@onready var prewish_stars = $Control/Stars
@onready var prewish_star_distant = $Control/StarDistant
@onready var prewish_star_close = $Control/StarClose
@onready var prewish_grass = $Control/Grass
@onready var prewish_grass_lit = $Control/GrassLit
@onready var gacha_box = $Control/GachaBox

const Gacha = preload("res://scripts/gacha_logic.gd")

func _input(event):
	if event.is_action_pressed("click"):
		if not finished:
			pass
			#skip_animation()
		else:
			visible = false
			$"../".visible = true
			queue_free()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if not started:
		if spawn_sprite():
			play_gacha_pull()
		else:
			finished = true
		started = true

func spawn_sprite() -> bool:
	gachaSplash = TextureRect.new()
	var target_instance = Gacha.new()
	var result = target_instance.pull_cat()
	if result == "":
		$Control/Broke.visible = true
		return false
	cat_id = result
	gachaSplash.texture = load(catsArt[cat_id].splash)
	#gachaSplash.stretch_mode = TextureRect.STRETCH_SCALE
	gachaSplash.expand_mode = TextureRect.EXPAND_FIT_WIDTH  # fits width, adjusts height to maintain aspect
	gachaSplash.set_anchors_preset(Control.PRESET_FULL_RECT)
	gachaSplash.visible = false
	$Control.add_child(gachaSplash)
	return true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func wait(time: float) -> void:
	await get_tree().create_timer(time).timeout

func play_gacha_pull() -> void:
	await play_pre_wish()
	await reveal_result()
	#multipull only
	#await show_result_screen()
	finished = true
	
	
func play_pre_wish() -> void:
	prewish_stars.visible = true
	prewish_grass.visible = true
	await wait(.5)
	prewish_star_distant.visible = true
	await wait(.5)
	prewish_star_distant.visible = false
	await wait(.5)
	prewish_star_distant.visible = true
	await wait(.5)
	prewish_star_close.visible = true
	prewish_grass_lit.visible = true
	await wait(.5)
	pass
	
func reveal_result() -> void:
	prewish_stars.visible = false
	prewish_star_distant.visible = false
	prewish_star_close.visible = false
	prewish_grass.visible = false
	prewish_grass_lit.visible = false
	gacha_box.visible = true
	await wait(.5)
	gacha_box.modulate = Color(5, 5, 5, 1)
	await wait(.5)
	gacha_box.visible = false
	gachaSplash.modulate = Color(0, 0, 0, 1)
	gachaSplash.visible = true
	await wait(.5)
	var tween = create_tween()
	tween.tween_property(gachaSplash, "modulate", Color(1,1,1,1), 0.3)
	pass
	
func show_result_screen() -> void:
	pass
	
