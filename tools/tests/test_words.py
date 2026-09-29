from collections import Counter
import random

import pytest

from astrolex_tools.words.acts import load_acts
from astrolex_tools.words.blocklist import Blocklist
from astrolex_tools.words.build import load_enable, rarity, tier_for
from astrolex_tools.words.db import WordDB, fits
from astrolex_tools.words.decoys import choose_decoys


def test_enable_loads_and_is_clean():
    words = load_enable()
    assert len(words) > 150_000
    assert all(w.islower() and w.isalpha() for w in words[:5000])


def test_tiers_follow_tunables():
    t = {"difficulty.zipf.easyMin": 4.5, "difficulty.zipf.mediumMin": 3.3}
    assert tier_for(5.0, 5, t) == "easy"
    assert tier_for(5.0, 9, t) == "hard"
    assert tier_for(3.0, 5, t) == "hard"
    assert tier_for(4.0, 5, t) == "medium"


def test_rarity_orders_q_above_e():
    assert rarity("quiz") > rarity("tree")


def test_fits_respects_multiplicity():
    assert fits(Counter("balloon"), Counter("balloonx"))
    assert not fits(Counter("balloon"), Counter("balon"))


def test_blocklist_has_seed_and_respects_allowlist():
    bl = Blocklist.load()
    assert bl.is_blocked("fuck")
    assert not bl.is_blocked("sex")  # allowlisted ordinary word
    assert bl.contains_blocked("YOU FUCK. I LISTEN.") == ["fuck"]
    assert bl.contains_blocked("YOU SPEAK. I LISTEN.") == []


def test_formable_finds_blocked_words_in_pool():
    bl = Blocklist.load()
    assert "shit" in bl.formable(Counter("this"), 6)
    assert bl.formable(Counter("qqq"), 6) == []


def test_decoys_never_add_new_blocked_word():
    bl = Blocklist.load()
    rng = random.Random(1)
    acts = load_acts()
    words = [w for ws in acts.values() for w in ws]
    for _ in range(300):
        targets = rng.sample(words, 4)
        base = Counter("".join(targets))
        baseline = set(bl.formable(base, 6))
        decoys, _ = choose_decoys(targets, 4, rng, bl, 6)
        assert len(decoys) == 4
        assert set(bl.formable(base + Counter(decoys), 6)) - baseline == set()


@pytest.mark.db
def test_db_has_act_words_and_none_blocked():
    db = WordDB.shared()
    bl = Blocklist.load()
    for act, words in load_acts().items():
        assert len(words) == 40, act
        missing = [w for w in words if not db.is_word(w)]
        assert missing == [], (act, missing)
        assert [w for w in words if bl.is_blocked(w)] == []
    row = db.row("bread")
    assert row["tier"] == "easy" and row["in_wordnet"] == 1 and row["definition"]
