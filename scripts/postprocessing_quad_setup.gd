extends MeshInstance3D

@export var distance_from_camera: float = 0.1
@export var auto_update: bool = true

var camera: Camera3D

func _ready():
	camera = get_parent() as Camera3D
	if not camera:
		push_error("QuadSizer: Parent must be a Camera3D!")
		return
	
	if not mesh:
		mesh = QuadMesh.new()
	
	update_quad_transform()
	
	if auto_update:
		get_viewport().size_changed.connect(_on_viewport_changed)

func _on_viewport_changed():
	update_quad_transform()

func update_quad_transform():
	if not camera:
		return
	
	position = Vector3(0, 0, -distance_from_camera)
	rotation = Vector3.ZERO
	
	var quad_size: Vector2
	
	# orthogonal
	if camera.projection == Camera3D.PROJECTION_ORTHOGONAL:
		var camera_size = camera.size
		var aspect_ratio = get_viewport().get_visible_rect().size.aspect()
		quad_size = Vector2(camera_size * aspect_ratio, camera_size)
		
	# perspective
	else:
		var fov_rad = deg_to_rad(camera.fov)
		var height = 2.0 * distance_from_camera * tan(fov_rad * 0.5)
		var aspect_ratio = get_viewport().get_visible_rect().size.aspect()
		var width = height * aspect_ratio
		quad_size = Vector2(width, height)
	
	var quad_mesh = mesh as QuadMesh
	if quad_mesh:
		quad_mesh.size = quad_size
	
	print("Quad sized to: ", quad_size, " at distance: ", distance_from_camera)

func resize_quad():
	update_quad_transform()

func set_distance(new_distance: float):
	distance_from_camera = new_distance
	update_quad_transform()
