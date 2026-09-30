"""scripts/ios/pick_simulator.py chooses a real simulator UDID (names like "iPhone SE (3rd generation)" broke name parsing)."""
import importlib.util

from astrolex_tools import repo_root

spec = importlib.util.spec_from_file_location("pick_simulator", repo_root() / "scripts/ios/pick_simulator.py")
pick_simulator = importlib.util.module_from_spec(spec)
spec.loader.exec_module(pick_simulator)

R = "com.apple.CoreSimulator.SimRuntime."
DEVICES = {"devices": {
    R + "iOS-18-6": [{"name": "iPhone 16 Pro", "udid": "P16", "isAvailable": True}],
    R + "iOS-26-2": [
        {"name": "iPad Pro 13-inch (M5)", "udid": "IPAD", "isAvailable": True},
        {"name": "iPhone 17 Pro Max", "udid": "P17MAX", "isAvailable": True},
        {"name": "iPhone 17 Pro", "udid": "P17", "isAvailable": True},
        {"name": "iPhone SE (3rd generation)", "udid": "SE", "isAvailable": True},
    ],
    R + "iOS-26-10": [{"name": "iPhone Air", "udid": "AIR", "isAvailable": False}],
    R + "watchOS-26-0": [{"name": "Apple Watch", "udid": "W", "isAvailable": True}],
}}


def test_prefers_pro_on_newest_runtime():
    assert pick_simulator.pick(DEVICES) == "P17"


def test_runtime_versions_compare_numerically():
    assert pick_simulator.runtime_version(R + "iOS-26-10") > pick_simulator.runtime_version(R + "iOS-26-2")


def test_exact_name_with_parentheses():
    assert pick_simulator.pick(DEVICES, "iPhone SE (3rd generation)") == "SE"
    assert pick_simulator.pick(DEVICES, "iPhone 16 Pro") == "P16"
    assert pick_simulator.pick(DEVICES, "iPhone 99") is None


def test_no_iphones():
    assert pick_simulator.pick({"devices": {R + "iOS-26-2": [{"name": "iPad", "udid": "X"}]}}) is None
