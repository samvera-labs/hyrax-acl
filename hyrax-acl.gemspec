# frozen_string_literal: true
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'hyrax/acl/version'

Gem::Specification.new do |spec|
  spec.authors       = ["Project Surfliner"]
  spec.emails        = ["tomjohnson@ucsb.edu"]
  spec.description   = 'Access Control List models and support for Hyrax'
  spec.summary       = <<-SUMMARY
  Hyrax Access Control List
SUMMARY

  spec.homepage      = "http://github.com/samvera-labs/hyrax-acl"

  spec.files         = `git ls-files`.split($OUTPUT_RECORD_SEPARATOR).select { |f| File.dirname(f) !~ %r{\A"?spec\/?} }
  spec.executables   = spec.files.grep(%r{^bin/}).map { |f| File.basename(f) }
  spec.name          = "hyrax-acl"
  spec.require_paths = ["lib"]
  spec.version       = Hyrax::Acl::VERSION
  spec.license       = 'Apache-2.0'
  spec.metadata      = { "rubygems_mfa_required" => "true" }

  spec.required_ruby_version = '>= 2.7'

  spec.add_dependency "valkyrie", "~> 2"

  spec.add_development_dependency "rspec"
end
