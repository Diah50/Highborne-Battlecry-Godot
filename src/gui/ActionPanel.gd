extends Panel
# this implements the action panel in the user interface bottom left corner

signal perform_action(action_name)

func _ready():
  empty()

# Setup panel buttons and actions
func setup(action_list):
  empty()
  var button_scene = load("res://scenes/gui/ButtonPanel.tscn")
  for action in action_list:
	var button = button_scene.instance()
	button.action = action
	button.connect("perform_action", self, "receive_perform_action")
	$GridContainer.add_child(button)

# Empty the panel
func empty():
  for child in $GridContainer.get_children():
	child.queue_free()

# Forward the signal upwards
func receive_perform_action(action_name):
  emit_signal("perform_action", action_name)
