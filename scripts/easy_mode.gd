extends CheckButton

func _ready() -> void:
	# Set initial value
	button_pressed = SaveManager.get_easy_mode()
	toggled.connect(_on_toggled)

# Public method to update the button from current setting
func update_easy_mode():
	button_pressed = SaveManager.get_easy_mode()

func _on_toggled(toggled_on: bool) -> void:
	SaveManager.set_easy_mode(toggled_on)
	SaveManager.save_settings()
