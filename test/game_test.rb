require_relative "test_helper"

class GameTest < Minitest::Test
  include TestHelper

  def game(answer = "apple")
    RubyWordle::Game.new(small_dictionary, answer: answer)
  end

  def test_rejects_malformed_and_unknown_words
    g = game
    assert_raises(RubyWordle::Game::InvalidGuess) { g.guess("app") }
    assert_raises(RubyWordle::Game::InvalidGuess) { g.guess("x-ray") }
    assert_raises(RubyWordle::Game::InvalidGuess) { g.guess("qqqqq") }
    assert_empty g.history
  end

  def test_rejects_answer_outside_word_list
    assert_raises(ArgumentError) { game("qqqqq") }
  end

  def test_win
    g = game
    g.guess("level")
    g.guess("apple")
    assert g.won?
    assert g.over?
    assert_raises(RubyWordle::Game::InvalidGuess) { g.guess("cigar") }
  end

  def test_loss_after_max_attempts
    g = game
    6.times { g.guess("cigar") }
    refute g.won?
    assert g.over?
  end

  def test_letter_states_keep_best_mark
    g = game
    g.guess("allee")
    g.guess("level")
    states = g.letter_states
    assert_equal F::CORRECT, states["a"]
    assert_equal F::PRESENT, states["l"]
    assert_equal F::CORRECT, states["e"]
    assert_equal F::ABSENT, states["v"]
  end

  def test_reveal_skips_positions_ever_found_and_repeats
    g = game
    g.guess("allee")
    g.guess("cigar")
    refute g.assisted?
    assert_equal [1, "p"], g.reveal
    assert g.assisted?
    g.guess("level")
    assert_equal [1, "p"], g.reveal
  end

  def test_reveal_allowed_with_exactly_two_unknown_positions
    dict = RubyWordle::Dictionary.new(answers: %w[apple], guesses: %w[angle])
    g = RubyWordle::Game.new(dict, answer: "apple")
    g.guess("angle")
    assert_equal [1, "p"], g.reveal
  end

  def test_reveal_refused_with_fewer_than_two_unknown_positions
    g = game
    g.guess("apply")
    assert_nil g.reveal
    refute g.assisted?
  end

  def test_random_answer_is_a_common_word
    g = RubyWordle::Game.new(small_dictionary, random: Random.new(1))
    assert_includes small_dictionary.answers, g.answer
  end
end
