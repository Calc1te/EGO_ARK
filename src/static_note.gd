extends Node2D
class_name Note

enum NoteType{
	Tap, #0
	Slide, #1
	Flick, #2
	HoldStart, #3
	HoldBody #4
}
const NO_HOLD_DURATION := -1
const MISS := 65535

const TEXTURE_TAP := "res://temp_assets/tap.png"
const TEXTURE_HOLD := "res://temp_assets/hold Background Removed.png"
const TEXTURE_FLICK := "res://temp_assets/lineRailRoot Background Removed.png"
const TEXTURE_HOLD_HEAD := "res://temp_assets/hold Background Removed.png"
const TEXTURE_HOLD_BODY := ""

var speed : float
var noteID : int
var durationTime : int # ms
var inTime : int # the time this note is supposed to be hit
var inJudgement : bool # if the note entered the Judgement area
var isActivate : bool # if the note is the "nearest to judgement line"
var isHoldActive : bool # active when holdStart is pressed
var holdDuration : float = 0
var hitTime : float

signal judgementEnabled(node : Node2D)
signal noteDestroyed(hitOffset : int, posY : int, holdDuration : int)
# for all note that isn't hold, hold duration should be -1(NO_HOLD_DURATION)
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
		NoteType.HoldBody:
			spriteNode.texture = load(TEXTURE_HOLD_BODY)
			
	holdDuration = 0
	pass # Replace with function body.


func _process(delta: float) -> void:
	if not isHoldActive && inJudgement:
		#print("Hold:", isHoldActive)
		#print("Judge", inJudgement)
		pass
	if not isHoldActive:
		position.y+=speed*delta
	else:
		#print("not Active")
		pass
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(_delta: float) -> void:

	_check_elimination()
	_check_input()
	
func _on_area_entered(area : Area2D):
	if area.name == "JudgeArea2D":
		emit_signal("judgementEnabled",self)
	

func _check_input() -> void:
	if not is_inside_tree():
		return
	if thisNoteType == NoteType.Tap:
		if Input.is_action_just_pressed("hit_center_track")&&isActivate&&inJudgement:
			hitTime = Time.get_ticks_msec()
			var offset = hitTime - inTime
			emit_signal("noteDestroyed", offset, position.y, NO_HOLD_DURATION)
			queue_free()
			return
	if thisNoteType == NoteType.HoldStart:
		hitTime = 0
		var offset : float
		if isActivate&&inJudgement:
			if Input.is_action_just_pressed("hit_center_track")&&isActivate&&inJudgement:
				isHoldActive = true
				#print(isHoldActive)
				hitTime = Time.get_ticks_msec()
				offset = hitTime - inTime
				holdDuration = 0
			if Input.is_action_pressed("hit_center_track")&&isActivate&&inJudgement:
				#print("hold")
				if isHoldActive:
					holdDuration = Time.get_ticks_msec() - hitTime
					
			if Input.is_action_just_released("hit_center_track")&&isActivate&&inJudgement:
				isHoldActive = false
				#print("release")
				var record_y : float = position.y
				emit_signal("noteDestroyed", offset, position.y, holdDuration)
				print(record_y)
				print(holdDuration)
			if holdDuration > durationTime:
				isHoldActive = false
			
	
		#return hitTime - inTime
		
func _check_elimination():
	if position.y > 575:
		spriteNode.modulate.a = 1.0 - (700-position.y)/125
	if position.y>=700:
		emit_signal("noteDestroyed", MISS, MISS, MISS)
		holdDuration = 0
		queue_free()
# ?????
