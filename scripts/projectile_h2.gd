extends CharacterBody2D

var SPEED = 300.0
var player

@onready var player1 = get_node_or_null("/root/level1/Player")  
@onready var player2 = get_node_or_null("/root/level_3/Player")
@onready var player3 = get_node_or_null("/root/bedran_1/Player")
@onready var player4 = get_node_or_null("/root/bedran_2/Player")

#LEFT TO RIGHT SOWRDS
func _physics_process(delta):
	SPEED = randi_range(200, 500)
	velocity = Vector2(-1*SPEED, 0)
	move_and_slide()

	if player1!=null:
		player=player1
	elif player2!=null:
		player=player2
	elif player3 != null:
		player=player3
	else: player = player4
	
	# Detect collision with player
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		if collision.get_collider() == player:
			var knockback_dir = sign(player.global_position.x - global_position.x)
			player.apply_knockback(300, knockback_dir)
			queue_free()  

	# Auto-destroy if too far down
	if position.x < -2700:
		queue_free()
