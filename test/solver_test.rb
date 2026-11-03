require_relative "test_helper"

class SolverTest < Minitest::Test
  include TestHelper

  def solver
    RubyWordle::Solver.new(small_dictionary)
  end

  def test_candidates_reproduce_every_observed_pattern
    s = solver.add("level", F.score("level", "apple"))
    refute_includes s.candidates, "shell"
    assert_includes s.candidates, "apple"
    s.candidates.each { |w| assert_equal F.score("level", "apple"), F.score("level", w) }
  end

  def test_two_yellows_of_one_letter_require_two_copies
    s = solver.add("speed", pattern("xxyyx"))
    refute_includes s.candidates, "cider"
  end

  def test_answer_survives_any_history
    dict = small_dictionary
    dict.answers.each do |answer|
      s = RubyWordle::Solver.new(dict)
      %w[crane array level].each { |g| s.add(g, F.score(g, answer)) }
      assert_includes s.candidates, answer
    end
  end

  def test_contradictory_history_leaves_nothing
    s = solver.add("zzzzz", pattern("ggggg"))
    s.add("cigar", pattern("ggggg"))
    assert_empty s.candidates
    assert_empty s.suggest
  end

  def test_undo_and_reset
    s = solver
    all = s.candidates
    s.add("cigar", pattern("ggggg"))
    assert_equal ["cigar"], s.candidates
    assert_equal all, s.undo.candidates
    s.add("cigar", pattern("ggggg"))
    assert_equal all, s.reset.candidates
  end

  def test_suggestions_are_ranked_and_marked
    s = solver
    ranked = s.suggest(5)
    assert_equal ranked.sort_by(&:expected).map(&:expected), ranked.map(&:expected)
    ranked.each { |r| assert_equal s.candidates.include?(r.word), r.possible }
  end

  def test_expected_survivors
    d = RubyWordle::Dictionary.new(answers: %w[aaaaa aaaab], guesses: %w[zzzzz])
    ranked = RubyWordle::Solver.new(d).suggest.to_h { |r| [r.word, [r.expected, r.possible]] }
    assert_equal({ "aaaaa" => [1.0, true], "aaaab" => [1.0, true], "zzzzz" => [2.0, true] }, ranked)
  end

  def test_uncommon_survivor_is_possible
    d = RubyWordle::Dictionary.new(answers: %w[apple], guesses: %w[cigar])
    assert RubyWordle::Solver.new(d).suggest.all?(&:possible)
  end

  def test_likely_falls_back_to_all_candidates
    s = solver.add("crane", F.score("crane", "slate"))
    assert_includes s.likely, "slate"
    refute s.likely.any? { |w| small_dictionary.common?(w) }
  end

  def test_history_is_not_affected_by_caller_mutation
    word = +"cigar"
    s = solver.add(word, pattern("ggggg"))
    word.replace("apple")
    assert_equal "cigar", s.history.first.first
  end

  def test_likely_prefers_common_words
    s = solver.add("crane", F.score("crane", "cigar"))
    assert s.likely.all? { |w| small_dictionary.common?(w) }
  end
end
