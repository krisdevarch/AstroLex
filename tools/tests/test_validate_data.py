from astrolex_tools.validate_data import validate_all


def test_all_tunables_validate():
    assert validate_all() == []
