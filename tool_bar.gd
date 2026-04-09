extends Control

signal tool_selected(tool:String)

@onready var selected_tool: Button = %LineMainButton

func handle_buttons(
	sub_tray: HBoxContainer,
	main_button: Button,
	this_button: Button,
	tool_name: String
):
	sub_tray.visible = false
	main_button.icon = this_button.icon
	selected_tool.set_pressed_no_signal(false)
	main_button.set_pressed_no_signal(true)
	selected_tool = main_button
	tool_selected.emit(tool_name)

func _on_line_main_button_pressed() -> void:
	if %LineSubTray.visible:
		%LineSubTray.visible = false
	else:
		%LineSubTray.visible = true
	

func _on_segment_button_pressed() -> void:
	handle_buttons(
		%LineSubTray,
		%LineMainButton,
		%SegmentButton,
		"segment"
	)


func _on_ray_button_pressed() -> void:
	handle_buttons(
		%LineSubTray,
		%LineMainButton,
		%RayButton,
		"ray"
	)

func _on_line_button_pressed() -> void:
	handle_buttons(
		%LineSubTray,
		%LineMainButton,
		%LineButton,
		"line"
	)


func _on_draw_main_button_pressed() -> void:
	if %DrawSubTray.visible:
		%DrawSubTray.visible = false
	else:
		%DrawSubTray.visible = true

func _on_freehand_button_pressed() -> void:
	handle_buttons(
		%DrawSubTray,
		%DrawMainButton,
		%FreehandButton,
		"freehand"
	)


func _on_poly_button_pressed() -> void:
	handle_buttons(
		%DrawSubTray,
		%DrawMainButton,
		%PolyButton,
		"poly"
	)
