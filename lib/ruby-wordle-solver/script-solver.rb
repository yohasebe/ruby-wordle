#! /usr/bin/env ruby

HOME_DIR = File.expand_path(File.join(File.dirname(__FILE__), "..", ".."))

require "readline"
require "script-utils"

module RubyWordleSolver
  NUM_LETTERS = 5
  MAX_SUGGESTIONS = 128

  LPAD = " " * 7
  PROMPT = "〉".bold.red

  @word_list = File.readlines("#{HOME_DIR}/word-lists/#{NUM_LETTERS}-letters/word-list.txt").map(&:strip)
  @word_list_basic = File.readlines("#{HOME_DIR}/word-lists/#{NUM_LETTERS}-letters/word-list-basic.txt").map(&:strip)

  @basic_word_list = {}
  File.readlines("#{HOME_DIR}/word-lists/#{NUM_LETTERS}-letters/word-list-basic.txt").map(&:strip).each do |b|
    @basic_word_list[b] = true
  end

  @basic_word_uniq_list = {}
  File.readlines("#{HOME_DIR}/word-lists/#{NUM_LETTERS}-letters/word-list-basic-uniq-letters.txt").map(&:strip).each do |b|
    @basic_word_uniq_list[b] = true
  end

  @letters_known = nil
  @letters_used  = nil
  @letters_not_used = nil

  def self.get_letters_known
    puts
    puts  "STEP 1".bold.bg_green + " Input " + "known letters".underline + " using alphabets and dots"
    puts  LPAD + "Then press \"↵\" (Type \"quit↵\" to exit)"
    if @letters_known
      puts LPAD + "Last time: #{@letters_known.bg_green}"
    else
      puts LPAD + "Example: #{'s...h'.bg_green}"
    end

    letters_known = Readline.readline(LPAD + PROMPT, true).strip.downcase

    exit if letters_known == "quit" || letters_known == "q"
    unless /\A[a-z\.]{5}\z/ =~ letters_known
      puts LPAD + "Sorry,".red + " the input format is not right"
      letters_known = get_letters_known
    end
    letters_known
  end

  def self.get_letters_used
    puts
    puts "STEP 2".bold.bg_brown + " Input pairs of " + "a position and a letter".underline
    puts LPAD + "Then press \"↵\" (Type \"quit↵\" to exit)"
    if @letters_used
      puts LPAD + "Last time: #{@letters_used.map{|p, l| (p + 1).to_s + l}.join(' ').bg_brown}"
    else
      puts LPAD + "Example: #{'1g 2e 5a'.bg_brown}"
    end

    letters_used = Readline.readline(LPAD + PROMPT, true).strip.downcase

    exit if letters_used == "quit" || letters_used == "q"
    if letters_used.strip == ""
      array_letters_used = []
    elsif /\A(?:[1-5][a-z][\s,]*)+\z/ =~ letters_used
      array_letters_used = []
      letters_used.gsub(/\s+/, "").split(//).each_slice(2) do |k, v|
        array_letters_used << [k.to_i - 1, v]
      end
    else
      puts LPAD + "Sorry,".red + " the input format is not right"
      array_letters_used = get_letters_used
    end
    array_letters_used
  end

  def self.get_letters_not_used
    puts
    puts "STEP 3".bold.bg_gray + " Input " + "letters not used".underline + " in the word"
    puts LPAD + "Then press \"↵\" (Type \"quit↵\" to exit)"
    if @letters_not_used
      puts LPAD + "Last time: #{@letters_not_used.join.bg_gray}"
    else
      puts LPAD + "Example: #{'ieagh'.bg_gray}"
    end

    letters_not_used = Readline.readline(LPAD + PROMPT, true).strip.downcase

    exit if letters_not_used == "quit" || letters_not_used == "q"
    if letters_not_used.strip == ""
      array_letters_not_used = []
    elsif /\A[a-z\s]+\z/ =~ letters_not_used
      array_letters_not_used = letters_not_used.split(//)
    else
      puts LPAD + "Sorry,".red + " the input format is not right"
      array_letters_not_used = get_letters_not_used
    end
    array_letters_not_used
  end

  def self.draw_decorated_border
    puts; puts (' '.bg_green * 5 + ' '.bg_gray * 3 + ' '.bg_brown  * 5 + ' '.bg_gray * 3) * 4; puts
  end

  def solve_wordle(letters_known, letters_used, letters_not_used, mode = :original, answer = nil)
    word_list = mode == :original ? @word_list : @word_list_basic
    indices_unknown_letters = (0 ... letters_known.length).find_all { |i| letters_known[i, 1] == '.' }

    word_list_a = word_list.select do |word|
      Regexp.compile(letters_known) =~ word
    end

    word_list_b = word_list_a.select do |word|
      word_letters = word.split(//)
      letters_in_candidate = word_letters.values_at(*indices_unknown_letters) - letters_used.map{|l| l[1]}
      cond1 = letters_used.all? do |position, letter|
        word_letters[position] != letter
      end
      cond2 = (letters_used.map{|l| l[1]} - word_letters).empty?
      cond3 = (letters_in_candidate - letters_not_used).size == letters_in_candidate.size
      cond1 && cond2 && cond3
    end

    if answer
      word_list_b.delete(answer)
      reduced_list = word_list_b.sample(MAX_SUGGESTIONS - 1)
      reduced_list << answer
    else
      reduced_list = word_list_b.sample(MAX_SUGGESTIONS)
    end

    results = reduced_list.sort.map do |word|
      if @basic_word_uniq_list[word]
        mode == :original ? word.red.bold : word.red
      elsif @basic_word_list[word]
        mode == :original ? word.blue.bold : word.blue
      else
        word
      end
    end
    puts
    results.each_with_index do |word, i|
      if (i + 1) % 8 == 0 || results.size == i + 1
        print word + "\n"
      else
        print word + "   "
      end
    end
    word_list_b
  end

  def run_interactively
    draw_decorated_border
    @letters_known = get_letters_known
    @letters_used  = get_letters_used
    @letters_not_used = get_letters_not_used
    results = solve_wordle(@letters_known, @letters_used, @letters_not_used)
    draw_decorated_border

    exit if results.size < 2

    puts "  ？  ".bold.bg_magenta + " Press \"↵\" to continue."
    puts LPAD + "Type \"quit↵\" to exit."

    response = Readline.readline(LPAD + PROMPT, true).strip.downcase

    if response == "quit" || response == "q"
      exit
    else
      run_interactively
    end
  end

  module_function :run_interactively
  module_function :solve_wordle
end

