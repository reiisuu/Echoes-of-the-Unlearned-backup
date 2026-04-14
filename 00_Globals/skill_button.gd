extends TextureButton

@onready var cooldown_timer: Timer = $Timer
@onready var time_label: Label = $Label 
@onready var cooldown_sweep: TextureProgressBar = $CooldownSweep

@export var cooldown_time: float = 15.0 
@export var hotkey: String = "X" 

func _ready():
	# 1. Connect signals
	pressed.connect(_on_pressed)
	cooldown_timer.timeout.connect(_on_timer_timeout)
	
	# 2. Setup Timer
	cooldown_timer.wait_time = cooldown_time
	cooldown_timer.one_shot = true
	
	# 3. Setup Visuals
	time_label.text = "" 
	cooldown_sweep.max_value = cooldown_time
	cooldown_sweep.value = 0 
	
	# 4. Disable processing until button is clicked
	set_process(false)
	setup_hotkey()

func setup_hotkey():
	if hotkey == "": return
	var new_shortcut = Shortcut.new()
	var input_key = InputEventKey.new()
	var parsed_key = OS.find_keycode_from_string(hotkey.to_upper())
	if parsed_key != 0:
		input_key.keycode = parsed_key
		new_shortcut.events = [input_key]
		self.shortcut = new_shortcut

func _process(_delta):
	# Update the countdown text
	time_label.text = "%3.1f" % cooldown_timer.time_left
	# Update the sweep visual
	cooldown_sweep.value = cooldown_timer.time_left

func _on_pressed():
	# Use your Global Player Manager
	var player = PlayerManager.player
	
	if player != null:
		# Trigger the player function
		player.start_enrage() 
		
		# Start UI Cooldown
		disabled = true
		cooldown_timer.start()
		set_process(true)
		print("!!! ENRAGE STARTED !!!")
	else:
		print("ERROR: PlayerManager.player is null! Are you running the whole game (F5)?")

func _on_timer_timeout():
	disabled = false
	time_label.text = "" 
	cooldown_sweep.value = 0 
	set_process(false)
