require "ruby-wordle/feedback"

module RubyWordle
  # Narrows down the words consistent with a history of guesses and
  # feedback, and ranks the next guess.
  #
  # A word stays a candidate only if scoring it as the answer reproduces
  # every observed pattern, so repeated letters are handled exactly as the
  # game scores them.
  class Solver
    Suggestion = Struct.new(:word, :expected, :possible)

    SAMPLE_SIZE = 400
    PROBE_SIZE = 300

    attr_reader :dictionary, :history, :candidates

    def initialize(dictionary, pool: dictionary.guesses)
      @dictionary = dictionary
      @pool = pool
      reset
    end

    def reset
      @history = []
      @candidates = @pool
      self
    end

    def add(guess, pattern)
      guess = guess.dup.freeze
      @history << [guess, pattern]
      @candidates = @candidates.select { |word| Feedback.score(guess, word) == pattern }
      self
    end

    def undo
      previous = @history[0...-1]
      reset
      previous.each { |guess, pattern| add(guess, pattern) }
      self
    end

    # Candidates that are common words; the answer is most likely among them.
    def likely
      common = @candidates.select { |w| @dictionary.common?(w) }
      common.empty? ? @candidates : common
    end

    # Ranks guesses by the expected number of likely candidates left after
    # playing them (lower is better), preferring words that can still be
    # the answer on ties. Large sets are estimated from an even sample.
    def suggest(limit = 10)
      targets = likely
      return [] if targets.empty?

      sample = spread(targets, SAMPLE_SIZE)
      scale = targets.size.to_f / (sample.size**2)
      possible = @candidates.to_h { |w| [w, true] }

      ranked = probes(targets).map do |probe|
        buckets = Hash.new(0)
        sample.each { |answer| buckets[Feedback.score(probe, answer)] += 1 }
        expected = buckets.each_value.sum { |n| n * n } * scale
        Suggestion.new(probe, expected, possible.key?(probe))
      end

      ranked.min_by(limit) { |s| [s.expected, s.possible ? 0 : 1, s.word] }
    end

    private

    def spread(words, size)
      return words if words.size <= size

      Array.new(size) { |i| words[i * words.size / size] }
    end

    # The targets themselves plus guesses whose letters split the targets
    # most evenly, which can narrow them down better than any target can.
    def probes(targets)
      frequency = Hash.new(0)
      targets.each { |w| w.chars.uniq.each { |c| frequency[c] += 1 } }
      split = frequency.transform_values { |n| n * (targets.size - n) }
      coverage = ->(w) { -w.chars.uniq.sum { |c| split.fetch(c, 0) } }

      own = targets.size <= PROBE_SIZE ? targets : targets.min_by(PROBE_SIZE, &coverage)
      others = @dictionary.guesses.min_by(PROBE_SIZE / 2, &coverage)
      own | others
    end
  end
end
