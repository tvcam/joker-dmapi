# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'joker-dmapi/version'

Gem::Specification.new do |gem|
  gem.name          = "joker-dmapi"
  gem.version       = JokerDMAPI::Version::VERSION
  gem.authors       = ["Yuriy Kolodovskyy"]
  gem.email         = %w{kolodovskyy@ukrindex.com}
  gem.description   = %q{Joker DMAPI client library}
  gem.summary       = %q{Joker DMAPI client library}
  gem.homepage      = "https://github.com/kolodovskyy/joker-dmapi"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = %w{lib}

  gem.add_dependency "addressable"
  gem.add_development_dependency "bundler"
end
