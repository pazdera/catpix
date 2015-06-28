# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'catpix/version'

Gem::Specification.new do |spec|
  spec.name          = "catpix"
  spec.version       = Catpix::VERSION
  spec.authors       = ["Radek Pazdera"]
  spec.email         = ["me@radek.io"]
  spec.summary       = %q{Cat images into the terminal.}
  spec.description   = %q{A library and a script that lets you easily print
                          images (png, jpg, gif and others) inside the command
                          line using imagemagick and the extended 256 colour
                          palette.}
  spec.homepage      = "https://github.com/pazdera/catpix"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "tco", "~> 0.1", ">= 0.1.6"
  spec.add_dependency "rmagick", "~> 2.15", ">= 2.15.2"
  spec.add_dependency "docopt", "~> 0.5", ">= 0.5.0"
  spec.add_dependency "ruby-terminfo", "~> 0.1", ">= 0.1.1"

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake", "~> 10.4"
end
