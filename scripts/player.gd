extends CharacterBody2D
#CONSTS
const SPEED = 130.0
const RUN_SPEED = 300.0
const ATTACK_DELAY := 0.41
#ONREADY
@onready var animated_sprite = $AnimatedSprite2D
@onready var attack_area = $AttackArea
@onready var abilty_1_timer: Timer = $abilty1Timer
@onready var ability_bar: ProgressBar = $"../GUI/abilityBar"
@onready var abilty_2_timer: Timer = $abilty2Timer
@onready var ability_bar2: ProgressBar = $"../GUI/abilityBar2"
#VARS
var JUMP_VELOCITY = -300.0
var attacking = false
var knockback_time = 0.0
var knockback_duration = 0.2  
var max_health = 3
var health = 3
var is_invincible = false
var invincibility_time = 1.5 
var invincibility_timer = 0.0
var can_move := true
var fading_out = false
var fade_speed = 1.0
var coyote_time = 0.1
var coyote_timer = 0.0
var jump_buffer_time = 0.1
var jump_buffer_timer = 0.0
var last_dir = 1
var attack_cooldown := 0.0
var canTeleport = true
var canTeleport2 = true
var pause_menu_scene = preload("res://scenes/pause_menu.tscn")
var is_paused = false
var can_pause: bool = true
#SFX
@onready var sfx_slash_1: AudioStreamPlayer = $SFX_SLASH1
@onready var sfx_slash_2: AudioStreamPlayer = $SFX_SLASH2
@onready var sfx_death: AudioStreamPlayer = $SFX_DEATH
@onready var sfx_teleport: AudioStreamPlayer = $SFX_TELEPORT
#steps SFX
@onready var sfx_step: AudioStreamPlayer = $SFX_STEP
var step_sounds = [
	preload("res://musics/sfx/Run_1.wav"),
	preload("res://musics/sfx/Run_2.wav"),
	preload("res://musics/sfx/Run_3.wav"),
	preload("res://musics/sfx/Run_4.wav"),
	preload("res://musics/sfx/Run_5.wav"),
	preload("res://musics/sfx/Run_6.wav"),
	preload("res://musics/sfx/Run_7.wav"),
	preload("res://musics/sfx/Run_8.wav")
]
#READY
func _ready():
	add_to_group("player")
	setup_health()
	if get_tree().current_scene.scene_file_path.ends_with("bedaran_3.tscn"):
		JUMP_VELOCITY=-500
	
func setup_health():
	# CHECK IF EASY MODE (3 OR 5)
	if SaveManager.get_easy_mode():
		max_health = 5
	else:
		max_health = 3
	
	health = max_health
	$"../GUI/health".text = "x" + str(health)
	print("Player health set to: ", health, " (Easy Mode: ", SaveManager.get_easy_mode(), ")")

#PHYSICS
func _physics_process(delta: float) -> void:
	#pause
	if can_pause and Input.is_action_just_pressed("ui_cancel") and not fading_out and health > 0:
		toggle_pause()
	if get_tree().paused:
		return 

	if fading_out:
		animated_sprite.modulate.a = max(animated_sprite.modulate.a - delta / fade_speed, 0)
		if animated_sprite.modulate.a <= 0:
			hide()
		return
	if not can_move:
		return

	# Add gravity
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Skip normal movement if in knockback
	if knockback_time > 0:
		knockback_time -= delta
		move_and_slide()
		return
	
	# Reduce attack cooldown timer
	if attack_cooldown > 0:
		attack_cooldown -= delta
	
	# Movement (before jumping)
	var direction := Input.get_axis("ui_left", "ui_right")
	#if not attacking:
	if direction > 0:
		if not attacking:
			if not sfx_step.playing and is_on_floor():
				play_random_step()
			animated_sprite.play("walk")
		animated_sprite.flip_h = false
		attack_area.scale.x = 1
		last_dir = 1
	elif direction < 0:
		if not attacking:
			if not sfx_step.playing and is_on_floor():
				play_random_step()
			animated_sprite.play("walk")
		animated_sprite.flip_h = true
		attack_area.scale.x = -1
		last_dir = -1
	else:
		if not attacking:
			animated_sprite.play("idle")
	#RUN
	var current_speed = SPEED
	if Input.is_action_pressed("run") and direction != 0:
		current_speed = RUN_SPEED
	#MOVE
	if direction:
		velocity.x = direction * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	# MOVE, THEN GET UPDATED FLOOR INFO
	move_and_slide()

	# JUMP TIMER
	if is_on_floor():
		coyote_timer = coyote_time
	else:
		coyote_timer = max(coyote_timer - delta, 0.0)
	
	if Input.is_action_just_pressed("ui_accept"):
		jump_buffer_timer = jump_buffer_time
	else:
		jump_buffer_timer = max(jump_buffer_timer - delta, 0.0)
	
	# JUMP IF:
	# ON FLOOR AND JUMP BUFFERED
	# IN COYOTE TIME
	if (is_on_floor() and jump_buffer_timer > 0) or (Input.is_action_just_pressed("ui_accept") and coyote_timer > 0):
		velocity.y = JUMP_VELOCITY
		coyote_timer = 0.0
		jump_buffer_timer = 0.0
		
	# INVINCIBILITY FLICKER
	if is_invincible:
		animated_sprite.modulate.a = 0.5 + 0.5 * sin(10 * invincibility_timer)
		invincibility_timer -= delta
		if invincibility_timer <= 0:
			is_invincible = false
			animated_sprite.modulate.a = 1

	# Attack
	if Input.is_action_just_pressed("attack") and !attacking and attack_cooldown <= 0.0 and health>0:
		animated_sprite.play("attack")
		playSlash()
		attacking = true
		attack_area.monitoring = true
		attack_cooldown = ATTACK_DELAY
	if (attacking and not animated_sprite.is_playing()) or health<=0:
		attacking = false
		attack_area.monitoring = false
		
	#ability1
	if Input.is_action_just_pressed("ability_1") && canTeleport:
		var current_scene = get_tree().current_scene
		var scene_path = current_scene.scene_file_path
	
		# Disable teleport in game , level_2 and level_3
		if scene_path.ends_with("level_2.tscn") or scene_path.ends_with("level_3.tscn") or scene_path.ends_with("game.tscn"):
			return  #don't teleport
		
		var teleport_distance = 150.0
		var destination = position + Vector2(0, -teleport_distance)
		
		# Check if destination is clear
		if is_destination_clear(destination):
			sfx_teleport.play()
			position = destination
			canTeleport = false
			abilty_1_timer.start()
			ability_bar.value = 0 
			update_ability_bar()
			
	#ability2
	if Input.is_action_just_pressed("ability_2") && canTeleport2:
		var current_scene = get_tree().current_scene
		var scene_path = current_scene.scene_file_path
	
		# Disable teleport unless in bedran location
		if scene_path.ends_with("bedran_1.tscn") or scene_path.ends_with("bedran_2.tscn") or scene_path.ends_with("bedran_3.tscn"):
			var teleport_distance2 = 75.0
			var destination2 = position + Vector2(last_dir * teleport_distance2, 0)
			
			position = destination2
			canTeleport2 = false
			abilty_2_timer.start()
			ability_bar2.value = 0 

