extends "res://tests/test_case.gd"

const LetterPool := preload("res://rules/letter_pool.gd")


func test_count_is_case_insensitive_and_ignores_non_letters() -> void:
	assert_eq(LetterPool.count("Stone!"), {"s": 1, "t": 1, "o": 1, "n": 1, "e": 1})


func test_anagram_fits_its_own_pool() -> void:
	assert_true(LetterPool.fits("notes", LetterPool.count("stone")))
	assert_true(LetterPool.fits("onset", LetterPool.count("stone")))


func test_multiplicity_is_respected() -> void:
	assert_false(LetterPool.fits("tests", LetterPool.count("stone")), "needs three t/s letters")
	assert_true(LetterPool.fits("too", LetterPool.count("tool")))
	assert_false(LetterPool.fits("tooo", LetterPool.count("tool")))


func test_empty_word_always_fits() -> void:
	assert_true(LetterPool.fits("", {}))
