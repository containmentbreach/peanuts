require 'forwardable'
require 'peanuts/converters'

module Peanuts
  class Mapping
    attr_reader :xmlname, :xmlns, :prefix, :options

    def initialize(xmlname, options)
      @xmlname, @xmlns, @prefix, @options = xmlname.to_s, options.delete(:xmlns), options.delete(:prefix), options
    end

    def node_type
      self.class.node_type
    end

    class << self
      def node_type(node_type = nil)
        @node_type = node_type if node_type
        @node_type
      end
    end
  end

  module Mappings
    class Root < Mapping
      node_type :element

      def to_xml(writer, &block)
        writer.write(node_type, xmlname, xmlns, prefix, &block)
      end
    end

    class MemberMapping < Mapping
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
        set(nut, getxml2(node, get(nut)))
      end

      def clear(nut)
        set(nut, nil)
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

      def getxml2(node, acc)
        getxml(node)
      end

      def parse(events)
        type.send(:_restore, events)
      end

      def build(nut, writer)
        type.send(:_save, nut, writer)
      end
    end

    class ElementValue < MemberMapping
      node_type :element

      private
      def getxml(node)
        froxml(node.value)
      end

      def setxml(writer, value)
        writer.write(node_type, xmlname, xmlns, prefix) do |w|
          w.value = toxml(value)
        end
      end
    end

    class Element < MemberMapping
      node_type :element

      private
      def getxml(node)
        parse(node)
      end

      def setxml(writer, value)
        writer.write(node_type, xmlname, xmlns, prefix) do |w|
          build(value, w)
        end
      end
    end

    class Attribute < MemberMapping
      node_type :attribute

      def initialize(name, type, options)
        super
        raise ArgumentError, 'a namespaced attribute must have namespace prefix' if xmlns && !prefix
      end

      private
      def getxml(node)
        froxml(node.value)
      end

      def setxml(node, value)
        backend.set_attribute(node, xmlname, xmlns, toxml(value))
      end
    end

    class ElementValues < MemberMapping
      node_type :element

      private
      def getxml2(node, acc)
        (acc || []) << froxml(node.value)
      end

      def setxml(node, values)
        values.each {|v| add_element(node, toxml(v)) } if values
      end
    end

    class Elements < MemberMapping
      node_type :element

      private
      def getxml2(node, acc)
        (acc || []) << parse(node)
      end

      def setxml(node, elements)
        elements.each {|e| build(node, e, add_element(node)) } if elements
      end
    end
  end
end
