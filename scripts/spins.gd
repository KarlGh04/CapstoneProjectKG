extends Area2D

@onready var player2 = get_node_or_null("/root/level_3/Player")

func _ready():
	connect("body_entered", self._on_body_entered)
#DAMAGE PLAYER IF COLLSION WITH SPINNING SWORDS
func _on_body_entered(body):
	if body == player2:
		var knockback_dir = sign(player2.global_position.x - global_position.x)
		player2.apply_knockback(300, knockback_dir)
