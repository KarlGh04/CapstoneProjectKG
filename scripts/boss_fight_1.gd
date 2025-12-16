extends CharacterBody2D
#CONSTS
const SPEED = 40
const GRAVITY = 500.0
#VARS
var direction = 1  # Starting direction (1 = right, -1 = left)
var knockback_time = 0.0
var knockback_duration = 0.2
var health = 50
var dead = false
var active = false
var projectile_scene = preload("res://scenes/projectile.tscn")
var projectile_sceneH = preload("res://scenes/projectile_h.tscn")
var is_flashing = false
var flash_duration = 0.1  
var flash_timer = 0.0
var loop_start = 0.0  
var loop_end = 335 
#SIGNALS
signal boss_activated
signal boss_died
#ONREADY
@onready var music_player: AudioStreamPlayer = $AudioStreamPlayer
@onready var ray_cast_right = $RayCastRight
@onready var ray_cast_left = $RayCastLeft
@onready var animated_sprite = $AnimatedSprite2D
@onready var player = get_node("../Player")
@onready var progress_bar = $UI/ProgressBar
@onready var deathMessage = $UI/Label
@onready var spawner_timer = $ProjectileSpawner/SpawnTimer
@onready var spawner = $ProjectileSpawner
@onready var spawner_timerH = $ProjectileSpawner_h/SpawnTimerH
@onready var spawnerH = $ProjectileSpawner_h
@onready var portalLeft = $"../RemoteTransform2D/ProjectileSpawner_h2/leftPortal"
@onready var sfx_death: AudioStreamPlayer = $SFX_DEATH
@onready var sfx_hit: AudioStreamPlayer = $SFX_HIT

#READY
func _ready():
	portalLeft.global_position = Vector2(-1240, 70)
	progress_bar.max_value = health
	progress_bar.value = health

#PHYSICS
func _physics_process(delta):
	if not active:
		return
	# Handle hit flash effect
	if is_flashing:
		flash_timer -= delta
		if flash_timer <= 0:
			is_flashing = false
			animated_sprite.modulate = Color(1, 1, 1)  # Reset to normal color		
	if dead:
		# Apply gravity so the boss falls
		velocity.y += GRAVITY * delta
		move_and_slide()
		return

	# Apply gravity
	velocity.y += GRAVITY * delta

	# Handle knockback
	if knockback_time > 0:
		knockback_time -= delta
		move_and_slide()
		return
	
	if not player or not player.is_inside_tree():
		return

	var distance_to_player = global_position.distance_to(player.global_position)
	
	# Regular patrol behavior
	handle_wall_collision()
	animated_sprite.play("default")
	velocity.x = direction * SPEED

	move_and_slide()

#ACTIVATE
func activate():
	if not active:
		active = true
		emit_signal("boss_activated")
		print("Boss activated!")
		$"../bossArea1Limits/CollisionShape2D".set_deferred("disabled",false)
		$"../bossArea1Limits/CollisionShape2D2".set_deferred("disabled",false)
		spawner_timer.start()
		spawner_timerH.start()
		start_boss_music()

#WALLS COLLISION
func handle_wall_collision():
	# Using raycasts 
	if ray_cast_right.is_colliding() and direction == 1:
		direction = -1
		animated_sprite.flip_h = true
	elif ray_cast_left.is_colliding() and direction == -1:
		direction = 1
		animated_sprite.flip_h = false
	


func _on_animated_sprite_2d_animation_finished() -> void:
	direction=0 # Replace with function body.

#ON HIT
func apply_knockback(amount: float, direction: int) -> void:
	health-=1
	sfx_hit.play()
	progress_bar.value = health
	# Start the hit flash effect
	is_flashing = true
	flash_timer = flash_duration
	animated_sprite.modulate = Color(10, 10, 10)  #white
	if health==0:
		sfx_death.play()
		spawner_timer.stop()
		spawner_timerH.stop()
		collision_layer = 0
		collision_mask = 0
		dead = true
		# Stop the boss music
		if music_player and music_player.playing:
			music_player.stop()
		
		emit_signal("boss_died")
		player.reset_health()
		#hide bar
		await get_tree().create_timer(1.0).timeout
		progress_bar.visible = false
		# Show "BOSS SLAINED"
		deathMessage.text = "VICTORY ACHIEVED"
		deathMessage.visible = true
		# Wait 5 seconds then hide the message
		await get_tree().create_timer(5.0).timeout
		deathMessage.visible = false
		$"../bossArea1Limits/CollisionShape2D".set_deferred("disabled",true)
		$"../bossArea1Limits/CollisionShape2D2".set_deferred("disabled",true)
		get_tree().change_scene_to_file("res://scenes/level_2.tscn")

#SPAWN SWORDS UP TO DOWN
func _on_spawn_timer_timeout() -> void:
	if dead: 
		return
	var spawn_pos = Vector2(randi_range(-1228.0, -1083.5), spawner.position.y)
	var spawn_pos2 = Vector2(randi_range(-1083.5, -939), spawner.position.y)
	var spawn_pos3 = Vector2(randi_range(-939, -794.5), spawner.position.y)
	var spawn_pos4 = Vector2(randi_range(-794.5, -650), spawner.position.y)
	
	var projectile = projectile_scene.instantiate()
	var projectile2 = projectile_scene.instantiate()
	var projectile3 = projectile_scene.instantiate()
	var projectile4 = projectile_scene.instantiate()
	
	projectile.global_position = spawn_pos
	projectile2.global_position = spawn_pos2
	projectile3.global_position = spawn_pos3
	projectile4.global_position = spawn_pos4
	
	get_parent().add_child(projectile)
	get_parent().add_child(projectile2)
	get_parent().add_child(projectile3)
	get_parent().add_child(projectile4)
	
	var new_wait = randf_range(0.5, 0.8)
	spawner_timer.wait_time = new_wait
	spawner_timer.start()  

#SPAWN SWORDS LEFT TO RIGHT
func _on_spawn_timer_h_timeout() -> void:
	if dead: 
		return
		
	portalLeft.visible = true
	await get_tree().create_timer(0.5).timeout
	var spawn_pos = Vector2(spawnerH.position.x, spawnerH.position.y)
	var projectile = projectile_sceneH.instantiate()
	projectile.global_position = spawn_pos
	get_parent().add_child(projectile)
	
	await get_tree().create_timer(1.0).timeout
	if dead:  
		return
	
	portalLeft.visible = false
	var new_wait = randf_range(2, 3)
	spawner_timerH.wait_time = new_wait
	spawner_timerH.start()

#MUSIC
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
