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
	'cooking_cat': {'splash': 'res://assets/cats/splashes/cat_splash_chef.png', 'stars': 4},
	'quality_control_cat': {'splash': 'res://assets/cats/splashes/cat_splash_inspector.png', 'stars': 4},
	'cheetah_cat': {'splash': 'res://assets/cats/splashes/cat_splash_zoomies.png', 'stars': 4},
	'pretty_cat': {'splash': 'res://assets/cats/splashes/cat_splash_pretty.png', 'stars': 4},
	'valentines_cat': {'splash': 'res://assets/cats/splashes/cat_splash_valentines.png', 'stars': 4},
	'fat_cat': {'splash': 'res://assets/cats/splashes/cat_splash_fat.png', 'stars': 4},
	'sign_spinner_cat': {'splash': 'res://assets/cats/splashes/cat_splash_cute.png', 'stars': 4},
	'ankle_biter_cat': {'splash': 'res://assets/cats/splashes/cat_splash_ankle.png', 'stars': 4},
	'reccomendation_cat': {'splash': 'res://assets/cats/splashes/cat_splash_recommender.png', 'stars': 4},
	'trash_cat': {'splash': 'res://assets/cats/splashes/cat_splash_trash.png', 'stars': 4},
}

const CAT_DESCRIPTIONS = {
	'qr_cat':              ["QR Cat", "Click seated customers to take their order"],
	'hermes_cat':          ["Hermes Cat", "Grants you a dash ability (press Shift to use)"],
	'money_cat':           ["Money Cat", "Automatically collects money so you don't have to"],
	'host_cat':            ["Host Cat", "Click waiting groups so that the host can seat them instantly"],
	'hopper_cat':          ["Hopper Cat", "Queue an extra order into a machine so you can load it and walk away"],
	'nihao_cat':           ["Nihao Cat", "This famous cat carries their franchise's popularity. It's inspiring you to carry more as well! (player can now carry 3 items)"],
	'counter_cat':         ["Counter Cat", "Unlocks the countertop plates — drop off a finished dish and come back for it later!"],
	'patience_cat':        ["Patience Cat", "Customers absorb his serenity, and find they have more patience than before"],
	'cooking_cat':         ["Chef Cat", "Decreases cooking time so dishes are ready faster"],
	'quality_control_cat': ["Inspector Cat", "He will only take the highest of quality items, your items sell for more"],
	'cheetah_cat':         ["Zoomies Cat", "She got the zoomies! Helps the player get around faster (base speed increase)"],
	'pretty_cat':          ["Pretty Cat", "Makes your customers more generous with their tips, as they get to look at her"],
	'valentines_cat':      ["Valentines Cat", "Less single people find their way to your cafe (more pairs or groups)"],
	'fat_cat':             ["Fat Cat", "Eats customers' food so they eat faster"],
	'sign_spinner_cat':    ["Sign Spinner Cat", "Spreads awareness so more customers come to your cafe!"],
	'ankle_biter_cat':     ["Ankle Biter Cat", "Nips at your customers' heels, making them walk faster"],
	'reccomendation_cat':  ["Recommendation Cat", "Customers order faster when this cat is pawing at the menu"],
	'trash_cat':           ["Trash Cat", "Click the trash can to discard inventory rather than walking to it"],
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
	_show_description_panel()
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

func _show_description_panel() -> void:
	var desc = CAT_DESCRIPTIONS.get(cat_id, [cat_id, ""])

	# Name panel — bottom left
	var name_panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.98, 0.96, 0.90, 1.0)
	style.border_color = Color(0.45, 0.28, 0.12, 1.0)
	style.set_border_width_all(2)
	style.set_corner_radius_all(3)
	style.set_content_margin_all(0)
	name_panel.add_theme_stylebox_override("panel", style)
	name_panel.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	name_panel.offset_left = 20
	name_panel.offset_bottom = -80
	name_panel.offset_top = -180
	name_panel.offset_right = 280

	var name_inner := MarginContainer.new()
	name_inner.add_theme_constant_override("margin_top", 12)
	name_inner.add_theme_constant_override("margin_bottom", 12)
	name_inner.add_theme_constant_override("margin_left", 16)
	name_inner.add_theme_constant_override("margin_right", 16)
	name_panel.add_child(name_inner)

	var name_label := Label.new()
	name_label.text = desc[0]
	name_label.add_theme_font_size_override("font_size", 24)
	name_label.add_theme_color_override("font_color", Color(0.45, 0.28, 0.12, 1.0))
	name_inner.add_child(name_label)

	# Desc panel — bottom right
	var desc_panel := PanelContainer.new()
	var style2 := style.duplicate()
	desc_panel.add_theme_stylebox_override("panel", style2)
	desc_panel.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	desc_panel.offset_right = -20
	desc_panel.offset_bottom = -80
	desc_panel.offset_top = -160
	desc_panel.offset_left = -300

	var desc_inner := MarginContainer.new()
	desc_inner.add_theme_constant_override("margin_top", 12)
	desc_inner.add_theme_constant_override("margin_bottom", 12)
	desc_inner.add_theme_constant_override("margin_left", 16)
	desc_inner.add_theme_constant_override("margin_right", 16)
	desc_panel.add_child(desc_inner)

	var desc_label := Label.new()
	desc_label.text = desc[1]
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.add_theme_color_override("font_color", Color(0.20, 0.10, 0.02, 1.0))
	desc_inner.add_child(desc_label)

	name_panel.modulate.a = 0.0
	desc_panel.modulate.a = 0.0
	$Control.add_child(name_panel)
	$Control.add_child(desc_panel)
	var tween = create_tween()
	tween.tween_property(name_panel, "modulate:a", 1.0, 0.4)
	tween.parallel().tween_property(desc_panel, "modulate:a", 1.0, 0.4)
	
