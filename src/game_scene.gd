extends Node2D
class_name gameScene
@onready var note_spawner : noteRoot = $staticRailCenter
@export var spawnHeight :int = 800
@export var isTestNoteSpawn : int = 1
@export var globalSpeed : float = 10
@onready var noteID : int = 0
##test variable
@export var inFrame : int = 360
##
var frame : int
@onready var noteSpawnFrame : int = inFrame - (abs(note_spawner.position.y-spawnHeight)/globalSpeed)
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	frame = 0
	note_spawner.spawnheight = spawnHeight
	if isTestNoteSpawn:
		var note = note_spawner.spawnNodeWithoutAdding()
		print(note)
		note = note as Note
		(func(): add_child(note)).call_deferred()
		return
	


func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("spawn_note"):
		spawnNote()
	if frame == noteSpawnFrame:
		spawnNote()
	frame+=1
	print(frame)

func spawnNote():
	var note = note_spawner.spawnNode(Note.NoteType.HoldStart, globalSpeed, noteID, inFrame)
	noteID+=1
	
