extends Node

var GAME_PK = Global.game_pk
var API_URL = "https://statsapi.mlb.com/api/v1.1/game/%d/feed/live" % GAME_PK

var empty_ball_theme = load("res://Themes/BallEmpty.tres")
var full_ball_theme = load("res://Themes/BallFull.tres")
var empty_strike_theme = load("res://Themes/StrikeEmpty.tres")
var full_strike_theme = load("res://Themes/StrikeFull.tres")


@onready var http_request: HTTPRequest = $HTTPRequest
@onready var poll_timer: Timer = $PollTimer
@onready var plays_label: RichTextLabel = $LastPlayContainer/LastPlayVerticalContainer/LastPlayText
@onready var pitcher_label: RichTextLabel = $PitcherText
@onready var batter_label: RichTextLabel = $BatterText
@onready var inning_label: RichTextLabel = $InningContainer/InningText
@onready var outs_label: RichTextLabel = $OutsText
@onready var home_score_label: RichTextLabel = $ScoreButton/HomeScoreContainer/HomeScoreText
@onready var away_score_label: RichTextLabel = $ScoreButton/AwayScoreContainer/AwayScoreText
@onready var ball_children = $CountContainer/CountInnerContainer/BallContainer.get_children()
@onready var strike_children = $CountContainer/CountInnerContainer/StrikeContainer.get_children()
@onready var base_children = $Field.get_children()
@onready var top_inning = $InningContainer/TopInning
@onready var bottom_inning = $InningContainer/BottomInning
@onready var inning_change_panel = $InningChangePanel
@onready var final_panel = $FinalContainer

var previous_home_score = 0
var previous_away_score = 0
var isFirst = true

@onready var run_panel: Panel = $RunAnimationPanel
@onready var run_sfx: AudioStreamPlayer = $RunSound

func _ready():
	# Setup HTTPRequest
	http_request.request_completed.connect(_on_http_request_completed)
	
	# Setup polling interval (e.g., every 10 seconds)
	poll_timer.wait_time = 5.0
	poll_timer.timeout.connect(_on_poll_timer_timeout)
	poll_timer.start()

	fetch_game_data()

func fetch_game_data():
	var err = http_request.request(API_URL)
	if err != OK:
		print("Failed to send request:", err)

func _on_http_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
	if response_code == 200:
		var json = JSON.parse_string(body.get_string_from_utf8())
		if json:
			handle_game_data(json)
		else:
			print("Failed to parse JSON.")
	else:
		print("HTTP Error:", response_code)

func _on_poll_timer_timeout():
	fetch_game_data()

func handle_game_data(data):
	var linescore = data.get("liveData", {}).get("linescore", {})
	var all_plays = data.get("liveData", {}).get("plays", {}).get("allPlays", [])
	var last_play = all_plays[-1] if all_plays.size() > 0 else {}
	
	var home_score = linescore.get("teams", {}).get("home", {}).get("runs", 0)
	home_score_label.text =  "[center]" + str(home_score) + "[/center]"
	var away_score = linescore.get("teams", {}).get("away", {}).get("runs", 0)
	away_score_label.text = "[center]" + str(away_score) + "[/center]"
	
	append_plays_this_half_inning_to_label(data)
	
	if is_game_over(data):
		final_panel.visible = true
		final_panel.get_children()[0].text = "[center]Final: " + Global.away_team_name.capitalize() + " " + str(away_score) + ", " + Global.home_team_name.capitalize() + " " + str(home_score) + "[/center]"
		return
	
	final_panel.visible = false

	# Batter and Pitcher
	var matchup = last_play.get("matchup", {})
	var batter_name = matchup.get("batter", {}).get("fullName", "Unknown")
	var pitcher_name = matchup.get("pitcher", {}).get("fullName", "Unknown")
	if(pitcher_name.length() > 12):
		pitcher_label.text = "Pitcher: " + str(pitcher_name.substr(0, 1)) + str(pitcher_name.substr(pitcher_name.find(" ")))
	else:
		pitcher_label.text = "Pitcher: " + str(pitcher_name)
	if(batter_name.length() > 12):
		batter_label.text = "Batter: " + str(batter_name.substr(0, 1)) + str(batter_name.substr(batter_name.find(" ")))
	else:
		batter_label.text = "Batter: " + str(batter_name)

	# Outs and Inning
	var outs = linescore.get("outs", 0)
	if(outs == 0):
		inning_change_panel.visible = false
		outs_label.text = "0 Outs"
	elif(outs == 1):
		inning_change_panel.visible = false
		outs_label.text = "1 Out";
	elif(outs == 2):
		inning_change_panel.visible = false
		outs_label.text = "2 Outs";
	elif(outs == 3):
		inning_change_panel.visible = true
		outs_label.text = "3 Outs";
	var inning = linescore.get("currentInning", 0)
	
	var is_top = linescore.get("isTopInning", true)

	var state_text = ""

	if outs == 3:
		state_text = "[center]Middle of Inning" if is_top else "[center]End of Inning"
		inning_change_panel.get_children()[0].text = state_text + " " + str(inning)
	
	inning_label.text = "[center]" + str(inning) + "[/center]"
	if linescore.get("inningState", "").to_lower() == "top":
		top_inning.visible = true
		bottom_inning.visible = false
	else:
		top_inning.visible = false
		bottom_inning.visible = true

	# Balls and Strikes
	var count = last_play.get("count", {})
	var balls = count.get("balls", 0)
	var strikes = count.get("strikes", 0)
	
	for n in range(3):
		ball_children[n].theme = empty_ball_theme
	if balls > 0:
		for n in range(clamp(balls, 0, 2)):
			ball_children[n].theme = full_ball_theme
	
	for n in range(2):
			strike_children[n].theme = empty_strike_theme
	if strikes > 0:
		for n in range(clamp(strikes, 0, 2)):
			strike_children[n].theme = full_strike_theme

	# Previous Play (second to last in allPlays)
	var previous_play_description = "None"
	if all_plays.size() >= 2:
		previous_play_description = all_plays[all_plays.size() - 2].get("result", {}).get("description", "None")

	# Output
	print("--- MLB Game State ---")
	print("Inning:", inning, "| Outs:", outs)
	print("Batter:", batter_name, "| Pitcher:", pitcher_name)
	print("Balls:", balls, "| Strikes:", strikes)
	print("Previous Play:", previous_play_description)

	var runners_on_base = get_runners_on_base(data)
	print(runners_on_base)
	
	for n in range(3):
			base_children[n].visible = false
	
	if runners_on_base.size() > 0:
		for n in range(runners_on_base.size()):
			base_children[n].visible = true
	move_window_to_bottom_right()
	
	check_for_run_score_change(data)

