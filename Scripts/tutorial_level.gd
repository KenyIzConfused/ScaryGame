extends Node3D
@onready var interact: Label3D = $door/Interact
@onready var mesh_instance_3d: MeshInstance3D = $door/MeshInstance3D
var near_door := false
var door_open := false
var original_position: Vector3
var original_rotation: float


func _ready() -> void:
	interact.visible = false
	original_position = mesh_instance_3d.position
	original_rotation = mesh_instance_3d.rotation_degrees.y


func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("interact") and near_door:
		door_open = not door_open
		var target_rotation := 90.0 if door_open else original_rotation
		var target_position := original_position + Vector3(-0.5, 0, 0.3) if door_open else original_position
		_animate_door(target_rotation, target_position)


func _animate_door(target_rotation: float, target_position: Vector3) -> void:
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(mesh_instance_3d, "rotation_degrees:y", target_rotation, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(mesh_instance_3d, "position", target_position, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _on_door_body_entered(body: Node3D) -> void:
	interact.visible = true
	near_door = true


func _on_door_body_exited(body: Node3D) -> void:
	interact.visible = false
	near_door = false


func _on_fuse_box_body_entered(body: Node3D) -> void:
	pass # Replace with function body.


func _on_fuse_box_body_exited(body: Node3D) -> void:
	pass # Replace with function body.
