extends Node2D
class_name LinearRailContainer


@export var linear_rail_scene : PackedScene


func on_linear_rail_init(rail_name : String, pos : Vector2, rot : float):
	if linear_rail_scene==null:
		push_error("linear_rail scene not found!")
		return
	var rail = linear_rail_scene.instantiate()
	rail.name = rail_name;
	rail.position = pos
	rail.rotation = rot
	add_child(rail)

	# this is so wrong but another signal just feels worse
	get_parent().event_handler.register_rail(rail)
	print("add a rail at ", pos, ", name = ", rail_name)

	
func on_linear_rail_destroy(rail_name : String):
	var rail = get_node_or_null(rail_name)
	if rail != null:
		rail.free()
		get_parent().event_handler.unregister_rail(rail_name)
	else:
		error_string(ERR_DOES_NOT_EXIST)
	
