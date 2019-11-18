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

You can find Saxon HE at http://saxon.sourceforge.net/ and Saxonica at
http://www.saxonica.com/

Saxon HE is (c) Michael H. Kay and released under the Mozilla MPL 1.0
(http://www.mozilla.org/MPL/1.0/)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'saxon'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install saxon

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

### Transform an XML document with XSLT

```ruby
transformer = Saxon::Processor.create.xslt_compiler.compile(Saxon::Source.from_path('/path/to/your.xsl'))

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

### Use your Saxon PE license and `.jar`s instead of the bundled Saxon HE

```ruby
require 'saxon-rb'

Saxon::Loader.load!('/path/to/SaxonHE9-9-1-2J') # The folder that contains the .jars, like $SAXON_HOME
config = Saxon::Configuration.create_licensed('/path/to/saxon.lic')
processor = Saxon::Processor.create(config)

processor.xslt_compiler...
```

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
