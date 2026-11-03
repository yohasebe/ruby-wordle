$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "ruby-wordle"
require "minitest/autorun"
require "stringio"

module TestHelper
  F = RubyWordle::Feedback

  def pattern(text)
    F.parse(text, text.size)
  end

  def small_dictionary
    RubyWordle::Dictionary.new(
      answers: %w[cigar apple those abide shell cider eerie],
      guesses: %w[array level speed allee apply geese crane slate zzzzz]
    )
  end
end
