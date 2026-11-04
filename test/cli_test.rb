require_relative "test_helper"

class CLITest < Minitest::Test
  include TestHelper

  def run_cli(args, input = "", clipboard: ->(_) { false })
    out = StringIO.new
    cli = RubyWordle::CLI.new(input: StringIO.new(input), output: out, dictionary: small_dictionary,
                              random: Random.new(1), env: {}, clipboard: clipboard)
    [cli.run(args), out.string]
  end

  def answer
    RubyWordle::Game.new(small_dictionary, random: Random.new(1)).answer
  end

  def test_share_copies_emoji_result
    copied = nil
    status, out = run_cli(["play"], "#{answer}\ns\nn\n", clipboard: ->(text) { copied = text })
    assert_equal 0, status
    assert_equal "ruby-wordle 1/6\n\n🟩🟩🟩🟩🟩\n", copied
    assert_includes out, "Copied"
    refute_includes out, "🟩"
  end

  def test_share_prints_result_without_clipboard
    wrong = (small_dictionary.answers - [answer]).first
    _, out = run_cli(["play"], "#{wrong}\nq\ns\nn\n")
    assert_includes out, "ruby-wordle X/6"
    assert_includes out, "⬛"
  end

  def test_no_share_without_guesses
    _, out = run_cli(["play"], "q\ns\n")
    refute_includes out, "share"
    refute_includes out, "ruby-wordle X/6"
  end

  def test_version_and_help
    status, out = run_cli(["-v"])
    assert_equal 0, status
    assert_includes out, RubyWordle::VERSION
    assert_equal 1, run_cli(["bogus"]).first
  end

  def test_options_after_command
    assert_includes run_cli(["solve", "--help"]).last, "Usage"
    assert_equal [0, "ruby-wordle #{RubyWordle::VERSION}\n"], run_cli(["play", "--version"])
    assert_equal 1, run_cli(["play", "extra"]).first
  end

  def test_injected_streams_are_used_even_if_they_claim_a_tty
    input = StringIO.new("cigar ggxxg\n")
    output = StringIO.new
    [input, output].each { |io| def io.tty? = true }
    RubyWordle::CLI.new(input: input, output: output, dictionary: small_dictionary, env: {}).run(["solve"])
    assert_includes output.string, "The answer is"
  end

  def test_interrupt_exits_with_130
    input = Object.new
    def input.gets = raise(Interrupt)
    def input.tty? = false
    cli = RubyWordle::CLI.new(input: input, output: StringIO.new, dictionary: small_dictionary, env: {})
    assert_equal 130, cli.run(["solve"])
  end

  def test_loss_after_six_turns
    status, out = run_cli(["play"], "zzzzz\n" * 6 + "n\n")
    assert_equal 0, status
    assert_includes out, "The answer was"
  end

  def test_output_has_no_escape_codes_without_tty
    _, out = run_cli(["solve", "crane:xyxxx"])
    refute_includes out, "\e["
  end

  def test_solve_once
    status, out = run_cli(["solve", "level:#{F.notation(F.score('level', 'apple'), 5)}"])
    assert_equal 0, status
    assert_includes out, "apple"
    refute_includes out, "shell"
  end

  def test_solve_groups_common_words_first
    _, out = run_cli(["solve", "zzzzz:xxxxx"])
    common = out.index("Common words:")
    other = out.index("Other words:")
    assert common && other && common < other
    assert_operator out.index("cigar"), :<, other
    assert_operator out.index("array"), :>, other
  end

  def list_output(common:, other:, all: false)
    words = ("aaaaa"..).first(common + other)
    dictionary = RubyWordle::Dictionary.new(answers: words.first(common), guesses: words)
    out = StringIO.new
    cli = RubyWordle::CLI.new(input: StringIO.new, output: out, dictionary: dictionary, env: {})
    cli.send(:list, words, all: all)
    out.string
  end

  def test_list_limit_counts_both_groups
    limit = RubyWordle::CLI::LISTED
    out = list_output(common: limit - 2, other: 5)
    assert_includes out, "Other words:"
    assert_equal limit, out.scan(/\b[a-z]{5}\b(?!:)/).size
    assert_includes out, "... 3 more (type all)"
    refute_includes list_output(common: limit + 1, other: 3), "Other words:"
    all = list_output(common: limit - 2, other: 5, all: true)
    assert_includes all, "Other words:"
    refute_includes all, "more (type all)"
  end

  def test_probe_suggestions_are_marked_without_colors
    cli = RubyWordle::CLI.new(input: StringIO.new, output: StringIO.new, dictionary: small_dictionary, env: {})
    assert_equal "crane (probe)", cli.send(:try_word, RubyWordle::Solver::Suggestion.new("crane", 1.0, false))
    assert_equal "cigar", cli.send(:try_word, RubyWordle::Solver::Suggestion.new("cigar", 1.0, true))
  end

  def test_solve_once_rejects_bad_turn
    assert_equal 1, run_cli(["solve", "crane:xyz"]).first
    assert_equal 1, run_cli(["solve", "cigar:ggggg", "apple:xxxxx"]).first
  end

  def test_interactive_solve_until_eof
    status, out = run_cli(["solve"], "cigar ggxxg\nundo\nbad\n")
    assert_equal 0, status
    assert_includes out, "The answer is CIDER"
    assert_includes out, "Sorry"
  end

  def test_solve_ends_when_solved
    status, out = run_cli(["solve"], "crane gyyxx\ncigar ggggg\nn\nlevel xxxxx\n")
    assert_equal 0, status
    assert_includes out, "Solved in 2!"
    assert_includes out, "Solve another? [y/N]"
    refute_includes out, "3 >"
  end

  def test_contradicting_turns_are_not_solved
    status, out = run_cli(["solve"], "crane xxxxx\ncigar ggggg\nundo\n")
    assert_equal 0, status
    refute_includes out, "Solved"
    assert_includes out, "No word matches"
    assert_includes out, "3 >"
    assert_equal 1, run_cli(["solve", "crane:xxxxx", "cigar:ggggg"]).first
    assert_equal 1, run_cli(["solve", "cigar:ggggg", "apple:ggggg"]).first
  end

  def test_solved_word_need_not_be_in_the_list
    status, out = run_cli(["solve", "fence:ggggg"])
    assert_equal 0, status
    assert_includes out, "Solved in 1!"
  end

  def test_end_of_input_at_solve_another
    status, out = run_cli(["solve"], "cigar ggggg\n")
    assert_equal 0, status
    assert out.end_with?("Solve another? [y/N] ")
  end

  def test_solve_another_starts_over
    _, out = run_cli(["solve"], "cigar ggggg\ny\n")
    assert_includes out.split("Solve another?").last, "1 >"
  end

  def test_solve_once_when_solved
    status, out = run_cli(["solve", "cigar:ggggg"])
    assert_equal 0, status
    assert_includes out, "Solved in 1!"
  end

  def test_play_win
    status, out = run_cli(["play"], "qqqqq\n#{answer}\nn\n")
    assert_equal 0, status
    assert_includes out, "not in the word list"
    assert_includes out, "Solved in 1/6"
    assert_includes out, "[#{answer[0].upcase}]"
  end

  def test_play_hint_and_give_up_at_eof
    status, out = run_cli(["play"], "?\nlevel\n")
    assert_equal 0, status
    assert_includes out, "#{small_dictionary.answers.size} words still fit"
    assert_includes out, "The answer was"
  end

  def test_hint_never_names_the_word
    dict = RubyWordle::Dictionary.new(answers: %w[apple cigar], guesses: [])
    secret = RubyWordle::Game.new(dict, random: Random.new(1)).answer
    other = (dict.answers - [secret]).first
    out = StringIO.new
    RubyWordle::CLI.new(input: StringIO.new("#{other}\n?\n?\nhint letter\nq\n"), output: out,
                        dictionary: dict, random: Random.new(1), env: {}, clipboard: ->(_) { false }).run(["play"])
    during = out.string.split("The answer was").first
    assert_includes during, "One word fits your clues."
    refute_match(/#{secret}/i, during.gsub("Hint: letter", ""))
    assert_includes during, "Hint: letter 1 is #{secret[0].upcase}"
    assert_includes during, "2/6 >"
    refute_includes during, "3/6 >"
  end

  def test_repeated_hint_does_not_reveal_a_letter
    _, out = run_cli(["play"], "?\n?\n?\nq\n")
    refute_includes out, "Hint: letter"
  end

  def test_assisted_result_is_marked_in_share
    copied = nil
    run_cli(["play"], "?\n#{answer}\ns\nn\n", clipboard: ->(text) { copied = text })
    assert_equal "ruby-wordle 1/6 (assisted)\n\n🟩🟩🟩🟩🟩\n", copied
  end

  def test_assisted_loss_is_marked
    copied = nil
    _, out = run_cli(["play"], "?\nzzzzz\nq\ns\nn\n", clipboard: ->(text) { copied = text })
    assert_includes out, "(assisted)"
    assert_match(/\Aruby-wordle X\/6 \(assisted\)\n/, copied)
  end

  def test_letter_hint_marks_share
    copied = nil
    run_cli(["play"], "hint letter\n#{answer}\ns\nn\n", clipboard: ->(text) { copied = text })
    assert_match(/\Aruby-wordle 1\/6 \(assisted\)/, copied)
  end

  def test_next_round_has_no_revealed_letter
    _, out = run_cli(["play"], "hint letter\n#{answer}\ny\nq\nn\n")
    first, second = out.split("Play again?", 2)
    assert_includes first, "Hint: letter"
    refute_includes second, "Hint: letter"
  end

  def test_next_round_starts_unassisted
    copied = nil
    second = RubyWordle::Game.new(small_dictionary, random: Random.new(1).tap { |r| small_dictionary.answers.sample(random: r) }).answer
    run_cli(["play"], "?\n#{answer}\ny\n#{second}\ns\nn\n", clipboard: ->(text) { copied = text })
    assert_equal "ruby-wordle 1/6\n\n🟩🟩🟩🟩🟩\n", copied
  end
end
