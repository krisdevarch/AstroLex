import pytest


def pytest_configure(config):
    config.addinivalue_line("markers", "db: needs the built word database (built on first use; slow the first time)")
