require 'bundler/setup'
require 'vcr'
require 'simplecov'
SimpleCov.start

require 'saxon/source'

module FixtureHelpers
  def fixture_path(path)
    File.expand_path(File.join('../fixtures', path), __FILE__)
  end

  def fixture_source(path, source_opts = {})
    Saxon::Source.from_path(fixture_path(path), source_opts)
  end

  def fixture_doc(processor, path, source_opts = {})
    doc_builder = processor.document_builder
    doc_builder.build(fixture_source(path, source_opts))
  end

  def string_doc(processor, str, source_opts = {base_uri: "http://example.org/"})
    doc_builder = processor.document_builder
    source = Saxon::Source.from_string(str, source_opts)
    doc_builder.build(source)
  end
end

VCR.configure do |c|
  c.cassette_library_dir = 'spec/fixtures/cassettes'
  c.hook_into :webmock
  c.configure_rspec_metadata!
end

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.include FixtureHelpers
end
