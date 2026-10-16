import pytest

pytest.importorskip("PIL")
from astrolex_tools import contrast  # noqa: E402


def test_ratio_known_values():
    assert contrast.ratio((0, 0, 0), (255, 255, 255)) == pytest.approx(21.0)
    assert contrast.ratio((255, 255, 255), (255, 255, 255)) == pytest.approx(1.0)


def test_every_body_pair_reaches_4_5():
    rs = contrast.rows()
    assert len(rs) == 4 + 4 * 4
    assert all(r >= contrast.BODY_MIN for _, _, r, body in rs if body)


def test_main_fails_when_a_pair_is_too_low(monkeypatch, tmp_path):
    monkeypatch.setattr(contrast, "rows", lambda: [("x", "y", 2.0, True)])
    monkeypatch.setattr("sys.argv", ["contrast", "--out", str(tmp_path / "c.md")])
    assert contrast.main() == 1
