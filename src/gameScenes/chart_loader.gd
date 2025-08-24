extends Node2D
class_name ChartLoader

signal chart_loaded(data : Dictionary, events : Array, notes : Array)

func load_chart(path : String):
	var file = FileAccess.open(path, FileAccess.READ)
	if file.get_error() != OK:
		push_error("[ChartLoader] Cannot open chart file: %s" % path)
		return
	var section : String = ""
	var general := {}
	var events := []
	var notes := []
	while not file.eof_reached():
		var line = file.get_line().strip_edges()

		if line == "" || line.begins_with("#"):
			continue

		if not line.begins_with("-") and line.ends_with(":"):
			section = line.substr(0, line.length() - 1)
			continue

		match section:
			"General":
				var parts = line.split(":", false, 1)
				var key = parts[0].strip_edges()
				var raw = parts[1].split("#")[0].strip_edges()
				if raw.begins_with('"') and raw.ends_with('"'):
					general[key] = raw.substr(1, raw.length() - 2)
				elif raw.begins_with("[") and raw.ends_with("]"):
					var arr = []
					for item in raw.substr(1, raw.length() - 2).split(","):
						arr.append(int(item.strip_edges()))
					general[key] = arr
				elif raw == "true" or raw == "false":
					general[key] = (raw == "true")
				elif raw.find('.') != -1:
					general[key] = float(raw)
				else:
					general[key] = int(raw)

			"Events":
				if line.begins_with("-"):
					var json_text = line.substr(1).split("#")[0].strip_edges()
					var res = JSON.parse_string(json_text)
					if res:
						events.append(res)
					else:
						push_error("[ChartLoader] Failed parsing event: %s" % json_text)

			"Notes":
				if line.begins_with("-"):
					var json_text = line.substr(1).split("#")[0].strip_edges()
					var res = JSON.parse_string(json_text)
					if res:
						notes.append(res)
					else:
						push_error("[ChartLoader] Failed parsing note: %s" % json_text)

	file.close()
	# print(general)
	# print(events)
	# print(notes)
	emit_signal("chart_loaded", general, events, notes)
		
