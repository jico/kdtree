# -*- encoding: utf-8 -*-
require File.expand_path('../lib/kdtree/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Jico Baligod"]
  gem.email         = ["jico@baligod.com"]
  gem.description   = %q{Ruby kD tree}
  gem.summary       = %q{Ruby kD tree data structure}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "kdtree"
  gem.require_paths = ["lib"]
  gem.version       = KDTree::VERSION

  gem.add_development_dependency "rake"
  gem.add_development_dependency "rspec", "~>2.11.0"
end
