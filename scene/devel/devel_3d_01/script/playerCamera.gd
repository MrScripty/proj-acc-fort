
extends Camera

# member variables here, example:
var mousePosLast = [0, 0]
var mousePosDiff = [0, 0]
# var b="textvar"

func _ready():				
	#tell engine we have stuff to process every cycle
	self.set_process(true)
	pass
	
func _input(event):
	#print("yes")
	if(event.type == InputEvent.KEY):
		if(event.scancode == KEY_FORWARD):
			print("yes")
			get_transform()[11] += 2000

func _process(delta):
	#get vars
	var mousePosCurrent = get_viewport().get_mouse_pos()
	#var camTransVec = get_camera_transform()
	var camTransVec = get_translation()
	var camRotVec = get_rotation()
	#print(camTransVec)
	
	#print(get_node("playerCamera"))
	
	#translate forward
	if(Input.is_key_pressed(KEY_W)):
		camTransVec[2] -= .1
		print(camTransVec)
		set_translation(camTransVec)
		
	#translate backwards
	if(Input.is_key_pressed(KEY_S)):
		camTransVec[2] += .1
		print(camTransVec)
		set_translation(camTransVec)
		
	#translate left
	if(Input.is_key_pressed(KEY_A)):
		camTransVec[0] -= .1
		print(camTransVec)
		set_translation(camTransVec)
		
	#translate right
	if(Input.is_key_pressed(KEY_D)):
		camTransVec[0] += .1
		print(camTransVec)
		set_translation(camTransVec)
	
	#calc camera rotation
	if(mousePosCurrent[0] != mousePosLast[0]) or (mousePosCurrent[1] != mousePosLast[1]):
		mousePosDiff[0] = mousePosCurrent[0] - mousePosLast[0]
		mousePosDiff[1] = mousePosCurrent[1] - mousePosLast[1]
		mousePosLast = mousePosCurrent
		
		camRotVec[0] += mousePosDiff[1] /2 * delta
		camRotVec[1] += mousePosDiff[0] /2 * delta
		
	#calc camera transform
	
	#set camera vectors
	set_rotation(camRotVec)
	
	#camRotVec[1] += 1*delta
	
	
	#print(camTransform[3])
	#print(camTransform[3][2])
	#camTransform[3][2] += 200*delta
	
	#curPos.x += .1 * delta
	pass



