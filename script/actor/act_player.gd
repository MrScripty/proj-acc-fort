#Kinimatic FPS character.

extends KinematicBody

#mi = mouse input
#amt = amount
#rot = rotatio
var mi_amt = 0.3
var mi_rotY = 0
var mi_rotX = 0

#Godot does not use real units so gravity is multiplyed
#vel = velocity
#accel = acceleration
#decel = decceleration
#jmp = jump
#rc = raycast
#dist = distance
#obj = object
var modeFly_maxVel = 30
var modeFly_accel = 4
var modeFly_decel = 4
var modeFly_vel = 100
var modeWalk_maxVel = 5
var modeWalk_accel = 2
var modeWalk_decel = 4
var modeWalk_vel = 100

var move_maxSlope = 40
var move_jmpTimeout = 0
var move_jmpVel = 3*3
var move_vel = Vector3()
var move_gravity = -9.81*3

var is_gravity = true
var is_modeFly = false
var is_moving = false
var is_onFloor = false

var rc_StairHight = 0.75
var rc_StairDist = 0.58
var rc_StairJmpVel = 5
var rc_StairJmpTimeout = 0

#at = audio trigger
var at_travelDist = 0
var at_lastTravelVec = Vector3()
var at_stepDist = 2


const Button_class = preload("res://script/button.gd")


func _ready():
	#enable process loop and input events
	set_fixed_process(true)
	set_process_input(true)
	#Disable select nodes from interacting with self
	get_node("spt_cam/cam/ray_interact").add_exception(self)



func _input(event):
	#rotate the cam using mouse motion, constrain max angle for x
	if event.type == InputEvent.MOUSE_MOTION:
		mi_rotY = fmod(mi_rotY - event.relative_x*mi_amt, 360)
		mi_rotX = max(min(mi_rotX - event.relative_y*mi_amt, 90), -90)
		#apply rotations to node
		get_node("spt_cam").set_rotation(Vector3(0, deg2rad(mi_rotY), 0))
		get_node("spt_cam/cam").set_rotation(Vector3(deg2rad(mi_rotX), 0, 0))
		
	if event.type == InputEvent.KEY:
		if Input.is_action_pressed("action_interact"):
			var rcInteract = get_node("spt_cam/cam/ray_interact")
			if rcInteract.is_colliding():
				var interactWith = rcInteract.get_collider()
				if interactWith extends Button_class:
					interactWith.on_interact()
					
	if Input.is_action_pressed("action_dev"):
		if is_modeFly:
			is_modeFly = false
		else:
			is_modeFly = true


func _fixed_process(delta):
	if is_modeFly:
		_modeFly(delta)
	else:
		_modeWalk(delta)


