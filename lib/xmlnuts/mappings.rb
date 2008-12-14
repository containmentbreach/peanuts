module XmlNuts
  class Mapping
    attr_reader :name, :xmlname, :xmlns, :type, :options, :converter

    def initialize(name, type, options)
      case type
      when Array
        raise ArgumentError, "invalid value for type: #{type}" if type.length != 1
        options[:item_type] = type.first
        @converter = Converters.create!(:list, options)
      when Class
        options[:object_type] = type
      else
        @converter = Converters.create!(type, options)
      end
      @name, @setter, @type, @options = name.to_sym, :"#{name}=", type, options
      @xmlname, @xmlns = (options.delete(:xmlname) || name).to_s, options.delete(:xmlns)
      @xmlns = @xmlns.to_s if @xmlns
    end

    def to_xml(backend, nut, node)
      setxml(backend, node, toxml(backend, get(nut)))
    end

    def from_xml(backend, nut, node)
      set(nut, froxml(backend, getxml(backend, node)))
    end

    private
    def get(nut) #:doc:
      nut.send(@name)
    end

    def set(nut, value) #:doc:
      nut.send(@setter, value)
    end

    def toxml(backend, value) #:doc:
      @converter ? @converter.to_xml(value) : value
    end

    def froxml(backend, text) #:doc:
      @converter ? @converter.from_xml(text) : text
    end
  end

  class ElementValueMapping < Mapping
    private
    def getxml(backend, node) #:doc:
      backend.each_element_with_value(node, xmlname, xmlns) {|e, v| return v }
      nil
    end

    def setxml(backend, node, value) #:doc:
      backend.add_element(node, xmlname, xmlns, value)
    end
  end

  class ElementMapping < Mapping
    private
    def getxml(backend, node) #:doc:
      backend.each_element_with_value(node, xmlname, xmlns) {|el, txt| return type.parse_node(backend, type.new, el) }
      nil
    end

    def setxml(backend, node, nut) #:doc:
      type.build_node(backend, nut, backend.add_element(node, xmlname, xmlns, nil))
    end
  end

  class AttributeMapping < Mapping
    private
    def getxml(backend, node) #:doc:
      backend.attribute(node, xmlname, xmlns)
    end

    def setxml(backend, node, value) #:doc:
      backend.set_attribute(node, xmlname, xmlns, value)
    end
  end

  class ElementValuesMapping < Mapping
    private
    def toxml(backend, values) #:doc:
      values.map {|x| super(backend, x) }
    end

    def froxml(backend, values) #:doc:
      values.map {|x| super(backend, x) }
    end

    def getxml(backend, node) #:doc:
      node && backend.enum_for(:each_element_with_value, node, xmlname, xmlns).map {|el, v| v }
    end

    def setxml(backend, node, values) #:doc:
      values.each {|x| backend.add_element(node, xmlname, xmlns, x) } if values
    end
  end

  class ElementsMapping < Mapping
    private
    def getxml(backend, node) #:doc:
      node && backend.enum_for(:each_element_with_value, node, xmlname, xmlns).map do |el, v|
        type.parse_node(backend, type.new, el)
      end
    end

    def setxml(backend, node, nuts) #:doc:
      nuts.each {|nut| type.build_node(backend, nut, backend.add_element(node, xmlname, xmlns, nil)) } if nuts
    end
  end
end
