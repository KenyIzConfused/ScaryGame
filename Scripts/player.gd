extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const TURN_SPEED = 12.0

var orbit_camera: Camera3D
var orbiting := false
var orbit_sensitivity := 0.003
var orbit_yaw := 0.0
var orbit_pitch := 0.0


func _ready() -> void:
	orbit_camera = get_viewport().get_camera_3d()
	if orbit_camera:
		orbit_yaw = orbit_camera.rotation.y
		orbit_pitch = orbit_camera.rotation.x


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			orbiting = true
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	if event is InputEventKey:
		if event.keycode == KEY_ESCAPE and event.pressed:
			orbiting = false
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			
			if orbit_camera:
				rotation.y = orbit_camera.rotation.y
				orbit_yaw = orbit_camera.rotation.y
	
	if orbiting and event is InputEventMouseMotion:
		orbit_yaw -= event.relative.x * orbit_sensitivity
		orbit_pitch -= event.relative.y * orbit_sensitivity
		orbit_pitch = clamp(orbit_pitch, -PI / 2.0, PI / 2.0)
		
		if orbit_camera:
			orbit_camera.rotation.y = orbit_yaw
			orbit_camera.rotation.x = orbit_pitch


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_action_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var input_dir := Input.get_vector("left", "right", "forward", "backward")
	var camera_basis := Basis(Vector3.UP, orbit_yaw)
	var direction := (camera_basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	var target_velocity := direction * SPEED
	velocity.x = move_toward(velocity.x, target_velocity.x, TURN_SPEED * delta)
	velocity.z = move_toward(velocity.z, target_velocity.z, TURN_SPEED * delta)

	move_and_slide()
