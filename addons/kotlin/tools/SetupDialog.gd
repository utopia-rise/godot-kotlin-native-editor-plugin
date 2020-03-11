tool
extends BaseProgressDialog
class_name SetupDialog

func set_step_text(info: String):
	$VBoxContainer/StepLabel.text = info
