require 'enumerator'
require 'xmlnuts/backend'
require 'xmlnuts/converters'

module XmlNuts
  module Mappings
    class Mapping
      attr_reader :xmlname, :xmlns, :options

      def initialize(xmlname, options)
        @xmlname, @xmlns, @options = xmlname.to_s, options.delete(:xmlns), options
      end
    end

    class Root < Mapping
      def initialize(xmlname, options = {})
        super
      end
    end

    class MemberMapping < Mapping
      include XmlBackend

      attr_reader :name, :type, :converter

      def initialize(name, type, options)
        super(options.delete(:xmlname) || name, options)
        case type
        when Array
          raise ArgumentError, "invalid value for type: #{type}" if type.length != 1
          options[:item_type] = type.first
          @converter = Converter.create!(:list, options)
        when Class
          options[:object_type] = type
        else
          @converter = Converter.create!(type, options)
        end
        @name, @setter, @type = name.to_sym, :"#{name}=", type
      end

      def to_xml(nut, node)
        setxml(node, get(nut))
      end

      def from_xml(nut, node)
        set(nut, getxml(node))
      end

      private
      def get(nut)
        nut.send(@name)
      end

      def set(nut, value)
        nut.send(@setter, value)
      end

      def toxml(value)
        @converter ? @converter.to_xml(value) : value
      end

      def froxml(text)
        @converter ? @converter.from_xml(text) : text
      end

      def each_element(node, &block)
        node && backend.each_element(node, xmlname, xmlns, &block)
        nil
      end

      def add_element(node, value = nil)
        backend.add_element(node, xmlname, xmlns, value)
      end

      def value(node)
        backend.value(node)
      end

      def parse(node)
        type.parse_node(type.new, node)
      end

      def build(node, nut, dest_node)
        nut && type.build_node(nut, dest_node)
      end
    end

    class ElementValue < MemberMapping
      private
      def getxml(node)
        each_element(node) {|e| return froxml(value(e)) }
      end

      def setxml(node, value)
        add_element(node, toxml(value))
      end
    end

    class Element < MemberMapping
      private
      def getxml(node)
        each_element(node) {|e| return parse(e) }
      end

      def setxml(node, value)
        build(node, value, add_element(node))
      end
    end

    class Attribute < MemberMapping
      private
      def getxml(node)
        froxml(backend.attribute(node, xmlname, xmlns))
      end

      def setxml(node, value)
        backend.set_attribute(node, xmlname, xmlns, toxml(value))
      end
    end

    class ElementValues < MemberMapping
      private
      def each_value(node)
        each_element(node) {|x| yield froxml(value(x)) }
      end

      def getxml(node)
        enum_for(:each_value, node).to_a
      end

      def setxml(node, values)
        unless node
          raise 'fuck'
        end
        values.each {|v| add_element(node, toxml(v)) } if values
      end
    end

    class Elements < MemberMapping
      private
      def each_object(node)
        each_element(node) {|e| yield parse(e) }
      end

      def getxml(node)
        enum_for(:each_object, node)
      end

      def setxml(node, elements)
        elements.each {|e| build(node, e, add_element(node)) } if elements
      end
    end
  end
end
