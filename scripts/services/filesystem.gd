class_name FileSystem

func _resolve_dir_path(path: String) -> String:
    var executable_relative_path: String = OS.get_executable_path().get_base_dir().path_join(path)
    return executable_relative_path if DirAccess.dir_exists_absolute(executable_relative_path) else path

func file_exists(filepath: String) -> bool:
    return FileAccess.file_exists(filepath)

func dir_exists(dirpath: String) -> bool:
    return DirAccess.dir_exists_absolute(self._resolve_dir_path(dirpath))

func read_json_from_file(filepath: String) -> Variant:
    if not FileAccess.file_exists(filepath):
        return {}

    var content: Variant = JSON.parse_string(FileAccess.get_file_as_string(filepath))
    return content if content != null else {}

func write_data_as_json_to_file(filepath: String, data: Variant) -> void:
    var file: FileAccess = FileAccess.open(filepath, FileAccess.WRITE)
    assert(file != null)
    file.store_string(JSON.stringify(data, "    ", true))

func dir_list(dirpath: String, files: bool = false) -> Array[String]:
    var resolved_path: String = self._resolve_dir_path(dirpath)
    if not DirAccess.dir_exists_absolute(resolved_path):
        return []

    var listing: Array[String] = []
    listing.assign(DirAccess.get_files_at(resolved_path) if files else DirAccess.get_directories_at(resolved_path))
    return listing
