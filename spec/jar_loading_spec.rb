if ENV['VERIFY_SAXON_LAZY_LOADING']
  require 'bundler/setup'
  require 'simplecov'
  SimpleCov.start
  require 'pathname'

  RSpec.describe "Jar loading" do
    specify "Bundled Saxon Jars not added to classpath after all Ruby files have been required" do
      lib_path = Pathname.new(__dir__).join('../lib').realpath

      require_targets = Pathname.glob("#{lib_path}/**/*.rb").map { |path|
        path.relative_path_from(lib_path).to_s.slice(0..-4)
      }.sort_by { |target| target.scan('/').size }.reject { |target|
        %w{saxon-rb_jars saxon/jruby_bug_6197_workaround}.include?(target)
      }

      require_targets.each do |target|
        require target
      end

      expect(Saxon::Loader.jars_on_classpath?).to be(false)

      if ENV['ALTERNATE_SAXON_HOME']
        Saxon::Loader.load!(ENV['ALTERNATE_SAXON_HOME'])
      else
        Saxon::Loader.load!
      end

      expect(Saxon::Loader.jars_on_classpath?).to be(true)
    end
  end
end