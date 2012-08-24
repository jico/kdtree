# -*- encoding: utf-8 -*-
require File.expand_path('../lib/kdtree/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Jico Baligod","Daniel Starling","Monty Williams"]
  gem.email         = ["jicob@crowdtap.com"]
  gem.description   = %q{A Ruby KD Tree implementation.}
  gem.summary       = %q{A vectorized KD Tree based on the Ruby implementation by MagLev.}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "kdtree"
  gem.require_paths = ["lib"]
  gem.version       = VERSION

  gem.add_development_dependency "rake"
  gem.add_development_dependency "rspec", "~>2.11.0"
end
