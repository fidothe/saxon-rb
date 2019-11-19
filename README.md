# saxon-rb – An idiomatic Ruby wrapper for Saxon

`saxon-rb` aims to be a fully-featured idiomatic wrapper for the Saxon XML
processing and transformation library. Built after several years experience with
writing, using, and maintaining the `saxon-xslt` XSLT-focussed wrapper,
`saxon-rb` aims to keep that ease-of-use for those most common cases, while
making the less-common cases easy as well.

Saxon provides a massive amount of valuable functionality beyond simple XSLT
compilation and invocation, and a lot of that is very hard to use from Ruby. The
facilities provided by it, and by the XSLT 2 and 3 specs, rely heavily on the
XDM values and types system, which `saxon-rb` makes easy to work with.

Parameter creation and passing, are richer and more expressive; results from
XSLT, or XPath, that aren't just result trees can be worked with directly in
Ruby.

[![Gem Version](https://badge.fury.io/rb/saxon.svg)](http://badge.fury.io/rb/saxon)
[![Code Climate](https://codeclimate.com/github/fidothe/saxon-rb/badges/gpa.svg)](https://codeclimate.com/github/fidothe/saxon-rb)
[![Test Coverage](https://codeclimate.com/github/fidothe/saxon-rb/badges/coverage.svg)](https://codeclimate.com/github/fidothe/saxon-rb/coverage)
[![CircleCI](https://circleci.com/gh/fidothe/saxon-rb.svg?style=svg)](https://circleci.com/gh/fidothe/saxon-rb)

You can find Saxon HE at http://saxon.sourceforge.net/ and Saxonica at
http://www.saxonica.com/

Saxon HE is (c) Michael H. Kay and released under the Mozilla MPL 1.0
(http://www.mozilla.org/MPL/1.0/)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'saxon-rb'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install saxon-rb

## Simple usage

```ruby
require 'saxon'

transformer = Saxon::Processor.create.xslt_compiler.compile(Saxon::Source.from_path('/path/to/your.xsl'))
output = transformer.apply_templates(Saxon::Source.from_path('/path/to/your.xml'))
```

## Usage

### Parse an XML document

Using a default document builder from the default processor:

```ruby
document_node = Saxon::Processor.create.document_builder.build(Saxon::Source.from_path('/path/to/your.xml'))
```

Or

```ruby
document_node = Saxon.XML('/path/to/your.xml')
```

### Transform an XML document with XSLT

```ruby
transformer = Saxon::Processor.create.xslt_compiler.compile(Saxon::Source.from_path('/path/to/your.xsl'))
# Or
transformer = Saxon.XSLT('/path/to/your.xsl')

# Apply templates against a document
result_1 = transformer.apply_templates(document_node)

# Call a template without a context item to process
result_2 = transformer.call_template('main-template')
```

### Run XPath queries against an XML document

It's possible to define namespaces and variables for your XPaths

```ruby
processor = Saxon::Processor.create
xpath = processor.xpath_compiler {
  namespace a: 'http://example.org/a'
  variable 'a:var', 'xs:string'
}.compile('//element[@attr = $a:var]')

matches = xpath.run(document_node, {
  'a:var' => 'the value'
})
```

## Migrating from `saxon-xslt` (or Nokogiri)

`saxon-xslt` wrapped Saxon and provided a Nokogiri-esque API. Nokogiri is built on XSLT 1 processors, and the APIs support XSLT 1 features, but won't allow XSLT 2/3 features (like setting initial tunnel parameters, starting processing by calling a named template, or a function). The main API for invoking XSLT in `saxon-rb` needs to be different from Nokogiri's so that full use of XSLT 2/3 features is possible.

By default, the original `saxon-xslt` API (on `Saxon::XSLT::Stylesheet`) is not available. If you need those methods, then you can load the legacy API by requiring `saxon/nokogiri`.

That gives you back the `#transform`, `#apply_to`, and `#serialize` methods on the object you get back after compiling an XSLT: `Saxon::XSLT::Executable` in `saxon-rb`. They work the same way, and you should be able to drop in `saxon-rb` as a replacement for XSLT processing.

```ruby
require 'saxon-rb'
require 'saxon/nokogiri'

xslt = Saxon.XSLT('/path/to/my.xsl')
xslt.apply_to(Saxon.XML('/path/to/my.xml')) #=> "<result-xml/>"
```

## Using your Saxon PE license and `.jar`s instead of the bundled Saxon HE

Saxon 9.9 HE is bundled with the gem. To use Saxon PE or EE (the commercial
versions) you need to make the `.jar`s available, and then create a licensed
`Saxon::Configuration` object. To make the `.jar`s available is simply a matter
of adding them to the `CLASS_PATH`. The version of Saxon downloaded directly
provides several `.jar` files. We provide a `Saxon::Loader` method for adding
the `.jar`s within the directory correctly. Saxon is distributed through Maven
as a single `.jar`, which you can just add to the `LOAD_PATH`/`CLASS_PATH`. If
you're adding to the `CLASS_PATH` directly, or calling `Saxon::Loader.load!`,
then you need to do it before you try and use the library.

### Loading a Saxon PE you downloaded directly from Saxonica

```ruby
require 'saxon-rb'

Saxon::Loader.load!('/path/to/SaxonPE9-9-1-2J') # The folder that contains the .jars, like $SAXON_HOME
config = Saxon::Configuration.create_licensed('/path/to/saxon.lic')
processor = Saxon::Processor.create(config)

processor.xslt_compiler...
```

### Loading a Saxon PE installed via Maven (e.g. with JBundler)

```ruby
require 'jbundler'
require 'saxon-rb'

config = Saxon::Configuration.create_licensed('/path/to/saxon.lic')
processor = Saxon::Processor.create(config)

...
```

See https://github.com/mkristian/jbundler for more on loading Java deps from
Maven.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run
`rake spec` to run the tests. You can also run `bin/console` for an interactive
prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To
release a new version, update the version number in `version.rb`, and then run
`bundle exec rake release`, which will create a git tag for the version, push
git commits and tags, and push the `.gem` file to
[rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at
https://github.com/fidothe/saxon-rb. This project is intended to be a safe,
welcoming space for collaboration, and contributors are expected to adhere to
the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Saxon-rb project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/fidothe/saxon-rb/blob/master/CODE_OF_CONDUCT.md).
