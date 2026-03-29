extends ColorRect

func _ready() -> void:
	color = Color(0.1, 0.05, 0.02, 0.75)
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_parent().visible = false

	# ── Centered panel ────────────────────────────────────────────────────────
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color     = Color(0.98, 0.95, 0.88, 1.0)
	style.border_color = Color(0.45, 0.28, 0.12, 1.0)
	style.set_border_width_all(3)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(0)
	panel.add_theme_stylebox_override("panel", style)
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical   = Control.GROW_DIRECTION_BOTH
	add_child(panel)

	var inner := MarginContainer.new()
	for side in ["margin_top", "margin_bottom", "margin_left", "margin_right"]:
		inner.add_theme_constant_override(side, 24)
	panel.add_child(inner)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	inner.add_child(vbox)

	# Title
	var title := Label.new()
	title.text = "PAUSED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color(0.28, 0.15, 0.05))
	title.add_theme_font_size_override("font_size", 24)
	vbox.add_child(title)

	var divider := ColorRect.new()
	divider.color = Color(0.45, 0.28, 0.12, 0.4)
	divider.custom_minimum_size = Vector2(220, 2)
	vbox.add_child(divider)

	# Sound slider row
	var slider_row := HBoxContainer.new()
	slider_row.add_theme_constant_override("separation", 8)
	vbox.add_child(slider_row)

	var slider_label := Label.new()
	slider_label.text = "Music"
	slider_label.add_theme_color_override("font_color", Color(0.28, 0.15, 0.05))
	slider_row.add_child(slider_label)

	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.01
	slider.value = db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Master")))
	slider.custom_minimum_size = Vector2(160, 20)
	slider.value_changed.connect(_on_slider_changed)
	slider_row.add_child(slider)

	# Resume button
	var resume_btn := _make_button("Resume")
	resume_btn.pressed.connect(_on_resume)
	vbox.add_child(resume_btn)


func _make_button(label_text: String) -> Button:
	var btn := Button.new()
	btn.text = label_text
	btn.custom_minimum_size = Vector2(220, 36)
	var style_normal := StyleBoxFlat.new()
	style_normal.bg_color     = Color(0.98, 0.95, 0.88, 1.0)
	style_normal.border_color = Color(0.45, 0.28, 0.12, 1.0)
	style_normal.set_border_width_all(2)
	style_normal.set_corner_radius_all(3)
	style_normal.set_content_margin_all(6)
	var style_hover := style_normal.duplicate()
	style_hover.bg_color = Color(0.88, 0.82, 0.70, 1.0)
	btn.add_theme_stylebox_override("normal", style_normal)
	btn.add_theme_stylebox_override("hover",  style_hover)
	btn.add_theme_stylebox_override("pressed", style_hover)
	btn.add_theme_color_override("font_color", Color(0.28, 0.15, 0.05))
	return btn


func _on_slider_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index("Master"),
		linear_to_db(value)
	)


func _on_resume() -> void:
	get_tree().paused = false
	get_parent().visible = false
	_set_hud_visible(true)


func _on_back_to_menu() -> void:
	get_tree().paused = false
	SaveManager.reset_all()
	get_tree().call_deferred("change_scene_to_file", "res://scenes/Main.tscn")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		var main = get_tree().current_scene
		if not main.get_node("GameWorld").visible:
			return
		var pausing = not get_tree().paused
		get_tree().paused = pausing
		get_parent().visible = pausing
		_set_hud_visible(not pausing)


func _set_hud_visible(show: bool) -> void:
	for node in get_tree().current_scene.get_children():
		if node is CanvasLayer and node.get_script() and node.get_script().resource_path.ends_with("hud.gd"):
			node.visible = show
