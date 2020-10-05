# this is a generated file, to avoid over-writing it just delete this comment
begin
  require 'jar_dependencies'
rescue LoadError
  require 'net/sf/saxon/Saxon-HE/10.2/Saxon-HE-10.2.jar'
end

if defined? Jars
  require_jar 'net.sf.saxon', 'Saxon-HE', '10.2'
end
