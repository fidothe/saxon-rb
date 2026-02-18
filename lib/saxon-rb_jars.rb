# this is a generated file, to avoid over-writing it just delete this comment
begin
  require 'jar_dependencies'
rescue LoadError
  require 'net/sf/saxon/Saxon-HE/12.9/Saxon-HE-12.9.jar'
  require 'org/xmlresolver/xmlresolver/5.3.3/xmlresolver-5.3.3.jar'
  require 'org/xmlresolver/xmlresolver/5.3.3/xmlresolver-5.3.3-data.jar'
end

if defined? Jars
  require_jar 'net.sf.saxon', 'Saxon-HE', '12.9'
  require_jar 'org.xmlresolver', 'xmlresolver', '5.3.3'
  require_jar 'org.xmlresolver', 'xmlresolver', 'data', '5.3.3'
end
