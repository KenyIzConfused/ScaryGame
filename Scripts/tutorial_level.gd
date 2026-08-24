extends Node3D
@onready var interact: Label3D = $door/Interact
@onready var mesh_instance_3d: MeshInstance3D = $door/MeshInstance3D
var near_door := false
var door_open := false
var original_position: Vector3


func _ready() -> void:
	interact.visible = false
	original_position = mesh_instance_3d.position


func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("interact") and near_door:
		door_open = not door_open
		if door_open:
			mesh_instance_3d.rotation_degrees.y = 90
			mesh_instance_3d.position = original_position + Vector3(-0.5, 0, 0)
		else:
			mesh_instance_3d.rotation_degrees.y = 0
			mesh_instance_3d.position = original_position


func _on_door_body_entered(body: Node3D) -> void:
	interact.visible = true
	near_door = true


func _on_door_body_exited(body: Node3D) -> void:
	interact.visible = false
	near_door = false
