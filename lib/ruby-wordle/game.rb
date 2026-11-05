require "ruby-wordle/feedback"

module RubyWordle
  # One round of Wordle with a hidden answer.
  class Game
    class InvalidGuess < StandardError; end
    class UnknownWord < InvalidGuess; end

    MAX_ATTEMPTS = 6

    attr_reader :answer, :history, :max_attempts, :dictionary, :revealed

    def initialize(dictionary, answer: nil, random: Random.new, max_attempts: MAX_ATTEMPTS)
      @dictionary = dictionary
      @answer = answer || dictionary.answers.sample(random: random)
      raise ArgumentError, "#{@answer} is not in the word list" unless dictionary.valid_guess?(@answer)

      @max_attempts = max_attempts
      @history = []
      @assisted = false
      @revealed = nil
    end

    # Marks that the player used a hint.
    def assist!
      @assisted = true
    end

    def assisted?
      @assisted
    end

    # Reveals the letter at the first position never guessed correctly, once
    # per game, as [position, letter]. Returns nil when fewer than two
    # positions have never been guessed correctly.
    def reveal
      return @revealed if @revealed

      found = @history.flat_map do |_, pattern|
        marks = Feedback.decode(pattern, length)
        marks.each_index.select { |i| marks[i] == Feedback::CORRECT }
      end
      unknown = (0...length).to_a - found
      return nil if unknown.size < 2

      assist!
      @revealed = [unknown.first, @answer[unknown.first]]
    end

    def length
      @answer.length
    end

    def guess(word)
      raise InvalidGuess, "the game is over" if over?
      raise InvalidGuess, "type #{length} letters (a-z)" unless word.match?(/\A[a-z]{#{length}}\z/)
      raise UnknownWord, "\"#{word}\" is not in the word list" unless @dictionary.valid_guess?(word)

      pattern = Feedback.score(word, @answer)
      @history << [word, pattern]
      pattern
    end

    def won?
      @history.any? { |_, pattern| pattern == Feedback.solved(length) }
    end

    def over?
      won? || @history.size >= @max_attempts
    end

    def attempts_left
      @max_attempts - @history.size
    end

    # The best feedback seen for each guessed letter, for the keyboard.
    def letter_states
      @history.each_with_object({}) do |(word, pattern), states|
        word.chars.zip(Feedback.decode(pattern, length)) do |char, mark|
          states[char] = mark if states.fetch(char, -1) < mark
        end
      end
    end
  end
end
