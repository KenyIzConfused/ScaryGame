extends CharacterBody3D

const SPEED := 3.5
const ATTACK_RANGE := 2.5
const SEARCH_DURATION := 10.0
const ARRIVE_DISTANCE := 1.0
const LOS_LOST_DELAY := 0.5
const ROTATION_SPEED := 8.0
const SEARCH_SCAN_DURATION := 2.0
const VIEW_ANGLE := deg_to_rad(90.0)
const VIEW_DISTANCE := 10.0

enum State { IDLE, PATROL, CHASE, ATTACK, SEARCH }

@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var detection_area: Area3D = $Area3D
@onready var raycast: RayCast3D = $RayCast3D
@onready var mesh: MeshInstance3D = $MeshInstance3D

var state := State.PATROL
var player: CharacterBody3D
var patrol_points: Array[Marker3D] = []
var current_patrol_index := 0
var last_known_player_pos := Vector3.ZERO
var search_timer := 0.0
var player_in_range := false
var los_lost_timer := 0.0
var idle_timer := 0.0
var is_arriving := false
var arrival_target_angle := 0.0
var search_phase := 0
var search_scan_timer := 0.0
var scan_angle := 0.0
var scan_direction := 1.0
var search_base_angle := 0.0

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	
	for child in get_children():
		if child is Marker3D:
			patrol_points.append(child)
	
	if patrol_points.is_empty():
		state = State.IDLE
		idle_timer = 2.0
	else:
		state = State.PATROL
		nav_agent.target_position = patrol_points[0].global_position
	
	nav_agent.path_desired_distance = ARRIVE_DISTANCE
	nav_agent.target_desired_distance = ARRIVE_DISTANCE
	raycast.add_exception(self)

func _physics_process(delta: float) -> void:
	match state:
		State.IDLE:
			update_idle(delta)
		State.PATROL:
			update_patrol(delta)
		State.CHASE:
			update_chase(delta)
		State.ATTACK:
			update_attack(delta)
		State.SEARCH:
			update_search(delta)
	
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	move_and_slide()

func update_idle(delta: float) -> void:
	idle_timer -= delta
	velocity.x = move_toward(velocity.x, 0, SPEED)
	velocity.z = move_toward(velocity.z, 0, SPEED)
	if idle_timer <= 0:
		if not patrol_points.is_empty():
			state = State.PATROL
			nav_agent.target_position = patrol_points[0].global_position
		else:
			idle_timer = 2.0

func update_patrol(delta: float) -> void:
	if patrol_points.is_empty():
		state = State.IDLE
		idle_timer = 2.0
		return
	
	if player_in_range and can_see_player():
		last_known_player_pos = player.global_position
		state = State.CHASE
		return
	
	var next_pos = nav_agent.get_next_path_position()
	var direction = (next_pos - global_position)
	direction.y = 0
	
	var path = nav_agent.get_current_navigation_path()
	if path.size() > 0 and global_position.distance_to(path[-1]) <= ARRIVE_DISTANCE and not is_arriving:
		is_arriving = true
		var next_marker = patrol_points[(current_patrol_index + 1) % patrol_points.size()]
		var look_dir = (next_marker.global_position - global_position).normalized()
		arrival_target_angle = atan2(look_dir.x, look_dir.z)
	
	if is_arriving:
		rotation.y = lerp_angle(rotation.y, arrival_target_angle, ROTATION_SPEED * delta)
		
		if abs(angle_difference(rotation.y, arrival_target_angle)) < 0.05:
			is_arriving = false
			current_patrol_index = (current_patrol_index + 1) % patrol_points.size()
			nav_agent.target_position = patrol_points[current_patrol_index].global_position
	else:
		if direction.length() > 0.1:
			var move_dir = direction.normalized()
			velocity.x = move_dir.x * SPEED
			velocity.z = move_dir.z * SPEED
			
			var target_angle = atan2(move_dir.x, move_dir.z)
			var current_angle = rotation.y
			rotation.y = lerp_angle(current_angle, target_angle, ROTATION_SPEED * delta)
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
			velocity.z = move_toward(velocity.z, 0, SPEED)

