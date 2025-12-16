extends CharacterBody2D

#CONSTANTS & SETTINGS
const GRAVITY = 500.0
const FLASH_DURATION = 0.1
const RUN_SPEED = 140.0
const DAMAGE_FLASH_COLOR = Color(10, 10, 10)
const NORMAL_COLOR = Color(1, 1, 1)

# Arena bounds
const ARENA_LEFT = -838
const ARENA_RIGHT = -300
const ARENA_TOP = -150
const ARENA_BOTTOM = 73

const AIR_HOVER_Y = -50 
const MOVE3_DURATION = 7.0    


#VARIABLES
var active = false
var dead = false
var doing_move = false
var is_flashing = false
var flash_timer = 0.0
var loop_start = 0.0  
var loop_end = 72 
var health = 30


#SIGNALS
signal boss_activated
signal boss_died


#ONREADY NODES & PRELOADS
@onready var anim = $AnimatedSprite2D
@onready var sword_collision: Area2D = $swordCollision
var sword_active = false   # true during move3
@onready var player = get_node("../Player")
@onready var progress_bar = $UI/ProgressBar
@onready var death_message = $UI/Label
@onready var attack_timer: Timer = $AttackTimer
@onready var run_timer: Timer = $RunTimer
@onready var music_player: AudioStreamPlayer = $AudioStreamPlayer
@onready var sfx_special: AudioStreamPlayer = $SFX_SPECIAL
@onready var sfx_lightning: AudioStreamPlayer = $"SFX_LIGHTNING"
@onready var sfx_attack: AudioStreamPlayer = $SFX_ATTACK
@onready var sfx_hit: AudioStreamPlayer = $SFX_HIT
@onready var sfx_death: AudioStreamPlayer = $SFX_DEATH

# Lightning scenes
var hLightning = preload("res://scenes/hLightning.tscn")
var vLightning = preload("res://scenes/vLightning.tscn")


#READY
func _ready():
	progress_bar.max_value = health
	progress_bar.value = health

	attack_timer.wait_time = 1.0
	attack_timer.one_shot = false
	attack_timer.autostart = false

	run_timer.one_shot = true

#PHYSICS
func _physics_process(delta):
	if not active:
		return
	
	# Flash hit effect
	if is_flashing:
		flash_timer -= delta
		if flash_timer <= 0:
			is_flashing = false
			anim.modulate = NORMAL_COLOR

	if dead:
		velocity.y += GRAVITY * delta
		move_and_slide()
		return

	# No movement unless doing move 3
	move_and_slide()


#ACTIVATION (ENTER AREA2D)
func activate():
	if not active:
		active = true
		emit_signal("boss_activated")
		print("Samurai boss activated!")

		# Enable arena limits
		$"../bossArea1Limits/CollisionShape2D".set_deferred("disabled", false)
		$"../bossArea1Limits/CollisionShape2D2".set_deferred("disabled", false)
		start_boss_music()
		attack_timer.start()


#DAMAGE
func apply_knockback(amount: float, direction: int) -> void:
	if dead: return
	
	health -= 1
	progress_bar.value = health
	sfx_hit.play()
	# Flash effect
	is_flashing = true
	flash_timer = FLASH_DURATION
	anim.modulate = DAMAGE_FLASH_COLOR

	if health <= 0:
		die()


#DEATH
func die():
	dead = true
	collision_layer = 0
	collision_mask = 0
	sfx_death.play()
	
	emit_signal("boss_died")
	# Stop the boss music
	if music_player and music_player.playing:
		music_player.stop()
	await get_tree().create_timer(1.0).timeout
	progress_bar.visible = false

	death_message.text = "VICTORY ACHIEVED"
	death_message.visible = true
	await get_tree().create_timer(1.0).timeout
	death_message.visible = false


#ATTACK CYCLE (RANDOM MOVE)
func _on_AttackTimer_timeout():
	if dead or not active or doing_move:
		return
	
	doing_move = true
	
	var move = randi() % 3
	match move:
		0: await perform_move_1()
		1: await perform_move_2()
		2: await perform_move_3()

	doing_move = false


