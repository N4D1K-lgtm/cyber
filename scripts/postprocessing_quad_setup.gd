extends MeshInstance3D

@export var distance_from_camera: float = 0.1
@export var auto_update: bool = true

var camera: Camera3D

func _ready():
	# Get the parent camera
	camera = get_parent() as Camera3D
	if not camera:
		push_error("QuadSizer: Parent must be a Camera3D!")
		return
	
	# Create quad mesh if it doesn't exist
	if not mesh:
		mesh = QuadMesh.new()
	
	# Initial setup
	update_quad_transform()
	
	# Connect to viewport changes if auto-update is enabled
	if auto_update:
		# Update when viewport size changes
		get_viewport().size_changed.connect(_on_viewport_changed)

func _on_viewport_changed():
	update_quad_transform()

func update_quad_transform():
	if not camera:
		return
	
	# Position the quad in front of the camera
	position = Vector3(0, 0, -distance_from_camera)
	rotation = Vector3.ZERO
	
	var quad_size: Vector2
	
	if camera.projection == Camera3D.PROJECTION_ORTHOGONAL:
		# Orthogonal camera - size is straightforward
		var camera_size = camera.size
		var aspect_ratio = get_viewport().get_visible_rect().size.aspect()
		quad_size = Vector2(camera_size * aspect_ratio, camera_size)
		
	else:
		# Perspective camera - calculate size based on FOV and distance
		var fov_rad = deg_to_rad(camera.fov)
		var height = 2.0 * distance_from_camera * tan(fov_rad * 0.5)
		var aspect_ratio = get_viewport().get_visible_rect().size.aspect()
		var width = height * aspect_ratio
		quad_size = Vector2(width, height)
	
	# Apply the size to the quad
	var quad_mesh = mesh as QuadMesh
	if quad_mesh:
		quad_mesh.size = quad_size
	
	# Debug output
	print("Quad sized to: ", quad_size, " at distance: ", distance_from_camera)

# Call this manually if you need to update the transform
func resize_quad():
	update_quad_transform()

# Helper function to adjust distance and resize accordingly
func set_distance(new_distance: float):
	distance_from_camera = new_distance
	update_quad_transform()
