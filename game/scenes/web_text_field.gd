extends Node
## A real HTML <input> laid over a LineEdit, on the web only (owner report, 17 Oct 2026: the name
## field never opened the iPhone keyboard). Godot opens its web keyboard from a queued input event,
## after the tap has ended, and iOS Safari only shows the keyboard when focus happens inside the tap.
## A tap on a page input opens it natively on every phone. The page input owns the typing; each
## change is handed to the LineEdit as `text_changed`, so the screen's own cleaning and checks run
## as before, and the cleaned text is written back. The input is all but invisible: the LineEdit
## underneath draws the text and lights its focus style while the page input has focus.

var _line: LineEdit
var _id: String
var _on_input: JavaScriptObject  # kept here: a callback stops working once nothing references it
var _on_focus: JavaScriptObject
var _rect := Rect2()
var _shown := false
var _normal: StyleBox


## Adds the overlay to `line` when running in a browser; does nothing anywhere else.
static func attach(line: LineEdit) -> void:
	if not OS.has_feature("web"):
		return
	var n: Node = (load("res://scenes/web_text_field.gd") as GDScript).new()
	n.name = "WebTextField"
	line.add_child(n)


func _ready() -> void:
	_line = get_parent() as LineEdit
	_id = "alx-input-%d" % get_instance_id()
	_line.focus_mode = Control.FOCUS_NONE  # the page input takes the taps and the keys
	_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_normal = _line.get_theme_stylebox("normal")
	_on_input = JavaScriptBridge.create_callback(_typed)
	_on_focus = JavaScriptBridge.create_callback(_focused)
	var win := JavaScriptBridge.get_interface("window")
	win.set(_key("in"), _on_input)
	win.set(_key("fo"), _on_focus)
	JavaScriptBridge.eval("""(function(){
var el=document.createElement('input');el.id=%s;el.type='text';el.maxLength=%d;
el.autocomplete='off';el.spellcheck=false;el.setAttribute('autocapitalize','characters');
el.setAttribute('autocorrect','off');el.setAttribute('enterkeyhint','done');
el.style.cssText='position:fixed;display:none;z-index:10;margin:0;padding:0;border:0;outline:none;background:transparent;color:transparent;caret-color:transparent;font-size:16px;opacity:0.01;';
el.value=%s;
el.addEventListener('input',function(){window[%s](el.value);});
el.addEventListener('focus',function(){window[%s](true);});
el.addEventListener('blur',function(){window[%s](false);window.scrollTo(0,0);});
el.addEventListener('keydown',function(e){if(e.key==='Enter'){el.blur();}});
document.body.appendChild(el);})()""" % [
		JSON.stringify(_id), _line.max_length if _line.max_length > 0 else 64, JSON.stringify(_line.text),
		JSON.stringify(_key("in")), JSON.stringify(_key("fo")), JSON.stringify(_key("fo"))])


func _key(what: String) -> String:
	return "%s_%s" % [_id.replace("-", "_"), what]


func _typed(args: Array) -> void:
	var v := str(args[0]) if not args.is_empty() else ""
	_line.text = v
	_line.text_changed.emit(v)
	if _line.text != v:  # the screen cleaned it (letters only, upper case): show the same in the page input
		JavaScriptBridge.eval("(function(){var el=document.getElementById(%s);if(el){el.value=%s;}})()" % [JSON.stringify(_id), JSON.stringify(_line.text)])


func _focused(args: Array) -> void:
	var on := not args.is_empty() and bool(args[0])
	_line.add_theme_stylebox_override("normal", _line.get_theme_stylebox("focus") if on else _normal)


## Keeps the page input over the LineEdit (window pixels to CSS pixels via the canvas) and hides it
## with the screen. Only talks to the page when something changed.
func _process(_delta: float) -> void:
	var shown := _line.is_visible_in_tree()
	var xf := _line.get_viewport().get_final_transform() * _line.get_global_transform_with_canvas()
	var r := xf * Rect2(Vector2.ZERO, _line.size)
	if shown == _shown and r.is_equal_approx(_rect):
		return
	_shown = shown
	_rect = r
	JavaScriptBridge.eval("""(function(){var el=document.getElementById(%s),c=document.getElementById('canvas');
if(!el||!c)return;var b=c.getBoundingClientRect(),k=b.width/(c.width||b.width);
el.style.left=(b.left+%f*k)+'px';el.style.top=(b.top+%f*k)+'px';
el.style.width=(%f*k)+'px';el.style.height=(%f*k)+'px';el.style.display=%s;})()""" % [
		JSON.stringify(_id), r.position.x, r.position.y, r.size.x, r.size.y, "'block'" if shown else "'none'"])


func _exit_tree() -> void:
	JavaScriptBridge.eval("(function(){var el=document.getElementById(%s);if(el){el.blur();el.remove();}delete window[%s];delete window[%s];})()" % [
		JSON.stringify(_id), JSON.stringify(_key("in")), JSON.stringify(_key("fo"))])
