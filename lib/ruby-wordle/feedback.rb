module RubyWordle
  # Wordle feedback for one guess against one answer.
  #
  # A pattern is an Integer in base 3, one digit per position (position 0 is
  # the least significant digit): 0 = absent, 1 = present elsewhere,
  # 2 = correct. Integers keep the solver's partitioning cheap.
  module Feedback
    ABSENT  = 0
    PRESENT = 1
    CORRECT = 2

    SYMBOLS = { "x" => ABSENT, "b" => ABSENT, "0" => ABSENT, "-" => ABSENT, "." => ABSENT,
                "y" => PRESENT, "1" => PRESENT,
                "g" => CORRECT, "2" => CORRECT }.freeze

    module_function

    def score(guess, answer)
      size = guess.bytesize
      marks = Array.new(size, ABSENT)
      remaining = Hash.new(0)

      size.times do |i|
        if guess.getbyte(i) == answer.getbyte(i)
          marks[i] = CORRECT
        else
          remaining[answer.getbyte(i)] += 1
        end
      end

      size.times do |i|
        next if marks[i] == CORRECT

        byte = guess.getbyte(i)
        if remaining[byte] > 0
          marks[i] = PRESENT
          remaining[byte] -= 1
        end
      end

      encode(marks)
    end

    def encode(marks)
      marks.reverse_each.reduce(0) { |acc, mark| acc * 3 + mark }
    end

    def decode(pattern, size)
      Array.new(size) do
        mark = pattern % 3
        pattern /= 3
        mark
      end
    end

    def solved(size)
      encode(Array.new(size, CORRECT))
    end

    # Parses user notation such as "xygxx", "01200" or "b.y-g".
    # Returns nil when the text is not a valid pattern of the given size.
    def parse(text, size)
      chars = text.downcase.chars
      return nil unless chars.size == size && chars.all? { |c| SYMBOLS.key?(c) }

      encode(chars.map { |c| SYMBOLS[c] })
    end

    def notation(pattern, size)
      decode(pattern, size).map { |mark| "xyg"[mark] }.join
    end
  end
end
