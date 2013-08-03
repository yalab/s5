# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 's5/version'

Gem::Specification.new do |spec|
  spec.name          = "s5"
  spec.version       = S5::VERSION
  spec.authors       = ["yalab"]
  spec.email         = ["rudeboyjet@gmail.com"]
  spec.description   = %q{Secure Sync to Amazon S3. }
  spec.summary       = %q{This gem provides Amazon S3 sync with client side encryption.}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "aws-sdk"
  spec.add_dependency "fssm"

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "minitest"
end
