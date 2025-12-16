extends Control
#ONREADY
@onready var main_buttons: VBoxContainer = $MainButtons
@onready var options: Panel = $Options
@onready var level_selection: Panel = $levelSelection
@onready var music_slider: HSlider = $Options/VBoxContainer/Music/AudioControl
@onready var sfx_slider: HSlider = $Options/VBoxContainer/SFX/AudioControl
@onready var fullscreen_button: CheckButton = $Options/VBoxContainer/FullScreenControl
@onready var easy_mode_button: CheckButton = $Options/VBoxContainer/easyMode
@onready var reset_progression_button: Button = $Options/VBoxContainer/delete
@onready var confirmation_dialog: AcceptDialog = $ConfirmationDialog
@onready var credits: Panel = $Credits
@onready var controls: Panel = $Controls
@onready var sfx_select: AudioStreamPlayer = $SFX_SELECT
@onready var sfx_back: AudioStreamPlayer = $SFX_BACK

#ALL LEVELS AND PATHS
var level_scenes = {
	"1-1": "res://scenes/prologue.tscn",
	"1-2": "res://scenes/level_2.tscn",
	"1-3": "res://scenes/level_3.tscn",
}
var level_scenes2 = {
	"2-1": "res://scenes/snow_1.tscn",
	"2-2": "res://scenes/snow_2.tscn",
	"2-3": "res://scenes/snow_3.tscn",
}
var level_scenes3 = {
	"3-1": "res://scenes/bedran_1.tscn",
	"3-2": "res://scenes/bedran_2.tscn",
	"3-3": "res://scenes/bedran_3.tscn",
}

# READY
func _ready() -> void:
	# Load settings 
	SaveManager.load_settings()
	# Update UI elements
	update_ui_elements()
	
	main_buttons.visible = true
	options.visible = false
	level_selection.visible = false
	credits.visible=false
	controls.visible=false
	
	# levelLoad with progression checking
	setup_level_buttons()
	# Connect reset progression 
	if reset_progression_button:
		reset_progression_button.pressed.connect(_on_reset_progression_pressed)

func setup_level_buttons():
	# Clear existing connections
	for button_name in level_scenes.keys():
		var button = $levelSelection/VBoxContainer/lvl1.get_node(button_name)
		if button.is_connected("pressed", _on_level_pressed.bind(button_name)):
			button.pressed.disconnect(_on_level_pressed.bind(button_name))
		button.pressed.connect(_on_level_pressed.bind(button_name))
		update_button_appearance(button, button_name)
		
	for button_name in level_scenes2.keys():
		var button = $levelSelection/VBoxContainer/lvl2.get_node(button_name)
		if button.is_connected("pressed", _on_level_pressed2.bind(button_name)):
			button.pressed.disconnect(_on_level_pressed2.bind(button_name))
		button.pressed.connect(_on_level_pressed2.bind(button_name))
		update_button_appearance(button, button_name)
		
	for button_name in level_scenes3.keys():
		var button = $levelSelection/VBoxContainer/lvl3.get_node(button_name)
		if button.is_connected("pressed", _on_level_pressed3.bind(button_name)):
			button.pressed.disconnect(_on_level_pressed3.bind(button_name))
		button.pressed.connect(_on_level_pressed3.bind(button_name))
		update_button_appearance(button, button_name)

#LEVEL PROGRESSION
func update_button_appearance(button: Button, level_name: String):
	if SaveManager.is_level_unlocked(level_name):
		button.disabled = false
		button.modulate = Color.WHITE  # Normal 
		if SaveManager.is_level_completed(level_name):
			button.modulate = Color.GREEN
	else:
		button.disabled = true
		button.modulate = Color.GRAY  # Grayed out (locked levels)

func update_ui_elements():
	# Update audio sliders
	if music_slider and music_slider.has_method("update_volume"):
		music_slider.update_volume()
	if sfx_slider and sfx_slider.has_method("update_volume"):
		sfx_slider.update_volume()
	
	# Update fullscreen button
	if fullscreen_button and fullscreen_button.has_method("update_display"):
		fullscreen_button.update_display()
	
	# Update easy mode button
	if easy_mode_button and easy_mode_button.has_method("update_easy_mode"):
		easy_mode_button.update_easy_mode()
	
	# Update level buttons appearance
	call_deferred("setup_level_buttons")

func _on_visibility_changed():
	if visible:
		update_ui_elements()

func _process(delta: float) -> void:
	pass

#START GAME BUTTON PRESSED
func _on_start_pressed() -> void:
	sfx_select.play()
	main_buttons.visible = false
	level_selection.visible = true
	# Refresh level buttons when opening level selection
	setup_level_buttons()

#OPTIONS BUTTON PRESSED
func _on_options_pressed() -> void:
	sfx_select.play()
	main_buttons.visible = false
	options.visible = true

#EXIT BUTTON PRESSED
func _on_exit_pressed() -> void:
	get_tree().quit()

#BACK BUTTON PRESSED
func _on_back_options_pressed() -> void:
	sfx_back.play()
	_ready()

# ENTER UNLOCKED LEVELS
func _on_level_pressed(button_name):
	if SaveManager.is_level_unlocked(button_name):
		get_tree().change_scene_to_file(level_scenes[button_name])
	else:
		print("Level ", button_name, " is locked!")

func _on_level_pressed2(button_name):
	if SaveManager.is_level_unlocked(button_name):
		get_tree().change_scene_to_file(level_scenes2[button_name])
	else:
		print("Level ", button_name, " is locked!")

func _on_level_pressed3(button_name):
	if SaveManager.is_level_unlocked(button_name):
		get_tree().change_scene_to_file(level_scenes3[button_name])
	else:
		print("Level ", button_name, " is locked!")

#RESET PROGRESSION
func _on_reset_progression_pressed():
	# Show confirmation dialog
	if confirmation_dialog:
		confirmation_dialog.dialog_text = "Are you sure you want to reset all game progression? This cannot be undone."
		confirmation_dialog.confirmed.connect(_confirm_reset_progression)
		confirmation_dialog.popup_centered()
	else:
		# Fallback: reset immediately
		_confirm_reset_progression()

func _confirm_reset_progression():
	SaveManager.reset_progression()
	print("Game progression has been reset!")
	update_ui_elements()
	# Disconnect signal / prevent multiple connections
	if confirmation_dialog and confirmation_dialog.confirmed.is_connected(_confirm_reset_progression):
		confirmation_dialog.confirmed.disconnect(_confirm_reset_progression)

#CREDITS PRESSED
func _on_credits_pressed() -> void:
	sfx_select.play()
	main_buttons.visible = false
	credits.visible = true

#CONTROLS PRESSED
func _on_controls_pressed() -> void:
	sfx_select.play()
	main_buttons.visible = false
	controls.visible = true
