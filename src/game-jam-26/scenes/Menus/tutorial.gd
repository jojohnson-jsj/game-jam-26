extends CanvasLayer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$ColorRect/quitButton.disabled = true
	$ColorRect/quitButton.visible = false


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_quit_button_pressed() -> void:
	visible = false


func _on_go_button_pressed() -> void:
	$"ColorRect/ScrollContainer/VBoxContainer/Entry part".visible = false
	$ColorRect/quitButton.disabled = false
	$ColorRect/quitButton.visible = true
	Wallet.add_money(40)
	$ColorRect/ScrollContainer.scroll_vertical = 0
	$"../StoreMenu".visible = true
	$"../StoreMenu".process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	process_mode = Node.PROCESS_MODE_DISABLED
	
