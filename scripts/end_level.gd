extends Area2D

#SEND THE PLAYER TO LEVEL 2-2
func _on_body_entered(body: Node2D) -> void:
	if not body.name == "Player":
		return
	
	var level = get_tree().get_root().get_node("snow_1")
	if level.dead_enemies >= level.total_enemies:
		SaveManager.complete_level("2-1")
		get_tree().change_scene_to_file("res://scenes/snow_2.tscn")
	else:
		print("Not all enemies are dead yet.")
