
extends KinematicBody

#Mouse look variables
var mouselook_sensitivity = 0.3
var yaw = 0
var pitch = 0

#Player movement variables
var velocity = Vector3()
const FLY_SPEED = 100
const FLY_ACCEL = 4
const WALK_MAX_SPEED = 15
const ACCEL = 2
const DEACCEL = 4
var is_moving = false
const GRAVITY = -9.8*3
const JUMP_SPEED = 3*3
var on_floor = false
const MAX_SLOPE_ANGLE = 40
var jump_timeout = 0
const MAX_JUMP_TIMEOUT = 0.2
const STAIR_RAYCAST_HEIGHT = 0.75
const STAIR_RAYCAST_DISTANCE = 0.58
const STAIR_JUMP_SPEED = 5
const STAIR_JUMP_TIMEOUT = 0.2
var fly_mode = false

const Button_class = preload("res://script/button.gd")


func _ready():
	set_fixed_process(true)
	set_process_input(true)
	get_node("spatial_yaw/camera_player/ray_interact").add_exception(self)
	pass
	
func _input(event):
	if event.type == InputEvent.MOUSE_MOTION:
		yaw = fmod(yaw - event.relative_x * mouselook_sensitivity, 360)
		pitch = max(min(pitch - event.relative_y * mouselook_sensitivity, 90), -90)
		get_node("spatial_yaw").set_rotation(Vector3(0, deg2rad(yaw), 0))
		get_node("spatial_yaw/camera_player").set_rotation(Vector3(deg2rad(pitch), 0, 0))
		
	if event.type == InputEvent.KEY:
		if Input.is_action_pressed("action_interact"):
			var ray = get_node("spatial_yaw/camera_player/ray_interact")
			if ray.is_colliding():
				var obj = ray.get_collider()
				if obj extends Button_class:
					print("yay")
					obj.on_pressed()
	pass
	
func _fixed_process(delta):
	if fly_mode:
		_fly(delta)
	else:
		_walk(delta)
	pass
	

func _fly(delta):
	#get camera rotation
	var aim = get_node("spatial_yaw/camera_player").get_global_transform().basis
	#calc move direction
	var direction = Vector3()
	if Input.is_action_pressed("move_forward"):
		direction -= aim[2]
	if Input.is_action_pressed("move_backward"):
		direction += aim[2]
	if Input.is_action_pressed("move_left"):
		direction -= aim[0]
	if Input.is_action_pressed("move_right"):
		direction += aim[0]

	direction = direction.normalized()
	
	#calc where target wants to move
	var target = direction * FLY_SPEED
	
	#calculate velocity
	velocity = Vector3().linear_interpolate(target, FLY_ACCEL * delta)
	
	#move node
	var motion = velocity * delta
	motion = move(motion)
	
	#slide until doesnt need to slide
	var original_vel = velocity
	var attempts = 4
	
	while(attempts and is_colliding()):
		var n = get_collision_normal()
		motion = n.slide(motion)
		velocity = n.slide(velocity)
		
		#check if moving backwards
		if(original_vel.dot(velocity)>0):
			motion = move(motion)
			if (motion.length()<0.001):
				break
		attempts -= 1


