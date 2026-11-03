#!/usr/bin/env ruby
# frozen_string_literal: true

# Release checks specific to ruby-wordle, run after script/verify_gem.rb
# (a verbatim copy of the shared gate) on the same built gem:
#
#   ruby script/verify_gem_local.rb pkg/ruby-wordle-X.Y.Z.gem
#
# 1. the working tree is clean: no uncommitted edits, no untracked files
# 2. every shipped file is byte-identical to its blob in HEAD
# 3. the shipped word lists are exactly what Dictionary.generate makes from
#    the source lists in HEAD
# 4. every line of the shipped word lists is five lowercase letters

require "rubygems"
require "rubygems/package"
require "zlib"
require "tmpdir"
require "fileutils"

gem_path = ARGV[0] or abort "verify_gem_local: pass the built .gem path"
abort "verify_gem_local: #{gem_path} not found" unless File.file?(gem_path)

def git(*args)
  out = IO.popen(["git", *args], "rb", &:read)
  abort "verify_gem_local: git #{args.join(' ')} failed" unless $?.success?
  out
end

payload = {}
Gem::Package::TarReader.new(File.open(gem_path, "rb")) do |outer|
  outer.each do |entry|
    next unless entry.full_name == "data.tar.gz"

    Zlib::GzipReader.wrap(entry) do |gz|
      Gem::Package::TarReader.new(gz) do |inner|
        inner.each { |e| payload[e.full_name.sub(%r{\A\./}, "")] = e.read.to_s if e.file? }
      end
    end
  end
end
abort "verify_gem_local: payload is empty — nothing was inspected" if payload.empty?

failures = []

dirty = git("status", "--porcelain", "--untracked-files=all").lines.map(&:chomp)
failures << "working tree is not clean (#{dirty.size}):\n  " + dirty.join("\n  ") unless dirty.empty?

differ = payload.reject { |name, data| git("show", "HEAD:#{name}") == data }.keys
failures << "shipped files differ from HEAD (#{differ.size}):\n  " + differ.join("\n  ") unless differ.empty?

lists = payload.keys.grep(%r{\Aword-lists/5-letters/[^/]+\.txt\z}).sort
failures << "no word lists in the gem" if lists.empty?

Dir.mktmpdir do |dir|
  %w[word-list-original.txt word-list-basic.txt].each do |name|
    File.binwrite(File.join(dir, name), git("show", "HEAD:word-lists/#{name}"))
  end
  $LOAD_PATH.unshift File.expand_path("../lib", __dir__)
  require "ruby-wordle/dictionary"
  out = RubyWordle::Dictionary.generate(length: 5, source_dir: dir, out_dir: File.join(dir, "out"))
  generated = Dir.children(out).sort.map { |name| "word-lists/5-letters/#{name}" }
  failures << "generated lists #{generated} do not match shipped #{lists}" unless generated == lists
  stale = lists.reject { |name| File.exist?(File.join(out, File.basename(name))) && File.binread(File.join(out, File.basename(name))) == payload[name] }
  failures << "word lists differ from a fresh generation (#{stale.size}):\n  " + stale.join("\n  ") unless stale.empty?
end

bad_lines = lists.sum { |name| payload[name].lines.count { |line| !line.match?(/\A[a-z]{5}\n\z/) } }
failures << "word list lines that are not five lowercase letters: #{bad_lines}" unless bad_lines.zero?

if failures.empty?
  puts "verify_gem_local: PASS — #{payload.size} files match HEAD; #{lists.size} word lists match a fresh generation"
else
  warn "verify_gem_local: FAIL — #{gem_path}"
  failures.each { |f| warn "  * #{f}" }
  exit 1
end
