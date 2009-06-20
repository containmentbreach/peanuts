require 'rexml/document'
require 'peanuts/backend'

class Peanuts::XmlBackend::REXMLBackend #:nodoc:
  def parse(source, options)
    case source
    when nil
      return nil
    when REXML::Document
      node = source.root
    when REXML::Node
      node = source
    when String, IO
      node = REXML::Document.new(source).root
    else
      raise ArgumentError, 'invalid source'
    end
    node && yield(node)
  end

  def build(result, options)
    case result
    when :string, :document, :object, String, IO
      doc = REXML::Document.new
    when REXML::Document
      doc = result
    when REXML::Node
      node, doc = result, result.document
    else
      raise ArgumentError, 'invalid destination'
    end
    node ||= doc.root
    unless node
      name, ns, prefix = options[:xmlname], options[:xmlns], options[:xmlns_prefix]
      name, ns = "#{prefix}:#{name}", nil if prefix
      node = add_element(doc, name, ns, nil)
    end

    yield node

    case result
    when :string
      doc.to_s
    when String
      result.replace(doc.to_s)
    when IO
      doc.write(result)
      result
    when REXML::Document, :document
      doc
    when REXML::Node, :object
      node
    end
  end

  def add_namespaces(context, namespaces)
    namespaces.each {|prefix, uri| context.add_namespace(prefix.to_s, uri) }
  end

  def each_element(context, name, ns, &block)
    ns = context.namespace unless ns
    REXML::XPath.each(context, "ns:#{name}", 'ns' => ns, &block)
  end

  def value(node)
    node.text
  end

  def attribute(context, name, ns)
    name, ns = to_prefixed_name(context, name, ns, true)
    context.attributes[name]
  end

  def set_attribute(context, name, ns, text)
    name, ns = to_prefixed_name(context, name, ns, true)
    context.add_attribute(name, text)
  end

  def add_element(context, name, ns, text)
    name, ns = to_prefixed_name(context, name, ns, false)
    elem = context.add_element(name)
    elem.add_namespace(ns) if ns
    elem.text = text if text
    elem
  end

  private
  def to_prefixed_name(context, name, ns, prefix_required)
    if ns
      if prefix = context.namespaces.invert[ns]
        name, ns = "#{prefix}:#{name}", nil
      else
        raise ArgumentError, "no prefix defined for #{ns}" if prefix_required
      end
    end
    return name, ns
  end
end
