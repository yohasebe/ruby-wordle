# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)

require "ruby-wordle/version"

Gem::Specification.new do |s|
  s.name        = "ruby-wordle"
  s.version     = RubyWordle::VERSION
  s.authors     = ["Yoichiro Hasebe"]
  s.email       = ["yohasebe@gmail.com"]
  s.homepage    = "http://github.com/yohasebe/ruby-wordle"
  s.summary     = %q{A set of ruby scripts to generate word-lists, solve Wordle, and play Wordle}
  s.description = %q{A set of ruby scripts to generate word-lists, solve Wordle, and play Wordle}
  s.licenses    = ["MIT"]
  s.files         = `git ls-files`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # specify any dependencies here; for example:
  s.add_runtime_dependency 'readline'
end
