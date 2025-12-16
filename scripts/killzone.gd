extends Area2D

@onready var timer = $Timer
var wait_for_restart := false
var restart_timer := 0.0

func _on_body_entered(body: Node2D) -> void:
	var player = $"../Player"
	player.trigger_killzone()
	

func activate_killzone():
	if Engine.time_scale < 1.0:  # Prevent triggering multiple times
		return
	Engine.time_scale = 0.5
	timer.start()
	# Show "YOU DIED" 
	var death_label = get_node("../GUI/DeathLabel") 
	death_label.visible = true
	
func _on_timer_timeout():
	Engine.time_scale = 1.0
	wait_for_restart = true
	restart_timer = 0.0

#RESTART LEVEL
func _process(delta):
	if wait_for_restart:
		restart_timer += delta
		if Input.is_action_just_pressed("ui_accept") or restart_timer >= 3.0:
			get_tree().reload_current_scene()
