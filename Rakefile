require "bundler/gem_tasks"
require "rake/testtask"
require_relative "lib/ruby-wordle/version"

# The release gate: `rake build` (and so `rake release`) fails unless the
# built gem passes both checks.
Rake::Task["build"].enhance do
  gem = "pkg/ruby-wordle-#{RubyWordle::VERSION}.gem"
  sh "ruby", "script/verify_gem.rb", gem
  sh "ruby", "script/verify_gem_local.rb", gem
end

Rake::TestTask.new(:test) do |t|
  t.libs << "lib" << "test"
  t.test_files = FileList["test/**/*_test.rb"]
end

desc "Regenerate word-lists/N-letters from the source lists (LENGTH=5)"
task :wordlists do
  $LOAD_PATH.unshift File.expand_path("lib", __dir__)
  require "ruby-wordle/dictionary"
  puts RubyWordle::Dictionary.generate(length: Integer(ENV.fetch("LENGTH", "5")))
end

desc "Record the README screenshots in img/ (requires vhs and ttyd)"
task :screenshots do
  FileList["img/*.tape"].each { |tape| sh "vhs", tape }
end

task default: :test
