extends Node2D
class_name Note

enum NoteType{
	Tap, #0
	Slide, #1
	Flick, #2
	HoldStart, #3
	HoldEnd #4
}

const TEXTURE_TAP := "res://temp_assets/tap.png"
const TEXTURE_HOLD := "res://temp_assets/hold Background Removed.png"
const TEXTURE_FLICK := "res://temp_assets/lineRailRoot Background Removed.png"
const TEXTURE_HOLD_HEAD := "res://temp_assets/hold Background Removed.png"

var speed : float
var noteID : int
var inTime : int # the time this note is supposed to be hit
var inJudgement : bool # if the note entered the Judgement area
var isActivate : bool # if the note is the "nearest to judgement line"

signal judgementEnabled(node : Node2D)
signal noteDestroyed(hitoffset : int)
@export var thisNoteType : NoteType = NoteType.HoldStart

@onready var spriteNode = $Sprite2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Area2D.connect("area_entered", _on_area_entered)
	match thisNoteType:
		NoteType.Tap:
			spriteNode.texture = load(TEXTURE_TAP)
		NoteType.Slide: 
			spriteNode.texture = load(TEXTURE_HOLD)
		NoteType.Flick:
			spriteNode.texture = load(TEXTURE_FLICK)
		NoteType.HoldStart:
			spriteNode.texture = load(TEXTURE_HOLD_HEAD)
		NoteType.HoldEnd:
			pass
	pass # Replace with function body.


func _process(delta: float) -> void:
	position.y+=speed*delta

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:

	_check_elimination()
	_check_input()
	
func _on_area_entered(area : Area2D):
	if area.name == "JudgeArea2D":
		emit_signal("judgementEnabled",self)
	
func _check_input() -> void:
	if Input.is_action_just_pressed("hit_center_track")&&isActivate&&inJudgement:
		var hitTime = Time.get_ticks_msec()
		var offset = hitTime - inTime
		emit_signal("noteDestroyed", offset)
		queue_free()
		#return hitTime - inTime
		
func _check_elimination():
	if position.y > 575:
		spriteNode.modulate.a = 1.0 - (700-position.y)/125
	if position.y>=700:
		emit_signal("noteDestroyed", 65535)
		queue_free()
