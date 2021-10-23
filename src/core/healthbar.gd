extends ProgressBar

func set_max_health(val):
  max_value = val

func set_current_health(val):
  value = max(0, val)
