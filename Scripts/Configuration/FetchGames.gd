extends HTTPRequest

@onready var game_list_container = $ScrollContainer/GameList
var game_button_theme: Theme = preload("res://Themes/GameOptionButtonTheme.tres")  # adjust path if needed

func fetch_games():
	var date = Time.get_date_dict_from_system()
	var year = date.year
	var month = date.month
	var day = date.day  # Adjust as needed (watch out for going below 1)

	var url = "https://statsapi.mlb.com/api/v1/schedule?sportId=1&date=%d-%02d-%02d" % [year, month, day]
	print("Fetching:", url)

	# Make the request
	request_completed.connect(_on_request_completed)
	var error = request(url)
	if error != OK:
		push_error("Request failed to start: %s" % error)

func _on_request_completed(result, response_code, headers, body):
	get_parent().loading = false;
	if response_code == 200:
		var json = JSON.parse_string(body.get_string_from_utf8())
		if json == null:
			push_error("Failed to parse JSON")
			return
		
		var tween = create_tween()

		var dates = json.get("dates", [])
		for date_entry in dates:
			var games = date_entry.get("games", [])
			for game in games:
				var away_team = game["teams"]["away"]["team"]["name"]
				var home_team = game["teams"]["home"]["team"]["name"]
				var matchup_text = "%s at %s" % [away_team, home_team]
				var game_pk = game["gamePk"]

				# Create and add button
				var button = Button.new()
				button.text = matchup_text
				button.theme = game_button_theme
				button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

				# Option 1: Use `bind()` to pass `game_pk`
				button.pressed.connect(_on_game_button_pressed.bind(game_pk, away_team, home_team))

				# Option 2 (alternative): Store gamePk as metadata (if needed elsewhere)
				# button.set_meta("game_pk", game_pk)

				game_list_container.add_child(button)
				button.modulate.a = 0.0
				tween.tween_property(button, "modulate:a", 1.0, 0.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	else:
		push_error("HTTP error: %s" % response_code)

func _on_game_button_pressed(game_pk, away_team, home_team):
	print("Selected gamePk:", game_pk, away_team, home_team)
	Global.game_pk = game_pk
	Global.away_team = away_team
	Global.home_team = home_team
	
	if (away_team == "Boston Red Sox"):
		Global.away_team_name = "Red Sox"
	elif (away_team == "Chicago White Sox"):
		Global.away_team_name = "White Sox"
	elif (away_team == "Toronto Blue Jays"):
		Global.away_team_name = "Blue Jays"
	else:
		Global.away_team_name = get_last_word(away_team)
	
	if (home_team == "Boston Red Sox"):
		Global.home_team_name = "Red Sox"
	elif (home_team == "Chicago White Sox"):
		Global.home_team_name = "White Sox"
	elif (home_team == "Toronto Blue Jays"):
		Global.home_team_name = "Blue Jays"
	else:
		Global.home_team_name = get_last_word(home_team)
	
	$WindowManager.open_gamefeed("res://Scenes/Gamefeed.tscn")

func get_last_word(text: String) -> String:
	var words = text.to_lower().strip_edges().split(" ")
	return words[-1] if words.size() > 0 else ""
