extends Node

@onready var checkpoint_label = $GUI/checkpoint

func _ready():
	show_checkpoint_message()

#HIDE CHECKPOINT MESSAGE
func show_checkpoint_message():
	checkpoint_label.visible = true
	await get_tree().create_timer(3.0).timeout  
	checkpoint_label.visible = false
