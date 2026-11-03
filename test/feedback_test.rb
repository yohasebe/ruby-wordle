require_relative "test_helper"

class FeedbackTest < Minitest::Test
  include TestHelper

  def notation(guess, answer)
    F.notation(F.score(guess, answer), guess.size)
  end

  def test_exact_match
    assert_equal "ggggg", notation("cigar", "cigar")
  end

  def test_repeated_guess_letter_marked_once_for_single_answer_letter
    assert_equal "xyxgx", notation("array", "cigar")
    assert_equal "xxyxy", notation("speed", "abide")
  end

  def test_green_takes_priority_over_earlier_yellow
    assert_equal "xxxgg", notation("geese", "those")
  end

  def test_repeated_letters_in_both
    assert_equal "yyxxx", notation("level", "apple")
    assert_equal "gyxxg", notation("allee", "apple")
  end

  def test_parse_accepts_alternative_notations
    expected = pattern("xygxx")
    assert_equal expected, F.parse("01200", 5)
    assert_equal expected, F.parse("-YG.b", 5)
  end

  def test_parse_rejects_wrong_size_or_symbol
    assert_nil F.parse("xyg", 5)
    assert_nil F.parse("xygzz", 5)
  end

  def test_round_trip
    (0...3**5).each { |p| assert_equal p, F.encode(F.decode(p, 5)) }
  end
end
