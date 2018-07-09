require 'java'

module Saxon
  # an easy-to-access place to keep JAXP-related Java classes
  module JAXP
    include_package 'javax.xml.transform.stream'
  end
end