func _walk(delta):
	if jump_timeout>0:
		jump_timeout -= delta
	var ray = get_node("ray_floorDetect")
	var step_ray = get_node("ray_stepDetect")
	#get camera rotation
	var aim = get_node("spatial_yaw/camera_player").get_global_transform().basis
	#calc move direction
	var direction = Vector3()
	if Input.is_action_pressed("move_forward"):
		direction -= aim[2]
	if Input.is_action_pressed("move_backward"):
		direction += aim[2]
	if Input.is_action_pressed("move_left"):
		direction -= aim[0]
	if Input.is_action_pressed("move_right"):
		direction += aim[0]
	if on_floor:
		if Input.is_action_pressed("action_jump"):
			velocity.y = JUMP_SPEED
			jump_timeout = MAX_JUMP_TIMEOUT
			on_floor = false

	is_moving = (direction.length()>0)
	direction.y = 0
	direction = direction.normalized()
	#clamp to ground if not jumping
	var is_ray_colliding = ray.is_colliding()
	
	if !on_floor and jump_timeout <= 0 and is_ray_colliding:
		set_translation(ray.get_collision_point())
		on_floor = true
	elif on_floor and not is_ray_colliding:
		on_floor = false
	
	if on_floor:
		#move along normal of floor
		var n = ray.get_collision_normal()
		velocity = velocity - velocity.dot(n)*n
		
		#if character infront of step and step is flat enough jump to step
		if is_moving and step_ray.is_colliding():
			var step_normal = step_ray.get_collision_normal()
			if (rad2deg(acos(step_normal.dot(Vector3(0, 1, 0))))< MAX_SLOPE_ANGLE):
				velocity.y += delta * GRAVITY
		
		#apply gravity on steep slope
		if (rad2deg(acos(n.dot(Vector3(0, 1, 0))))> MAX_SLOPE_ANGLE):
			velocity.y += delta * GRAVITY
			
		#move along floor but dont change velocity
		var floor_velocity = _get_floor_velocity(ray, delta)
		if floor_velocity.length()!=0:
			move(floor_velocity * delta)
		pass
	else:
		#apply gravity if falling
		velocity.y += delta * GRAVITY
	
	#calc where target wants to move
	var target = direction * WALK_MAX_SPEED
	#if moving accelerate otherwise deccelerate
	var accel = DEACCEL
	if is_moving:
		accel=ACCEL
	
	#calculate velocity change
	var hvel = velocity
	hvel.y = 0
	
	#calc calc velocity towards target on XY plane
	hvel = hvel.linear_interpolate(target, accel * delta)
	velocity.x = hvel.x
	velocity.z = hvel.z
	
	#move node
	var motion = velocity * delta
	motion = move(motion)
	
	#slide until doesnt need to slide
	var original_vel = velocity
	var attempts = 4
	
	if(motion.length()>0 and is_colliding()):
		var n = get_collision_normal()
		motion = n.slide(motion)
		velocity = n.slide(velocity)
		if(original_vel.dot(velocity)>0):
			motion = move(motion)
					
		attempts -= 1
		
	#update position of raycast for stairs to where character is trying to go so will cast ray next loop
	if is_moving:
		var sensor_position = Vector3(direction.z, 0, -direction.x) * STAIR_RAYCAST_DISTANCE
		sensor_position.y = STAIR_RAYCAST_HEIGHT
		step_ray.set_translation(sensor_position)
		
		
func _get_floor_velocity(ray, delta):
	var floor_velocity = Vector3()
	#only static and rigid bodys considered a floor
	#character ontop character ignored
	var object = ray.get_collider()
	if object extends RigidBody or object extends StaticBody:
		var point = ray.get_collision_point() - object.get_translation()
		var floor_angular_vel = Vector3()
		#get floor velocity and rotation
		if object extends RigidBody:
			floor_velocity = object.get_linear_velocity()
			floor_angular_vel = object.get_angular_velocity()
		elif object extends StaticBody:
			floor_velocity = object.get_constant_linear_velocity()
			floor_angular_vel = object.get_constant_angular_velocity()
		#if there is angular velocity the floor valocity must take into account
		if(floor_angular_vel.length()>0):
			var transform = Matrix3(Vector3(1, 0, 0), floor_angular_vel.x)
			transform = transform.rotated(Vector3(0, 1, 0), floor_angular_vel.y)
			transform = transform.rotated(Vector3(0, 0, 1), floor_angular_vel.z)
			floor_velocity += transform.xform_inv(point) - point
			
			#if floor has angular velocity (rotation), character must rotate too
			yaw = fmod(yaw + rad2deg(floor_angular_vel.y) * delta, 360)
			get_node("spatial_yaw").set_rotation(Vector3(0, deg2rad(yaw), 0))
	return floor_velocity
			
			
func _on_area_ladder_body_enter( body ):
	fly_mode = true


func _on_area_ladder_body_exit( body ):
	fly_mode = false
