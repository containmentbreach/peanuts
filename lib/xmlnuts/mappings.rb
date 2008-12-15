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
    end

    module NestedMixin #:nodoc:
      private
      def parse(node)
        backend.each_element_with_value(node, xmlname, xmlns) {|el, txt| return type.parse_node(type.new, el) }
        nil
      end

      def build(node, nut)
        nut && type.build_node(nut, backend.add_element(node, xmlname, xmlns, nil))
      end
    end

    module ElementsMixin #:nodoc:
      private
      def getxml(node)
        node && backend.enum_for(:each_element_with_value, node, xmlname, xmlns).map {|el, v| froxml(v) }
      end

      def setxml(node, values)
        values.each {|x| toxml(node, x) } if values
      end

      def toxml(value, node)
        super(value)
      end
    end

    class ElementValue < MemberMapping
      private
      def getxml(node)
        backend.each_element_with_value(node, xmlname, xmlns) {|e, v| return froxml(v) }
        nil
      end

      def setxml(node, value)
        backend.add_element(node, xmlname, xmlns, toxml(value))
      end
    end

    class Element < MemberMapping
      include NestedMixin

      private
      alias getxml parse
      alias setxml build
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
      include ElementsMixin
    end

    class Elements < MemberMapping
      include NestedMixin
      include ElementsMixin

      private
      alias froxml parse
      alias toxml build
    end
  end
end
