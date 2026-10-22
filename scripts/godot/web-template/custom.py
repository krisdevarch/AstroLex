# SCons options for AstroLex's slim web export template (scripts/godot/web-template/build.sh).
# The game is 2D, English-only and uses no physics, video, networking or 3D, so the engine
# is built without them. Re-enable a module here before the game starts to use it: a class
# from a disabled module is missing at runtime and its scripts fail to load.
platform = "web"
threads = "no"
optimize = "size"
lto = "full"
debug_symbols = "no"

disable_3d = "yes"
disable_physics_2d = "yes"
disable_physics_3d = "yes"
disable_navigation_2d = "yes"
disable_navigation_3d = "yes"
disable_xr = "yes"
vulkan = "no"
brotli = "no"
minizip = "no"
javascript_eval = "yes"

# Keep: gdscript, freetype (font rendering), text_server_fb (simple Latin shaping; replaces the
# HarfBuzz/ICU text server), webp (imported textures are stored as WebP), regex (rules/babel.gd).
modules_enabled_by_default = "no"
module_gdscript_enabled = "yes"
module_freetype_enabled = "yes"
module_text_server_fb_enabled = "yes"
module_webp_enabled = "yes"
module_regex_enabled = "yes"
