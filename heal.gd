extends TextureButton

# --- Nodes ---
@onready var cooldown_timer: Timer = $Timer
@onready var time_label: Label = $Label 
@onready var cooldown_sweep: TextureProgressBar = $CooldownSweep

# --- Settings ---
@export var cooldown_time: float = 2.0  
@export var max_potions_per_life: int = 5
@export var hotkey: String = "R"

# --- Logic Variables ---
var potions_left: int = 5

func _ready():
	# 1. Connect signals
	if not pressed.is_connected(_on_pressed):
		pressed.connect(_on_pressed)
	if not cooldown_timer.timeout.is_connected(_on_timer_timeout):
		cooldown_timer.timeout.connect(_on_timer_timeout)
	
	# 2. Initial Setup
	cooldown_timer.wait_time = cooldown_time
	cooldown_timer.one_shot = true
	potions_left = max_potions_per_life
	
	# 3. Visual Setup
	cooldown_sweep.max_value = cooldown_time
	cooldown_sweep.value = 0
	update_ui_text()
	
	# 4. Setup Hotkey
	call_deferred("setup_hotkey")
	set_process(false)

func setup_hotkey():
	if hotkey == "": return
	var new_shortcut = Shortcut.new()
	var input_key = InputEventKey.new()
	var parsed_key = OS.find_keycode_from_string(hotkey.to_upper())
	
	if parsed_key != KEY_NONE:
		input_key.keycode = parsed_key
		new_shortcut.events = [input_key]
		self.shortcut = new_shortcut

func _on_pressed():
	# Access the player via your Manager
	var player = PlayerManager.player
	
	# CHECK: Player exists? Have potions? Timer not running?
	if player != null and potions_left > 0 and cooldown_timer.is_stopped():
		# 1. Trigger the heal inside the player
		player.apply_heal() 
		
		# 2. Update UI Count
		potions_left -= 1
		update_ui_text()
		
		# 3. Start Visual Cooldown
		disabled = true
		cooldown_timer.start()
		set_process(true)
		
	elif potions_left <= 0:
		print("No potions remaining for this life.")

func _process(_delta):
	# Update the progress bar sweep
	cooldown_sweep.value = cooldown_timer.time_left

func _on_timer_timeout():
	disabled = false
	set_process(false)
	cooldown_sweep.value = 0
	update_ui_text()

func update_ui_text():
	# Update the number '5' on your button
	time_label.text = str(potions_left)

func reset_potions():
	# Call this from your player script when a life is lost
	potions_left = max_potions_per_life
	disabled = false
	update_ui_text()