func update_chase(delta: float) -> void:
	if not player_in_range:
		last_known_player_pos = player.global_position if player else global_position
		state = State.SEARCH
		search_timer = SEARCH_DURATION
		search_phase = 0
		search_scan_timer = SEARCH_SCAN_DURATION
		scan_angle = 0.0
		scan_direction = 1.0
		search_base_angle = rotation.y
		return
	
	if can_see_player():
		last_known_player_pos = player.global_position
		nav_agent.target_position = player.global_position
		los_lost_timer = LOS_LOST_DELAY
	else:
		los_lost_timer -= delta
		if los_lost_timer <= 0:
			last_known_player_pos = player.global_position if player else global_position
			state = State.SEARCH
			search_timer = SEARCH_DURATION
			search_phase = 0
			search_scan_timer = SEARCH_SCAN_DURATION
			scan_angle = 0.0
			scan_direction = 1.0
			search_base_angle = rotation.y
			return
	
	if global_position.distance_to(player.global_position) <= ATTACK_RANGE:
		state = State.ATTACK
		return
	
	var next_pos = nav_agent.get_next_path_position()
	var direction = (next_pos - global_position)
	direction.y = 0
	if direction.length() > 0.1:
		var move_dir = direction.normalized()
		velocity.x = move_dir.x * SPEED
		velocity.z = move_dir.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

func update_attack(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0, SPEED)
	velocity.z = move_toward(velocity.z, 0, SPEED)
	
	if player and global_position.distance_to(player.global_position) > ATTACK_RANGE:
		state = State.CHASE

func update_search(delta: float) -> void:
	if player_in_range and can_see_player():
		state = State.CHASE
		return
	
	if search_phase == 0:
		scan_angle += ROTATION_SPEED * 0.8 * scan_direction * delta
		if scan_angle > PI * 0.6:
			scan_direction = -1
		elif scan_angle < -PI * 0.6:
			scan_direction = 1
		
		rotation.y = search_base_angle + scan_angle
		search_scan_timer -= delta
		search_timer -= delta
		
		if search_scan_timer <= 0:
			search_phase = 1
			nav_agent.target_position = last_known_player_pos
	elif search_phase == 1:
		search_timer -= delta
		if search_timer <= 0:
			if not patrol_points.is_empty():
				state = State.PATROL
				nav_agent.target_position = patrol_points[current_patrol_index].global_position
			else:
				state = State.IDLE
				idle_timer = 2.0
			return
		
		nav_agent.target_position = last_known_player_pos
		
		var next_pos = nav_agent.get_next_path_position()
		var direction = (next_pos - global_position)
		direction.y = 0
		if direction.length() > 0.1:
			var move_dir = direction.normalized()
			velocity.x = move_dir.x * SPEED * 0.5
			velocity.z = move_dir.z * SPEED * 0.5
			
			var target_angle = atan2(move_dir.x, move_dir.z)
			rotation.y = lerp_angle(rotation.y, target_angle, ROTATION_SPEED * delta)
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
			velocity.z = move_toward(velocity.z, 0, SPEED)

func can_see_player() -> bool:
	if not player:
		return false
	
	var to_player = player.global_position - global_position
	var distance = to_player.length()
	
	if distance > VIEW_DISTANCE:
		return false
	
	var direction = to_player.normalized()
	var forward = -global_transform.basis.z.normalized()
	forward.y = 0
	forward = forward.normalized()
	direction.y = 0
	direction = direction.normalized()
	
	var angle = acos(forward.dot(direction))
	if angle > VIEW_ANGLE * 0.5:
		return false
	
	raycast.target_position = raycast.to_local(player.global_position)
	raycast.force_raycast_update()
	
	if raycast.is_colliding():
		var collider = raycast.get_collider()
		if collider == player or (collider is CharacterBody3D and collider.is_in_group("player")):
			return true
		return false
	
	return true

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_in_range = true

func _on_area_3d_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_in_range = false
