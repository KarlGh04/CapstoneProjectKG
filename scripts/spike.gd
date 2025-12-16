extends Area2D

@onready var anim = $AnimatedSprite2D
#SPAWN SPIKES THE DELETE
func _ready():
	anim.play("spike_up")  
	await get_tree().create_timer(2.0).timeout
	queue_free()

#DAMAGE PLAYER
func _on_body_entered(body):
	if body.is_in_group("player"):
		body.apply_knockback(300, sign(body.global_position.x - global_position.x))
