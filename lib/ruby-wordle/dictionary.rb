require "set"

module RubyWordle
  # Word lists for one word length.
  #
  # +answers+ are common words a game picks from; +guesses+ are every word
  # accepted as a guess. Every answer is also a valid guess.
  class Dictionary
    DATA_DIR = File.expand_path("../../word-lists", __dir__)
    WORD_LENGTH = 5

    attr_reader :answers, :guesses, :length

    def self.load(dir = File.join(DATA_DIR, "#{WORD_LENGTH}-letters"), length: WORD_LENGTH)
      read = ->(name) { File.readlines(File.join(dir, name), chomp: true) }
      new(answers: read.("word-list-basic.txt"), guesses: read.("word-list.txt"), length: length)
    end

    def self.default
      @default ||= load
    end

    def initialize(answers:, guesses:, length: WORD_LENGTH)
      @length = length
      invalid = (answers + guesses).grep_v(/\A[a-z]{#{length}}\z/)
      raise ArgumentError, "not #{length} letters a-z: #{invalid.first(3).join(', ')}" unless invalid.empty?
      raise ArgumentError, "no answers" if answers.empty?

      @answers = answers.uniq.sort.freeze
      @guesses = (guesses | answers).sort.freeze
      @answer_set = @answers.to_set
      @guess_set = @guesses.to_set
    end

    def valid_guess?(word)
      @guess_set.include?(word)
    end

    def common?(word)
      @answer_set.include?(word)
    end

    # Keeps alphabetic words of +length+ letters, lowercased. Capitalized
    # entries in a source list (proper nouns) are dropped when
    # +lowercase_only+ is set.
    def self.normalize(lines, length:, lowercase_only: false)
      lines.map(&:strip)
           .reject { |w| lowercase_only && w.match?(/\A[A-Z][a-z]/) }
           .map(&:downcase)
           .select { |w| w.match?(/\A[a-z]{#{length}}\z/) }
           .uniq
           .sort
    end

    # Writes the n-letter lists derived from the full and basic source lists.
    def self.generate(length:, source_dir: DATA_DIR, out_dir: File.join(source_dir, "#{length}-letters"))
      read = ->(name) { File.readlines(File.join(source_dir, name), chomp: true) }
      basic = normalize(read.("word-list-basic.txt"), length: length, lowercase_only: true)
      all = (normalize(read.("word-list-original.txt"), length: length) | basic).sort
      uniq = ->(words) { words.select { |w| w.chars.uniq.size == length } }

      Dir.mkdir(out_dir) unless Dir.exist?(out_dir)
      {
        "word-list.txt" => all,
        "word-list-uniq-letters.txt" => uniq.(all),
        "word-list-basic.txt" => basic,
        "word-list-basic-uniq-letters.txt" => uniq.(basic)
      }.each do |name, words|
        File.write(File.join(out_dir, name), words.map { |w| "#{w}\n" }.join)
      end
      out_dir
    end
  end
end
