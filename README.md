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

```ruby
processor = Saxon::Processor.create
xpath = processor.xpath_compiler.compile('//element[@attr = $a:var]')

matches = xpath.run(document_node)
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

## Usage

### XSLT

Using XSLT involves creating a compiler, compiling an XSLT document, and then
using that compiled document to transform something.

#### Constructing a Compiler

The simplest way is to call `#xslt_compiler` on a `Saxon::Processor` instance.

```ruby
processor = Saxon::Processor.create

# Simplest, default options
compiler = processor.xslt_compiler
```

In order to set compile-time options, declare static compile-time parameters
then pass a block to the method using the DSL syntax (see [the DSL
RDoc](https://rubydoc.info/gems/saxon-rb/Saxon/XSLT/EvaluationContext/DSL) for
complete details):

```ruby
compiler = processor.xslt_compiler {
  static_parameters 'param' => 'value'
  default_collation 'https://www.w3.org/2005/xpath-functions/collation/html-ascii-case-insensitive/'
}
```

The static context for a Compiler cannot be changed, you must create a new one
with the context you want. We make it very simple to create a new Compiler based
on an existing one. Declaring a parameter again overwrites the value.

```ruby
new_compiler = compiler.create {
  static_parameters 'param' => 'new value'
}

new_compiler.default_collation #=> "https://www.w3.org/2005/xpath-functions/collation/html-ascii-case-insensitive/"
```

If you wanted to remove a value, you need to start from scratch. You can, of
course, extract any data you want from a compiler instance separately and use
that to create a new one.

```ruby
params = compiler.static_parameters
new_compiler = processor.xslt_compiler {
  static_parameters params
}
new_compiler.default_collation #=> nil
```

#### Compiling an XSLT stylesheet

Once you have a compiler, call `#compile` and pass in a {Saxon::Source} or an
existing {Saxon::XDM::Node}. Parameters and other run-time configuration options
can be set using a block in the same way as creating a compiler. You'll be returned a {Saxon::XSLT::Executable}.

```ruby
source = Saxon::Source.create('my.xsl')
xslt = compiler.compile(source) {
  initial_template_parameters 'param' => 'other value'
}
```

You can also pass in (or override) parameters at stylesheet execution time, but if you'll be executing the same stylesheet against many documents with the same initial parameters then setting them at compile time is simpler.

#### Executing an XSLT stylesheet

Once you have a compiled stylesheet, then it can be executed against a source document in a variety of ways.

First, you can use the traditional *apply templates* ,method, which was the only way in XSLT 1.

```ruby
input = Saxon::Source.create('input.xml')
result = xslt.apply_templates(input)
```

Next, you can call a specific named template (new in XSLT 2).

```ruby
result = xslt.call_template('template-name')
```

Note that there's no input document here. If your XSLT needs a global context item set when you invoke it via a named template, then you can do that, too:

```ruby
input = processor.XML('input.xml')
result = xslt.call_template('template-name', {
  global_context_item: input
})
```

Global and initial template parameters can be set at compiler creation time, compile time, or execution time. See [Setting parameters](#label-Setting+parameters) for details.

#### Setting parameters

There are four kinds of parameters you can set: *Static parameters*, which are
set at stylesheet compile time and cannot be changed after compilation. *Global
parameters* defined by top-level `<xsl:parameter/>` are available throughout an
XSLT, and they can be set when the compiled XSLT is run. The other two kinds
of parameters relate to parameters passed to the *first* template run (either
the first template matched when called with `#apply_templates`, or the named
template called with `#call_template`). *Initial template parameters* are
essentially implied `<xsl:with-parameter tunnel="no">` elements. *Initial
template tunnel parameters* are implied `<xsl:with-parameter tunnel="yes">`
elements.

```ruby
# At compile time
xslt = compiler.compile(source) {
  static_parameters 'static-param' => 'static value'
  global_parameters 'param' => 'global value'
  initial_template_parameters 'param' => 'other value'
  initial_template_tunnel_parameters 'param' => 'tunnel value'
}

# At execution time
xslt.apply_templates(input, {
  global_parameters: {'param' => 'global value'},
  initial_template_parameters: {'param' => 'other value'},
  initial_template_tunnel_parameters: {'param' => 'tunnel value'}
})
```

Multiple parameters can be set:

```ruby
# At compile time
xslt = compiler.compile(source) {
  global_parameters 'param-1' => 'a', 'param-2' => 'b'
}

# At execution time
xslt.apply_templates(input, {
  global_parameters: {'param-1' => 'a', 'param-2' => 'b'}
})
```

Parameter names in XSLT are QNames, and values are an XDM Value. `saxon-rb` will
convert Ruby values (see {Saxon::QName.resolve} and {Saxon::XDM.Value}). You can
also use explicit {Saxon::QName} or XDM values:

```ruby
compiler.compile(source) {
  global_parameters Saxon::QName.clark('{http://example.org/#ns}name') => Saxon::XDM.Value(1)
}
```

If you need to use parameter names which use a namespace prefix, you must use an
explicit {Saxon::QName} to refer to it.

### XPath

Using an XPath involves creating a compiler, compiling an XPath into an
executable, and then running that XPath executable against an XDM node.

In order to use prefixed QNames in your XPaths, like +/ns:name/+, then you need
to declare prefix/namespace URI bindings when you create a compiler.

It's also possible to make use of variables in your XPaths by declaring them at
the compiler creation stage, and then passing in values for them as XPath run
time.

```ruby
processor = Saxon::Processor.create
xpath = processor.xpath_compiler {
  namespace a: 'http://example.org/a'
  variable 'a:var', 'xs:string'
}.compile('//a:element[@attr = $a:var]')

matches = xpath.evaluate(document_node, {
  'a:var' => 'the value'
}) #=> Saxon::XDM::Value
```

The {XPath::Executable#evaluate} method returns an XDM Value containing the
result sequence. For a result sequence with multiple items then it'll be a
{Saxon::XDM::Value}. A single-item sequence will return an appropriate item
instance - a {Saxon::XDM::Node} or a {Saxon::XDM::AtomicValue}.

You can also use the {XPath::Executable#as_enum} to return a lazy enumerator
over the result.

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
