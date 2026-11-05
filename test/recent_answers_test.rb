require_relative "test_helper"
require "tmpdir"

class RecentAnswersTest < Minitest::Test
  include TestHelper

  LIMIT = RubyWordle::RecentAnswers::LIMIT

  def setup
    @dir = Dir.mktmpdir
    @path = File.join(@dir, "ruby-wordle", "recent-answers.txt")
  end

  def teardown
    FileUtils.remove_entry(@dir)
  end

  def recent
    RubyWordle::RecentAnswers.for("XDG_STATE_HOME" => @dir)
  end

  def state(text)
    FileUtils.mkdir_p(File.dirname(@path))
    File.binwrite(@path, text)
  end

  def answers
    small_dictionary.answers
  end

  def test_location
    path = ->(env) { RubyWordle::RecentAnswers.for(env).instance_variable_get(:@path) }
    home = File.join(@dir, "home")
    assert_equal @path, path.call("XDG_STATE_HOME" => @dir, "HOME" => home)
    expected = File.join(home, ".local", "state", "ruby-wordle", "recent-answers.txt")
    assert_equal expected, path.call("XDG_STATE_HOME" => "state", "HOME" => home)
    assert_nil path.call("HOME" => "home")
    assert_nil path.call({})
  end

  def test_picks_each_answer_once_before_repeating
    random = Random.new(1)
    picked = answers.map { recent.pick(answers, random) }
    assert_equal answers.sort, picked.sort
    assert_includes answers, recent.pick(answers, random)
  end

  def test_keeps_the_latest_words_once
    state("apple\ncigar\n")
    recent.pick(["apple"], Random.new(1))
    assert_equal %w[cigar apple], recent.words
    state((1..LIMIT).map { |i| "w#{'a' * i}" }.join("\n") + "\n")
    recent.pick(["cigar"], Random.new(1))
    assert_equal LIMIT, recent.words.size
    assert_equal "waa", recent.words.first
  end

  def test_only_the_latest_words_are_avoided
    state((["apple"] + ["cigar"] * LIMIT).join("\n"))
    assert_equal "apple", recent.pick(%w[apple cigar], Random.new(1))
  end

  def test_malformed_records_are_dropped
    state("apple\n\xFF\nCigar\nshell")
    assert_equal %w[apple shell], recent.words
  end

  def test_oversized_file_is_ignored
    state("apple\n" + "a" * RubyWordle::RecentAnswers::MAX_BYTES)
    assert_empty recent.words
  end

  def test_unusable_file_is_ignored
    FileUtils.mkdir_p(@path)
    assert_includes answers, recent.pick(answers, Random.new(1))
    assert_empty recent.words
  end

  def test_read_error_is_ignored
    io = StringIO.new
    io.define_singleton_method(:read) { |*| raise Errno::EIO }
    io.define_singleton_method(:write) { |*| flunk "wrote after a failed read" }
    store = RubyWordle::RecentAnswers.new(nil)
    store.define_singleton_method(:open_locked) { io }
    assert_equal "apple", store.pick(["apple"], Random.new(1))
    assert_empty store.words
  end

  # A random source that checks the file is locked while the word is picked.
  class LockProbe
    attr_reader :locked

    def initialize(path)
      @path = path
    end

    def rand(*args)
      File.open(@path) { |file| @locked = !file.flock(File::LOCK_EX | File::LOCK_NB) }
      Random.new(1).rand(*args)
    end
  end

  def test_file_is_locked_while_picking
    probe = LockProbe.new(@path)
    recent.pick(answers, probe)
    assert probe.locked
  end

  def test_games_avoid_recent_answers
    input = "q\ny\n" * (answers.size - 1) + "q\nn\n"
    out = StringIO.new
    RubyWordle::CLI.new(input: StringIO.new(input), output: out, dictionary: small_dictionary, env: {},
                        recent: recent).run(["play"])
    shown = out.string.scan(/The answer was (\w+)/).flatten.map(&:downcase)
    assert_equal answers.sort, shown.sort
  end
end
