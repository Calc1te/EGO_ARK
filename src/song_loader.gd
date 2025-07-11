extends Node
class_name SongLoader
signal song_loaded(data : SongData)

func load_song(path : String):
    var file = FileAccess.open(path, FileAccess.READ)
    if file.get_error() != OK:
        push_error("[ChartLoader] Cannot open chart file: %s" % path)
        return
    var content = file.get_as_text()
    file.close()
    emit_signal("song_loaded",_to_SongData(JSON.parse_string(content)))
    
func _to_SongData(data : Dictionary) -> SongData:
    var song = SongData.new()
    song.songID = data["songID"]
    song.song_name = data["song_name"]
    song.artist = data["artist"]
    song.cover = load(data["cover"])
    song.wav_path = data["wav_path"]
    song.preview_start = data["preview_start"]
    song.preview_end = data["preview_end"]
    song.chart_id_array = data["chart_id_array"]

    return song

    
    