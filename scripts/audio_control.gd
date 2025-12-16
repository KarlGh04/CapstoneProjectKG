extends HSlider

@export var audio_bus_name: String
var audio_bus_id

func _ready() -> void:
	audio_bus_id = AudioServer.get_bus_index(audio_bus_name)
	
	# Set initial value (will be updated again after settings load)
	var current_volume_db = AudioServer.get_bus_volume_db(audio_bus_id)
	value = db_to_linear(current_volume_db)
	
	value_changed.connect(_on_value_changed)

# Public method to update the slider from current audio bus volume
func update_volume():
	var current_volume_db = AudioServer.get_bus_volume_db(audio_bus_id)
	value = db_to_linear(current_volume_db)

func _on_value_changed(value: float) -> void:
	var db = linear_to_db(value)
	AudioServer.set_bus_volume_db(audio_bus_id, db)
	SaveManager.save_settings()
