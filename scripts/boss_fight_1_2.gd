extends CharacterBody2D
#CONST
const GRAVITY = 500.0
#VARS
var SPEED = 40
var teleport = 0
var direction = 1  # Starting direction (1 = right, -1 = left)
var knockback_time = 0.0
var knockback_duration = 0.2
var health = 50
var dead = false
var active = false
var is_teleporting = false
var projectile_scene = preload("res://scenes/projectile.tscn")
var projectile_sceneH = preload("res://scenes/projectile_h.tscn")
var projectile_sceneH2 = preload("res://scenes/projectile_horizontal_2.tscn")
var is_flashing = false
var flash_duration = 0.1  
var flash_timer = 0.0
var phase_two_active = false
var ball_scene = preload("res://scenes/spins.tscn")
var orbit_balls = []
var orbit_radius = 80
var orbit_speed = 1.5
var orbit_angle_offset = 0.0 
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
@onready var spawnerH2 = $"../RemoteTransform2D/ProjectileSpawner_h2"
@onready var portalLeft = $"../RemoteTransform2D/ProjectileSpawner_h2/leftPortal"
@onready var portalRight = $"../RemoteTransform2D/ProjectileSpawner_h2/rightPortal"
@onready var collision1 = $CollisionShape2D
@onready var sfx_death: AudioStreamPlayer = $SFX_DEATH
@onready var sfx_hit: AudioStreamPlayer = $SFX_HIT

#READY
func _ready():
	portalLeft.global_position = Vector2(-1895, 700)
	portalRight.global_position = Vector2(-1340, 700)
	progress_bar.max_value = health
	progress_bar.value = health
	
#PHYSICS	
func _physics_process(delta):
	if not active:
		return

	# Flashing effect
	if is_flashing:
		flash_timer -= delta
		if flash_timer <= 0:
			is_flashing = false
			animated_sprite.modulate = Color(1, 1, 1)

	if dead:
		velocity.y += GRAVITY * delta
		move_and_slide()
		return

	# Orbiting behavior(PHASE2)
	if phase_two_active:
		global_position.y = 625
		velocity.y = 0  # Don't fall
		SPEED=60
		orbit_angle_offset += orbit_speed * delta
		for i in range(orbit_balls.size()):
			var angle = orbit_angle_offset + i * PI/2
			var offset = Vector2(cos(angle), sin(angle)) * orbit_radius
			orbit_balls[i].global_position = global_position + offset

		# Movement still handled here normally
		if not is_teleporting:
			animated_sprite.play("default")
			velocity.x = direction * SPEED
			move_and_slide()

	# Phase 1 behavior
	velocity.y += GRAVITY * delta
	if knockback_time > 0:
		knockback_time -= delta
		move_and_slide()
		return

	if not player or not player.is_inside_tree():
		return

	handle_wall_collision()
	if not is_teleporting:
		animated_sprite.play("default")
	velocity.x = direction * SPEED
	move_and_slide()
	
#ACTIVATION
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

#HANDLE WALL COLLISION
func handle_wall_collision():
	# Using raycasts 
	if ray_cast_right.is_colliding() and direction == 1:
		direction = -1
		animated_sprite.flip_h = true
	elif ray_cast_left.is_colliding() and direction == -1:
		direction = 1
		animated_sprite.flip_h = false
	

func _on_animated_sprite_2d_animation_finished() -> void:
	direction=0 

#ON HIT
func apply_knockback(amount: float, direction: int) -> void:
	sfx_hit.play()
	health-=1
	progress_bar.value = health
	teleport +=1
	# Start the hit flash effect
	is_flashing = true
	flash_timer = flash_duration
	animated_sprite.modulate = Color(10, 10, 10)  # Bright white
	
	# === PHASE 2 START ===
	if not phase_two_active and health <= 25:
		phase_two_active = true
		# Disable phase 1 attacks
		spawner_timer.stop()
		spawner_timerH.stop()
		# Add new phase 2 behaviors here
		print("Phase 2 started!")
		call_deferred("start_phase_two_attacks")
	
	#teleport
	if health >0 && teleport >2:
		var x = randi_range(-1700 , -1400)
		var attempts = 0
		while abs(x - position.x)<150 and attempts < 100:
			x = randi_range(-1700 , -1400)
			attempts += 1
		is_teleporting = true
		animated_sprite.play("teleport")
		await get_tree().process_frame  # Allow a frame to pass so the animation starts
		await animated_sprite.animation_finished  
		position.x = x
		position.y = randi_range(663, 450)
		animated_sprite.play("teleport")
		await get_tree().process_frame  # Allow a frame to pass so the animation starts
		await animated_sprite.animation_finished
		is_teleporting = false
		teleport =0
	#DEATH
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
		deathMessage.text = "SPACE ABILITY ACQUIRED"
		deathMessage.visible = true
		# Wait 5 seconds then hide the message
		await get_tree().create_timer(5.0).timeout
		deathMessage.visible = false
		$"../bossArea1Limits/CollisionShape2D".set_deferred("disabled",true)
		$"../bossArea1Limits/CollisionShape2D2".set_deferred("disabled",true)
		
#SPAWN UP TO DOWN SWORDS
func _on_spawn_timer_timeout() -> void:
	if phase_two_active:
		return
	var spawn_pos = Vector2(randi_range(-1900.0, -1755.5), 350)
	var spawn_pos2 = Vector2(randi_range(-1755.5, -1611), 350)
	var spawn_pos3 = Vector2(randi_range(-1611, -1466.5), 350)
	var spawn_pos4 = Vector2(randi_range(-1466.5, -1322), 350)
	
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

#SPAWN RIGHT TO LEFT AND KEFT TO RIGHT SWORDS
func _on_spawn_timer_h_timeout() -> void:
	if phase_two_active:
		return
		
	var p1 = randi_range(0,1)
	var p2 = randi_range(0,1)
	portalLeft.play("default")
	portalRight.play("default")
	if p1 ==1:
		#left to right
		portalLeft.visible = true
		await get_tree().create_timer(0.5).timeout
		var spawn_pos = Vector2(-2000, 700)	
		var projectile = projectile_sceneH.instantiate()		
		projectile.global_position = spawn_pos		
		get_parent().add_child(projectile)
	if p2 ==1:
		#right to left
		portalRight.visible = true
		await get_tree().create_timer(0.5).timeout
		var spawn_pos2 = Vector2(-1233, 700)
		var projectile2 = projectile_sceneH2.instantiate()
		projectile2.global_position = spawn_pos2
		get_parent().add_child(projectile2)
	var new_wait = randf_range(2, 3)
	await get_tree().create_timer(1.0).timeout
	portalLeft.visible = false
	portalRight.visible = false
	spawner_timerH.wait_time = new_wait
	spawner_timerH.start()

#PHASE2 ATTACK
func start_phase_two_attacks():
	var x = randi_range(-1700 , -1400)
	var attempts = 0
	while abs(x - position.x)<150 and attempts < 100:
		x = randi_range(-1700 , -1400)
		attempts += 1
	is_teleporting = true
	animated_sprite.play("teleport")
	await get_tree().process_frame  # Allow a frame to pass so the animation starts
	await animated_sprite.animation_finished  
	position.x = x
	animated_sprite.play("teleport")
	await get_tree().process_frame  # Allow a frame to pass so the animation starts
	await animated_sprite.animation_finished
	is_teleporting = false
	teleport =0
		#Spawn orbiting balls
	animated_sprite.play("default")
	for i in range(4):
		var ball = ball_scene.instantiate()
		add_child(ball)  # Attach to the boss node
		orbit_balls.append(ball)

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
