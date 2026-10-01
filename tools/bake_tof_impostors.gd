extends SceneTree

const CAMERA_SCENE: PackedScene = preload("res://scenes/map_editor/tile_cam.tscn")

const RESOURCE_PREFIXES: PackedStringArray = [
    "res://resources/terrain/",
    "res://resources/decoration/",
    "res://resources/frame/",
]
const OUTPUT_ROOT: String = "res://assets/impostors/tof"
const ROTATIONS: PackedInt32Array = [0, 90, 180, 270]
const PIXELS_PER_UNIT: float = 64.0
const PIXEL_SIZE: float = 1.0 / PIXELS_PER_UNIT
const CAPTURE_SIZE := Vector2i(4096, 4096)
const CELL_PADDING: int = 8
const MIN_SHADOW_CONTRAST: float = 0.1
const SHADOW_OPACITY: float = 0.5

var _viewport: SubViewport
var _camera_rig: Node3D
var _camera: Camera3D
var _shadow_receiver: MeshInstance3D
var _preview_factory := TileView.new()
var _failures: int = 0


func _initialize() -> void:
    self.call_deferred("_run")


func _run() -> void:
    self._create_capture_viewport()

    var paths: PackedStringArray = self._collect_resource_paths()
    var requested_path: String = self._requested_resource_path()
    if not requested_path.is_empty():
        paths = PackedStringArray([requested_path])

    print("Baking %d TOF impostors at %d px/unit" % [paths.size(), int(self.PIXELS_PER_UNIT)])
    for index: int in paths.size():
        await self._bake_resource(paths[index], index + 1, paths.size())

    self._preview_factory.free()
    self._viewport.free()
    if self._failures == 0:
        print("TOF impostor bake complete")
    else:
        push_error("TOF impostor bake failed for %d resource(s)" % self._failures)
    self.quit(self._failures)


func _create_capture_viewport() -> void:
    self._viewport = SubViewport.new()
    self._viewport.name = "TOFImpostorCapture"
    self._viewport.size = self.CAPTURE_SIZE
    self._viewport.own_world_3d = true
    self._viewport.transparent_bg = true
    self._viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
    self.root.add_child(self._viewport)

    self._camera_rig = self.CAMERA_SCENE.instantiate() as Node3D
    self._viewport.add_child(self._camera_rig)
    self._camera = self._camera_rig.get_node("pivot/arm/lens") as Camera3D
    self._camera.size = float(self.CAPTURE_SIZE.y) / self.PIXELS_PER_UNIT
    self._camera.position.z = 64.0
    self._camera.far = 256.0

    var light: DirectionalLight3D = self._camera_rig.get_node("DirectionalLight3D") as DirectionalLight3D
    light.shadow_enabled = true

    self._shadow_receiver = MeshInstance3D.new()
    var receiver_mesh := PlaneMesh.new()
    var capture_world_size: float = float(self.CAPTURE_SIZE.y) * self.PIXEL_SIZE
    receiver_mesh.size = Vector2.ONE * capture_world_size * 4.0
    self._shadow_receiver.mesh = receiver_mesh
    self._shadow_receiver.position.y = -0.01
    self._shadow_receiver.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    var receiver_material := StandardMaterial3D.new()
    receiver_material.albedo_color = Color.WHITE
    receiver_material.disable_ambient_light = true
    receiver_material.metallic_specular = 0.0
    receiver_material.roughness = 1.0
    self._shadow_receiver.material_override = receiver_material
    self._shadow_receiver.hide()
    self._camera_rig.add_child(self._shadow_receiver)


func _collect_resource_paths() -> PackedStringArray:
    var paths := PackedStringArray()
    for prefix: String in self.RESOURCE_PREFIXES:
        var directory := DirAccess.open(prefix)
        if directory == null:
            push_error("Could not open %s" % prefix)
            self._failures += 1
            continue
        for filename: String in directory.get_files():
            if filename.get_extension() != "tres":
                continue
            var resource_path: String = prefix + filename
            var resource: MapObjectResource = load(resource_path) as MapObjectResource
            if resource != null and resource.mesh != null and not resource is RotatingTileResource:
                paths.append(resource_path)
    paths.sort()
    return paths


func _requested_resource_path() -> String:
    for argument: String in OS.get_cmdline_user_args():
        if argument.begins_with("--resource="):
            return argument.trim_prefix("--resource=")
    return ""


