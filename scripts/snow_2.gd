extends Node2D

@onready var snowball_scene = preload("res://scenes/snowball.tscn")
@onready var spawn_position = $SnowballSpawnPoint
#COUUNTERS FOR DEAD AND ALIVE ENEMIES
var total_enemies := 3
var dead_enemies := 0

#CHECK DEAD ENEMIES
func report_enemy_death():
	dead_enemies += 1
	print("Enemy died. Total dead:", dead_enemies)

#SPAWN SNOWBALLS
func _on_snow_ball_timer_timeout() -> void:
	var snowball = snowball_scene.instantiate()
	snowball.global_position = spawn_position.global_position
	add_child(snowball)
