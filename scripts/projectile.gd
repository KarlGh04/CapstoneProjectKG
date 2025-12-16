extends CharacterBody2D

var SPEED = 300.0

@onready var player = get_node_or_null("/root/level1/Player") 
@onready var player2 = get_node_or_null("/root/level_3/Player")

#UP TO DOWN SWORDS
func _physics_process(delta):
	SPEED = randi_range(100, 500)
	velocity = Vector2(0, SPEED)
	move_and_slide()

	# Detect collision with player
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		if collision.get_collider() == player:
			var knockback_dir = sign(player.global_position.x - global_position.x)
			player.apply_knockback(300, knockback_dir)
			queue_free()  
		if collision.get_collider() == player2:
			var knockback_dir = sign(player2.global_position.x - global_position.x)
			player2.apply_knockback(300, knockback_dir)
			queue_free()  
	# Auto-destroy if too far down
	if position.y > 2000:
		queue_free()
