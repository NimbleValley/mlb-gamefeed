extends Control

@onready var title_label = $Title
@onready var title_background = $TitleBackground
@onready var loading_label = $LoadingLabel
@onready var tween = create_tween()

var dot_count := 0
var loading = true;

func _ready():
	# Setup title label for slide-in
	var target_pos_label = title_label.position
	title_label.position = target_pos_label - Vector2(300, 0)
	title_label.modulate.a = 0.0
	
	var target_pos_background = title_background.position
	title_background.position = target_pos_background - Vector2(0, 100)
	title_background.modulate.a = 0.0

	# Hide loading initially
	loading_label.visible = false
	loading_label.clear()

	 # Slide to target position over 1 second, easing out
	tween.tween_property(title_label, "position", target_pos_label, 1.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	# Fade in alpha to 1 over the same time
	tween.parallel().tween_property(title_label, "modulate:a", 1.0, 1.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	tween.parallel().tween_property(title_background, "position", target_pos_label, 1.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(title_background, "modulate:a", 0.8, 1.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	# When done, start loading
	tween.tween_callback(Callable(self, "_start_loading"))
	
	$GameFetcher.fetch_games()

func _start_loading():
	loading_label.modulate.a = 0.0
	loading_label.visible = true
	var tween2 = create_tween()
	tween2.tween_property(loading_label, "modulate:a", 1.0, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	animate_loading()

func animate_loading():
	dot_count = 0
	_update_loading_text()
	get_tree().create_timer(0.5).timeout.connect(_update_loading_text)

func _update_loading_text():
	if !loading:
		loading_label.visible = false
		return;
	dot_count = (dot_count + 1) % 4
	var dots = ".".repeat(dot_count)

	loading_label.clear()
	loading_label.append_text("Loading games" + dots)

	# Keep looping
	get_tree().create_timer(1).timeout.connect(_update_loading_text)
