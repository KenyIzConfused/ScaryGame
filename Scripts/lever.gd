extends Area3D

@onready var lever: MultiMeshInstance3D = $Lever
@onready var on_label: Label3D = get_node_or_null("ONlabel")
@onready var off_label: Label3D = get_node_or_null("OFFlabel")
@onready var lights: Node3D = get_node_or_null("../lights")

const COLOR_GREEN := Color(0.3, 1.0, 0.3, 1)
const COLOR_RED := Color(1.0, 0.2, 0.2, 1)
const COLOR_WHITE := Color(1.0, 1.0, 1.0, 1)

var is_player_near := false
var is_lever_on := false
var original_rotation: float
var original_position: Vector3
const ROTATION_OFFSET := -70.0
const POSITION_OFFSET := Vector3(-0.3, 0.42, 0)


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	original_rotation = lever.rotation_degrees.z
	original_position = lever.position
	lever.rotation_degrees.z = original_rotation
	_update_labels()
	_toggle_lights()


func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("interact") and is_player_near:
		is_lever_on = not is_lever_on
		var target_rotation := original_rotation + ROTATION_OFFSET if is_lever_on else original_rotation
		var target_position := original_position + POSITION_OFFSET if is_lever_on else original_position
		_animate(target_rotation, target_position)
		_update_labels()
		_toggle_lights()


func _animate(target_rotation: float, target_position: Vector3) -> void:
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(lever, "rotation_degrees:z", target_rotation, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(lever, "position", target_position, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _update_labels() -> void:
	if on_label and off_label:
		if is_lever_on:
			on_label.modulate = COLOR_WHITE
			off_label.modulate = COLOR_RED
		else:
			on_label.modulate = COLOR_GREEN
			off_label.modulate = COLOR_WHITE


func _toggle_lights() -> void:
	if lights:
		lights.visible = not is_lever_on


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		is_player_near = true


func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		is_player_near = false
