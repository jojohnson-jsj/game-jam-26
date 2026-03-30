extends Control

signal start_day_pressed

const INTERACT_SFX = preload("res://assets/sound assests/interact-sound.mp3")

var _header_label: Label
var _money_label: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# Dark overlay
	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.05, 0.05, 0.12, 0.96)
	add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	# Order ticket: cream background, warm brown border
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color     = Color(0.98, 0.96, 0.90, 1.0)
	style.border_color = Color(0.45, 0.28, 0.12, 1.0)
	style.set_border_width_all(2)
	style.set_corner_radius_all(3)
	style.set_content_margin_all(0)
	panel.add_theme_stylebox_override("panel", style)
	panel.custom_minimum_size = Vector2(220, 0)
	center.add_child(panel)

	var inner := MarginContainer.new()
	inner.add_theme_constant_override("margin_top", 20)
	inner.add_theme_constant_override("margin_bottom", 20)
	inner.add_theme_constant_override("margin_left", 24)
	inner.add_theme_constant_override("margin_right", 24)
	panel.add_child(inner)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 8)
	inner.add_child(vbox)

	# Header — updated dynamically in refresh()
	_header_label = Label.new()
	_header_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_header_label.add_theme_color_override("font_color", Color(0.45, 0.28, 0.12, 1.0))
	vbox.add_child(_header_label)

	# Dashed separator
	var sep1 := Label.new()
	sep1.text = "- - - - - - - - - - - -"
	sep1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sep1.add_theme_color_override("font_color", Color(0.60, 0.42, 0.22, 0.7))
	vbox.add_child(sep1)

	var money_row := HBoxContainer.new()
	money_row.alignment = BoxContainer.ALIGNMENT_CENTER
	money_row.add_theme_constant_override("separation", 5)
	vbox.add_child(money_row)

	var coin_icon := TextureRect.new()
	coin_icon.texture = load("res://assets/Misc/coin.png")
	coin_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	coin_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	coin_icon.custom_minimum_size = Vector2(24, 24)
	money_row.add_child(coin_icon)

	_money_label = Label.new()
	_money_label.add_theme_color_override("font_color", Color(0.20, 0.10, 0.02, 1.0))
	money_row.add_child(_money_label)

	# Dashed separator
	var sep2 := Label.new()
	sep2.text = "- - - - - - - - - - - -"
	sep2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sep2.add_theme_color_override("font_color", Color(0.60, 0.42, 0.22, 0.7))
	vbox.add_child(sep2)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 8)
	vbox.add_child(spacer)

	# Button styled to match the receipt
	var btn_style := StyleBoxFlat.new()
	btn_style.bg_color = Color(0.45, 0.28, 0.12, 1.0)
	btn_style.set_corner_radius_all(3)
	btn_style.set_content_margin_all(0)

	var btn_hover := StyleBoxFlat.new()
	btn_hover.bg_color = Color(0.58, 0.38, 0.18, 1.0)
	btn_hover.set_corner_radius_all(3)
	btn_hover.set_content_margin_all(0)

	var start_btn := Button.new()
	start_btn.text = "Continue"
	start_btn.add_theme_stylebox_override("normal", btn_style)
	start_btn.add_theme_stylebox_override("hover", btn_hover)
	start_btn.add_theme_stylebox_override("pressed", btn_style)
	start_btn.add_theme_color_override("font_color", Color(0.98, 0.95, 0.88, 1.0))
	start_btn.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 0.95, 1.0))
	start_btn.custom_minimum_size = Vector2(0, 36)
	start_btn.pressed.connect(_on_start_day_pressed)
	vbox.add_child(start_btn)


func refresh(completed_day: int, current_money: float) -> void:
	if _header_label:
		_header_label.text = "— DAY %d SUMMARY —" % completed_day
	if _money_label:
		_money_label.text = "$%.0f" % current_money


func _on_start_day_pressed() -> void:
	SoundManager.play_sfx(INTERACT_SFX)
	emit_signal("start_day_pressed")
