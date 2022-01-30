#! /usr/bin/env ruby
#
NUM_LETTERS = 5

original_word_list = File.readlines("./word-lists/word-list-original.txt")
n_letter_dir = "./word-lists/#{NUM_LETTERS}"

unless Dir.exist? n_letter_dir
  Dir.mkdir File.expand_path(n_letter_dir)
end

n_letter_word_file = File.new(File.join(n_letter_dir, "word-list.txt"), "w")
uniq_n_letter_word_file= File.new(File.join(n_letter_dir, "word-list-uniq"), "w")

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

n_letter_word_file.close
uniq_n_letter_word_file.close
