extends CanvasLayer

var _day_label: Label
var _money_label: Label


func _ready() -> void:
	layer = 10
	visible = false

	# ── Single panel: day counter + money (top-left) ────────────────────────
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_left", 12)
	margin.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	add_child(margin)

	var panel := _make_panel()
	margin.add_child(panel)

	var inner := _make_inner()
	panel.add_child(inner)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	inner.add_child(hbox)

	_day_label = Label.new()
	_day_label.text = "DAY %d" % GlobalInventory.day
	_day_label.add_theme_color_override("font_color", Color(0.28, 0.15, 0.05, 1.0))
	hbox.add_child(_day_label)

	var sep := Label.new()
	sep.text = "|"
	sep.add_theme_color_override("font_color", Color(0.45, 0.28, 0.12, 0.5))
	hbox.add_child(sep)

	var coin_icon := TextureRect.new()
	coin_icon.texture = load("res://assets/Misc/coin.png")
	coin_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	coin_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	coin_icon.custom_minimum_size = Vector2(24, 24)
	hbox.add_child(coin_icon)

	_money_label = Label.new()
	_money_label.text = "$%.0f" % Wallet.money_owned
	_money_label.add_theme_color_override("font_color", Color(0.28, 0.15, 0.05, 1.0))
	hbox.add_child(_money_label)

	GameManager.day_started.connect(_on_day_started)
	GameManager.night_started.connect(_on_night_started)
	Wallet.money_changed.connect(_on_money_changed)


func _make_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color     = Color(0.98, 0.95, 0.88, 1.0)
	style.border_color = Color(0.45, 0.28, 0.12, 1.0)
	style.set_border_width_all(2)
	style.set_corner_radius_all(3)
	style.set_content_margin_all(0)
	panel.add_theme_stylebox_override("panel", style)
	return panel


func _make_inner() -> MarginContainer:
	var inner := MarginContainer.new()
	inner.add_theme_constant_override("margin_top", 5)
	inner.add_theme_constant_override("margin_bottom", 5)
	inner.add_theme_constant_override("margin_left", 12)
	inner.add_theme_constant_override("margin_right", 12)
	return inner


func _on_day_started(day_number: int) -> void:
	visible = true
	_day_label.text = "DAY %d" % day_number
	_money_label.text = "$%.0f" % Wallet.money_owned


func _on_night_started() -> void:
	visible = false


func _on_money_changed(new_amount: float) -> void:
	if _money_label:
		_money_label.text = "$%.0f" % new_amount
