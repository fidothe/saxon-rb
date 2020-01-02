# this is a generated file, to avoid over-writing it just delete this comment
begin
  require 'jar_dependencies'
rescue LoadError
  require 'net/sf/saxon/Saxon-HE/9.9.1-6/Saxon-HE-9.9.1-6.jar'
end

if defined? Jars
  require_jar 'net.sf.saxon', 'Saxon-HE', '9.9.1-6'
end
