extends Node2D

@onready var note_spawner : noteRoot = $staticRailCenter
@export var isTestNoteSpawn : int = 1
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var note = note_spawner.spawnNodeWithoutAdding()
	print(note)
	note = note as Note
	(func(): add_child(note)).call_deferred()
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("spawn_note"):
		spawnNote()
	pass

func spawnNote():
	var noteTap = note_spawner.spawnNode(Note.NoteType.Tap)
	var noteSlide = note_spawner.spawnNode(Note.NoteType.Slide)
	var noteHold = note_spawner.spawnNode(Note.NoteType.Hold)
	
