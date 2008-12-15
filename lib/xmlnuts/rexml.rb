require 'rexml/document'
require 'xmlnuts/backend'

class XmlNuts::XmlBackend::REXMLBackend #:nodoc:
  def source(source, options)
    case source
    when REXML::Node
      source
    when String
      doc = REXML::Document.new(source)
      doc.root
    else
      nil
    end
  end

  def build(nut, destination, options)
    case destination
    when :string, :document, :object, String, IO
      doc = REXML::Document.new
    when REXML::Node
      node = destination
      doc = node.document
    when REXML::Document
      doc = destination
    else
      raise ArgumentError, 'invalid destination'
    end
    node = doc.root || doc.add_element('root') unless node
    node = nut.class.build_node(nut, node)
    case destination
    when :string
      doc.to_s
    when String
      destination.replace(doc.to_s)
    when IO
      doc.write(destination)
      destination
    when REXML::Document, :document
      doc
    when REXML::Node, :object
      node
    end
  end

  def add_namespaces(context, namespaces)
    namespaces.each {|prefix, uri| context.add_namespace(prefix.to_s, uri) }
  end

  def each_element_with_value(context, name, ns)
    REXML::XPath.each(context, "ns:#{name}", 'ns' => ns) {|el| yield el, el.text }
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

  def to_prefixed_name(context, name, ns, prefix_required)
    if ns
      if prefix = context.namespaces.invert[ns]
        return "#{prefix}:#{name}", nil
      else
        raise ArgumentError, "no prefix defined for #{ns}" if prefix_required
      end
    else
      return name, ns
    end
  end
end
