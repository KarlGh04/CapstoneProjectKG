extends Node
#SAVE FILE
const SETTINGS_PATH = "user://game_settings.cfg"

#SAVE
func save_settings():
	var config = ConfigFile.new()
	
	# Save audio settings
	config.set_value("audio", "master_volume", get_bus_volume("Master"))
	config.set_value("audio", "music_volume", get_bus_volume("Music")) 
	config.set_value("audio", "sfx_volume", get_bus_volume("SFX"))
	
	# Save display settings
	config.set_value("display", "fullscreen", DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN)
	
	# Save game difficulty
	config.set_value("game", "easy_mode", get_easy_mode())
	
	# Save level progression
	config.set_value("progress", "unlocked_levels", get_unlocked_levels())
	config.set_value("progress", "completed_levels", get_completed_levels())
	
	#check if file saved
	var error = config.save(SETTINGS_PATH)
	if error == OK:
		print("Settings saved!")
	else:
		print("Error saving settings: ", error)

#LOAD
func load_settings():
	var config = ConfigFile.new()
	var error = config.load(SETTINGS_PATH)
	
	#check if load
	if error != OK:
		print("No saved settings found, using defaults")
		return false
	
	# Load and apply audio settings
	set_bus_volume("Master", config.get_value("audio", "master_volume", 1.0))
	set_bus_volume("Music", config.get_value("audio", "music_volume", 1.0))
	set_bus_volume("SFX", config.get_value("audio", "sfx_volume", 1.0))
	
	# Load and apply display settings
	var fullscreen = config.get_value("display", "fullscreen", false)
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen 
		else DisplayServer.WINDOW_MODE_WINDOWED
	)
	
	# Load game difficulty
	var easy_mode = config.get_value("game", "easy_mode", false)
	set_easy_mode(easy_mode)
	
	# Load level progression
	set_unlocked_levels(config.get_value("progress", "unlocked_levels", ["1-1"]))
	set_completed_levels(config.get_value("progress", "completed_levels", []))
	
	print("Settings loaded successfully!")
	return true

# Easy mode getter/setter
func get_easy_mode() -> bool:
	return ProjectSettings.get_setting("game/easy_mode", false)

func set_easy_mode(enabled: bool):
	ProjectSettings.set_setting("game/easy_mode", enabled)

# Level progression getters/setters
func get_unlocked_levels() -> Array:
	return ProjectSettings.get_setting("game/unlocked_levels", ["1-1"])

func set_unlocked_levels(levels: Array):
	ProjectSettings.set_setting("game/unlocked_levels", levels)

func get_completed_levels() -> Array:
	return ProjectSettings.get_setting("game/completed_levels", [])

func set_completed_levels(levels: Array):
	ProjectSettings.set_setting("game/completed_levels", levels)

# Level progression management
func unlock_level(level_name: String):
	var unlocked = get_unlocked_levels()
	if not level_name in unlocked:
		unlocked.append(level_name)
		set_unlocked_levels(unlocked)
		save_settings()

#COMPLETE A LEVEL
func complete_level(level_name: String):
	var completed = get_completed_levels()
	if not level_name in completed:
		completed.append(level_name)
		set_completed_levels(completed)
		save_settings()
	
	# Auto-unlock next level
	unlock_next_level(level_name)

func unlock_next_level(completed_level: String):
	var level_order = ["1-1", "1-2", "1-3", "2-1", "2-2", "2-3", "3-1", "3-2", "3-3"]
	var current_index = level_order.find(completed_level)
	if current_index != -1 and current_index + 1 < level_order.size():
		var next_level = level_order[current_index + 1]
		unlock_level(next_level)

func is_level_unlocked(level_name: String) -> bool:
	return level_name in get_unlocked_levels()

func is_level_completed(level_name: String) -> bool:
	return level_name in get_completed_levels()

# get/set volume
func get_bus_volume(bus_name: String) -> float:
	var bus_index = AudioServer.get_bus_index(bus_name)
	if bus_index != -1:
		var volume_db = AudioServer.get_bus_volume_db(bus_index)
		return db_to_linear(volume_db)
	return 1.0

func set_bus_volume(bus_name: String, volume_linear: float):
	var bus_index = AudioServer.get_bus_index(bus_name)
	if bus_index != -1:
		var volume_db = linear_to_db(volume_linear)
		AudioServer.set_bus_volume_db(bus_index, volume_db)

# reset progression
func reset_progression():
	set_unlocked_levels(["1-1"])
	set_completed_levels([])
	save_settings()
	print("Level progression reset")
