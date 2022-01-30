#! /usr/bin/env ruby

NUM_LETTERS = 5

word_list = File.readlines("./word-lists/#{NUM_LETTERS}-letters/word-list.txt").map(&:strip)

def get_letters_known
  puts  "STEP 1) 🟩 Input letters and positions using alphabets and dots. Then press Enter"
  puts  "           [e.g. s...h]"
  print "        ＞ "
  letters_known = gets.strip.downcase
  unless /\A[a-z\.]{5}\z/ =~ letters_known
    puts "Sorry, the input format is not right"
    letters_known = get_letters_known
  end
  letters_known
end

def get_letters_used
  puts "STEP 2) 🟨 Input pairs of a position (starting from 1) and a letter. Then press Enter."
  puts "           [e.g. 1g 2e 5a]"
  print "        ＞ "
  letters_used = gets.strip.downcase
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
  puts "STEP 3) ⬛︎ Input letters not used in the word. Then Press Enter."
  puts "           [e.g. ieagh]"
  print "        ＞ "
  letters_not_used = gets.gsub(/\s+/, "").downcase
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

letters_known = get_letters_known
letters_used  = get_letters_used
letters_not_used = get_letters_not_used
indices_unknown_letters = (0 ... letters_known.length).find_all { |i| letters_known[i, 1] == '.' }

word_list_a = word_list.select do |word|
  Regexp.compile(letters_known) =~ word
end

word_list_b = word_list_a.select do |word|
  word_letters = word.split(//)
  letters_in_candidate = word_letters.values_at(*indices_unknown_letters)
  cond1 = letters_used.all? do |position, letter|
    word_letters[position] != letter
  end
  cond2 = (letters_used.map{|l| l[1]} - word_letters).empty?
  cond3 = (letters_in_candidate - letters_not_used).size == letters_in_candidate.size
  cond1 && cond2 && cond3
end

puts "------------------------------------------------"
puts word_list_b.join(", ")
puts "------------------------------------------------"