func get_runners_on_base(data):
	var runners_on_base = []
	var offense = data.get("liveData", {}).get("linescore", {}).get("offense", {})

	if offense.has("first"):
		runners_on_base.append("First")
	if offense.has("second"):
		runners_on_base.append("Second")
	if offense.has("third"):
		runners_on_base.append("Third")

	return runners_on_base

func append_plays_this_half_inning_to_label(data):
	var all_plays = data.get("liveData", {}).get("plays", {}).get("allPlays", [])
	var linescore = data.get("liveData", {}).get("linescore", {})
	var current_inning = linescore.get("currentInning", 0)
	var current_half = linescore.get("inningState", "").to_lower()  # "top" or "bottom"

	var plays_this_half_inning = []
	for play in all_plays:
		var inning = play.get("about", {}).get("inning", 0)
		var half = play.get("about", {}).get("halfInning", "").to_lower()
		if inning == current_inning and half == current_half:
			plays_this_half_inning.append(play)

	var text = ""
	for i in range(plays_this_half_inning.size() - 1, -1, -1):
		var play = plays_this_half_inning[i]
		var desc = play.get("result", {}).get("description", "No description")
		if(desc == "No description"):
			continue
		var half = play.get("about", {}).get("halfInning", "").capitalize()
		text += "%s - %s\n" % [half + " " + str(current_inning), desc]

	plays_label.text = text

func is_game_over(data):
	var state = data.get("gameData", {}).get("status", {}).get("detailedState", "")
	return state == "Final" or state == "Game Over"

func move_window_to_bottom_right():
	var screen_index = DisplayServer.window_get_current_screen()
	var screen_size = DisplayServer.screen_get_size(screen_index)
	var screen_position = DisplayServer.screen_get_position(screen_index)
	var window_size = DisplayServer.window_get_size()

	var target_position = screen_position + screen_size - window_size - Vector2i(0, 40)  # margin from corner
	DisplayServer.window_set_position(target_position)


func check_for_run_score_change(data):
	var linescore = data.get("liveData", {}).get("linescore", {})
	var teams = linescore.get("teams", {})

	var home_score = teams.get("home", {}).get("runs", 0)
	var away_score = teams.get("away", {}).get("runs", 0)

	if !isFirst:
		if home_score > previous_home_score:
			animate_run_scored("home", home_score - previous_home_score)

		if away_score > previous_away_score:
			animate_run_scored("away", away_score - previous_away_score)
	
	isFirst = false

	# Update previous scores
	previous_home_score = home_score
	previous_away_score = away_score

func animate_run_scored(team: String, runs: int):
	run_sfx.play()
	var text = "[center]%s team scored!" % team.capitalize()
	if runs > 1:
		text = "[center]%s team scored %d runs!" % [team.capitalize(), runs]

	run_panel.get_children()[0].text = text
	run_panel.modulate.a = 0.0
	run_panel.visible = true

	var tween = create_tween()
	tween.tween_property(run_panel, "modulate:a", 1.0, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_interval(4.0)
	tween.tween_property(run_panel, "modulate:a", 0.0, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
