extends GutTest


func test_volume_and_msaa_conversions() -> void:
    var settings := SettingsService.new()

    for value: int in range(11):
        var expected: int = -80 if value == 0 else (value - 10) * 6
        assert_eq(settings._get_decibels(value), expected)
    assert_eq(settings._get_decibels(11), 0)

    assert_eq(settings._get_msaa(0), Viewport.MSAA_DISABLED)
    assert_eq(settings._get_msaa(2), Viewport.MSAA_2X)
    assert_eq(settings._get_msaa(4), Viewport.MSAA_4X)
    assert_eq(settings._get_msaa(8), Viewport.MSAA_8X)
    assert_eq(settings._get_msaa(3), Viewport.MSAA_DISABLED)
    settings.free()
