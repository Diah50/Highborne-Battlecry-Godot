extends Unit
class_name Archer

var projectile = preload("res://scenes/core/Arrow.tscn")

var portrait : Texture = load("res://graphics/k\'inh humans assets/k\'inh unit portraits/jungle archer icon.png")

func _ready():
  ._ready()
  speed = 250
  health = 20
  attack_range = 1000
  view_range = 1000

func handle_hit(projectile_sprite : Sprite):
  if target != null:
	var arrow = projectile.instance()
	arrow.prepare(projectile_sprite.texture, self, 700, target.position)
	get_parent().add_child(arrow)

func play_animation(anim_name):
  $BodyWithAnimation.set_direction(velocity.normalized())
  if "attack" in anim_name:
	$BodyWithAnimation.set_animation("bow")
  elif "walk" in anim_name:
	$BodyWithAnimation.set_animation("walk")
  elif "death" == anim_name:
	$BodyWithAnimation.set_animation("death")
