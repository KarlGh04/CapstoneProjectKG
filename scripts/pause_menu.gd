extends CanvasLayer
#ONREADY
@onready var back_button: Button = $VBoxContainer/resume
@onready var restart: Button = $VBoxContainer/restart
@onready var main_menu_button: Button = $VBoxContainer/mainMenu

#READY
func _ready():
	back_button.pressed.connect(_on_resume_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)
	
	# NO INPUTS
	set_process_input(false)

#GO BACK TO MENU
func _on_main_menu_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn") 

#RESUME
func _on_resume_pressed() -> void:
	get_tree().paused = false
	queue_free()

#RESTART LEVEL
func _on_restart_pressed() -> void:
	get_tree().paused = false
	queue_free()
	get_tree().reload_current_scene()
