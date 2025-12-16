extends CharacterBody2D
#CONSTS
const SPEED = 40
const JUMP_FORCE = -200 #height
const HORIZONTAL_JUMP_SPEED = 80
const GRAVITY = 500.0
const JUMP_KNOCKBACK_WINDOW = 1.0 
const JUMP_DISTANCE = 300
#VARS
var direction = 1
var is_jumping = false
var is_on_cooldown = false
var knockback_time = 0.0
var knockback_duration = 0.2
var health = 6
var knockback = 0
var dead = false
var jump_time = 0.0
var active = false
var is_flashing = false
var flash_duration = 0.1
var flash_timer = 0.0
#ONREADY
@onready var ray_cast_right = $RayCastRight
@onready var ray_cast_left = $RayCastLeft
@onready var animated_sprite = $AnimatedSprite2D
@onready var jump_cooldown_timer = $JumpCooldownTimer
@onready var player = get_node("../Player")
@onready var dagger_right = preload("res://scenes/projectile_h.tscn")
@onready var dagger_left = preload("res://scenes/projectile_horizontal_2.tscn")
@onready var sfx_death: AudioStreamPlayer = $SFX_DEATH
@onready var sfx_hit: AudioStreamPlayer = $SFX_HIT

#PHYSICS
func _physics_process(delta):
	if not player or not player.is_inside_tree():
		return

	var distance_to_player = global_position.distance_to(player.global_position)
	
	if not active and distance_to_player <= 500:
		active = true
		print("Enemy jumper activated!")

	if not active or dead:
		return

	# Hit flash
	if is_flashing:
		flash_timer -= delta
		if flash_timer <= 0:
			is_flashing = false
			animated_sprite.modulate = Color(1, 1, 1)

	if dead:
		$CollisionShape2D.disabled = true
		velocity.y += GRAVITY * delta  # Let gravity pull it down
		move_and_slide()
		return

	# Gravity
	velocity.y += GRAVITY * delta

	if knockback_time > 0:
		knockback_time -= delta
		move_and_slide()
		return

	# Jump behavior
	if not is_jumping and not is_on_cooldown and distance_to_player < JUMP_DISTANCE:
		start_jump()

	if is_jumping:
		jump_time += delta
		move_and_slide()

		# Collision check during jump
		if jump_time <= JUMP_KNOCKBACK_WINDOW:
			for i in get_slide_collision_count():
				var collision = get_slide_collision(i)
				if collision.get_collider() == player:
					var knockback_dir = sign(player.global_position.x - global_position.x)
					player.apply_knockback(300, knockback_dir)
		return

	# Normal movement / patrol
	handle_wall_collision()
	animated_sprite.play("default")
	velocity.x = direction * SPEED
	move_and_slide()

#JUMP ATTACK
func start_jump():
	throw_dagger()
	is_jumping = true
	is_on_cooldown = true
	jump_time = 0.0
	direction = sign(player.global_position.x - global_position.x)
	velocity.x = direction * HORIZONTAL_JUMP_SPEED
	velocity.y = JUMP_FORCE
	animated_sprite.flip_h = direction < 0
	animated_sprite.play("jump")
	jump_cooldown_timer.start()

#THROW ATTACK
func throw_dagger():
	var dagger
	if direction == 1:
		dagger = dagger_right.instantiate()
	else:
		dagger = dagger_left.instantiate()
	var spawn_offset = Vector2(20 * direction, -5)
	dagger.global_position = global_position + spawn_offset
	get_parent().add_child(dagger)

#WALK AFTER JUMP
func _on_jump_cooldown_timer_timeout():
	is_jumping = false
	is_on_cooldown = false
	animated_sprite.play("default")

#ON HIT
func apply_knockback(amount: float, direction: int) -> void:
	knockback += 1
	is_flashing = true
	flash_timer = flash_duration
	animated_sprite.modulate = Color(10, 10, 10)
	if knockback == 4:
		knockback = 0
		velocity.x = direction * amount
		knockback_time = knockback_duration
	health -= 1
	sfx_hit.play()
	if health == 0:
		sfx_death.play()
		die()

#DEATH
func die():
	animated_sprite.modulate = Color(1, 1, 1)
	$CollisionShape2D.disabled = true
	set_collision_mask_value(1, false)
	set_collision_layer_value(2, false)
	collision_layer = 0
	collision_mask = 0
	dead = true
	is_jumping = false
	is_on_cooldown = false
	jump_cooldown_timer.stop()
	var tween = create_tween()
	tween.tween_property($AnimatedSprite2D, "modulate:a", 0.0, 1.0)

#WALL COLLISION
func handle_wall_collision():
	# Using raycasts 
	if ray_cast_right.is_colliding() and direction == 1:
		direction = -1
		animated_sprite.flip_h = true
	elif ray_cast_left.is_colliding() and direction == -1:
		direction = 1
		animated_sprite.flip_h = false
