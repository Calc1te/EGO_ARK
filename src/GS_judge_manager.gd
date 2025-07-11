extends Node
class_name GSJudge

signal combo_update(combo : int, score : int)

###### Customized Options loaded before game start #####
@export var playerOffset : float = 0
@export var globalSpeed : float = 10
@export var referenceOffset : float = 0


##### Judgement Constants ##### DT for central track #####
const DT_CRIT_PERFECT = 26
const DT_PERFECT = 40
const DT_GOOD = 60
const DT_BAD = 125
##### SD for semisphere tracks #####
const SD_CRIT_PERFECT = 26
const SD_PERFECT = 40
const SD_GOOD = 60
const SD_BAD = 125
##### hold and flick factor #####
const HOLD_SCALING = 0.5
const FLICK_SCALING = 0.9

###### Score and Accuracy Variables ######
var singleNoteScore : float
var current_score : int = 0
var max_combo : int = 0
var current_combo : int = 0
var total_notes : int = 0
var notes_hit : int = 0
var crit_perfect_count : int = 0
var perfect_count : int = 0
var good_count : int = 0
var bad_count : int = 0
var miss_count : int = 0


func calculate_acc(acc : int, holdError : int):
    print(acc, ",", holdError)
    #acc是按照毫秒计算不是帧数计算
    if acc == 1000 && holdError == -1:
        print("slide Perfect")
        add_score_and_combo("perfect")
        return
    var hitError : int = abs(acc - referenceOffset + playerOffset)
    print(acc - referenceOffset + playerOffset)
    if holdError == -1:
        if hitError > DT_BAD:
            print("miss")
            add_score_and_combo("miss")
        elif hitError < DT_BAD && hitError > DT_GOOD:
            print("bad")
            add_score_and_combo("bad")
        elif hitError < DT_GOOD && hitError > DT_PERFECT:
            print("good")
            add_score_and_combo("good")
        elif hitError < DT_PERFECT && hitError > DT_CRIT_PERFECT:
            print("perfect")
            add_score_and_combo("perfect")
        elif hitError < DT_CRIT_PERFECT:
            print("crit perfect")
            add_score_and_combo("crit_perfect")

    else:
        hitError = int(hitError+holdError*HOLD_SCALING)
        print(hitError)
        if hitError > DT_BAD:
            print("miss")
            add_score_and_combo("miss")
        elif hitError < DT_BAD && hitError > DT_GOOD:
            print("bad")
            add_score_and_combo("bad")
        elif hitError < DT_GOOD && hitError > DT_PERFECT:
            print("good")
            add_score_and_combo("good")
        elif hitError < DT_PERFECT && hitError > DT_CRIT_PERFECT:
            print("perfect")
            add_score_and_combo("perfect")
        elif hitError < DT_CRIT_PERFECT:
            print("crit perfect")
            add_score_and_combo("crit_perfect")


func add_score_and_combo(judgement: String):
    
    match judgement:
        "crit_perfect":
            current_score += int(singleNoteScore * 1.0)
            current_combo += 1
            crit_perfect_count += 1
            notes_hit += 1
        "perfect":
            current_score += int(singleNoteScore * 1.0)
            current_combo += 1
            perfect_count += 1
            notes_hit += 1
        "good":
            current_score += int(singleNoteScore * 0.7)
            current_combo += 1
            good_count += 1
            notes_hit += 1
        "bad":
            current_score += int(singleNoteScore * 0.1)
            current_combo = 0
            bad_count += 1
            notes_hit += 1
        "miss":
            current_combo = 0
            miss_count += 1
    
    # Update max combo
    if current_combo > max_combo:
        max_combo = current_combo

    emit_signal('combo_update', current_combo, round(current_score))

    
func get_accuracy() -> float:
    if total_notes == 0:
        return 0.0
    return (1*crit_perfect_count+.9*perfect_count+.3*good_count)/total_notes


func score_init() -> void:
    singleNoteScore = 100000.0/total_notes
