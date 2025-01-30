@tool
extends Path3D

# GUI-updatable distance between planks of the train tracks.
@export var distance_between_planks: float = 0.5

# Tracks if recalculation is necessary.
var is_dirty: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if is_dirty:
		_update_multimesh()
		is_dirty = false

# Updates the MultiMesh
func _update_multimesh() -> void:
	# Calculate the number of planks to generate.
	var path_length: float = curve.get_baked_length()
	var count: int = floor(path_length/distance_between_planks)

	# Obtain MultiMesh instance, update singleton properties.
	var mm: MultiMesh = $MultiMeshInstance3D.multimesh
	mm.instance_count = count

	# Defines offset so plank isn't at the start of the path, but 1/2 a gap in
	var offset = distance_between_planks/2.0

	# Iterate through instances to define their positions
	for i in range(count):
		# Calculate distance along path, then get coordinates of that distance
		# along the path.
		var curve_distance: float = offset + distance_between_planks * i
		var position: Vector3 = curve.sample_baked(curve_distance, true)

		# BASIS - the set of 3 vectors, X, Y, and Z, that describe the orientation
		# of an object in terms of the global coordinate system.
		var basis: Basis = Basis()

		# Obtain data for our Basis
		var forward: Vector3 = position.direction_to(curve.sample_baked(curve_distance + .01, true))
		var up: Vector3 = curve.sample_baked_up_vector(curve_distance, true)

		# Create our basis. Note the order of the cross product, and that to apply
		# Z correctly, we have to take its negative due to Godot's coordinate
		# system having a negative direction for positive Z.
		basis.y = up
		basis.x = forward.cross(up).normalized()
		basis.z = -forward

		# Create the Transform3D object that we'll send to the instance.
		var transform: Transform3D = Transform3D(basis, position)
		# Apply offset to lower planks below bottom of rails.
		transform.origin -= basis.y*0.05
		# Set transform properties for the instance.
		mm.set_instance_transform(i, transform)


func _on_curve_changed() -> void:
	is_dirty = true
