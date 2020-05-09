include YARD
include Templates

module JavadocHtmlHelper
  JAVA_TYPE_MATCHER = /\A(?:[a-z_$](?:[a-z0-9_$]*)\.)+[A-Z][A-Za-z_$]*/
  RUBY_COLLECTION_TYPE_MATCHER = /\A(?:[A-Z][A-Za-z0-9_])(?:::[A-Z][A-Za-z0-9_]*)*</
  SAXON_TYPE_MATCHER = /\A(?:net\.sf\.saxon|com\.saxonica)/

  def format_types(typelist, brackets = true)
    return unless typelist.is_a?(Array)
    list = typelist.map { |type|
      case type
      when JAVA_TYPE_MATCHER
        format_java_type(type)
      else
        super([type], false)
      end
    }
    list.empty? ? "" : (brackets ? "(#{list.join(", ")})" : list.join(", "))
  end

  def format_java_type(type)
    "<tt>" + linkify_saxon_type(type) + "</tt>"
  end

  def linkify_saxon_type(type)
    case type
    when SAXON_TYPE_MATCHER
      link = url_for_java_object(type)
    else
      link = nil
    end
    link ? link_url(link, type, :title => h(type)) : type
  end

  def linkify(*args)
    if args.first.is_a?(String)
      case args.first
      when JAVA_TYPE_MATCHER
        link = url_for_java_object(args.first)
        title = args.first
        link ? link_url(link, title, :title => h(title)) : title
      else
        super
      end
    else
      super
    end
  end

  def url_for(obj, anchor = nil, relative = true)
    case obj
    when JAVA_TYPE_MATCHER
      url_for_java_object(obj, anchor, relative)
    else
      super
    end
  end

  def url_for_java_object(obj, anchor = nil, relative = nil)
    case obj
    when SAXON_TYPE_MATCHER
      package, _, klass = obj.rpartition(".")
      "http://saxonica.com/documentation/index.html#!javadoc/#{package}/#{klass}"
    else
      path = obj.split(".").join("/")
      "https://docs.oracle.com/javase/8/docs/api/index.html?#{path}.html"
    end
  end
end

Template.extra_includes << proc { |opts| JavadocHtmlHelper if opts.format == :html }
# Engine.register_template_path(File.dirname(__FILE__))