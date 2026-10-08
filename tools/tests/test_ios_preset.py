"""game/export_presets.cfg: the iOS preset exports an Xcode project only and carries no account detail (WP-3.0)."""
import configparser

from astrolex_tools import repo_root


def ios_options():
    cfg = configparser.ConfigParser(comment_prefixes=(";",), interpolation=None)
    cfg.read(repo_root() / "game/export_presets.cfg")
    section = next(s for s in cfg.sections() if cfg[s].get("platform") == '"iOS"')
    return {k: v.strip('"') for k, v in cfg[section + ".options"].items()}


def test_ios_preset_exports_project_only_for_iphone():
    opts = ios_options()
    assert opts["application/export_project_only"] == "true"
    assert opts["application/targeted_device_family"] == "0"  # iPhone only


def test_ios_preset_holds_placeholders_not_account_details():
    # The ship script passes the real team and bundle ID to xcodebuild from scripts/ios/.env.local.
    opts = ios_options()
    assert opts["application/app_store_team_id"] == "0000000000"
    assert opts["application/bundle_identifier"] == "com.example.astrolex"


def test_ios_preset_version_matches_the_game():
    project = (repo_root() / "game/project.godot").read_text()
    assert f'config/version="{ios_options()["application/short_version"]}"' in project
