extends GutTest


func test_native_pagination_slices_and_clamps() -> void:
    var maps := MapManagerService.new()
    maps.skirmish["gamma"] = {}
    maps.skirmish["alpha"] = {}
    maps.skirmish["beta"] = {}

    assert_eq(maps.get_pages_count(maps.LIST_STOCK, 2), 2)
    assert_eq(maps.get_maps_page(maps.LIST_STOCK, 1, 2), ["gamma"])
    assert_true(maps.get_maps_page(maps.LIST_STOCK, 2, 2).is_empty())
    maps.free()

    var listing := StoryListingPanel.new()
    listing._page_size = 2
    assert_eq(listing._normalize_page_no(5, 99), [2, true])
    assert_eq(listing._slice_page(["a", "b", "c", "d", "e"], 99), ["e"])
    listing.free()
