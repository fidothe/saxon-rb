unless Java::net::sf::saxon::s9api::Xslt30Transformer.instance_methods.include?(:setInitialMode)
  class Java::net::sf::saxon::s9api::Xslt30Transformer
    java_alias :setInitialMode, :setInitialMode, [Java::net::sf::saxon::s9api::QName]
    java_alias :setErrorReporter, :setErrorReporter, [Java::net::sf::saxon::lib::ErrorReporter]
  end
end
