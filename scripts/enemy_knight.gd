extends CharacterBody2D
#CONSTS
const SPEED = 40
const ROLL_SPEED = 100
const ROLL_DISTANCE = 100 
const GRAVITY = 500.0
const ROLL_KNOCKBACK_WINDOW = 1.0  # seconds during roll when knockback is active
#VARS
var direction = 1  # Starting direction (1 = right, -1 = left)
var is_rolling = false
var is_on_cooldown = false
var knockback_time = 0.0
var knockback_duration = 0.2
var health = 6
var knockback = 0
var dead = false
var roll_time = 0.0
var active = false
var is_flashing = false
var flash_duration = 0.1  
var flash_timer = 0.0
#ONREADY
@onready var ray_cast_right = $RayCastRight
@onready var ray_cast_left = $RayCastLeft
@onready var animated_sprite = $AnimatedSprite2D
@onready var roll_cooldown_timer = $RollCooldownTimer
@onready var player = get_node("../Player")
@onready var sfx_death: AudioStreamPlayer = $SFX_DEATH
@onready var sfx_hit: AudioStreamPlayer = $SFX_HIT

#PHYSICS
func _physics_process(delta):
	if not player or not player.is_inside_tree():
		return

	var distance_to_player = global_position.distance_to(player.global_position)

	if not active and distance_to_player <= 500:
		active = true
		print("Enemy knight activated!")

	if not active or dead:
		return
	
	# Handle hit flash effect
	if is_flashing:
		flash_timer -= delta
		if flash_timer <= 0:
			is_flashing = false
			animated_sprite.modulate = Color(1, 1, 1) 
	
	if dead:
		$CollisionShape2D.disabled = true
		velocity = Vector2.ZERO
		move_and_slide()
		return

	# Apply gravity
	velocity.y += GRAVITY * delta

	if knockback_time > 0:
		knockback_time -= delta
		move_and_slide()
		return

	# Rolling behavior
	if distance_to_player < ROLL_DISTANCE and not is_rolling and not is_on_cooldown:
		start_roll()

	if is_rolling:
		roll_time += delta
		velocity.x = direction * ROLL_SPEED
		move_and_slide()

		# Check for player collision DURING roll
		if roll_time <= ROLL_KNOCKBACK_WINDOW:
			for i in get_slide_collision_count():
				var collision = get_slide_collision(i)
				if collision.get_collider() == player:
					var knockback_dir = sign(player.global_position.x - global_position.x)
					player.apply_knockback(300, knockback_dir)
		return

	# Regular patrol behavior
	handle_wall_collision()
	animated_sprite.play("default")
	velocity.x = direction * SPEED

	move_and_slide()

#ATTACK
func start_roll():
	is_rolling = true
	is_on_cooldown = true
	roll_time = 0.0  # start counting the roll duration
	animated_sprite.play("roll")
	direction = sign(player.global_position.x - global_position.x)
	animated_sprite.flip_h = direction < 0
	roll_cooldown_timer.start()

#WALL COLLISION
func handle_wall_collision():
	# Using raycasts (make sure they're properly set up in the scene)
	if ray_cast_right.is_colliding() and direction == 1:
		direction = -1
		animated_sprite.flip_h = true
	elif ray_cast_left.is_colliding() and direction == -1:
		direction = 1
		animated_sprite.flip_h = false

#STOP ROLL
func _on_roll_cooldown_timer_timeout() -> void:
	is_rolling = false
	is_on_cooldown = false
	if animated_sprite.flip_h == false:
		direction =1;
	else:
		direction = -1;
	animated_sprite.play("default")
	

func _on_animated_sprite_2d_animation_finished() -> void:
	direction=0 # Replace with function body.

#ON HIT
func apply_knockback(amount: float, direction: int) -> void:
	knockback+=1
	# Start the hit flash effect
	is_flashing = true
	flash_timer = flash_duration
	animated_sprite.modulate = Color(10, 10, 10)  # Bright white
	if knockback==4:
		knockback=0
		velocity.x = direction * amount
		knockback_time = knockback_duration
	health-=1
	sfx_hit.play()
	#DEATH
	if health==0:
		sfx_death.play()
		animated_sprite.modulate = Color(1, 1, 1)  # Reset to normal color
		$CollisionShape2D.disabled=true
		set_collision_mask_value(1, false)
		set_collision_layer_value(2,false)
		collision_mask
		animated_sprite.play("death")
		dead = true
		is_rolling = false
		is_on_cooldown = false
		roll_cooldown_timer.stop()
		
		#mandatory fight in level 2-1
		var level = get_tree().get_root().get_node_or_null("snow_1")
		if level and level.has_method("report_enemy_death"):
			level.report_enemy_death()