# MOVE 1
# Teleport corner → hold 3s → lightning → teleport other side →
# attack 3s → lightning
func perform_move_1() -> void:
	var side = randi() % 2

	var start_x
	if side == 0:
		start_x = ARENA_LEFT
	else:
		start_x = ARENA_RIGHT

	var end_x
	if side == 0:
		end_x = ARENA_RIGHT
	else:
		end_x = ARENA_LEFT

	var start_pos = Vector2(start_x, ARENA_BOTTOM)
	var end_pos = Vector2(end_x, ARENA_BOTTOM)

	# TELEPORT START
	sfx_special.play()
	global_position = start_pos
	var dir = sign(player.global_position.x - global_position.x)
	anim.flip_h = (dir<0)
	if dir < 0:
		sword_collision.scale.x = -1
	else:
		sword_collision.scale.x = 1
	anim.play("hold")
	await get_tree().create_timer(2.6).timeout

	# SPAWN LIGHTNING CENTER
	spawn_h_lightning()

	# TELEPORT END
	global_position = end_pos
	anim.play("attack")
	await get_tree().create_timer(3.0).timeout

	# SPAWN LIGHTNING CENTER
	spawn_h_lightning()

# MOVE 2
# Boss floats in air → spawns two vertical lightnings each second
# from edges → toward center until covered
func perform_move_2() -> void:
	# TELEPORT TO AIR AT RANDOM X
	var x = randf_range(ARENA_LEFT, ARENA_RIGHT)
	global_position = Vector2(x, AIR_HOVER_Y)
	anim.play("default")

	var steps = 6  
	for step in range(steps + 1):
		play_lightning_sfx()
		spawn_v_lightnings(step, steps)
		await get_tree().create_timer(1.0).timeout


# MOVE 3
# Run toward player for 7 seconds, slashing if close
func perform_move_3() -> void:
	run_timer.start(MOVE3_DURATION)
	anim.play("run")

	while run_timer.time_left > 0 and not dead:
		if not player or not player.is_inside_tree():
			break

		var dir = sign(player.global_position.x - global_position.x)
		anim.flip_h = (dir < 0)
		if dir < 0:
			sword_collision.scale.x = -1
		else:
			sword_collision.scale.x = 1

		velocity.x = dir * RUN_SPEED
		velocity.y += GRAVITY * get_physics_process_delta_time()

		# Slash if close
		if global_position.distance_to(player.global_position) < 70:
			sword_active = true
			sword_collision.monitoring = true
			sword_collision.monitorable = true
			anim.play("attack")
			sfx_attack.play()
			await anim.animation_finished
			sword_active = false
			sword_collision.monitoring = false
			sword_collision.monitorable = false
			await get_tree().create_timer(1.0).timeout
			anim.play("run")

		move_and_slide()
		await get_tree().process_frame

	velocity = Vector2.ZERO
	anim.play("default")

#LIGHTNING SPAWN HELPERS
func spawn_h_lightning():
	var center_pos = Vector2(
		(ARENA_LEFT + ARENA_RIGHT) / 2,
		ARENA_BOTTOM
	)
	var l = hLightning.instantiate()
	get_parent().add_child(l)
	l.global_position = center_pos

func spawn_v_lightnings(step, max_steps):
	var center_x = (ARENA_LEFT + ARENA_RIGHT) / 2
	var ratio = float(step) / max_steps

	var x1 = lerp(ARENA_LEFT, center_x, ratio)
	var x2 = lerp(ARENA_RIGHT, center_x, ratio)

	var pos_y = (ARENA_TOP + ARENA_BOTTOM) / 2

	var v1 = vLightning.instantiate()
	var v2 = vLightning.instantiate()

	get_parent().add_child(v1)
	get_parent().add_child(v2)

	v1.global_position = Vector2(x1, pos_y)
	v2.global_position = Vector2(x2, pos_y)


func _on_sword_collision_body_entered(body: Node2D) -> void:
	if sword_active and body.is_in_group("player"):
		body.apply_knockback(300, sign(body.global_position.x - global_position.x))
		
#MUSIC/SFX
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
			
func play_lightning_sfx():
	var sfx = $SFX_LIGHTNING.duplicate()
	sfx.pitch_scale = randf_range(0.75, 1.25)
	add_child(sfx)
	sfx.play()
	# Queue free after the sound ends
	sfx.finished.connect(func(): sfx.queue_free())
	
