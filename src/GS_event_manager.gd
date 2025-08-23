extends Node
class_name GSEvent

const BPM_CHANGE = 0
const INIT_RAIL = 1
const RELOCATE_RAIL = 2
const DESTROY_RAIL = 3

var upcoming_events = []
var active_events = []
var next_event_idx: int = 0

var rail_manager = {}

signal gameplay_BPM_change(bpm : float)
signal linear_rail_init(rail_name : String, pos : Vector2, rot : float)
signal linear_rail_destroy(rail_name : String)
# TODO : finish this before Aug20
# update at Aug22 : we are so back
func _ready() -> void:
    next_event_idx = 0


func _parse_raw_events(raw_events) -> void:
    for raw in raw_events:
        var e = {
            "type": raw[0],
            "time": raw[1],
            "params": raw[2]
        }
        upcoming_events.append(e)
    upcoming_events.sort_custom(_sort_by_event_time)

func _process_event(delta):
    if upcoming_events.size() == 0 and active_events.size() == 0:
        return

    var NOW = Time.get_ticks_msec()
    while next_event_idx < upcoming_events.size() && upcoming_events[next_event_idx]["time"] <= NOW:
        _parse_instant_event(upcoming_events[next_event_idx])
        next_event_idx += 1

func _sort_by_event_time(a, b) -> bool:
    return a["time"] < b["time"]

func _on_bpm_change():
    pass

func _parse_instant_event(event : Dictionary) -> void:
    match event["type"]:
        BPM_CHANGE:
            _change_bpm(event["params"])
        INIT_RAIL:
            _init_rail(event["params"])
        RELOCATE_RAIL:
            _parse_continuous_event(event)
        DESTROY_RAIL:
            pass



func _update_active_events():
    pass

func _init_rail(data):
    var rail_name = data[0]
    var pos = Vector2(data[1],data[2])
    var rot = deg_to_rad(data[3])
    emit_signal("linear_rail_init",rail_name,pos,rot)


func _destroy_rail(rail_name : String):
    emit_signal("linear_rail_destroy",rail_name)

func _parse_continuous_event(event):
    # later
    pass

func _change_bpm(bpm):
    emit_signal("gameplay_BPM_change", bpm)
        

func _add_rail_to_GS(root : Node2D):
    rail_manager[root.name] = root
    print("add rail to collection")

func _remove_rail_from_GS(rail_name : String):
    rail_manager[rail_name] = null    
