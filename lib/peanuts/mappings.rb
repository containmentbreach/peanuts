require 'forwardable'
require 'peanuts/backend'
require 'peanuts/converters'
require 'peanuts/xml/footprint'

module Peanuts
  module Mappings
    class Footprint
      extend Forwardable
      include Peanuts::XML::Footprint

      def initialize(mapping)
        @mapping = mapping
      end

      def_delegator :@mapping, :node_type
      def_delegator :@mapping, :xmlname, :name
      def_delegator :@mapping, :xmlns, :ns
    end

    class Mapping
      attr_reader :xmlname, :xmlns, :options

      def initialize(xmlname, options)
        @xmlname, @xmlns, @options = xmlname.to_s, options.delete(:xmlns), options
      end

      def footprint
        Footprint.new(self)
      end

      def node_type
        @@node_type
      end

      def self.node_type(node_type)
        @@node_type = node_type
      end
    end

    class Root < Mapping
      def initialize(xmlname, options = {})
        super
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
        type.parse_events(type.new, events)
      end

      def build(node, nut, dest_node)
        nut && type.build_node(nut, dest_node)
      end
    end

    class ElementValue < MemberMapping
      node_type :element

      private
      def getxml(node)
        froxml(node.read_text)
      end

      def setxml(node, value)
        add_element(node, toxml(value))
      end
    end

    class Element < MemberMapping
      node_type :element

      private
      def getxml(node)
        parse(node.subtree)
      end

      def setxml(node, value)
        build(node, value, add_element(node))
      end
    end

    class Attribute < MemberMapping
      node_type :attribute

      private
      def getxml(node)
        froxml(node.value)
      end

      def setxml(node, value)
        backend.set_attribute(node, xmlname, xmlns, toxml(value))
      end

      def node_type
        :attribute
      end
    end

    class ElementValues < MemberMapping
      node_type :element

      private
      def getxml2(node, acc)
        (acc || []) << node.read_text
      end

      def setxml(node, values)
        unless node
          raise 'fuck'
        end
        values.each {|v| add_element(node, toxml(v)) } if values
      end

      def node_type
        :element
      end
    end

    class Elements < MemberMapping
      node_type :element

      private
      def getxml2(node, acc)
        (acc || []) << parse(node.subtree)
      end

      def setxml(node, elements)
        elements.each {|e| build(node, e, add_element(node)) } if elements
      end

      def node_type
        :element
      end
    end
  end
end
