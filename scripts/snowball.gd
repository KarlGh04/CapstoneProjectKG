extends Area2D

const SPEED := 200.0

#SNOWBALL MOVEMENT
func _process(delta):
	position.x -= SPEED * delta

#HIT PLAYER
func _on_body_entered(body):
	if body.is_in_group("player"):
		body.apply_knockback(250, -1)
		queue_free()
