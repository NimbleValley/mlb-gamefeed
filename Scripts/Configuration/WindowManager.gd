extends Node2D


func _ready():
	pass;

func open_gamefeed(scene_path: String):
	# Load and change to new scene
	get_tree().change_scene_to_file(scene_path)

	# Get screen size and window size
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP, true)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
	DisplayServer.window_set_size(Vector2i(400 , 150))

	var screen_index = DisplayServer.window_get_current_screen()
	var screen_size = DisplayServer.screen_get_size(screen_index)
	var screen_position = DisplayServer.screen_get_position(screen_index)
	var window_size = DisplayServer.window_get_size()

	var target_position = screen_position + screen_size - window_size - Vector2i(0, 40)  # margin from corner
	DisplayServer.window_set_position(target_position)
