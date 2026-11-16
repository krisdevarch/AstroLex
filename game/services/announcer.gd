extends RefCounted
## Screen reader voice for the web build (WP-F.33). The game draws everything into one <canvas>, which
## a screen reader cannot read, so the page keeps a visually hidden aria-live region (#alx-live in
## web/shell.html) and the game writes into it: the screen's name when a screen opens, and the
## focused control's label when keyboard focus moves. Off the web it only remembers what it would have
## said. fake() never touches the page (tests).

var spoken: Array[String] = []
var _web: bool = false


static func real() -> RefCounted:
	var a: RefCounted = (load("res://services/announcer.gd") as GDScript).new()
	a.set("_web", OS.has_feature("web"))
	return a


static func fake() -> RefCounted:
	return (load("res://services/announcer.gd") as GDScript).new()


## Speaks `text` politely (after whatever the reader is saying). Empty or repeated text is skipped.
func say(text: String) -> void:
	var t := text.strip_edges()
	if t == "" or (not spoken.is_empty() and spoken[spoken.size() - 1] == t):
		return
	spoken.append(t)
	if spoken.size() > 50:
		spoken.remove_at(0)
	if _web:
		JavaScriptBridge.eval("window.__alxSay && window.__alxSay(%s)" % JSON.stringify(t))


func last() -> String:
	return "" if spoken.is_empty() else spoken[spoken.size() - 1]


## What a screen reader should call `c`: a button's text, else its tooltip (icon buttons), else a
## label's text; "" when it has none.
static func label_of(c: Control) -> String:
	if c == null:
		return ""
	var out := ""
	if c is Button and str((c as Button).text).strip_edges() != "":
		out = str((c as Button).text)
	elif str(c.tooltip_text) != "":
		out = str(c.tooltip_text)
	elif c is Label:
		out = str((c as Label).text)
	elif c is LineEdit:
		out = str((c as LineEdit).placeholder_text)
	if c is BaseButton and (c as BaseButton).toggle_mode and out != "":
		out += ", on" if (c as BaseButton).button_pressed else ", off"
	return out.strip_edges()
