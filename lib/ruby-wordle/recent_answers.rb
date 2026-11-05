require "fileutils"

module RubyWordle
  # The answers of the last games, kept in a file so that the game does not
  # pick them again soon. Without a usable file nothing is remembered.
  class RecentAnswers
    LIMIT = 200

    def self.for(env)
      base = env["XDG_STATE_HOME"].to_s
      base = File.join(env["HOME"], ".local", "state") if !base.start_with?("/") && env["HOME"]
      new(base.start_with?("/") ? File.join(base, "ruby-wordle", "recent-answers.txt") : nil)
    end

    def initialize(path)
      @path = path
    end

    def words
      @path ? File.readlines(@path, chomp: true) : []
    rescue SystemCallError
      []
    end

    def add(word)
      return unless @path

      FileUtils.mkdir_p(File.dirname(@path))
      File.write(@path, ((words - [word]) << word).last(LIMIT).join("\n") + "\n")
    rescue SystemCallError
      nil
    end
  end
end
