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

      def save(writer, &block)
        writer.write(node_type, xmlname, xmlns, prefix, &block)
      end
    end

    class MemberMapping < Mapping
      attr_reader :name, :type, :converter

      def initialize(name, type, options)
        super(options.delete(:xmlname) || name, options)
        case type
        when Array
          raise ArgumentError, "invalid value for type: #{type.inspect}" if type.length != 1
          options[:item_type] = type.first
          @converter = Converter.create!(:list, options)
        when Class
          options[:object_type] = type
        else
          @converter = Converter.create!(type, options)
        end
        @name, @setter, @type = name.to_sym, :"#{name}=", type
      end

      def save(nut, writer)
        save_value(writer, get(nut))
      end

      def restore(nut, reader)
        set(nut, restore_value(reader, get(nut)))
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

      def write(writer, &block)
        writer.write(node_type, xmlname, xmlns, prefix, &block)
      end

      def restore_object(events)
        type.send(:_restore, events)
      end

      def save_object(nut, writer)
        type.send(:_save, nut, writer)
      end
    end

    module SingleMapping
      private
      def restore_value(reader, acc)
        read_value(reader)
      end

      def save_value(writer, value)
        write(writer) {|w| write_value(w, value) }
      end
    end

    module MultiMapping
      def restore_value(reader, acc)
        (acc || []) << read_value(reader)
      end

      def save_value(writer, values)
        for value in values
          write(writer) {|w| write_value(w, value) }
        end
      end
    end

    module ValueMapping
      private
      def read_value(reader)
        from_xml(reader.value)
      end

      def write_value(writer, value)
        writer.value = to_xml(value)
      end
    end

    module ObjectMapping
      private
      def read_value(reader)
        restore_object(reader)
      end

      def write_value(writer, value)
        save_object(value, writer)
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
        raise ArgumentError, 'a namespaced attribute must have namespace prefix' if xmlns && !prefix
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
  end
end
