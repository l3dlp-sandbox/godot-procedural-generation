## World generator that uses white noise to place asteroids in sectors.
class_name WhiteNoiseWorldGenerator
extends WorldGenerator

## The asteroid scene to instantiate inside sectors.
export var Asteroid: PackedScene
## The number of asteroids to place in each sector.
export var asteroid_density := 3

onready var grid_drawer := $GridDrawer
onready var player := $Player


# Upon starting the game, we generate sectors around the player and initialise
# the grid drawer, which needs to know the sector size and the number of sector
# we generate on each axis.
func _ready() -> void:
	generate()
	grid_drawer.setup(sector_size, sector_axis_count)


# We use the physics process function to track where the player is in the world
# and generate new sectors as they move away from existing ones.
func _physics_process(_delta: float) -> void:
	# Every frame, we compare the player's position to the current sector. If
	# they move far enough from it, we need to update the world.
	var sector_location := _current_sector * sector_size
	# Calculating the squared distance to a point is much faster for comparison
	# than using the `Vector2.distance_to()` method.
	#
	# That is because the distance function calculates square roots, which is
	# computationally intensive. It may not matter in a small game, but if you
	# compare distances often, you want to compare the squared distances
	# instead.
	if player.global_position.distance_squared_to(sector_location) > _total_sector_count:
		# Our function to update the sectors takes a vector to offset. As the
		# player can be moving left, right, up, or down, we store that
		# information in our sector_offset variable.
		var sector_offset := Vector2.ZERO
		sector_offset = (player.global_position - sector_location) / sector_size
		sector_offset = sector_offset.floor()

		_update_sectors(sector_offset)
		# We also update the grid position to encompass the active sectors. We
		# don't need to redraw the grid, so we move it using the provided
		# function.
		grid_drawer.move_grid_to(_current_sector)


# Generates asteroids and places them inside
# of the sector's bounds with a random position, rotation, and scale.
func _generate_sector(x_id: int, y_id: int) -> void:
	# We calculate and set a unique seed for the current sector. This resets the
	# series of numbers generated by our `RandomNumberGenerator` back to the
	# start, which ensures the world generates the same every time we use the
	# same seed.
	_rng.seed = make_seed_for(x_id, y_id)

	# List of entities generated in this sector.
	var sector_data := []
	# Generates random Vector2 in a square and assign an asteroid to it, with a
	# random angle and scale. The asteroids can overlap.
	for _i in range(asteroid_density):
		var asteroid := Asteroid.instance()
		add_child(asteroid)

		# We generate a random position for each asteroid within the rectangle's bounds.
		asteroid.position = _generate_random_position(x_id, y_id)
		asteroid.rotation = _rng.randf_range(-PI, PI)
		asteroid.scale *= _rng.randf_range(0.2, 1.0)
		sector_data.append(asteroid)

	# We store references to all asteroids to free them later.
	_sectors[Vector2(x_id, y_id)] = sector_data


# Returns a random position within the sector's bounds, given the sector's coordinates.
func _generate_random_position(x_id: int, y_id: int) -> Vector2:
	# Calculate the sector boundaries based on the current x and y sector
	# coordinates.
	var sector_position = Vector2(x_id * sector_size, y_id * sector_size)
	var sector_top_left = Vector2(
		sector_position.x - _half_sector_size, sector_position.y - _half_sector_size
	)
	var sector_bottom_right = Vector2(
		sector_position.x + _half_sector_size, sector_position.y + _half_sector_size
	)

	# Here, we are not preventing the asteroids from overlapping. They may
	# also be fairly large and so close to the sector's boundaries they
	# overlap with a neighboring sector.
	# We'll address those issues when implementing the blue noise world
	# generator.
	return Vector2(
		_rng.randf_range(sector_top_left.x, sector_bottom_right.x),
		_rng.randf_range(sector_top_left.y, sector_bottom_right.y)
	)
