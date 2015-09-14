
extends Spatial

#file to hold keybindings and graphical settings
var userPrefPath = ("res://data/userPrefs.json")
var f = File.new()


func _ready():
	get_node("audio_stream").play("room noise")
	self.set_process(true)
	pass

func _enter_tree():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	pass
	
func _exit_tree():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	pass

func _input(event):
	if event.type == InputEvent.MOUSE_MOTION:
		pass


func _process(delta):
	#end program
	if(Input.is_key_pressed(KEY_ESCAPE)):
		self.get_tree().quit()

	#mute audio
	#if(Input.is_key_pressed(KEY_M)):
	#	self.get_SamplePlayer2D().stop()
	#pass
