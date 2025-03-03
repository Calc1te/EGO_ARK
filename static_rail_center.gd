extends Node2D
class_name noteRoot
# The center of linerail, should also be the spawner of notes
@export var spawnheight : int = 600
@export var noteScene : PackedScene
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func spawnNode(note_type : Note.NoteType, speed : float, noteID : int):
	print("spawner called")
	#print(note_type)
	if noteScene==null:
		return
	var instance = noteScene.instantiate()
	instance.position.x = position.x
	instance.position.y = position.y-spawnheight
	instance.thisNoteType = note_type
	instance.speed = speed
	instance.noteID = noteID
	get_tree().root.add_child(instance)
	instance.connect("judgementEnabled", _on_judge_enabled)
	return instance
	
func spawnNodeWithoutAdding():
	if noteScene == null:
		return
	var instance = noteScene.instantiate()
	instance.position.x = position.x
	instance.position.y = position.y-spawnheight
	
	print(instance)
	return instance
	
func _on_judge_enabled(node : Node2D):
	print(node.noteID)
	print("received check")
