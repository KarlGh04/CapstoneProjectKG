extends Node
#COUNTER FOR ENEMIES(DEAD AND ALIVE)
var total_enemies := 4
var dead_enemies := 0
@onready var sfx_ambiance: AudioStreamPlayer = $SFX_AMBIANCE

#CHECK DEAD ENEMIES
func report_enemy_death():
	dead_enemies += 1
	print("Enemy died. Total dead:", dead_enemies)
