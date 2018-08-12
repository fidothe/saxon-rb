require 'saxon/loader'

module Saxon
  module S9API
    def self.const_missing(name)
      Saxon::Loader.load!
      begin
        const_get(name)
      rescue NameError
        msg = "uninitialized constant Saxon::S9API::#{name}"
        e = NameError.new(msg, name)
        raise e
      end
    end
  end
end
