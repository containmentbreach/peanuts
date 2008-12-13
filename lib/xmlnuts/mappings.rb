module XmlNuts
  class Mapping
    attr_reader :name, :xmlname, :type, :options, :converter

    def initialize(name, type, options)
      @name, @xmlname, @type, @options = name.to_sym, (options.delete(:xmlname) || name).to_s, type, options
      @setter = :"#{name}="
      @converter = Converters.create(type, options)
    end

    def to_xml(nut, node)
      setxml(node, toxml(get(nut)))
    end

    def from_xml(nut, node)
      set(nut, froxml(getxml(node)))
    end

    private
    def get(nut) #:doc:
      nut.send(name)
    end

    def set(nut, value) #:doc:
      nut.send(@setter, value)
    end

    def toxml(value) #:doc:
      value
    end

    def froxml(text) #:doc:
      text
    end
  end

  class PrimitiveMapping < Mapping
    def initialize(name, type, options)
      if type.is_a?(Array)
        raise ArgumentError, "invalid value for type: #{type}" if type.length != 1
        type, options[:item_type] = :list, type.first
      end
      super
      raise ArgumentError, "converter absent for type #{type.inspect}" unless converter
    end

    private
    def toxml(value) #:doc:
      converter.to_xml(value)
    end

    def froxml(text) #:doc:
      converter.from_xml(text)
    end
  end

  class ElementMapping < PrimitiveMapping
    private
    def getxml(node) #:doc:
      (e = node.elements[xmlname]) && e.text
    end

    def setxml(node, value) #:doc:
      (node.elements[xmlname] ||= REXML::Element.new(xmlname)).text = value
    end
  end

  class AttributeMapping < PrimitiveMapping
    private
    def getxml(node) #:doc:
      node.attributes[xmlname]
    end

    def setxml(node, value) #:doc:
      node.add_attribute(xmlname, value)
    end
  end

  module NestedMany
    private
    def toxml(nested_nuts) #:doc:
      nested_nuts && nested_nuts.map {|x| super(x) }
    end

    def froxml(nested_nodes) #:doc:
      nested_nodes && nested_nodes.map {|x| super(x) }
    end
  end

  class ElementsMapping < PrimitiveMapping
    include NestedMany

    private
    def getxml(node) #:doc:
      (e = node.get_elements(xmlname)) && e.map {|x| x.text }
    end

    def setxml(node, values) #:doc:
      values.each {|x| node.add_element(xmlname).text = x } if values
    end
  end

  class NestedMapping < Mapping
    private
    def toxml(nested_nut) #:doc:
      type.build_node(nested_nut, Element.new(xmlname))
    end

    def froxml(nested_node) #:doc:
      type.parse_node(type.new, nested_node)
    end
  end

  class NestedOneMapping < NestedMapping
    private
    def getxml(node) #:doc:
      node.elements[xmlname]
    end

    def setxml(node, nested_node) #:doc:
      node.elements << nested_node if nested_node
    end
  end

  class NestedManyMapping < NestedMapping
    include NestedMany

    private
    def getxml(node) #:doc:
      node.get_elements(xmlname)
    end

    def setxml(node, nested_nodes) #:doc:
      nested_nodes.each {|x| node.add_element(x) }
    end
  end
end
