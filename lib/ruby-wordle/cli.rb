require "ruby-wordle/version"
require "ruby-wordle/feedback"
require "ruby-wordle/dictionary"
require "ruby-wordle/game"
require "ruby-wordle/recent_answers"
require "ruby-wordle/solver"
require "ruby-wordle/style"

module RubyWordle
  # Command-line front end for playing and solving.
  class CLI
    KEYBOARD = %w[qwertyuiop asdfghjkl zxcvbnm].freeze
    SUGGESTIONS = 5
    LISTED = 40
    COLUMNS = 8

    USAGE = <<~TEXT.freeze
      Usage: ruby-wordle <command> [options]

      Commands:
        play                     Play a game against the computer
        solve                    Find the answer of a game played elsewhere
        solve GUESS:COLORS ...   Print candidates for the given turns and exit

      COLORS has one character per letter: g = green, y = yellow, x = gray.
      Example: ruby-wordle solve crane:xyxxg

      Options:
        --no-color     Disable colors (also when NO_COLOR is not empty)
        -v, --version  Show the version
        -h, --help     Show this help
    TEXT

    CLIPBOARD_COMMANDS = [%w[pbcopy], %w[wl-copy], %w[xclip -selection clipboard], %w[xsel --clipboard --input]].freeze

    # +clipboard+ takes the text to copy and returns whether it was copied.
    def initialize(input: $stdin, output: $stdout, dictionary: nil, random: Random.new, env: ENV, clipboard: nil,
                   recent: RecentAnswers.for(env))
      @input = input
      @output = output
      @dictionary = dictionary
      @random = random
      @recent = recent
      @clipboard = clipboard || method(:copy_to_system_clipboard)
      @style = Style.for(output, env)
    end

    def run(argv)
      args = argv.dup
      @style = Style.new(color: false) if args.delete("--no-color")
      return info("ruby-wordle #{VERSION}") if args.intersect?(%w[-v --version])
      return info(USAGE) if args.empty? || args.intersect?(%w[-h --help])

      case args.shift
      when "play", "p" then args.empty? ? (play; 0) : usage_error
      when "solve", "solver", "s" then args.empty? ? (solve; 0) : solve_once(args)
      else usage_error
      end
    rescue Interrupt
      say
      130
    end

    private

    def dictionary
      @dictionary ||= Dictionary.default
    end

    def say(text = "")
      @output.puts text
      count_rows(text)
    end

    def info(text)
      say text
      0
    end

    def usage_error
      say USAGE
      1
    end

    # Reline reads and writes the process's terminal, so it is used only
    # when the CLI runs on the standard streams of a terminal.
    def interactive_terminal?
      @input.equal?($stdin) && @output.equal?($stdout) && @input.tty? && @output.tty?
    end

    # Returns the stripped line, or nil at end of input.
    def ask(prompt)
      line = interactive_terminal? ? read_terminal(prompt) : read_plain(prompt)
      typed = line&.chomp.to_s
      # The width of anything but printable ASCII depends on the terminal.
      @redraw[:reliable] = false if @redraw && !typed.match?(/\A[\x20-\x7e]*\z/)
      count_rows("#{prompt}#{typed}")
      line&.strip&.downcase
    end

    def read_terminal(prompt)
      require "reline"
      Reline.readline(prompt, true)
    end

    def read_plain(prompt)
      @output.print prompt
      @input.gets
    end

    # [height, width] of the terminal, or nil when it is unknown.
    def terminal_size
      require "io/console"
      size = @output.winsize
      size if size.all?(&:positive?)
    rescue StandardError
      nil
    end

    # --- redraw -------------------------------------------------------------
    #
    # On a terminal, the board (in the solver, the turns and the candidates) is
    # drawn over the previous one together with the prompts, hints and
    # messages printed below it. The rows printed since the board started are
    # counted; when the count may be wrong (the window was resized, or input
    # had characters of unknown width) or the rows no longer fit on the
    # screen, a new board is printed below instead.

    def start_redraw
      size = interactive_terminal? && terminal_size
      @redraw = size ? { rows: 0, size: size, reliable: true } : nil
    end

    def stop_redraw
      @redraw = nil
    end

    def count_rows(text)
      return unless @redraw

      @redraw[:reliable] = false unless terminal_size == @redraw[:size]
      width = @redraw[:size].last
      text.to_s.chomp.split("\n", -1).then { |lines| lines.empty? ? [""] : lines }.each do |line|
        columns = line.gsub(/\e\[[0-9;]*m/, "").length
        @redraw[:rows] += [(columns - 1) / width + 1, 1].max
      end
    end

    def rewind
      return unless @redraw

      size = terminal_size
      rows = @redraw[:rows]
      if @redraw[:reliable] && size == @redraw[:size] && rows.positive? && rows < size.first
        @output.print "\e[#{rows}A\r\e[J"
      end
      @redraw = size && { rows: 0, size: size, reliable: true }
    end

    def quit?(line)
      line.nil? || %w[q quit exit].include?(line)
    end

    # --- play ---------------------------------------------------------------

    def play
      loop do
        game = Game.new(dictionary, answer: @recent.pick(dictionary.answers, @random))
        play_round(game)
        options = game.history.empty? ? "[y/N]" : "[y/N/s(hare)]"
        line = ask("Play again? #{options} ")
        if %w[s share].include?(line) && !game.history.empty?
          share(game)
          line = ask("Play again? [y/N] ")
        end
        break unless %w[y yes].include?(line)
      end
    end

    def play_round(game)
      say @style.paint("Guess the #{game.length}-letter word in #{game.max_attempts} tries.", :bold, :cyan)
      say @style.paint("Type ? for a hint, q to give up.", :gray)
      start_redraw
      draw(game)

      until game.over?
        line = ask("#{game.history.size + 1}/#{game.max_attempts} > ")
        if quit?(line)
          break
        elsif line == "help"
          say @style.paint("  ? = how many words fit, hint letter = reveal a letter, q = give up", :gray)
        elsif ["?", "h", "hint"].include?(line)
          hint(game)
        elsif ["hint letter", "letter"].include?(line)
          hint_letter(game)
        elsif !line.empty?
          begin
            game.guess(line)
            draw(game)
          rescue Game::InvalidGuess => e
            say @style.paint("  Sorry, #{e.message}.", :red) +
                (e.is_a?(Game::UnknownWord) ? @style.paint(" (q to give up)", :gray) : "")
          end
        end
      end

      stop_redraw
      finish(game)
    end

    def draw(game)
      rewind
      # Tiles are 3 columns wide with 1-column gaps, so every row has an odd
      # width and the board and keyboard rows share one center column.
      width = ->(tiles) { tiles * 4 - 1 }
      full = width.(KEYBOARD.map(&:size).push(game.length).max)
      indent = ->(tiles) { "  " + " " * ((full - width.(tiles)) / 2) }

      empty = @style.paint(Array.new(game.length, " · ").join(" "), :dim)
      board = game.history.map { |word, pattern| @style.row(word, pattern) } + [empty] * game.attempts_left
      say
      # A blank line between rows keeps tiles of adjacent rows apart.
      say board.map { |row| indent.(game.length) + row }.join("\n\n")
      say
      states = game.letter_states
      KEYBOARD.each do |keys|
        say indent.(keys.size) + keys.chars.map { |c| @style.tile(c, states[c]) }.join(" ")
      end
      say
      return unless game.revealed

      say "  #{letter_clue(game)}"
      say
    end

    # Hints never name a word: they count the common words that fit the
    # guesses so far, or reveal one letter when asked explicitly.
    def hint(game)
      solver = Solver.new(dictionary, pool: dictionary.answers)
      game.history.each { |word, pattern| solver.add(word, pattern) }
      count = solver.candidates.size
      return say(@style.paint("  No word in the answer list fits; hints are unavailable.", :red)) if count.zero?

      game.assist!
      say "  #{count == 1 ? 'One word fits your clues.' : "#{count} words still fit your clues."}"
      say @style.paint("  For a stronger hint, type: hint letter (reveals one letter, once per game)", :gray) unless game.revealed
    end

    def hint_letter(game)
      if game.reveal
        say "  #{letter_clue(game)}"
      else
        say @style.paint("  A letter hint would give away the word.", :red)
      end
    end

    def letter_clue(game)
      position, letter = game.revealed
      @style.paint("Hint: letter #{position + 1} is #{letter.upcase}", :yellow)
    end

    def assisted(game)
      game.assisted? ? " (assisted)" : ""
    end

    def finish(game)
      say
      if game.won?
        say @style.paint("  Solved in #{game.history.size}/#{game.max_attempts}!#{assisted(game)}", :bold, :green)
      else
        say "  The answer was #{@style.paint(game.answer.upcase, :bold)}.#{assisted(game)}"
      end
      say
    end

    # The result as emoji squares, which keep their colors when pasted.
    def share(game)
      score = game.won? ? game.history.size : "X"
      grid = game.history.map { |_, pattern| @style.emoji(pattern, game.length) }
      text = "ruby-wordle #{score}/#{game.max_attempts}#{assisted(game)}\n\n#{grid.join("\n")}\n"
      say
      if @clipboard.call(text)
        say @style.paint("  Copied the result to the clipboard.", :green)
      else
        text.each_line { |line| say "  #{line.chomp}" }
      end
      say
    end

    def copy_to_system_clipboard(text)
      return false unless interactive_terminal?

      CLIPBOARD_COMMANDS.any? do |command|
        IO.popen(command, "w", err: File::NULL) { |io| io.write(text) }
        $?.success?
      rescue SystemCallError
        false
      end
    end

    # --- solve --------------------------------------------------------------

    def solve
      solver = Solver.new(dictionary)
      say @style.paint("Enter each guess and its colors, e.g. crane xyxxg", :bold, :cyan)
      say @style.paint("g = green, y = yellow, x = gray. Commands: undo, reset, all, q", :gray)
      start_redraw
      report(solver)

      loop do
        line = ask("#{solver.history.size + 1} > ")
        break if quit?(line)

        case line
        when "" then next
        when "undo", "u" then solver.undo
        when "reset", "r" then solver.reset
        when "all", "a" then list(solver.candidates, all: true); next
        else
          turn = parse_turn(line)
          next unless turn

          solver.add(*turn)
        end
        rewind
        show_history(solver)
        report(solver)
        next unless solved?(solver)
        break unless %w[y yes].include?(ask("Solve another? [y/N] "))

        solver.reset
        rewind
        report(solver)
      end
      stop_redraw
    end

    # The last turn is all green and every turn fits that word. The word need
    # not be in the word list.
    def solved?(solver)
      answer, pattern = solver.history.last
      return false unless pattern == Feedback.solved(dictionary.length)

      solver.history.all? { |guess, colors| Feedback.score(guess, answer) == colors }
    end

    def solve_once(args)
      solver = Solver.new(dictionary)
      args.each do |arg|
        turn = parse_turn(arg)
        return 1 unless turn

        solver.add(*turn)
      end
      show_history(solver)
      report(solver, all: true)
      solved?(solver) || !solver.candidates.empty? ? 0 : 1
    end

    # Accepts "crane xyxxg" or "crane:xyxxg".
    def parse_turn(text)
      word, colors = text.downcase.split(/[\s:]+/, 2)
      size = dictionary.length
      pattern = colors && Feedback.parse(colors, size)
      if word.to_s.match?(/\A[a-z]{#{size}}\z/) && pattern
        [word, pattern]
      else
        say @style.paint("  Sorry, write a #{size}-letter word and #{size} colors (g, y, x), e.g. crane xyxxg", :red)
        nil
      end
    end

    def show_history(solver)
      return if solver.history.empty?

      say
      say solver.history.map { |word, pattern| "  #{@style.row(word, pattern)}" }.join("\n\n")
    end

    def report(solver, all: false)
      candidates = solver.candidates
      say
      if solved?(solver)
        say @style.paint("  Solved in #{solver.history.size}!", :bold, :green)
      else
        report_candidates(solver, candidates, all)
      end
      say
    end

    def report_candidates(solver, candidates, all)
      case candidates.size
      when 0
        say @style.paint("  No word matches. Check the colors, or type undo.", :red)
      when 1
        say "  The answer is #{@style.paint(candidates.first.upcase, :bold, :green)}."
      else
        common = candidates.count { |w| dictionary.common?(w) }
        say "  #{candidates.size} words possible (#{common} common)"
        tries = solver.suggest(SUGGESTIONS).map do |s|
          "#{try_word(s)} #{@style.paint(format('~%.1f', s.expected), :dim)}"
        end
        say "  Try: #{tries.join('   ')}"
        list(candidates, all: all)
      end
    end

    # A suggestion that cannot be the answer is gray, or marked without colors.
    def try_word(suggestion)
      return @style.paint(suggestion.word, :bold) if suggestion.possible

      @style.color? ? @style.paint(suggestion.word, :gray) : "#{suggestion.word} (probe)"
    end

    # Common words, then the others, at most LISTED in all unless +all+.
    def list(words, all: false)
      limit = all ? words.size : LISTED
      shown = 0
      common, other = words.partition { |w| dictionary.common?(w) }
      [["Common words", common], ["Other words", other]].each do |label, group|
        group = group.first(limit - shown)
        next if group.empty?

        say
        say "  #{label}:"
        group.each_slice(COLUMNS) { |slice| say "  " + slice.join("  ") }
        shown += group.size
      end
      say @style.paint("  ... #{words.size - shown} more (type all)", :gray) if shown < words.size
    end
  end
end
