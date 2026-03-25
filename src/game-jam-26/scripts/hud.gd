extends CanvasLayer

var _day_label: Label


func _ready() -> void:
	layer = 10
	visible = false

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_left", 12)
	margin.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	add_child(margin)

	# Order ticket: cream background, warm brown border
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color        = Color(0.98, 0.95, 0.88, 1.0)   # cream
	style.border_color    = Color(0.45, 0.28, 0.12, 1.0)   # coffee brown
	style.set_border_width_all(2)
	style.set_corner_radius_all(3)
	style.set_content_margin_all(0)
	panel.add_theme_stylebox_override("panel", style)
	margin.add_child(panel)

	var inner := MarginContainer.new()
	inner.add_theme_constant_override("margin_top", 5)
	inner.add_theme_constant_override("margin_bottom", 5)
	inner.add_theme_constant_override("margin_left", 12)
	inner.add_theme_constant_override("margin_right", 12)
	panel.add_child(inner)

	_day_label = Label.new()
	_day_label.text = "DAY %d" % GlobalInventory.day
	_day_label.add_theme_color_override("font_color", Color(0.28, 0.15, 0.05, 1.0))  # dark brown
	inner.add_child(_day_label)

	GameManager.day_started.connect(_on_day_started)
	GameManager.night_started.connect(_on_night_started)


func _on_day_started(day_number: int) -> void:
	visible = true
	_day_label.text = "DAY %d" % day_number


func _on_night_started() -> void:
	visible = false
