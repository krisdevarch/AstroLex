extends RefCounted
## Sharing the Daily Signal (WP-F.6): the web Share sheet when the browser has one, else the
## clipboard. Everything else (desktop, headless) copies. The only code that touches navigator.share.

const FILE_NAME := "astrolex-daily.png"


## Shares `text` (and the PNG, base64, when the browser can share files). Call from inside the tap.
## Returns "shared" when the share sheet took it, else "copied" (text on the clipboard).
static func share(text: String, png_b64: String = "") -> String:
	if OS.has_feature("web") and str(JavaScriptBridge.eval(_share_js(text, png_b64), true)) == "shared":
		return "shared"
	copy(text)
	return "copied"


static func copy(text: String) -> void:
	DisplayServer.clipboard_set(text)
	if OS.has_feature("web"):
		JavaScriptBridge.eval(_copy_js(text), true)


static func _share_js(text: String, png_b64: String) -> String:
	return """(function(t, b) {
  try {
    if (!navigator.share) return 'no';
    var d = {text: t};
    if (b) {
      try {
        var bin = atob(b), a = new Uint8Array(bin.length);
        for (var i = 0; i < bin.length; i++) a[i] = bin.charCodeAt(i);
        var f = new File([a], '%s', {type: 'image/png'});
        if (navigator.canShare && navigator.canShare({files: [f]})) d.files = [f];
      } catch (e) {}
    }
    navigator.share(d).catch(function() {});
    return 'shared';
  } catch (e) { return 'no'; }
})(%s, %s)""" % [FILE_NAME, JSON.stringify(text), JSON.stringify(png_b64)]


static func _copy_js(text: String) -> String:
	return """(function(t) {
  try {
    if (navigator.clipboard && navigator.clipboard.writeText) { navigator.clipboard.writeText(t).catch(function() {}); return 1; }
    var e = document.createElement('textarea');
    e.value = t; document.body.appendChild(e); e.select();
    document.execCommand('copy'); document.body.removeChild(e);
  } catch (x) {}
  return 1;
})(%s)""" % JSON.stringify(text)