func _modeWalk(delta):
	#get look rotation (movement will be relitive to this vector)
	var lookRot = get_node("spt_cam/cam").get_global_transform().basis
	#get raycasts
	var rcFloor = get_node("ray_floorDetect")
	var rcStair = get_node("ray_stairDetect")
	if move_jmpTimeout>0:
		move_jmpTimeout-=delta
	
	#Direction to move
	var moveDirection = Vector3()
	var moveJmp = false
	if Input.is_action_pressed("move_front"):
		moveDirection -= lookRot[2]
	if Input.is_action_pressed("move_back"):
		moveDirection += lookRot[2]
	if Input.is_action_pressed("move_left"):
		moveDirection -= lookRot[0]
	if Input.is_action_pressed("move_right"):
		moveDirection += lookRot[0]
	if Input.is_action_pressed("action_jump"):
		moveJmp = true
	moveDirection.y = 0
	
	#Determine if moving 
	var moveAccel = modeWalk_decel
	var isStair = false
	if moveDirection.length()>0:
		is_moving = true
		moveAccel = modeWalk_accel
		#check if there is a stair, get vectors if true
		if rcStair.is_colliding():
			var rcStairNor = rcStair.get_collision_normal()
			var rcStairPoint = rcStair.get_collision_point()
			#determine if stair is at exceptable angle
			#if (rad2deg(acos(rcStairNor.dot(Vector3(0, 1, 0))))< move_maxSlope):
			#	var isStair = true
	
	#Determine if on floor and get floor vectors if true. Takes into account move_maxSlope
	var rcFloorPoint = Vector3()
	var rcFloorNor = Vector3()
	if rcFloor.is_colliding():
		rcFloorPoint = rcFloor.get_collision_point()
		rcFloorNor = rcFloor.get_collision_normal()
		if (rad2deg(acos(rcFloorNor.dot(Vector3(0, 1, 0))))< move_maxSlope):
			is_onFloor = true
	else:
		is_onFloor = false
		
	#calculate object target location vector
	var moveTarget = Vector3()
	if is_onFloor:
		moveTarget = moveDirection*modeWalk_maxVel
		moveTarget.y = rcFloorPoint.y
		
	#calculate object velocity
	var moveVel = Vector3()
	if is_onFloor:
		#Orient vector along floor normal
		move_vel = move_vel-move_vel.dot(rcFloorNor)*rcFloorNor
		#Velocity caused by user input
		moveVel = move_vel
		moveVel.y = 0
		moveVel = moveVel.linear_interpolate(moveTarget, moveAccel*delta)
		move_vel.x = moveVel.x
		move_vel.z = moveVel.z
		#Velocity caused by jump
		if moveJmp:
			move_jmpTimeout = 0.2
			move_vel.y += move_jmpVel
	else:
		#Add gravity effect
		move_vel.y += move_gravity*delta
	
	#Audio triggers
	var audioSample = get_node("audio_sample")
	#Floor steps
	if is_onFloor and is_moving:
		if at_lastTravelVec == Vector3():
			at_lastTravelVec = get_translation()
		else:
			var currentVec = get_translation()
			#Calc dist between vectors on XZ
			currentVec.x -= at_lastTravelVec.x
			currentVec.z -= at_lastTravelVec.z
			at_travelDist += (sqrt(currentVec.x*currentVec.x + currentVec.z*currentVec.z)*1)
			at_lastTravelVec = get_translation()
		#make step sound every x distance traveld
		if at_travelDist >= at_stepDist:
			at_travelDist = 0
			#audioSample.play('footstep_01')
	else:
		at_travelDist = 0
		at_lastTravelVec = Vector3()
	#jump sound
	if moveJmp:
		print('jump')
	
	
	#Update node translation
	#print(moveVel)
	move(move_vel*delta)
		
	#slide, alows movment along a surface. Note that this is still a bit sticky.
	#var moveVec = move_vel*delta
	#var moveOriginalVel = move_vel
	#var collisionNor = get_collision_normal()
	#moveVec = collisionNor.slide(moveVec)
	#move_vel = collisionNor.slide(move_vel)
		

	
	#determine if on floor and snap to it but dissable snap if an action requires
	#var rcFloorCollision = rcFloor.is_colliding()
	#if rcFloorCollision and move_jmpTimeout<=0:
	#	is_onFloor = true
	#	#gets vector of ray collision and moves us to that point
	#	set_translation(rcFloor.get_collision_point())
		#calc velocity relitive to floor normal
	#	var rcFloorNor(rcFloor.get_collision_normal())
	#	move_vel = move_vel-move_vel.dot(rcFloorNor)*rcFloorNor
		

	
	#idk what this does
	#moveDirection = moveDirection.normalized()


func _modeFly(delta):
	#get look rotation (movment will be relitive to this vector)
	var lookRot = get_node("spt_cam/cam").get_global_transform().basis
	
	#Direction to move
	var moveDirection = Vector3()
	if Input.is_action_pressed("move_front"):
		moveDirection -= lookRot[2]
	if Input.is_action_pressed("move_back"):
		moveDirection += lookRot[2]
	if Input.is_action_pressed("move_left"):
		moveDirection -= lookRot[0]
	if Input.is_action_pressed("move_right"):
		moveDirection += lookRot[0]
	
	moveDirection = moveDirection.normalized()

	#calc where player will move to
	var moveTarget = moveDirection * modeFly_vel
	
	#Velocity to move at
	move_vel = Vector3().linear_interpolate(moveTarget, modeFly_accel*delta)
	
	#slide, alows movment along a surface. Note that this is still a bit sticky.
	var moveVec = move_vel*delta
	var moveOriginalVel = move_vel
	var collisionNor = get_collision_normal()
	moveVec = collisionNor.slide(moveVec)
	move_vel = collisionNor.slide(move_vel)
	
	#move (translate) node
	#check resulting velocity is not opposite to original velocity
	if(moveOriginalVel.dot(move_vel)>0):
		moveVec = move(moveVec)


func _on_area_ladder_body_enter( body ):
	is_modeFly = true


func _on_area_ladder_body_exit( body ):
	is_modeFly = false