#UPDATE ABILITIES 
func update_ability_bar():
	var tween = create_tween()
	tween.tween_method(update_bar_value, 0, 6, 6.0)

func update_bar_value(value: float):
	ability_bar.value = value
func update_bar_value2(value: float):
	ability_bar2.value = value
	
func _on_abilty_1_timer_timeout() -> void:
	canTeleport = true
	ability_bar.value = ability_bar.max_value
func _on_abilty_2_timer_timeout() -> void:
	canTeleport2 = true
	ability_bar2.value = ability_bar2.max_value

#CHECK IF CAN TELEPORT UP
func is_destination_clear(dest: Vector2) -> bool:
	var space_state = get_world_2d().direct_space_state
	# Check a small area at the destination 
	var query = PhysicsShapeQueryParameters2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(20, 35) # Small check area
	query.shape = shape
	query.transform = Transform2D(0, dest)
	query.collision_mask = 1 
	query.exclude = [self] # Exclude player
	var results = space_state.intersect_shape(query)
	return results.is_empty() # Empty == destination is clear

#ON HIT
func apply_knockback(amount: float, direction: int) -> void:
	if is_invincible:
		return
	velocity.x = direction * amount
	knockback_time = knockback_duration
	animated_sprite.play("hurt")
	# Decrease health
	if health > 0:
		health -= 1
		$"../GUI/health".text = "x" + str(health)
	# If health reaches 0, trigger killzone manually
	if health <= 0:
		trigger_killzone()  #slow time and wait for restart
		sfx_death.play()
	is_invincible = true
	invincibility_timer = invincibility_time

#HIT ENEMIES
func _on_attack_area_body_entered(body: Node2D) -> void:
	if attacking and body.is_in_group("enemies"):  # Optional group check
		var knockback_dir = sign(body.global_position.x - global_position.x)
		body.apply_knockback(300, knockback_dir)

#DIE
func trigger_killzone():
	can_move = false  # Stop inputs
	fading_out = true
	var killzone = get_node("../Killzone")  
	killzone.activate_killzone()
func reset_health():
	health= max_health
	$"../GUI/health".text = "x" + str(health)

#TOGGLE PAUSE
func toggle_pause():
	# Toggle engine pause
	get_tree().paused = !get_tree().paused
	is_paused = get_tree().paused  # Sync variable with engine state
	
	if get_tree().paused:
		# Show pause menu
		var pause_menu = pause_menu_scene.instantiate()
		get_parent().add_child(pause_menu)  # Add to parent so it's not paused
	else:
		# Remove pause menu
		var pause_menu = get_parent().get_node_or_null("PauseMenu")
		if pause_menu:
			pause_menu.queue_free()

#SFXs
func playSlash():
	var random_binary_choice = randi() % 2
	if random_binary_choice==0:
		sfx_slash_1.pitch_scale = randf_range(0.95, 1.05)
		sfx_slash_1.play()
	else:
		sfx_slash_2.pitch_scale = randf_range(0.95, 1.05)
		sfx_slash_2.play()
		
func play_random_step():
	var rand_sound = step_sounds[randi() % step_sounds.size()]
	sfx_step.stream = rand_sound
	sfx_step.play()
	
