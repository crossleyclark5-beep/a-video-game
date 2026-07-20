extends Control
## Floating interaction prompt. Bind to InteractionAgent.focus_changed.

@onready var _label: Label = %PromptLabel
@onready var _panel: PanelContainer = %PromptPanel

var _agent: InteractionAgent = null


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	call_deferred("_style_prompt")


func _style_prompt() -> void:
	if _panel:
		DFStyle.apply_panel(_panel, true)
	if _label:
		DFStyle.apply_label_cyan(_label, DFStyle.FONT_BODY)


func bind_agent(agent: InteractionAgent) -> void:
	if _agent != null and _agent.focus_changed.is_connected(_on_focus_changed):
		_agent.focus_changed.disconnect(_on_focus_changed)
	_agent = agent
	if _agent:
		_agent.focus_changed.connect(_on_focus_changed)
		_on_focus_changed(_agent.get_focus())


func _on_focus_changed(interactable: Interactable) -> void:
	if interactable == null:
		visible = false
		return
	_label.text = interactable.get_prompt_text()
	visible = true
