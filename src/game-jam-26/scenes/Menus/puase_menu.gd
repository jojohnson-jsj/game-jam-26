extends ColorRect


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _unhandled_input(event: InputEvent) -> void:
	if(event.is_action_pressed("pause")):
		var isPause = !get_tree().paused
		get_tree().paused = isPause
		visible = isPause
		print(isPause)
