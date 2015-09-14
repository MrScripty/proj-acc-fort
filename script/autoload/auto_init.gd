
extends Spatial


func _ready():
	#get_node("audio_stream").play("room noise")
	self.set_process(true)


func _enter_tree():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

		
func _exit_tree():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _input(event):
	if event.type == InputEvent.MOUSE_MOTION:


func _process(delta):
	#end program
	if(Input.is_key_pressed(KEY_ESCAPE)):
		self.get_tree().quit()

	#mute audio
	#if(Input.is_key_pressed(KEY_M)):
	#	self.get_SamplePlayer2D().stop()
	#pass
