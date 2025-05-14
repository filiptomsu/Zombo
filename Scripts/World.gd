extends Node3D

@onready var hit_rect = $UI/HitRect
@onready var spawns = $Map/Spawns
@onready var navigation_region = $Map/NavigationRegion3D
@onready var zombie_timer = $ZombieSpawnTimer
@onready var score_label = $UI/ScoreLabel
@onready var wave_label = $UI/WaveLabel
@onready var pause_menu = $UI/PauseMenu
@onready var crosshair = $UI/CrossHair
@onready var end_label = $UI/PauseMenu/VBoxContainer/Label
@onready var resumeBtn = $UI/PauseMenu/VBoxContainer/ResumeButton

var zombie = load("res://Scenes/Zombie.tscn")

var wave_index := 0
var waves := [4,6,8,10] 
var zombies_to_spawn := 0
var zombies_alive := 0
var score := 0

func _ready():
	randomize()
	_register_existing_zombies()
	start_wave()
	crosshair.position.x = get_viewport().size.x / 2 
	crosshair.position.y = get_viewport().size.y / 2 

# Zaregistruje zombíky, co jsou už ve scéně
func _register_existing_zombies():
	for child in navigation_region.get_children():
		if child is CharacterBody3D and "zombie_died" in child.get_signal_list():
			child.connect("zombie_died", _on_zombie_died)
			zombies_alive += 1

func start_wave():
	if wave_index >= waves.size():
		print("Všechny vlny dokončeny!")
		return
	
	var current_wave = wave_index + 1
	wave_label.text = "Wave: %d" % current_wave
	
	zombies_to_spawn = waves[wave_index]
	zombies_alive = 0 
	zombie_timer.start()

func _on_zombie_spawn_timer_timeout():
	if zombies_to_spawn > 0:
		var spawn_point = _get_random_child(spawns).global_position
		var instance = zombie.instantiate()
		instance.position = spawn_point
		navigation_region.add_child(instance)

		instance.connect("zombie_died", _on_zombie_died)
		
		zombies_to_spawn -= 1
		zombies_alive += 1
	else:
		zombie_timer.stop()

func _on_zombie_died():
	if zombies_alive <= 0:
		return  

	zombies_alive -= 1
	score += 100
	score_label.text = "Score: %d" % score

	if zombies_alive <= 0 and zombies_to_spawn <= 0:
		wave_index += 1

		if wave_index >= waves.size():
			show_end_menu()
		else:
			await get_tree().create_timer(3.0).timeout
			start_wave()

func _on_player_player_hit():
	hit_rect.visible = true
	await get_tree().create_timer(0.2).timeout
	hit_rect.visible = false

func _get_random_child(parent_node):
	var random_id = randi() % parent_node.get_child_count()
	return parent_node.get_child(random_id)

func _unhandled_input(event):
	if event.is_action_pressed("cancel"): 
		if get_tree().paused:
			resume_game()
		else:
			pause_game()

func pause_game():
	get_tree().paused = true
	pause_menu.visible = true
	end_label.text = "Pozastaveno"
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func resume_game():
	get_tree().paused = false
	pause_menu.visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
func show_end_menu():
	get_tree().paused = true
	pause_menu.visible = true
	end_label.text = "Konec hry!"
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _on_resume_button_pressed():
	resume_game()

func _on_quit_button_pressed():
	get_tree().quit()


func _on_reset_pressed() -> void:
	# Reset základních proměnných
	wave_index = 0
	score = 0
	score_label.text = "Score: 0"

	# Odstranění existujících zombíků
	for child in navigation_region.get_children():
		if child is CharacterBody3D and child.has_signal("zombie_died"):
			child.queue_free()

	zombies_to_spawn = 0
	zombies_alive = 0

	# Skrytí menu a spuštění první vlny
	pause_menu.visible = false
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	start_wave()
