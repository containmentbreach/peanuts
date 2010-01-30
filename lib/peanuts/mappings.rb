require 'forwardable'
require 'peanuts/converters'
require 'set'

module Peanuts
  class Mapping
    attr_reader :local_name, :namespace_uri, :prefix, :options

    def initialize(local_name, options)
      @local_name, @namespace_uri, @prefix, @options = local_name.to_s, options.delete(:ns), options.delete(:prefix), options
    end

    def matches?(reader)
      node_type == reader.node_type &&
        local_name == reader.local_name &&
        namespace_uri == reader.namespace_uri
    end

    def self.node_type(node_type)
      define_method(:node_type) { node_type }
    end
  end

  module Mappings # :nodoc:
    class Root < Mapping
      node_type :element

      def write(writer, &block)
        writer.write(node_type, local_name, namespace_uri, prefix, &block)
      end
    end

    class MemberMapping < Mapping
      attr_reader :name, :type, :converter

      def initialize(name, type, options)
        @bare_name = name.to_s.sub(/\?\z/, '')

        super(options.delete(:name) || @bare_name, options)

        @type = type
        @converter = case type
        when Symbol
          Converter.create!(type, options)
        when Class
          if type < Converter
            @type = nil
            Converter.create!(type, options)
          end
        when Array
          raise ArgumentError, "invalid value for type: #{type.inspect}" if type.length != 1
          options[:item_type] = type.first
          Converter.create!(:list, options)
        else
          raise ArgumentError, "invalid value for type: #{type.inspect}"
        end
        @name, @setter = name.to_sym, :"#{@bare_name}="
      end

      def define_accessors(type)
        raise ArgumentError, "#{name}: method already defined or reserved" if type.method_defined?(name)
        raise ArgumentError, "#{@setter}: method already defined or reserved" if type.method_defined?(@setter)

        ivar = :"@#{@bare_name}"
        raise ArgumentError, "#{ivar}: instance variable already defined" if type.instance_variable_defined?(ivar)

        type.send(:define_method, name) do
          instance_variable_get(ivar)
        end
        type.send(:define_method, @setter) do |value|
          instance_variable_set(ivar, value)
        end
      end

      def read(nut, reader)
        set(nut, read_it(reader, get(nut)))
      end

      def write(nut, writer)
        write_it(writer, get(nut))
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

      def to_xml(value)
        @converter ? @converter.to_xml(value) : value
      end

      def from_xml(text)
        @converter ? @converter.from_xml(text) : text
      end

      def write_node(writer, &block)
        writer.write(node_type, local_name, namespace_uri, prefix, &block)
      end
    end

    module SingleMapping
      private
      def read_it(reader, acc)
        read_value(reader)
      end

      def write_it(writer, value)
        write_node(writer) {|w| write_value(w, value) } if value
      end
    end

    module MultiMapping
      def read_it(reader, acc)
        (acc || []) << read_value(reader)
      end

      def write_it(writer, values)
        values.each {|value| write_node(writer) {|w| write_value(w, value) } } if values
      end
    end

    module ValueMapping
      private
      def read_value(reader)
        from_xml(reader.value)
      end

      def write_value(writer, value)
        writer.write_value(to_xml(value))
      end
    end

    module ObjectMapping
      private
      def read_value(reader)
        Mapper.of(type).read(type.new, reader)
      end

      def write_value(writer, value)
        Mapper.of(type).write_children(value, writer)
      end
    end

    class Content < MemberMapping
      NODETYPES = Set[:text, :significant_whitespace, :cdata].freeze

      include ValueMapping

      node_type :text

      def initialize(name, type, options)
        options[:name] = '#text'
        super
      end

      def matches?(reader)
        NODETYPES.include? reader.node_type
      end

      private
      def read_it(reader, acc)
        (acc || '') << read_value(reader)
      end

      def write_it(writer, value)
        write_value(writer, value) if value
      end
    end

    class ElementValue < MemberMapping
      include SingleMapping
      include ValueMapping

      node_type :element
    end

    class Element < MemberMapping
      include SingleMapping
      include ObjectMapping

      node_type :element
    end

    class Attribute < MemberMapping
      include SingleMapping
      include ValueMapping

      node_type :attribute

      def initialize(name, type, options)
        super
        raise ArgumentError, 'a namespaced attribute must have namespace prefix' if namespace_uri && !prefix
      end
    end

    class ElementValues < MemberMapping
      include MultiMapping
      include ValueMapping

      node_type :element
    end

    class Elements < MemberMapping
      include MultiMapping
      include ObjectMapping

      node_type :element
    end

    class WrapperElement < Element
      def read(nut, reader)
        Mapper.of(type).read(nut, reader)
      end

      def write(nut, writer)
        write_node(writer) {|w| Mapper.of(type).write_children(nut, w) }
      end

      def clear(nut)
        type.mapper.clear(nut)
      end

      def define_accessors(type)
        Mapper.of(self.type).define_accessors(type)
      end
    end

    ShallowElement = WrapperElement
  end
end
