extends CanvasLayer
var max_health
var health

#READY
func _ready() -> void:
	if SaveManager.get_easy_mode():
		max_health = 5
	else:
		max_health = 3
	
	health = max_health
	$health.text= "x" + str(health)

func _process(delta: float) -> void:
	pass
