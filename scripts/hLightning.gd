extends Area2D

@onready var anim = $AnimatedSprite2D

#ANIMATION THEN DELETE
func _ready():
	anim.play("attack")  
	await get_tree().create_timer(0.2).timeout
	queue_free()

#DAMAGE THE PLAYER
func _on_body_entered(body):
	if body.is_in_group("player"):
		body.apply_knockback(300, sign(body.global_position.x - global_position.x))
