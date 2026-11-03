require "ruby-wordle/feedback"

module RubyWordle
  # Terminal styling. With color disabled, marks are shown with brackets:
  # [A] correct, (A) present elsewhere, and a plain lowercase letter absent.
  class Style
    CODES = { bold: 1, dim: 2, underline: 4, red: 31, green: 32, yellow: 33,
              blue: 34, magenta: 35, cyan: 36, gray: 90 }.freeze
    # Fixed 256-color tiles (green, yellow, gray with white letters) look the
    # same in every terminal theme.
    TILE_CODES = { Feedback::CORRECT => "1;38;5;231;48;5;71", Feedback::PRESENT => "1;38;5;231;48;5;178",
                   Feedback::ABSENT => "1;38;5;231;48;5;240" }.freeze
    EMOJI = { Feedback::CORRECT => "🟩", Feedback::PRESENT => "🟨", Feedback::ABSENT => "⬛" }.freeze

    def self.for(output, env = ENV)
      new(color: output.respond_to?(:tty?) && output.tty? && env["NO_COLOR"].to_s.empty?)
    end

    def initialize(color:)
      @color = color
    end

    def color?
      @color
    end

    def paint(text, *styles)
      return text.to_s unless @color && !styles.empty?

      "\e[#{styles.map { |s| CODES.fetch(s) }.join(';')}m#{text}\e[0m"
    end

    # A letter tile; +mark+ is a Feedback mark, or nil for an untested letter.
    def tile(char, mark)
      if @color
        mark ? "\e[#{TILE_CODES.fetch(mark)}m #{char.upcase} \e[0m" : " #{char.upcase} "
      else
        case mark
        when Feedback::CORRECT then "[#{char.upcase}]"
        when Feedback::PRESENT then "(#{char.upcase})"
        when Feedback::ABSENT then " #{char.downcase} "
        else " #{char.upcase} "
        end
      end
    end

    def row(word, pattern)
      marks = Feedback.decode(pattern, word.length)
      word.chars.zip(marks).map { |char, mark| tile(char, mark) }.join(" ")
    end

    def emoji(pattern, length)
      Feedback.decode(pattern, length).map { |mark| EMOJI[mark] }.join
    end
  end
end
