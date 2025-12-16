extends Node2D
#ONREADY
@onready var camera = $Player/Camera2D
@onready var player = $Player
@onready var boss_area = $bossArea1
@onready var boss = $bossFight1
@onready var my_label = $bossFight1/UI/ProgressBar
@onready var sfx_ambiance: AudioStreamPlayer = $SFX_AMBIANCE
#VARS
var camera_locked = false
var camera_position_before_lock = Vector2.ZERO
var has_entered_boss_area = false  # New flag to track first entry
var boss1_alive = true

#READY
func _ready() -> void:
	boss.connect("boss_died", Callable(self, "_on_boss_died"))
	boss.connect("boss_activated", Callable(self, "_on_boss_activated")) 
	camera.position_smoothing_enabled = true
	camera.global_position = player.global_position
	
#FIX CAMERA DURING BOSSFIGHT
func _process(delta: float) -> void:
	if camera_locked:
		camera.global_position = camera_position_before_lock

#ACTIVATE BOSSFIGHT
func _on_boss_area_1_body_entered(body: Node2D) -> void:
	if body.name == "Player" and not has_entered_boss_area and boss1_alive:  # Only freeze on first entry
		has_entered_boss_area = true
		camera_position_before_lock = camera.global_position
		camera.position_smoothing_enabled = false
		camera_locked = true
		camera.make_current()
		sfx_ambiance.stop()
		boss.activate()

func _on_boss_activated():
	print("Boss fight begins!")
	my_label.visible = true

#BOSS DIED
func _on_boss_died():
	boss1_alive = false
	camera_locked = false
	has_entered_boss_area = false  
	camera.position = Vector2.ZERO # Reset to player's center
	camera.position_smoothing_enabled = true
	camera.make_current()
	# Force the camera to immediately update to player's position
	camera.global_position = player.global_position
	SaveManager.complete_level("1-3")

#NEXT LEVEL
func _on_end_level_body_entered(body: Node2D) -> void:
	if !body.is_in_group("enemies"):
		get_tree().change_scene_to_file("res://scenes/snow_1.tscn")
