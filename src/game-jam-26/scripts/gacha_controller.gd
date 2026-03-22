extends Node2D

var started := false
var finished := false

@onready var prewish = $PreWish
@onready var prewish_stars = $PreWish/Stars
@onready var prewish_star_distant = $PreWish/StarDistant
@onready var prewish_star_close = $PreWish/StarClose
@onready var prewish_grass = $PreWish/Grass
@onready var prewish_grass_lit = $PreWish/GrassLit
@onready var gacha_box = $GachaBox
@onready var gigi_test_sprite = $GigiTestSprite

func _input(event):
	if event.is_action_pressed("click"):
		if not finished:
			pass
			#skip_animation()
		else:
			pass
			#go_back()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if not started:
		play_gacha_pull()
		started = true

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
	prewish.visible = false
	gacha_box.visible = true
	await wait(.5)
	gacha_box.modulate = Color(5, 5, 5, 1)
	await wait(.5)
	gacha_box.visible = false
	gigi_test_sprite.modulate = Color(0, 0, 0, 1)
	gigi_test_sprite.visible = true
	await wait(.5)
	var tween = create_tween()
	tween.tween_property(gigi_test_sprite, "modulate", Color(1,1,1,1), 0.3)
	pass
	
func show_result_screen() -> void:
	pass
	
