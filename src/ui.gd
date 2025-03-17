extends Control

@export var game_scene : PackedScene
@export var option_scene : PackedScene
# Called when the node enters the scene tree for the first time.


func _on_start_pressed() -> void:
	get_tree().change_scene_to_packed(game_scene)


func _on_options_pressed() -> void:
	get_tree().change_scene_to_packed(option_scene)
