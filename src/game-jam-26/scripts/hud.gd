extends CanvasLayer

var _day_label: Label
var _money_label: Label

var _dash_panel_container: PanelContainer = null
var _dash_widget: Control = null   # wrapper — animated on pop, draws the icon
var _dash_was_ready: bool = true
var _dash_ratio: float = 1.0       # 0..1 fill level, written by _process
var _dash_icon_tex: Texture2D = null

var _time_bar_fill: ColorRect = null
var _time_bar_width: float = 0.0

const DASH_ICON_SIZE = 42  # display size in pixels


func _ready() -> void:
	layer = 10
	visible = false

	# ── Outer container: main panel + dash panel side by side ───────────────
	var outer_margin := MarginContainer.new()
	outer_margin.add_theme_constant_override("margin_top", 12)
	outer_margin.add_theme_constant_override("margin_left", 12)
	outer_margin.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	add_child(outer_margin)

	var outer_hbox := HBoxContainer.new()
	outer_hbox.add_theme_constant_override("separation", 6)
	outer_margin.add_child(outer_hbox)

	# ── Main panel: DAY + coin + money ──────────────────────────────────────
	var main_panel := _make_panel()
	outer_hbox.add_child(main_panel)

	var main_inner := _make_inner(5, 5, 12, 12)
	main_panel.add_child(main_inner)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	main_inner.add_child(hbox)

	_day_label = Label.new()
	_day_label.text = "DAY %d" % GlobalInventory.day
	_day_label.add_theme_color_override("font_color", Color(0.28, 0.15, 0.05, 1.0))
	hbox.add_child(_day_label)

	var sep := Label.new()
	sep.text = "|"
	sep.add_theme_color_override("font_color", Color(0.45, 0.28, 0.12, 0.5))
	hbox.add_child(sep)

	var coin_hbox := HBoxContainer.new()
	coin_hbox.add_theme_constant_override("separation", 1)
	hbox.add_child(coin_hbox)

	var coin_icon := TextureRect.new()
	coin_icon.texture = load("res://assets/Misc/coin.png")
	coin_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	coin_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	coin_icon.custom_minimum_size = Vector2(26, 32)
	coin_hbox.add_child(coin_icon)

	_money_label = Label.new()
	_money_label.text = "$%.0f" % Wallet.money_owned
	_money_label.add_theme_color_override("font_color", Color(0.28, 0.15, 0.05, 1.0))
	_money_label.custom_minimum_size = Vector2(40, 0)  # room for "$9999"
	coin_hbox.add_child(_money_label)

	# ── Dash indicator panel ─────────────────────────────────────────────────
	_dash_panel_container = _make_panel()
	_dash_panel_container.visible = false
	outer_hbox.add_child(_dash_panel_container)

	var dash_inner := _make_inner(1, 1, 4, 4)
	_dash_panel_container.add_child(dash_inner)

	# CenterContainer centres its child at the child's minimum size.
	var dash_center := CenterContainer.new()
	dash_inner.add_child(dash_center)

	# Plain Control used purely as a canvas for custom drawing.
	# custom_minimum_size tells CenterContainer exactly how big to make it —
	# no texture node involved, so no minimum-size override.
	_dash_icon_tex = load("res://assets/Misc/cat_dash_icon.png")
	_dash_widget = Control.new()
	_dash_widget.custom_minimum_size = Vector2(DASH_ICON_SIZE, DASH_ICON_SIZE)
	_dash_widget.pivot_offset = Vector2(DASH_ICON_SIZE / 2.0, DASH_ICON_SIZE / 2.0)
	_dash_widget.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	# draw_texture_rect_region scales src → dest exactly, no node size fights.
	_dash_widget.draw.connect(_on_draw_dash_icon)
	dash_center.add_child(_dash_widget)

	GameManager.day_started.connect(_on_day_started)
	GameManager.night_started.connect(_on_night_started)
	Wallet.money_changed.connect(_on_money_changed)

	# ── Time bar: centered top, sun → bar → moon ─────────────────────────────
	var time_margin := MarginContainer.new()
	time_margin.add_theme_constant_override("margin_top", 26)
	time_margin.anchor_left = 0.5
	time_margin.anchor_right = 0.5
	time_margin.anchor_top = 0.0
	time_margin.anchor_bottom = 0.0
	time_margin.grow_horizontal = Control.GROW_DIRECTION_BOTH
	add_child(time_margin)

	var time_panel := _make_panel()
	time_margin.add_child(time_panel)

	var time_inner := _make_inner(5, 5, 10, 10)
	time_panel.add_child(time_inner)

	var time_hbox := HBoxContainer.new()
	time_hbox.add_theme_constant_override("separation", 6)
	time_inner.add_child(time_hbox)

	# Sun placeholder
	var sun := ColorRect.new()
	sun.color = Color(1.0, 0.85, 0.1)
	sun.custom_minimum_size = Vector2(12, 12)
	time_hbox.add_child(sun)

	# Bar background
	var bar_bg := ColorRect.new()
	bar_bg.color = Color(0.45, 0.28, 0.12, 0.3)
	bar_bg.custom_minimum_size = Vector2(400, 12)
	time_hbox.add_child(bar_bg)

	# Bar fill (child of bar_bg so it's clipped naturally)
	_time_bar_fill = ColorRect.new()
	_time_bar_fill.color = Color(0.95, 0.75, 0.2)
	_time_bar_fill.size = Vector2(0, 12)
	bar_bg.add_child(_time_bar_fill)
	_time_bar_width = 400.0

	# Moon placeholder
	var moon := ColorRect.new()
	moon.color = Color(0.95, 0.95, 1.0)
	moon.custom_minimum_size = Vector2(12, 12)
	time_hbox.add_child(moon)


