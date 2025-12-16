extends Area2D

#ENTER AREA2D TO JUMP TO NEXT LEVEL
func _on_body_entered(body: Node2D) -> void:
	var scene_path = get_tree().current_scene.scene_file_path
	var filename = scene_path.get_file().get_basename()
	if !body.is_in_group("enemies"):
		if(filename=="level_2"):
			SaveManager.complete_level("1-2")
			get_tree().change_scene_to_file("res://scenes/level_3.tscn")
		elif(filename=="bedran_1"):
			SaveManager.complete_level("3-1")
			get_tree().change_scene_to_file("res://scenes/bedran_2.tscn")
		elif(filename=="bedran_2"):
			SaveManager.complete_level("3-2")
			get_tree().change_scene_to_file("res://scenes/bedran_3.tscn")
