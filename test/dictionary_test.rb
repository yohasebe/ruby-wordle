require_relative "test_helper"
require "tmpdir"

class DictionaryTest < Minitest::Test
  D = RubyWordle::Dictionary

  def test_normalize
    lines = ["APPLE", "apple", " zebra ", "x-ray", "let's", "aAbcd", "Paris", "toolong"]
    assert_equal %w[aabcd apple paris zebra], D.normalize(lines, length: 5)
    assert_equal %w[aabcd apple zebra], D.normalize(lines, length: 5, lowercase_only: true)
  end

  def test_generate
    Dir.mktmpdir do |dir|
      File.write(File.join(dir, "word-list-original.txt"), "zebra\nbobby\napple")
      File.write(File.join(dir, "word-list-basic.txt"), "Paris\nkinda\nAPPLE\n")
      out = D.generate(length: 5, source_dir: dir)
      read = ->(name) { File.read(File.join(out, name)).split("\n") }
      assert_equal %w[apple bobby kinda zebra], read.("word-list.txt")
      assert_equal %w[kinda zebra], read.("word-list-uniq-letters.txt")
      assert_equal %w[apple kinda], read.("word-list-basic.txt")
      assert_equal %w[kinda], read.("word-list-basic-uniq-letters.txt")
    end
  end

  def test_answers_are_valid_guesses
    d = D.new(answers: %w[kinda apple apple], guesses: %w[zebra])
    assert_equal %w[apple kinda], d.answers
    assert d.valid_guess?("kinda")
  end

  def test_rejects_invalid_words_and_empty_answers
    assert_raises(ArgumentError) { D.new(answers: %w[x-ray], guesses: []) }
    assert_raises(ArgumentError) { D.new(answers: %w[apple], guesses: %w[toolong]) }
    assert_raises(ArgumentError) { D.new(answers: [], guesses: %w[apple]) }
  end

  def test_bundled_lists_are_consistent
    d = D.default
    refute_empty d.answers
    assert d.answers.all? { |w| w.match?(/\A[a-z]{5}\z/) && d.valid_guess?(w) }
    assert_equal d.guesses.uniq, d.guesses
  end
end
