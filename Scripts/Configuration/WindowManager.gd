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

	var screen_size = DisplayServer.screen_get_size()
	var window_size = DisplayServer.window_get_size()

	# Bottom-right corner = screen size - window size
	var new_position = screen_size - window_size

	# Optional: Add padding from edge
	new_position -= Vector2i(0, 40)

	# Move the window
	DisplayServer.window_set_position(new_position)
