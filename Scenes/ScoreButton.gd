extends Button


# Called when the node enters the scene tree for the first time.
func _ready():
	$AwayScoreContainer/AwayLogo.texture = load("res://Images/Logos/" + str(Global.away_team_name) + ".svg")
	$HomeScoreContainer/HomeLogo.texture = load("res://Images/Logos/" + str(Global.home_team_name) + ".svg")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
