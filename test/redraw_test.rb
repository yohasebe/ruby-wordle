require_relative "test_helper"

class RedrawTest < Minitest::Test
  include TestHelper

  UP = /\e\[(\d+)A/

  # A CLI that behaves as if it ran on a terminal of the given size. The
  # terminal echoes the typed line; +on_read+ runs before each line is read.
  def play(lines, size: [40, 80], on_read: nil)
    out = StringIO.new
    input = StringIO.new(lines.join("\n") + "\n")
    cli = RubyWordle::CLI.new(input: input, output: out, dictionary: small_dictionary,
                              random: Random.new(1), env: {}, clipboard: ->(_) { false })
    current = size
    cli.define_singleton_method(:interactive_terminal?) { true }
    out.define_singleton_method(:winsize) { current or raise Errno::ENOTTY }
    cli.define_singleton_method(:read_terminal) do |prompt|
      current = on_read.call(input.lineno, current) if on_read
      line = input.gets
      out.print prompt, line
      line
    end
    cli.run(["play"])
    out.string
  end

  def rewinds(out)
    out.scan(UP).flatten.map(&:to_i)
  end

  # Blank, 6 board rows with 5 blank lines between them, blank, 3 keyboard
  # rows, blank, then the prompt.
  BOARD_AND_PROMPT = 1 + 11 + 1 + 3 + 1 + 1

  def test_board_is_redrawn_over_the_previous_one
    assert_equal [BOARD_AND_PROMPT, BOARD_AND_PROMPT], rewinds(play(%w[level cigar q n]))
  end

  def test_messages_below_the_board_are_counted
    assert_equal [BOARD_AND_PROMPT + 2], rewinds(play(%w[qqqqq level q n]))
  end

  def test_wrapped_lines_are_counted
    # At width 50 the board fits; the rejected line ("1/6 > " and 60 letters)
    # wraps to two rows and is followed by a one-row error message.
    assert_equal [BOARD_AND_PROMPT + 2 + 1], rewinds(play(["a" * 60, "level", "q", "n"], size: [40, 50]))
  end

  def test_unknown_terminal_size_appends
    [nil, [0, 0], [24, 0]].each do |size|
      out = play(%w[level q n], size: size)
      assert_empty rewinds(out)
      assert_includes out, "The answer was"
    end
  end

  def test_resize_appends_a_new_board
    resize = ->(lineno, size) { lineno == 1 ? [40, 120] : size }
    assert_equal [BOARD_AND_PROMPT], rewinds(play(%w[level cigar q n], on_read: resize))
  end

  def test_resize_and_restore_between_redraws_appends
    resize = ->(lineno, size) { { 1 => [40, 20], 2 => [40, 80] }.fetch(lineno, size) }
    assert_equal [BOARD_AND_PROMPT], rewinds(play(%w[level qqqqq cigar q n], on_read: resize))
  end

  def test_input_of_unknown_width_appends_once
    assert_equal [BOARD_AND_PROMPT], rewinds(play(["界界界", "level", "cigar", "q", "n"]))
  end

  def test_output_taller_than_the_screen_appends
    assert_empty rewinds(play(%w[level q n], size: [10, 80]))
  end

  def test_revealed_letter_is_kept_after_redraw
    out = play(["hint letter", "level", "q", "n"])
    last_board = out.split(UP).last
    assert_includes last_board, "Hint: letter 1 is #{answer_for_seed[0].upcase}"
  end

  def answer_for_seed
    RubyWordle::Game.new(small_dictionary, random: Random.new(1)).answer
  end
end
