# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "junk/version"

Gem::Specification.new do |s|
  s.name        = "junk"
  s.version     = Junk::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["David Albert"]
  s.email       = ["davidbalbert@gmail.com"]
  s.homepage    = "http://github.com/davidbalbert/junk"
  s.summary     = %q{A place to keep all the stuff you're not supposed to commit.}
  s.description = %q{Junk is a simple wrapper around git that tracks all the files you're not supposed to commit.}

  s.rubyforge_project = "junk"

  s.add_dependency "trollop", "~> 1.16.2"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

end
