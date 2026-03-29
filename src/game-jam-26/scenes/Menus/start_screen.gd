extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_play_button_pressed() -> void:
	$"../../".call("_on_start_day_pressed")

func _on_pull_button_pressed() -> void:
	$"../../StoreMenu".visible = true
	$"../../StoreMenu".process_mode = Node.PROCESS_MODE_ALWAYS
	$"../".visible = false
	$"../".process_mode = Node.PROCESS_MODE_DISABLED


func _on_quit_button_pressed() -> void:
	get_tree().quit()


func _on_inventory_button_pressed() -> void:
	var page = $"../../CatPlacementPage/CatPlacementPage"
	page.open()
	$"../".visible = false
	$"../".process_mode = Node.PROCESS_MODE_DISABLED


func _on_cat_button_pressed() -> void:
	$catButton/AudioStreamPlayer.play()
