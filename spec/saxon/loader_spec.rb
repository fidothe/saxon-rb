require 'saxon/loader'

module Saxon
  RSpec.describe Loader do
    specify "reports whether it's loaded" do
      if Saxon::S9API.const_defined?(:Processor)
        expect(Saxon::Loader.jars_loaded?).to be(true)
      else
        expect(Saxon::Loader.jars_loaded?).to be(false)
      end
    end
  end
end