# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "birddog/version"

Gem::Specification.new do |s|
  s.name        = "birddog"
  s.version     = Birddog::VERSION
  s.authors     = ["Brandon Dewitt"]
  s.email       = ["brandonsdewitt@gmail.com"]
  s.homepage    = ""
  s.summary     = %q{Birddog (derived from Bloodhound) is for natural language scope creation and user determined rule selection}
  s.description = %q{Seeeeeeeee Readme}

  s.rubyforge_project = "birddog"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # specify any dependencies here; for example:
  s.add_development_dependency "minitest"
  s.add_development_dependency "rake"
  s.add_development_dependency "sqlite3-ruby"
  s.add_development_dependency "pry"

  s.add_runtime_dependency "chronic"
  s.add_runtime_dependency "activerecord"
  s.add_runtime_dependency "activesupport"
  s.add_runtime_dependency "squeel"
end