func _bake_resource(resource_path: String, current: int, total: int) -> void:
    var resource: MapObjectResource = load(resource_path) as MapObjectResource
    if resource == null or resource.mesh == null or resource is RotatingTileResource:
        push_error("Cannot bake ineligible resource: %s" % resource_path)
        self._failures += 1
        return

    var images: Array[Image] = []
    var bounds := Rect2i()
    var has_bounds: bool = false
    var preview: Node3D = self._preview_factory._create_preview(resource)
    self._camera_rig.add_child(preview)
    for child: Node in preview.get_children():
        var mesh_instance: MeshInstance3D = child as MeshInstance3D
        if mesh_instance != null:
            mesh_instance.cast_shadow = resource.mesh_cast_shadow

    for rotation: int in self.ROTATIONS:
        preview.rotation = Vector3(0, deg_to_rad(rotation), 0)
        var image: Image = await self._capture_image()
        if image == null:
            push_error("The active renderer cannot capture viewport textures; run the baker without --headless")
            self._failures += 1
            preview.free()
            return
        var object_bounds: Rect2i = image.get_used_rect()
        if object_bounds.size == Vector2i.ZERO:
            push_error("Empty capture for %s at %d degrees" % [resource_path, rotation])
            self._failures += 1
            preview.free()
            return
        if resource.mesh_cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF:
            self._shadow_receiver.show()
            preview.hide()
            var shadow_baseline: Image = await self._capture_image()
            preview.show()
            var shadow: Image = await self._capture_image()
            self._shadow_receiver.hide()
            var shadow_margin: int = maxi(object_bounds.size.x, object_bounds.size.y)
            shadow = self.extract_shadow(
                shadow,
                shadow_baseline,
                object_bounds.grow(shadow_margin)
            )
            image = self.composite_shadow(image, shadow)
            if image == null:
                push_error("Could not compose baked shadow for %s at %d degrees" % [resource_path, rotation])
                self._failures += 1
                preview.free()
                return
        var used_rect: Rect2i = image.get_used_rect()
        if used_rect.size == Vector2i.ZERO:
            push_error("Empty capture for %s at %d degrees" % [resource_path, rotation])
            self._failures += 1
            preview.free()
            return
        if self._touches_capture_edge(used_rect):
            push_error("Capture boundary is too small for %s at %d degrees" % [resource_path, rotation])
            self._failures += 1
            preview.free()
            return
        bounds = used_rect if not has_bounds else bounds.merge(used_rect)
        has_bounds = true
        images.append(image)

    preview.free()
    bounds = bounds.grow(self.CELL_PADDING)
    var capture_origin := Vector2i(self.CAPTURE_SIZE.x >> 1, self.CAPTURE_SIZE.y >> 1)
    var baked: Dictionary = self.build_sheet(images, bounds, capture_origin)
    if baked.is_empty():
        push_error("Could not assemble frames for %s" % resource_path)
        self._failures += 1
        return

    var output_base: String = self._output_base_for(resource_path)
    var output_directory: String = output_base.get_base_dir()
    var make_directory_error: Error = DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_directory))
    if make_directory_error != OK:
        push_error("Could not create %s" % output_directory)
        self._failures += 1
        return

    var sheet: Image = baked["image"] as Image
    var png_path: String = output_base + ".png"
    var png_error: Error = sheet.save_png(png_path)
    if png_error != OK:
        push_error("Could not save %s" % png_path)
        self._failures += 1
        return
    var import_error: Error = self._configure_png_import(png_path)
    if import_error != OK:
        push_error("Could not configure texture import for %s" % png_path)
        self._failures += 1
        return

    sheet.generate_mipmaps()
    var texture_path: String = output_base + ".res"
    var texture: PortableCompressedTexture2D = null
    if resource.tof_impostor_path == texture_path:
        texture = load(texture_path) as PortableCompressedTexture2D
    var is_new_texture: bool = texture == null
    if is_new_texture:
        texture = PortableCompressedTexture2D.new()
    texture.keep_compressed_buffer = true
    texture.create_from_image(sheet, PortableCompressedTexture2D.COMPRESSION_MODE_BASIS_UNIVERSAL)
    var save_flags: int = ResourceSaver.FLAG_CHANGE_PATH if is_new_texture else ResourceSaver.FLAG_NONE
    var texture_error: Error = ResourceSaver.save(texture, texture_path, save_flags)
    if texture_error != OK:
        push_error("Could not save %s" % texture_path)
        self._failures += 1
        return

    var original_uid: int = ResourceLoader.get_resource_uid(resource_path)
    resource.tof_impostor_path = texture_path
    resource.tof_impostor_origin = baked["origin"] as Vector2
    resource.tof_impostor_pixel_size = self.PIXEL_SIZE
    var resource_error: Error = ResourceSaver.save(resource, resource_path)
    if original_uid != ResourceUID.INVALID_ID:
        ResourceSaver.set_uid(resource_path, original_uid)
    if resource_error != OK:
        push_error("Could not update %s" % resource_path)
        self._failures += 1
        return

    print("[%d/%d] %s -> %dx%d" % [current, total, resource_path, sheet.get_width(), sheet.get_height()])


