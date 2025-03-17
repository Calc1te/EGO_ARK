extends Control

@onready var offsetLabel = $Offset
@onready var speedLabel = $Speed
@onready var demoPlay = $gameScene
@onready var offsetSlider = $OffsetAdjust
@onready var speedSlider = $SpeedAdjust
@onready var offsetValue : float
@onready var speedValue : float

@export var mainMenu : PackedScene

func _ready() -> void:
	#print("current offset value: ", offsetValue)
	offsetValue = demoPlay.playerOffset
	speedValue = demoPlay.globalSpeed
	offsetLabel.text = str("offset: ", offsetValue)
	speedLabel.text = str("speed: ", speedValue)
	demoPlay.isDemoPlay = true
	offsetSlider.value = offsetValue
	speedSlider.value = speedValue

func _on_offset_adjust_value_changed(value: float) -> void:
	offsetValue = value
	offsetLabel.text = str("offset: ",offsetValue)
	demoPlay.playerOffset = value


func _on_save_pressed() -> void:
	pass # Replace with function body.


func _on_speed_adjust_value_changed(value: float) -> void:
	speedValue = value
	speedLabel.text = str("speed: ", speedValue)
	demoPlay.globalSpeed = value
	demoPlay.updateSpeed()
	


func _on_back_pressed() -> void:
	print("back")
	get_tree().change_scene_to_packed(mainMenu)
