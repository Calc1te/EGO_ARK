extends Node2D
class_name gameScene
@onready var note_spawner : noteRoot = $staticRailCenter
@export var isTestNoteSpawn : int = 1
@export var globalSpeed : float = 10
@onready var noteID : int = 0;
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if isTestNoteSpawn:
		var note = note_spawner.spawnNodeWithoutAdding()
		print(note)
		note = note as Note
		(func(): add_child(note)).call_deferred()
		return
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("spawn_note"):
		spawnNote()
	pass

func spawnNote():
	var noteTap = note_spawner.spawnNode(Note.NoteType.HoldStart, globalSpeed, noteID)
	noteID+=1
	