func _capture_image() -> Image:
    self._viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
    await self.process_frame
    await self.process_frame
    var image: Image = self._viewport.get_texture().get_image()
    if image == null:
        return null
    image.convert(Image.FORMAT_RGBA8)
    return image


static func composite_shadow(object: Image, shadow: Image) -> Image:
    if object == null or shadow == null or object.get_size() != shadow.get_size():
        return null
    var composed: Image = shadow.duplicate()
    composed.blend_rect(object, Rect2i(Vector2i.ZERO, object.get_size()), Vector2i.ZERO)
    return composed


static func extract_shadow(shadowed: Image, baseline: Image, search_rect: Rect2i) -> Image:
    if shadowed == null or baseline == null or shadowed.get_size() != baseline.get_size():
        return null
    var result := Image.create_empty(
        shadowed.get_width(),
        shadowed.get_height(),
        false,
        Image.FORMAT_RGBA8
    )
    result.fill(Color.TRANSPARENT)
    var bounds := search_rect.intersection(Rect2i(Vector2i.ZERO, shadowed.get_size()))
    var shadow_region: Image = shadowed.get_region(bounds)
    var baseline_region: Image = baseline.get_region(bounds)
    shadow_region.convert(Image.FORMAT_L8)
    baseline_region.convert(Image.FORMAT_L8)
    var shadow_data: PackedByteArray = shadow_region.get_data()
    var baseline_data: PackedByteArray = baseline_region.get_data()
    var output_data := PackedByteArray()
    output_data.resize(shadow_data.size() * 2)
    for index: int in shadow_data.size():
        var baseline_luminance: int = baseline_data[index]
        if baseline_luminance == 0:
            continue
        var contrast: float = clampf(
            float(baseline_luminance - shadow_data[index]) / float(baseline_luminance),
            0.0,
            1.0
        )
        if contrast >= MIN_SHADOW_CONTRAST:
            output_data[index * 2 + 1] = int(contrast * SHADOW_OPACITY * 255.0)
    var extracted := Image.create_from_data(
        bounds.size.x,
        bounds.size.y,
        false,
        Image.FORMAT_LA8,
        output_data
    )
    extracted.convert(Image.FORMAT_RGBA8)
    result.blit_rect(extracted, Rect2i(Vector2i.ZERO, bounds.size), bounds.position)
    return result


func _touches_capture_edge(rect: Rect2i) -> bool:
    return rect.position.x <= 0 or rect.position.y <= 0 \
        or rect.end.x >= self.CAPTURE_SIZE.x or rect.end.y >= self.CAPTURE_SIZE.y


func _output_base_for(resource_path: String) -> String:
    var relative_path: String = resource_path.trim_prefix("res://resources/").trim_suffix(".tres")
    return "%s/%s" % [self.OUTPUT_ROOT, relative_path]


func _configure_png_import(png_path: String) -> Error:
    var import_path: String = png_path + ".import"
    var config := ConfigFile.new()
    if FileAccess.file_exists(import_path):
        var load_error: Error = config.load(import_path)
        if load_error != OK:
            return load_error
    config.set_value("params", "compress/mode", 2)
    config.set_value("params", "mipmaps/generate", true)
    config.set_value("params", "detect_3d/compress_to", 0)
    return config.save(import_path)


static func build_sheet(images: Array[Image], bounds: Rect2i, origin: Vector2i) -> Dictionary:
    if images.size() != ROTATIONS.size() or bounds.size.x <= 0 or bounds.size.y <= 0:
        return {}

    var sheet_size := bounds.size * 2
    var sheet := Image.create_empty(sheet_size.x, sheet_size.y, false, Image.FORMAT_RGBA8)
    sheet.fill(Color.TRANSPARENT)
    for index: int in images.size():
        if images[index] == null or not Rect2i(Vector2i.ZERO, images[index].get_size()).encloses(bounds):
            return {}
        var destination := Vector2i(index % 2, index >> 1) * bounds.size
        sheet.blit_rect(images[index], bounds, destination)

    return {
        "image": sheet,
        "origin": Vector2(origin - bounds.position),
    }
