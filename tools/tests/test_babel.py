from collections import Counter

import pytest

from astrolex_tools.babel.compose import Template, anagrams_of, compose, load_templates
from astrolex_tools.babel.lexicon import load_lexicon
from astrolex_tools.babel.validate import validate_line


@pytest.mark.db
def test_signature_anagram_silent_listen():
    assert "listen" in anagrams_of("silent")
    assert "silent" in anagrams_of("listen")


@pytest.mark.db
def test_templates_load_and_have_twelve():
    assert len(load_templates()) == 12


@pytest.mark.db
def test_lexicon_is_clean_and_sized():
    lex = load_lexicon()
    assert 450 <= len(lex) <= 520
    assert all(lw.pos in {"N", "V", "A", "R", "X"} for lw in lex)
    words = {lw.word for lw in lex}
    assert {"listen", "silent", "quiet", "no", "you"} <= words


@pytest.mark.db
def test_compose_never_uses_letters_outside_pool():
    targets = ["silent", "water", "bread", "hope"]
    pool = Counter("".join(targets))
    lines = compose(pool, targets)
    assert lines, "expected at least one line from a 19-letter pool"
    for ln in lines:
        assert validate_line(ln.text, pool) == [], ln
    assert any(ln.template_id == "signature" and ln.text == "LISTEN." for ln in lines)


@pytest.mark.db
def test_compose_rejects_when_literal_does_not_fit():
    # Pool without the letters for the literal "NOT" (no n, o, t) -> the not_that template yields nothing.
    pool = Counter("silea")
    tpl = [Template("not_that", "NOT {T}. {ANAGRAM_T}.")]
    assert compose(pool, ["silent"], templates=tpl) == []


@pytest.mark.db
def test_validate_line_reports_missing_letters_and_blocked():
    pool = Counter("listen")
    assert validate_line("LISTEN.", pool) == []
    problems = validate_line("LISTEN TO ME.", pool)
    assert any("letters not in pool" in p for p in problems)
    problems = validate_line("SHIT.", Counter("shit"))
    assert any("blocked" in p for p in problems)
