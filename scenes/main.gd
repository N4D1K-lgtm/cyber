extends Control


func _ready():
	var viewport = $SubViewport
	print("SubViewport: ", viewport)

	if viewport:
		viewport.handle_input_locally = true
		viewport.gui_disable_input = false
		print("SubViewport configured for input")
	else:
		print("ERROR: SubViewport not found!")


func _input(event):
	$SubViewport.push_input(event)
