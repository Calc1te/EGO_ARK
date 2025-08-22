extends Node2D
class_name linearRailContainer


@export var linear_rail_scene : PackedScene


func on_linear_rail_init(rail_name : String, pos : Vector2, rot : float):
    if linear_rail_scene==null:
        push_error("linear_rail scene not found!")
        return
    var rail = linear_rail_scene.instantiate()
    rail.this_root_name = rail_name;
    rail.position = pos
    rail.rotation = rot

    # this is so wrong but another signal just feels worse
    get_parent().event_handler._add_rail_to_GS(rail)

    
