# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'saxon/version'

Gem::Specification.new do |spec|
  spec.name          = 'saxon'
  spec.version       = Saxon::VERSION
  spec.authors       = ['Matt Patterson']
  spec.email         = ['matt@werkstatt.io']

  spec.description   = %q{Wraps the Saxon 9.9 XML and XSLT library so you can process, transform, query, and generate XML documents using XSLT 3, XQuery, and XPath 3.1. The HE open-source version is bundled, but you can use the paid-for PE and EE versions of the Java library with this gem as well.

It aims to provide an idiomatic Ruby wrapper around all of Saxon's features.}
  spec.summary       = %q{Saxon 9.9 for JRuby, with an idiomatic Ruby API}
  spec.homepage      = "https://github.com/fidothe/saxon-rb"
  spec.license       = 'MIT'
  spec.platform      = 'java'

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.requirements << 'jar net.sf.saxon, Saxon-HE, 9.9.1-2'

  spec.add_development_dependency 'bundler', '~> 2.0'
  spec.add_development_dependency 'jar-dependencies'
  spec.add_development_dependency 'rake', '~> 12.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'vcr', '~> 4.0'
  spec.add_development_dependency 'addressable', '~> 2.4.0'
  spec.add_development_dependency 'webmock', '~> 2.3.2'
  spec.add_development_dependency 'yard', '~> 0.9.12'
  spec.add_development_dependency 'simplecov', '~> 0.15'
end
