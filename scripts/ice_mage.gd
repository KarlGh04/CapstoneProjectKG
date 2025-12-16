extends CharacterBody2D
#CONSTS
const SPEED = 40
const GRAVITY = 500.0
#VARS
var direction = 1  # Starting direction (1 = right, -1 = left)
var knockback_time = 0.0
var knockback_duration = 0.2
var health = 25
var dead = false
var active = false
var is_flashing = false
var flash_duration = 0.1  
var flash_timer = 0.0
var spike_scene = preload("res://scenes/spike.tscn")
var slash_scene = preload("res://scenes/ice_slash.tscn")
var hammer_scene = preload("res://scenes/hammer.tscn")

#ATTACK PATTERNS/POSITIONS/ANIMATIONS
var attack_positions = [
	{ "x": 1967, "y": 90, "animation": "default", "face": 1 },    # Ground left
	{ "x": 2490, "y": 90, "animation": "default", "face": -1 },   # Ground right
	{ "x": 1967, "y": 10, "animation": "fly", "face": 1 },        # Midair left
	{ "x": 2490, "y": 10, "animation": "fly", "face": -1 },       # Midair right
	{ "x": 1967, "y": -55, "animation": "fly", "face": 1 },       # High air left
	{ "x": 2490, "y": -55, "animation": "fly", "face": -1 }       # High air right
]

#SIGNALS
signal boss_activated
signal boss_died
#ONREADY
@onready var ray_cast_right = $RayCastRight
@onready var ray_cast_left = $RayCastLeft
@onready var animated_sprite = $AnimatedSprite2D
@onready var player = get_node("../Player")
@onready var progress_bar = $UI/ProgressBar
@onready var deathMessage = $UI/Label
@onready var attack_timer = $AttackTimer
@onready var sfx_hammer: AudioStreamPlayer = $SFX_HAMMER
@onready var sfx_spikes: AudioStreamPlayer = $SFX_SPIKES
@onready var sfx_slice: AudioStreamPlayer = $SFX_SLICE
@onready var sfx_death: AudioStreamPlayer = $SFX_DEATH
@onready var sfx_hit: AudioStreamPlayer = $SFX_HIT

#READY
func _ready():
	progress_bar.max_value = health
	progress_bar.value = health
	
	attack_timer.wait_time = 3.0
	attack_timer.autostart = false
	attack_timer.one_shot = false
	attack_timer.start()

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

	# Handle knockback
	if knockback_time > 0:
		knockback_time -= delta
		move_and_slide()
		return
	
	if not player or not player.is_inside_tree():
		return

	var distance_to_player = global_position.distance_to(player.global_position)

	move_and_slide()

#ACTIVATE
func activate():
	if not active:
		active = true
		emit_signal("boss_activated")
		print("Boss activated!")
		$"../bossArea1Limits/CollisionShape2D".set_deferred("disabled",false)
		$"../bossArea1Limits/CollisionShape2D2".set_deferred("disabled",false)


func _on_animated_sprite_2d_animation_finished() -> void:
	direction=0

#ON HIT
func apply_knockback(amount: float, direction: int) -> void:
	sfx_hit.play()
	health-=1
	progress_bar.value = health
	# Start the hit flash effect
	is_flashing = true
	flash_timer = flash_duration
	animated_sprite.modulate = Color(10, 10, 10)  # Bright white
	if health==0:
		sfx_death.play()
		collision_layer = 0
		collision_mask = 0
		dead = true
		#$CollisionShape2D.disabled = true
		emit_signal("boss_died")
		#hide bar
		await get_tree().create_timer(1.0).timeout
		progress_bar.visible = false
		# Show "BOSS SLAINED"
		deathMessage.text = "MAGE KILLED"
		deathMessage.visible = true
		await get_tree().create_timer(1.0).timeout
		deathMessage.visible = false

#RANDOM ATTACKS
func perform_random_attack():
	if dead or not active:
		return
	
	var choice = attack_positions[randi() % attack_positions.size()]
	global_position = Vector2(choice["x"], choice["y"])
	direction = choice["face"]
	animated_sprite.flip_h = (direction == -1)
	
	# FLY (if in air)
	if choice["animation"] == "fly":
		animated_sprite.play("fly")
		await animated_sprite.animation_finished
		
	# DEFAULT (if in ground)
	if choice["animation"] == "default":
		animated_sprite.play("default")
		await animated_sprite.animation_finished
		
	# Then attack animation
	animated_sprite.play("attack")
	# summon spikes
	if choice["y"] == 90:
		spawn_spikes(choice["x"])
	elif choice["y"] == -55:
		spawn_slash(choice["x"])
	else:
		spawn_hammer(choice["x"])
	await animated_sprite.animation_finished
	
#SPAWN SPIKES
func spawn_spikes(x_pos: float):
	#2055 2425
	sfx_spikes.play()
	var s_pos
	if (x_pos == 1967): s_pos = 2425
	else: s_pos= 2030
	var spike_instance = spike_scene.instantiate()
	var spike_instance2 = spike_scene.instantiate()
	get_parent().add_child(spike_instance)
	get_parent().add_child(spike_instance2)
	spike_instance.global_position = Vector2(s_pos, 70)
	spike_instance2.global_position = Vector2(2240, 70)

#SPAWN SLASH
func spawn_slash(x_pos: float):
	#2055 2425
	sfx_slice.play()
	var s_pos
	if (x_pos == 1967): s_pos = 2055
	else: s_pos= 2425
	var slash_instance = slash_scene.instantiate()
	get_parent().add_child(slash_instance)
	slash_instance.global_position = Vector2(s_pos, 10)
	if x_pos >= 2490:
		slash_instance.rotation = deg_to_rad(180)

#SPAWN HAMMER
func spawn_hammer(x_pos: float):
	#2055 2425
	sfx_hammer.play(1.0)
	var s_pos
	if (x_pos == 1967): s_pos = 2100
	else: s_pos= 2425
	var hammer_instance = hammer_scene.instantiate()
	get_parent().add_child(hammer_instance)
	hammer_instance.global_position = Vector2(s_pos, 10)
	if x_pos >= 2400:
		hammer_instance.get_node("AnimatedSprite2D").flip_h = true

#PERFORM NEXT ATTACK
func _on_attack_timer_timeout() -> void:
	perform_random_attack()
