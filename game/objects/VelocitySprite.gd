class_name VelocitySprite; extends Sprite2D;

# i steal from sword cube!!!
@export var velocity:Vector2 = Vector2.ZERO
@export var acceleration:Vector2 = Vector2.ZERO
@export var moving:bool = false
var antialiasing:bool:
	get: return texture_filter == CanvasItem.TEXTURE_FILTER_LINEAR
	set(alias):
		antialiasing = alias
		texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR if alias else CanvasItem.TEXTURE_FILTER_NEAREST 
		
func _process(delta):
	if moving:
		var velocity_delta:Vector2 = _get_velocity_delta(velocity, acceleration, delta)

		position.x += (velocity.x + velocity_delta.x) * delta
		position.y += (velocity.y + velocity_delta.y) * delta

		velocity.x += velocity_delta.x * 2.0
		velocity.y += velocity_delta.y * 2.0

func copy_from(sprite:VelocitySprite):
	velocity = sprite.velocity
	acceleration = sprite.acceleration
	moving = sprite.moving
	
static func _compute_velocity(in_velocity:float, in_acceleration:float, elapsed:float):
	return in_velocity + (in_acceleration * elapsed if in_acceleration != 0.0 else 0.0)

static func _get_velocity_delta(in_velocity:Vector2, in_acceleration:Vector2, elapsed:float):
	return Vector2(
		0.5 * (_compute_velocity(in_velocity.x, in_acceleration.x, elapsed) - in_velocity.x),
		0.5 * (_compute_velocity(in_velocity.y, in_acceleration.y, elapsed) - in_velocity.y),
	)
