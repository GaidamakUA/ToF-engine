extends GutTest


func test_native_read_and_directory_listing() -> void:
    var filesystem := FileSystem.new()
    var fixture_path := "res://tests/fixtures/board/headless_validation_map.json"

    assert_true(filesystem.file_exists(fixture_path))
    assert_true(filesystem.read_json_from_file(fixture_path) is Dictionary)
    assert_eq(filesystem.read_json_from_file("res://missing.json"), {})
    assert_has(filesystem.dir_list("res://tests/fixtures/board", true), "headless_validation_map.json")
    assert_has(filesystem.dir_list("res://tests/fixtures"), "board")
