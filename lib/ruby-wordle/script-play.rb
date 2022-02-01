#! /usr/bin/env ruby

require "readline"
require "script-solver"

module RubyWordlePlay
  NUM_LETTERS = 5
  NUM_ATTEMPTS = 6

  LPAD = " " * 1
  PROMPT = "〉".bold.red

  @word_list_basic = File.readlines("#{HOME_DIR}/word-lists/#{NUM_LETTERS}-letters/word-list-basic.txt").map(&:strip)
  @word_list_original = File.readlines("#{HOME_DIR}/word-lists/#{NUM_LETTERS}-letters/word-list.txt").map(&:strip)
  @word = @word_list_basic.sample
  @not_used = []
  @not_used_here = {1 => [], 2 => [], 3 => [], 4 => [], 5 => []}
  @letters_known = ".....".split(//)

  def self.check_dict(attempt)
    @word_list_original.include?(attempt)
  end

  def self.evaluate(attempt)
    puts
    @letters_known = attempt.split(//)
    correct = []
    wrong   = []
    @word.split(//).each_with_index do |l, i|
      if attempt[i] == l
        correct << i
      else
        wrong << i
        @letters_known[i] = '.'
      end
    end
    attempt.split(//).each_with_index do |l, i|
      if correct.include?(i)
        print " #{@word[i]} ".upcase.bg_green
      else
        elsewhere = wrong.map{|i|@word[i]}.index(l)
        if elsewhere
          print " #{l} ".upcase.bg_brown
          @not_used_here[i + 1] << l unless @not_used_here[i + 1].include? l
        else
          print "   ".bg_gray
          @not_used << attempt[i] if /[a-z]/ =~ attempt[i]
          @not_used.uniq!
          @not_used.sort!
        end
      end
    end
    puts
    correct.size == NUM_LETTERS
  end

  def self.get_help
    letters_used = []
    @not_used_here.each do |k, v|
      v.each do |r|
        letters_used << [k - 1, r]
      end
    end
    RubyWordleSolver.solve_wordle(@letters_known.join, letters_used, @not_used, :basic, @word)
  end

  def self.ask_for_attempt(str)
    puts
    print  " #{str} ".bold.bg_cyan + " "
    attempt = Readline.readline(LPAD + PROMPT, true).strip.downcase
    if attempt == "quit" || attempt == "q"
      exit
    elsif attempt == "help" || attempt == "h" || attempt == "?"
      get_help
      attempt = ask_for_attempt(str)
    end

    unless /\A[a-z]{5}\z/ =~ attempt
      puts
      puts LPAD + "Sorry,".red + " the input format is not right"
      puts
      attempt = ask_for_attempt(str)
    end

    unless check_dict(attempt)
      puts
      puts LPAD + "Sorry,".red + " it's not listed in the dictionary"
      puts
      attempt = ask_for_attempt(str)
    end
    attempt
  end

  def self.draw_decorated_border
    puts
    puts (' '.bg_green * 5 + ' '.bg_gray * 3 + ' '.bg_brown  * 5 + ' '.bg_gray * 3) * 4
    puts
  end

  def play_wordle
    draw_decorated_border;
    puts "Input a word of 5 letters and press \"↵\"".cyan.bold
    puts "Type \"?↵\" for help, \"quit↵\" to exit".gray

    NUM_ATTEMPTS.times do |i|
      attempt = ask_for_attempt("#{i + 1}/#{NUM_ATTEMPTS}")
      result = evaluate(attempt)
      puts
      if result
        puts "C O R R E C T !".upcase.bg_magenta
        exit
      elsif i + 1 == NUM_ATTEMPTS
        puts " ANSWER: #{@word} ".upcase.bg_red
        exit
      else
        puts @not_used.uniq.map{|l| " #{l.upcase} "}.join.bg_black if !@not_used.empty?
        puts
      end
    end
    draw_decorated_border
  end

  module_function :play_wordle
end
