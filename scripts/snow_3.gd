extends Node2D
#ONREADY
@onready var camera = $Player/Camera2D
@onready var player = $Player
@onready var boss_area = $boss_area_1  
@onready var boss = $iceMage
@onready var boss2 = $iceMage2
@onready var my_label = $iceMage/UI/ProgressBar
@onready var my_label2 = $iceMage2/UI/ProgressBar
@onready var music_player: AudioStreamPlayer = $AudioStreamPlayer
@onready var sfx_ambiance: AudioStreamPlayer = $SFX_AMBIANCE
@onready var new_ability: Label = $GUI/newAbility
#VARS
var camera_locked = false
var camera_position_before_lock = Vector2.ZERO
var has_entered_boss_area = false  #flag to track first entry
var boss1_alive = true
var boss2_alive = true
var loop_start = 13  
var loop_end = 169 

#READY
func _ready() -> void:
	boss.connect("boss_died", Callable(self, "_on_boss_died1"))
	boss.connect("boss_activated", Callable(self, "_on_boss_activated"))
	boss2.connect("boss_died", Callable(self, "_on_boss_died2"))
	boss2.connect("boss_activated", Callable(self, "_on_boss_activated")) 
	camera.position_smoothing_enabled = true
	camera.global_position = player.global_position
	
	# Connect the area entered signal programmatically if not done in the editor
	if boss_area:
		boss_area.connect("body_entered", Callable(self, "_on_boss_area_1_body_entered"))

#LOCK CAMERA ON BOSSFIGHT
func _process(delta: float) -> void:
	if camera_locked:
		camera.global_position = camera_position_before_lock

#ACTIVATE BOTH BOSSFIGHTS
func _on_boss_area_1_body_entered(body: Node2D) -> void:
	if body.name == "Player" and not has_entered_boss_area and boss1_alive and boss2_alive: 
		has_entered_boss_area = true
		camera_position_before_lock = camera.global_position
		camera.position_smoothing_enabled = false
		camera_locked = true
		camera.make_current()
		#disable pause
		body.can_pause = false
		#activate
		boss.activate()
		boss.visible=true
		boss2.activate()
		boss2.visible=true
		sfx_ambiance.stop()
		start_boss_music()

func _on_boss_activated():
	print("Boss fight begins!")
	my_label2.position = my_label.position - Vector2(0, 30)
	my_label.visible = true
	my_label2.visible = true

#BOTH BOSSES DIED (MAGE 1 AND 2)
func _on_boss_died():
	SaveManager.complete_level("2-3")
	# Stop the boss music
	if music_player and music_player.playing:
		music_player.stop()
	camera_locked = false
	has_entered_boss_area = false  
	camera.position = Vector2.ZERO # Reset to player's center
	camera.position_smoothing_enabled = true
	camera.make_current()
	new_ability.visible = true
	# Force the camera to immediately update to player's position
	camera.global_position = player.global_position
	$"bossArea1Limits/CollisionShape2D".set_deferred("disabled",true)
	$"bossArea1Limits/CollisionShape2D2".set_deferred("disabled",true)
	await get_tree().create_timer(5.0).timeout
	get_tree().change_scene_to_file("res://scenes/bedran_1.tscn")

func _on_boss_died1():
	boss1_alive = false
	if not boss2_alive:
		_on_boss_died()
func _on_boss_died2():
	boss2_alive = false
	if not boss1_alive:
		_on_boss_died()
		
#START MUSIC
func start_boss_music():
	if not music_player.playing:
		music_player.play()
		var timer = Timer.new()
		timer.wait_time = 0.1  # Check every 0.1 seconds
		timer.timeout.connect(_check_music_position)
		add_child(timer)
		timer.start()

func _check_music_position():
	if music_player.playing:
		var current_pos = music_player.get_playback_position()
		#jump to loop start
		if current_pos >= loop_end:
			music_player.seek(loop_start)
