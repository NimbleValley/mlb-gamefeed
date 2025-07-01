extends HBoxContainer


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_close_button_pressed():
	# Reset any custom window settings (optional)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP, false)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)

	# Resize window back to normal if needed
	DisplayServer.window_set_size(Vector2i(800, 500))  # or your default size
	var screen_size = DisplayServer.screen_get_size()
	var window_size = Vector2i(800, 500)
	var centered_position = (screen_size - window_size) / 4
	DisplayServer.window_set_position(centered_position)

	# Change scene to home screen
	get_tree().change_scene_to_file("res://Scenes/Configuration.tscn")
	DisplayServer.window_set_position(centered_position)


func _on_minimize_button_pressed():
	get_tree().root.mode = Window.MODE_MINIMIZED


func _on_external_button_pressed():
	_open_gameday(Global.home_team_name, Global.away_team_name, Global.game_pk);

func _open_gameday(home_team_name: String, away_team_name: String, game_pk: int):
	# Get today's date
	var date = Time.get_datetime_dict_from_system()
	var year = date["year"]
	var month = "%02d" % date["month"]
	var day = "%02d" % date["day"]

	# Construct URL
	var url = "https://www.mlb.com/gameday/%s-vs-%s/%d/%s/%s/%d/live" % [
		away_team_name, home_team_name, year, month, day, game_pk
	]
	
	url = url.replace("diamondbacks", "d-backs")

	# Open in default browser
	OS.shell_open(url)