func _process(_delta: float) -> void:
	# Time bar
	if _time_bar_fill != null and GameManager.day_active:
		var ratio = 1.0 - (GameManager.day_timer.time_left / GameManager.day_duration)
		_time_bar_fill.size.x = _time_bar_width * ratio

	if _dash_widget == null or not visible:
		return
	var player = get_tree().get_first_node_in_group("player")
	var show_dash: bool = player != null and player.has_dash_cat
	_dash_panel_container.visible = show_dash
	if not show_dash:
		return

	var cooldown_timer: float = player._dash_cooldown_timer
	var cooldown_max: float   = player.DASH_COOLDOWN
	var is_ready: bool        = cooldown_timer <= 0.0

	_dash_ratio = 1.0 if is_ready else 1.0 - (cooldown_timer / cooldown_max)
	_dash_widget.queue_redraw()

	if is_ready and not _dash_was_ready:
		_dash_was_ready = true
		_pop_dash_icon()
	elif not is_ready:
		_dash_was_ready = false


func _on_draw_dash_icon() -> void:
	if _dash_icon_tex == null or _dash_widget == null:
		return
	var tw := float(_dash_icon_tex.get_width())   # 48
	var th := float(_dash_icon_tex.get_height())  # 48
	var s  := float(DASH_ICON_SIZE)               # 42

	# Dim full icon as background.
	_dash_widget.draw_texture_rect(_dash_icon_tex, Rect2(0.0, 0.0, s, s),
		false, Color(1.0, 1.0, 1.0, 0.25))

	# The sprite content occupies y=9..38 of the 48-px canvas; the top 9 px are
	# transparent padding. If we map the fill to the full canvas height the icon
	# looks "completely full" ~0.9 s before the cooldown expires (because all
	# visible content is already revealed once ratio > 38/48 ≈ 0.79). Instead,
	# map the fill to the content bounding box so ratio=1.0 coincides exactly
	# with the ready state and the pop animation.
	const CONTENT_TOP := 9.0   # first non-transparent row in source
	const CONTENT_BOT := 38.0  # one past last non-transparent row in source
	var content_h_src := CONTENT_BOT - CONTENT_TOP          # 29 px in source
	var content_bot_dst := (CONTENT_BOT / th) * s           # ≈ 33.25 px in display
	var content_h_dst   := (content_h_src / th) * s         # ≈ 25.375 px in display

	var fill_h_src := content_h_src * _dash_ratio
	var fill_h_dst := content_h_dst * _dash_ratio
	var src_y      := CONTENT_BOT - fill_h_src
	var dst_y      := content_bot_dst - fill_h_dst

	_dash_widget.draw_texture_rect_region(_dash_icon_tex,
		Rect2(0.0, dst_y, s, fill_h_dst),
		Rect2(0.0, src_y, tw, fill_h_src))


func _pop_dash_icon() -> void:
	if _dash_widget == null:
		return
	var tween = create_tween()
	tween.tween_property(_dash_widget, "scale", Vector2(1.4, 1.4), 0.07) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(_dash_widget, "scale", Vector2.ONE, 0.12) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN_OUT)


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


func _make_inner(mt: int, mb: int, ml: int, mr: int) -> MarginContainer:
	var inner := MarginContainer.new()
	inner.add_theme_constant_override("margin_top",    mt)
	inner.add_theme_constant_override("margin_bottom", mb)
	inner.add_theme_constant_override("margin_left",   ml)
	inner.add_theme_constant_override("margin_right",  mr)
	return inner


func _on_day_started(day_number: int) -> void:
	visible = true
	_day_label.text   = "DAY %d" % day_number
	_money_label.text = "$%.0f" % Wallet.money_owned
	_dash_was_ready = true


func _on_night_started() -> void:
	visible = false


func _on_money_changed(new_amount: float) -> void:
	if _money_label:
		_money_label.text = "$%.0f" % new_amount
