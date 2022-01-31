#! /usr/bin/env ruby

NUM_LETTERS = 5

@word_list = File.readlines("./word-lists/#{NUM_LETTERS}-letters/word-list.txt").map(&:strip)

@basic_word_list = {}
File.readlines("./word-lists/#{NUM_LETTERS}-letters/word-list-basic.txt").map(&:strip).each do |b|
  @basic_word_list[b] = true
end

@basic_word_uniq_list = {}
File.readlines("./word-lists/#{NUM_LETTERS}-letters/word-list-basic-uniq-letters.txt").map(&:strip).each do |b|
  @basic_word_uniq_list[b] = true
end

@letters_known = nil
@letters_used  = nil
@letters_not_used = nil

class String
  def black;          "\e[30m#{self}\e[0m" end
  def red;            "\e[31m#{self}\e[0m" end
  def green;          "\e[32m#{self}\e[0m" end
  def brown;          "\e[33m#{self}\e[0m" end
  def blue;           "\e[34m#{self}\e[0m" end
  def magenta;        "\e[35m#{self}\e[0m" end
  def cyan;           "\e[36m#{self}\e[0m" end
  def gray;           "\e[37m#{self}\e[0m" end

  def bg_black;       "\e[40m#{self}\e[0m" end
  def bg_red;         "\e[41m#{self}\e[0m" end
  def bg_green;       "\e[42m#{self}\e[0m" end
  def bg_brown;       "\e[43m#{self}\e[0m" end
  def bg_blue;        "\e[44m#{self}\e[0m" end
  def bg_magenta;     "\e[45m#{self}\e[0m" end
  def bg_cyan;        "\e[46m#{self}\e[0m" end
  def bg_gray;        "\e[47m#{self}\e[0m" end

  def bold;           "\e[1m#{self}\e[22m" end
  def italic;         "\e[3m#{self}\e[23m" end
  def underline;      "\e[4m#{self}\e[24m" end
  def blink;          "\e[5m#{self}\e[25m" end
  def reverse_color;  "\e[7m#{self}\e[27m" end
end

def get_letters_known
  puts
  puts  "STEP 1".bold.bg_green + " Input " + "known letters".underline + " using alphabets and dots"
  puts  "       Then press \"↵\" (Type \"quit↵\" to exit)"
  if @letters_known
    puts  "       Last time: #{@letters_known.bg_green}"
  else
    puts  "       Example: #{'s...h'.bg_green}"
  end
  print "       ＞ "
  letters_known = gets.strip.downcase
  exit if letters_known == "quit" || letters_known == "q"
  unless /\A[a-z\.]{5}\z/ =~ letters_known
    puts "Sorry, the input format is not right"
    letters_known = get_letters_known
  end
  letters_known
end

def get_letters_used
  puts
  puts  "STEP 2".bold.bg_brown + " Input pairs of " + "a position and a letter".underline
  puts  "       Then press \"↵\" (Type \"quit↵\" to exit)"
  if @letters_used
    puts  "       Last time: #{@letters_used.map{|p, l| (p + 1).to_s + l}.join(' ').bg_brown}"
  else
    puts  "       Example: #{'1g 2e 5a'.bg_brown}"
  end
  print "       ＞ "
  letters_used = gets.strip.downcase
  exit if letters_used == "quit" || letters_used == "q"
  if letters_used.strip == ""
    array_letters_used = []
  elsif /\A(?:[1-5][a-z][\s,]*)+\z/ =~ letters_used
    array_letters_used = []
    letters_used.split(" ").each do |kv|
      kv.strip!
      array_letters_used << [kv[0].to_i - 1, kv[1]]
    end
  else
    puts "Sorry, the input format is not right"
    array_letters_used = get_letters_used
  end
  array_letters_used
end

def get_letters_not_used
  puts
  puts  "STEP 3".bold.bg_gray + " Input " + "letters not used".underline + " in the word"
  puts  "       Then press \"↵\" (Type \"quit↵\" to exit)"
  if @letters_not_used
    puts  "       Last time: #{@letters_not_used.join.bg_gray}"
  else
    puts  "       Example: #{'ieagh'.bg_gray}"
  end
  print "       ＞ "
  letters_not_used = gets.gsub(/\s+/, "").downcase
  exit if letters_not_used == "quit" || letters_not_used == "q"
  if letters_not_used.strip == ""
    array_letters_not_used = []
  elsif /\A[a-z\s]+\z/ =~ letters_not_used
    array_letters_not_used = letters_not_used.split(//)
  else
    puts "Sorry, the input format is not right"
    array_letters_not_used = get_letters_not_used
  end
  array_letters_not_used
end

def solve_wordle
  @letters_known = get_letters_known
  @letters_used  = get_letters_used
  @letters_not_used = get_letters_not_used
  indices_unknown_letters = (0 ... @letters_known.length).find_all { |i| @letters_known[i, 1] == '.' }

  word_list_a = @word_list.select do |word|
    Regexp.compile(@letters_known) =~ word
  end

  word_list_b = word_list_a.select do |word|
    word_letters = word.split(//)
    letters_in_candidate = word_letters.values_at(*indices_unknown_letters) - @letters_used.map{|l| l[1]}
    cond1 = @letters_used.all? do |position, letter|
      word_letters[position] != letter
    end
    cond2 = (@letters_used.map{|l| l[1]} - word_letters).empty?
    cond3 = (letters_in_candidate - @letters_not_used).size == letters_in_candidate.size
    cond1 && cond2 && cond3
  end

  puts
  puts (' '.bg_green * 4 + ' '.bg_gray * 4 + ' '.bg_brown  * 4 + ' '.bg_gray * 4) * 4
  results = word_list_b.map do |word|
    if @basic_word_uniq_list[word]
      word.red.bold
    elsif @basic_word_list[word]
      word.blue.bold
    else
      word
    end
  end.join("\t")
  puts results
  puts (' '.bg_green * 4 + ' '.bg_gray * 4 + ' '.bg_brown  * 4 + ' '.bg_gray * 4) * 4
  puts

  exit if word_list_b.size < 2

  puts "       Press \"↵\" to continue."
  puts "       Type \"quit↵\" to exit."
  response = gets.strip.downcase
  if response == "quit" || response == "q"
    exit
  else
    solve_wordle
  end
end

solve_wordle
