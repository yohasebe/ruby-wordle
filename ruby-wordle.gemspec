require_relative "lib/ruby-wordle/version"

Gem::Specification.new do |s|
  s.name        = "ruby-wordle"
  s.version     = RubyWordle::VERSION
  s.authors     = ["Yoichiro Hasebe"]
  s.email       = ["yohasebe@gmail.com"]
  s.homepage    = "https://github.com/yohasebe/ruby-wordle"
  s.summary     = "Play Wordle and solve Wordle on the command line"
  s.description = "A command-line Wordle game and a solver that ranks the next guess, with English word lists."
  s.license     = "MIT"
  s.metadata    = {
    "source_code_uri" => "https://github.com/yohasebe/ruby-wordle",
    "changelog_uri" => "https://github.com/yohasebe/ruby-wordle/blob/main/CHANGELOG.md",
    "rubygems_mfa_required" => "true"
  }

  s.required_ruby_version = ">= 3.2"
  # Only files tracked by git ship, even if other files match the patterns.
  tracked = IO.popen(%w[git ls-files -z], chdir: __dir__, &:read).split("\x0")
  s.files = Dir["lib/**/*.rb", "bin/ruby-wordle", "word-lists/5-letters/*.txt",
                "README.md", "CHANGELOG.md", "LICENSE", base: __dir__] & tracked
  s.bindir = "bin"
  s.executables = ["ruby-wordle"]
  s.require_paths = ["lib"]

  s.add_dependency "reline", "~> 0.3"
end
