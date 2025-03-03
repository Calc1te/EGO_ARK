extends Node2D
class_name Note

enum NoteType{
	Tap, #0
	Slide, #1
	Flick, #2
	HoldStart, #3
	HoldEnd #4
}
var speed : float
var noteID : int
signal judgementEnabled(node : Node2D)
@export var thisNoteType : NoteType = NoteType.HoldStart
@onready var spriteNode = $Sprite2D
var tap = load("res://temp_assets/tap.png") as Texture2D
var hold = load("res://temp_assets/hold Background Removed.png") as Texture2D
var flick = load("res://temp_assets/lineRailRoot Background Removed.png") as Texture2D
var holdHead = load("res://temp_assets/hold Background Removed.png") as Texture2D
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Area2D.connect("area_entered", _on_area_entered)
	match thisNoteType:
		NoteType.Tap:
			spriteNode.texture = tap
		NoteType.Slide: 
			spriteNode.texture = hold
		NoteType.Flick:
			spriteNode.texture = flick
		NoteType.HoldStart:
			spriteNode.texture = holdHead
		NoteType.HoldEnd:
			pass
	print(noteID)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	position.y+=speed
	pass
func _on_area_entered(area : Area2D):
	if area.name == "JudgeArea2D":
		print("area check")
		emit_signal("judgementEnabled",self)
	pass
