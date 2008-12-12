module XmlNuts
  class Mapping
    attr_reader :name, :xmlname, :type, :options

    def initialize(name, type, options)
      @name, @xmlname, @type, @options = name.to_sym, (options.delete(:xmlname) || name).to_s, type, options
    end

    def to_xml(nut, node)
      setxml(node, get(nut))
    end

    def from_xml(nut, node)
      set(nut, getxml(node))
    end

    def get(nut)
      nut.send(name)
    end

    def set(nut, value)
      nut.send("#{name}=", value)
    end
  end

  class PrimitiveMapping < Mapping
    attr_reader :converter

    def initialize(name, type, options)
      super
      @converter = Converters.lookup!(type)
    end

    def get(nut)
      converter.to_xml(super(nut), options)
    end

    def set(nut, text)
      super(nut, converter.from_xml(text, options))
    end
  end

  class ElementMapping < PrimitiveMapping
    def getxml(node)
      (e = node.elements[xmlname]) ? e.text : nil
    end

    def setxml(node, value)
      (node.elements[xmlname] ||= REXML::Element.new(xmlname)).text = value
    end
  end

  class AttributeMapping < PrimitiveMapping
    def getxml(node)
      node.attributes[xmlname]
    end

    def setxml(node, value)
      node.add_attribute(xmlname, value)
    end
  end

  class HasOneMapping < Mapping
    def getxml(node)
      (e = node.elements[xmlname]) ? type.parse(e) : nil
    end

    def setxml(node, value)
      type.build(value, node.add_element(xmlname)) if value
    end
  end
end
