extends Node2D
class_name Note
enum NoteType{
	Tap,
	Slide,
	Flick,
	Hold
}
@export var speed : float = 1;
@export var thisNoteType : NoteType
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	position.y+=speed
	pass
