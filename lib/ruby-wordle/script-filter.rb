#! /usr/bin/env ruby

NUM_LETTERS = 5

HOME_DIR = File.expand_path(File.join(File.dirname(__FILE__), "..", ".."))

original_word_list = File.readlines("#{HOME_DIR}/word-lists/word-list-original.txt")
basic_word_list = File.readlines("#{HOME_DIR}/word-lists/word-list-basic.txt")
n_letter_dir = "#{HOME_DIR}/word-lists/#{NUM_LETTERS}-letters"

unless Dir.exist? n_letter_dir
  Dir.mkdir File.expand_path(n_letter_dir)
end

n_letter_word_file = File.new(File.join(n_letter_dir, "word-list.txt"), "w")
uniq_n_letter_word_file = File.new(File.join(n_letter_dir, "word-list-uniq-letters.txt"), "w")
basic_n_letter_word_file = File.new(File.join(n_letter_dir, "word-list-basic.txt"), "w")
uniq_basic_n_letter_word_file = File.new(File.join(n_letter_dir, "word-list-basic-uniq-letters.txt"), "w")

original_word_list.sort!.uniq!
original_word_list.each do |line|
  chars = line.strip.split(//)
  if chars.size == NUM_LETTERS
    line.downcase!
    n_letter_word_file.write line
    if chars.uniq.size == chars.size
      uniq_n_letter_word_file.write line
    end
  end
end

basic_word_list.sort!.uniq!
basic_word_list.each do |line|
  chars = line.strip.split(//)
  if chars.size == NUM_LETTERS
    line.downcase!
    basic_n_letter_word_file.write line
    if chars.uniq.size == chars.size
      uniq_basic_n_letter_word_file.write line
    end
  end
end

n_letter_word_file.close
uniq_n_letter_word_file.close
basic_n_letter_word_file.close
uniq_basic_n_letter_word_file.close

