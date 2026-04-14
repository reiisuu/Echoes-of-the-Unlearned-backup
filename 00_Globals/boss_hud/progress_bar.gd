extends ProgressBar

func _ready():
	set_process(false)

func set_bar_value(value):
	self.value = value
	#set_process(false)
	$Timer.stop()
	$Timer.start(0)
	if(value > $ProgressBar2.value):
		$ProgressBar2.value = value

func _on_timer_timeout():
	set_process(true)

func _process(delta):
	$ProgressBar2.value = lerp($ProgressBar2.value, value, 0.1)
	if($ProgressBar2.value - value <= 0.5):
		$ProgressBar2.value = value
		set_process(false)
	
