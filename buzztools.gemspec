# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'buzztools/version'

Gem::Specification.new do |spec|
  spec.name          = "buzztools"
  spec.version       = Buzztools::VERSION
  spec.authors       = ["Gary McGhee"]
  spec.email         = ["contact@buzzware.com.au"]
  spec.description   = "reusable function library"
  spec.summary       = "reusable function library"
  spec.homepage      = "https://github.com/buzzware/buzztools"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]
  spec.add_development_dependency "railties", ">= 3.1"
  spec.add_development_dependency "bundler", ">= 1.3"
  spec.add_development_dependency "rake"
end
