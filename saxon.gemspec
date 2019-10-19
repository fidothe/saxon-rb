# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'saxon/version'

Gem::Specification.new do |spec|
  spec.name          = 'saxon'
  spec.version       = Saxon::VERSION
  spec.authors       = ['Matt Patterson']
  spec.email         = ['matt@werkstatt.io']

  spec.description   = %q{Deprecated version of the Saxon XML and XSLT library wrapper.

The gem has been renamed saxon-rb. This gem depends on that gem. To continue to see updates, please replace saxon with saxon-rb in your Gemfiles.

This gem has a hard dependency on version #{Saxon::VERSION} of saxon-rb, but will never be updated.
}
  spec.summary       = %q{Saxon 9.9 for JRuby, with an idiomatic Ruby API, now renamed to saxon-rb}
  spec.homepage      = "https://github.com/fidothe/saxon-rb"
  spec.license       = 'MIT'
  spec.platform      = 'java'
  spec.post_install_message = "saxon has been renamed to saxon-rb. Please rename in your Gemfile or gemspec (that's all you need to do). This gem won't get any new updates."

  spec.files         = %w{LICENSE.txt saxon.gemspec lib}
  spec.bindir        = 'exe'
  spec.executables   = []
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'saxon-rb', Saxon::VERSION
end
