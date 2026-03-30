extends Node2D

const FADE_DURATION := 0.65

var _night_screen_ctrl: Control
var _hud: CanvasLayer
var _fade_rect: ColorRect
var _night_music: AudioStreamPlayer
var _money_at_day_start: float = 0.0


var _first_day: bool = true

func _ready() -> void:
	# Initial visibility: only the start menu is active
	$GameWorld.visible = false
	$GameWorld.process_mode = Node.PROCESS_MODE_DISABLED
	$StartMenu.visible = true
	$StartMenu.process_mode = Node.PROCESS_MODE_ALWAYS
	$NightScreen.visible = false
	$NightScreen.process_mode = Node.PROCESS_MODE_DISABLED
	$StoreMenu.visible = false
	$StoreMenu.process_mode = Node.PROCESS_MODE_DISABLED

	# Build the night screen UI and wire its button back here
	_night_screen_ctrl = load("res://scripts/night_screen.gd").new()
	_night_screen_ctrl.start_day_pressed.connect(_on_night_continue_pressed)
	$NightScreen.add_child(_night_screen_ctrl)

	# HUD — self-managing via GameManager signals
	_hud = load("res://scripts/hud.gd").new()
	add_child(_hud)

	# Full-screen black fade overlay — sits above everything
	var fade_layer := CanvasLayer.new()
	fade_layer.layer = 99
	add_child(fade_layer)
	_fade_rect = ColorRect.new()
	_fade_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fade_rect.color = Color.BLACK
	_fade_rect.modulate.a = 0.0
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_layer.add_child(_fade_rect)

	# Night music player — persists across night screen and start menu
	_night_music = AudioStreamPlayer.new()
	_night_music.stream = load("res://assets/sound assests/Bkg-Music/harumachimusic-morning-calm-236192.mp3")
	_night_music.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_night_music)

	# Connect to the day/night cycle
	GameManager.night_started.connect(_on_night_started)

	# Save state is only used to bridge days within a single session.
	# Do NOT load it here — every game launch starts fresh from day 1.
	if DebugConfig.starting_money > 0.0:
		Wallet.add_money(DebugConfig.starting_money)


func _on_night_started() -> void:
	# Fade to black, then swap to night screen, then fade back in
	_fade_to(1.0, FADE_DURATION, func():
		$GameWorld/Music.stop()
		_night_music.play()
		$GameWorld.visible = false
		$GameWorld.process_mode = Node.PROCESS_MODE_DISABLED
		# Clean up customers so they don't show through the night screen
		for customer in GameManager.active_customers:
			if is_instance_valid(customer):
				customer.get_node("PatienceTimer").stop()
				customer.queue_free()
		GameManager.active_customers.clear()
		GameManager.waiting_queue.clear()
		$NightScreen.visible = true
		$NightScreen.process_mode = Node.PROCESS_MODE_ALWAYS
		# Day hasn't incremented yet — pass the completed day number
		_night_screen_ctrl.refresh(GlobalInventory.day, _money_at_day_start, Wallet.money_owned)
		_fade_to(0.0, FADE_DURATION)
	)


func _on_night_continue_pressed() -> void:
	_fade_to(1.0, FADE_DURATION, func():
		$NightScreen.visible = false
		$NightScreen.process_mode = Node.PROCESS_MODE_DISABLED
		$StartMenu.visible = true
		$StartMenu.process_mode = Node.PROCESS_MODE_ALWAYS
		# Stop start screen music — game music continues from GameWorld/Music
		var start_music = $StartMenu.get_node_or_null("Start Screen/Music")
		if start_music:
			start_music.stop()
		var start_screen = $StartMenu.get_node_or_null("Start Screen")
		if start_screen and start_screen.has_method("show_info_panel"):
			start_screen.show_info_panel()
		_fade_to(0.0, FADE_DURATION)
	)

func _on_start_day_pressed() -> void:
	_fade_to(1.0, FADE_DURATION, func():
		SaveManager.save_state()
		if not _first_day:
			GlobalInventory.day += 1
		_first_day = false
		$NightScreen.visible = false
		$NightScreen.process_mode = Node.PROCESS_MODE_DISABLED
		$StartMenu.visible = false
		$StartMenu.process_mode = Node.PROCESS_MODE_DISABLED
		$GameWorld.visible = true
		$GameWorld.process_mode = Node.PROCESS_MODE_PAUSABLE
		$GameWorld.startDay()
		_money_at_day_start = Wallet.money_owned
		_night_music.stop()
		if not $GameWorld/Music.playing:
			$GameWorld/Music.play()
		_fade_to(0.0, FADE_DURATION)
	)


# Animate _fade_rect alpha to `target`. Calls `on_complete` when done (optional).
func _fade_to(target: float, duration: float, on_complete: Callable = Callable()) -> void:
	var tween := create_tween()
	tween.tween_property(_fade_rect, "modulate:a", target, duration).set_ease(Tween.EASE_IN_OUT)
	if on_complete.is_valid():
		tween.tween_callback(on_complete)
