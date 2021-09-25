extends KinematicBody

# Car behavior parameters, adjust as needed

export var gravity = -20.0
export var wheel_base = 0.6  # distance between front/rear axles

export var steering_limit = 15.0  # front wheel max turning angle (deg)

export var engine_power = 20.0
export var braking = -9.0
export var friction = -2.0
export var drag = -2.0
export var max_speed_reverse = 10.0

onready var wheel_front_left: Spatial = $model/front_left
onready var wheel_front_right: Spatial = $model/front_right

# Car state properties

var acceleration = Vector3.ZERO  # current acceleration

var velocity = Vector3.ZERO  # current velocity

var steer_angle = 0.0  # current wheel angle


signal change_camera

var current_camera = 0
onready var num_cameras = $camera_positions.get_child_count()



func get_input():
	var turn = Input.get_action_strength("turn_left")
	turn -= Input.get_action_strength("turn_right")
	steer_angle = turn * deg2rad(steering_limit)
	wheel_front_left.rotation.y = steer_angle*2
	wheel_front_right.rotation.y = steer_angle*2
	acceleration = Vector3.ZERO
	if Input.is_action_pressed("accel"):
		acceleration = -transform.basis.z * engine_power
	if Input.is_action_pressed("brake"):
		acceleration = -transform.basis.z * braking


func apply_friction(delta: float):
	if velocity.length() < 0.2 and acceleration.length() == 0:
		velocity.x = 0
		velocity.z = 0
	var friction_force = velocity * friction * delta
	var drag_force = velocity * velocity.length() * drag * delta
	acceleration += drag_force + friction_force


func apply_steering(delta: float):
	var rear_wheel = transform.origin + transform.basis.z * wheel_base / 2.0
	var front_wheel = transform.origin - transform.basis.z * wheel_base / 2.0
	rear_wheel += velocity * delta
	front_wheel += velocity.rotated(transform.basis.y, steer_angle) * delta
	var new_direction = rear_wheel.direction_to(front_wheel)
	
	var d = new_direction.dot(velocity.normalized())
	if d > 0:
		velocity = new_direction * velocity.length()
	if d < 0:
		velocity = -new_direction * min(velocity.length(), max_speed_reverse)
	look_at(transform.origin + new_direction, transform.basis.y)


func _input(event: InputEvent):
	if event is InputEventKey and event.is_action_pressed("quit"):
		get_tree().quit()
	if event.is_action_pressed("change_camera"):
		current_camera = wrapi(current_camera + 1, 0, num_cameras)
		emit_signal("change_camera", $camera_positions.get_child(current_camera))


func _ready():
	emit_signal("change_camera", $camera_positions.get_child(current_camera))

func _physics_process(delta: float):
	if is_on_floor():
		get_input()
		apply_friction(delta)
		apply_steering(delta)
	acceleration.y = gravity
	velocity += acceleration * delta
	velocity = move_and_slide_with_snap(velocity, -transform.basis.y, Vector3.UP, true)
