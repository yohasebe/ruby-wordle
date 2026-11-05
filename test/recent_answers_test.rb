require_relative "test_helper"
require "tmpdir"

class RecentAnswersTest < Minitest::Test
  include TestHelper

  def with_state
    Dir.mktmpdir { |dir| yield dir, RubyWordle::RecentAnswers.for("XDG_STATE_HOME" => dir) }
  end

  def test_location
    path = ->(env) { RubyWordle::RecentAnswers.for(env).instance_variable_get(:@path) }
    assert_equal "/s/ruby-wordle/recent-answers.txt", path.call("XDG_STATE_HOME" => "/s", "HOME" => "/h")
    assert_equal "/h/.local/state/ruby-wordle/recent-answers.txt", path.call("XDG_STATE_HOME" => "s", "HOME" => "/h")
    assert_nil path.call({})
  end

  def test_keeps_the_latest_words_once
    with_state do |_, recent|
      %w[apple cigar apple].each { |word| recent.add(word) }
      assert_equal %w[cigar apple], recent.words
      (RubyWordle::RecentAnswers::LIMIT + 1).times { |i| recent.add("w#{i}") }
      assert_equal RubyWordle::RecentAnswers::LIMIT, recent.words.size
      assert_equal "w1", recent.words.first
    end
  end

  def test_unusable_file_is_ignored
    with_state do |dir|
      File.write(File.join(dir, "ruby-wordle"), "")
      recent = RubyWordle::RecentAnswers.for("XDG_STATE_HOME" => dir)
      assert_nil recent.add("apple")
      assert_empty recent.words
    end
  end

  def test_games_avoid_recent_answers
    with_state do |_, recent|
      answers = small_dictionary.answers
      cli = RubyWordle::CLI.new(input: StringIO.new("q\ny\n" * answers.size + "q\nn\n"), output: StringIO.new,
                                dictionary: small_dictionary, env: {}, recent: recent)
      cli.run(["play"])
      assert_equal answers.sort, recent.words.first(answers.size).sort
    end
  end

  def test_all_answers_avoided_falls_back_to_all
    answer = RubyWordle::Game.new(small_dictionary, avoid: small_dictionary.answers).answer
    assert_includes small_dictionary.answers, answer
  end
end
