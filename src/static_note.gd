extends Node2D
class_name StatNote

enum NoteType { Tap, Slide, Flick, HoldStart, HoldBody }

const NO_HOLD_DURATION := -1
const MISS := 65535
const ELIMINATION_START := 575
const ELIMINATION_END := 700

const TEXTURE_TAP        := "res://temp_assets/tap.png"
const TEXTURE_HOLD       := "res://temp_assets/hold Background Removed.png"
const TEXTURE_FLICK      := "res://temp_assets/lineRailRoot Background Removed.png"
const TEXTURE_HOLD_HEAD  := "res://temp_assets/hold Background Removed.png"
const TEXTURE_HOLD_BODY  := "res://temp_assets/hold_BODY.png"


# ────────────────────────── 状态量 ──────────────────────────
var speed           : float
var noteID          : int
var durationTime    : int          # ms hold的理论持续时间
var inTime          : int          # 音符生成的时间，会在计算判定时被referenceOffset抵消
var inJudgement     : bool = false # 是否进入判定区
var isActivate     	: bool = false # 是否是“最近的”可判定音符
var isHoldActive   	: bool = false # Hold 当前是否处于按住状态

var holdDuration   	: int  = 0     # 每实例独立
var holdLength 		: int		   # 用于生成HoldBody长度
var hitTime        	: int  = -1    # 开始按下的绝对时间

# 用于实时计算 Hold 时长
var _hold_start_time : int = -1   # 仅 HoldStart 使用

signal judgementEnabled(node : Node2D)
signal noteDestroyed(hitOffset : int, posY : int, holdDuration : int)

@export var thisNoteType : NoteType = NoteType.HoldStart
@onready var spriteNode : AnimatedSprite2D = $Sprite2D
@onready var holdBodyContainer : Node2D = $holdBodyContainer
@export var isAutoPlay := false
var thisNoteRoot : Node2D =  null
# ────────────────────────── 生命周期 ──────────────────────────
func _ready() -> void:
	$Area2D.connect("area_entered", _on_area_entered)
	_setup_texture()
	thisNoteRoot = get_parent()
	_reset_hold_state()
	spriteNode.z_index = 10
	if thisNoteType == NoteType.HoldStart:
		_draw_hold_bodies()

func _physics_process(_delta: float) -> void:
	_move_note(_delta)
	_check_elimination()
	_check_input()          
	_update_hold_duration()

# ────────────────────────── 内部逻辑 ──────────────────────────
func _setup_texture() -> void:
	match thisNoteType:
		NoteType.Tap:       spriteNode.animation = "tap"
		NoteType.Slide:		spriteNode.animation = "slide"
		NoteType.Flick:		spriteNode.animation = "flick"
		NoteType.HoldStart:	spriteNode.animation = "holdStart"
	spriteNode.play()
		

func _reset_hold_state() -> void: 
	isHoldActive     = false
	holdDuration     = 0
	hitTime          = -1
	_hold_start_time = -1

func _move_note(delta: float) -> void:
	if !isHoldActive:
		position.y += speed * delta
	if isHoldActive:
		holdBodyContainer.position.y += speed * delta * _get_angle()[0] 


func _get_angle():
	# no longer use
	var angle : float = thisNoteRoot.rotation
	return [sin(angle), cos(angle)]

func _on_area_entered(area : Area2D) -> void:
	if area.name == "JudgeArea2D":
		inJudgement = true
		emit_signal("judgementEnabled", self)

	

func _check_input() -> void:

	if !is_inside_tree(): return
	if !isActivate || !inJudgement: return

	match thisNoteType:
		NoteType.Tap:
			if Input.is_action_just_pressed("hit_center_track"):
				_tap_hit()
		NoteType.HoldStart:
			if !isHoldActive and Input.is_action_just_pressed("hit_center_track"):
				_start_hold()
			elif isHoldActive and Input.is_action_just_released("hit_center_track"):
				_end_hold()
		NoteType.Slide:
			if Input.is_action_just_pressed("hit_center_track")||Input.is_action_pressed("hit_center_track"):
				_slide_hit()

func _tap_hit() -> void:
	hitTime = Time.get_ticks_msec()
	var offset := hitTime - inTime
	emit_signal("noteDestroyed", offset, position.y, NO_HOLD_DURATION)
	queue_free()

# ────────────────────────── Hold ─────────────────────────────────
func _draw_hold_bodies() -> void:
	var yOffset = 0
	for i in range(durationTime):
		var holdBodyClone = Sprite2D.new()
		holdBodyClone.texture = load(TEXTURE_HOLD_BODY)
		holdBodyClone.position = Vector2(0,yOffset)
		holdBodyClone.z_index = 0
		holdBodyContainer.add_child(holdBodyClone)
		yOffset -= 1

func _start_hold() -> void:
	isHoldActive     = true
	_hold_start_time = Time.get_ticks_msec()
	hitTime          = _hold_start_time   # 记录首击时刻

func _update_hold_duration() -> void:
	var early_release := !isAutoPlay && !Input.is_action_pressed("hit_center_track")
	if isHoldActive:
		holdDuration = Time.get_ticks_msec() - _hold_start_time
		if holdDuration >= (durationTime+50) or early_release:
			_end_hold()

func _end_hold() -> void:
	isHoldActive = false
	var offset := hitTime - inTime  # 命中偏差仍用首击时刻计算
	# print('ref:',offset,',',abs(holdDuration-durationTime))
	emit_signal("noteDestroyed", offset, position.y, abs(holdDuration-durationTime))
	queue_free()


# ────────────────────────── Slide ────────────────────────────────
func _slide_hit() -> void:
	emit_signal("noteDestroyed", 1000, position.y, NO_HOLD_DURATION)
	queue_free()
	 

# ────────────────────────── Miss & Fade Out ──────────────────────────
func _check_elimination() -> void:
	if position.y > 575.0:
		spriteNode.modulate.a = 1.0 - (700.0 - position.y) / 125.0
	if position.y >= 700.0:
		emit_signal("noteDestroyed", MISS, MISS, MISS)

		queue_free()
