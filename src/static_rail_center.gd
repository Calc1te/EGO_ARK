extends Node2D
class_name noteRoot
# The center of linerail, should also be the spawner of notes
var spawnheight : int
@export var noteScene : PackedScene
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func spawnNode(note_type : Note.NoteType, speed : float, noteID : int, inTime : int):
	print("spawner called")
	speed = 200*speed
	if noteScene==null:
		return
	var instance = noteScene.instantiate()
	# 此处的position是相对（判定原点的）坐标系
	#instance.position.x = position.x
	instance.position.y = -spawnheight
	instance.thisNoteType = note_type
	instance.speed = speed
	instance.noteID = noteID
	instance.inTime = Time.get_ticks_msec()
	add_child(instance)
	instance.connect("judgementEnabled", _on_judge_enabled)
	return instance
	
#func spawnNodeWithoutAdding():
	#if noteScene == null:
		#return
	#var instance = noteScene.instantiate()
	#instance.position.x = position.x
	#instance.position.y = position.y-spawnheight
	#
	#print(instance)
	#return instance
	
func _on_judge_enabled(node : Node2D):
	print(node.noteID)
	node.inJudgement = true
	print("received check")
