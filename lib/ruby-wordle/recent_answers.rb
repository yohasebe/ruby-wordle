require "fileutils"

module RubyWordle
  # The answers of the last games, kept in a file so that the game does not
  # pick them again soon. Without a usable file nothing is remembered.
  class RecentAnswers
    LIMIT = 200
    # A larger file was not written by this class and is ignored.
    MAX_BYTES = 64 * 1024

    def self.for(env)
      base = env["XDG_STATE_HOME"].to_s
      base = File.join(env["HOME"], ".local", "state") if !File.absolute_path?(base) && env["HOME"]
      new(File.absolute_path?(base) ? File.join(base, "ruby-wordle", "recent-answers.txt") : nil)
    end

    def initialize(path)
      @path = path
    end

    # Picks a word of +answers+ that is not a recent answer, or any word if all
    # are, and records it. The file stays locked meanwhile, so games started at
    # the same time pick different words.
    def pick(answers, random)
      with_file do |file|
        recent = file && read(file)
        pool = answers - recent.to_a
        word = (pool.empty? ? answers : pool).sample(random: random)
        write(file, recent, word) if recent
        word
      end
    end

    def words
      with_file { |file| file && read(file) }.to_a
    end

    private

    def with_file
      file = open_locked
      yield file
    ensure
      file&.close
    end

    def open_locked
      return unless @path

      FileUtils.mkdir_p(File.dirname(@path))
      return if File.exist?(@path) && !File.file?(@path)

      file = File.open(@path, File::RDWR | File::CREAT, 0o644)
      file.flock(File::LOCK_EX)
      file
    rescue SystemCallError
      file&.close
      nil
    end

    # The recorded words, or nil if the file cannot be read.
    def read(file)
      data = file.read(MAX_BYTES + 1)
      return [] if data.nil? || data.bytesize > MAX_BYTES

      data.force_encoding(Encoding::UTF_8).scrub.split("\n").grep(/\A[a-z]+\z/).last(LIMIT)
    rescue SystemCallError
      nil
    end

    def write(file, recent, word)
      file.rewind
      file.write(((recent - [word]) << word).last(LIMIT).join("\n") << "\n")
      file.flush
      file.truncate(file.pos)
    rescue SystemCallError
      nil
    end
  end
end
